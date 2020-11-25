//
//  BLEServiceState.swift
//  BLESwiftUITwo
//
//  Created by Aly Yakan on 23/11/2020.
//

import SwiftUI
import CoreBluetooth
import Combine
import OSLog

struct Constants {
    static let testServiceUUID = CBUUID(string: "00ff0000-1000-1000-1000-ffffffff0000")
    static let writeableCharacteristicUUID = CBUUID(string: "00ff0000-1000-1000-1000-000000000001")
    static let readableCharacteristicUUID = CBUUID(string: "00ff0000-1000-1000-1000-000000000002")
    static let notifyCharacteristicUUID = CBUUID(string: "00ff0000-1000-1000-1000-000000000003")
}

class BLEServerState: ObservableObject {
    @Published private(set) var state = CBManagerState.unknown
    @Published private(set) var peripherals: [Peripheral] = []
    @Published private(set) var connectedPeripheral: Peripheral? = nil
    @Published private(set) var services: [CBService]? = nil // Might not be needed.
    @Published private(set) var characteristics: [CBCharacteristic] = []
    @Published private(set) var myChars: [Characterestic] = [] // experimenting custom class wrapper.

    fileprivate func updateState(_ state: CBManagerState) {
        self.state = state
    }

    fileprivate func appendOrUpdate(peripheral: Peripheral) {
        guard  let index = peripherals.firstIndex(of: peripheral) else {
            os_log("Discovered new peripheral: \(peripheral.id), \(peripheral.name ?? "No Name")")
            peripherals.append(peripheral)
            return
        }

        peripherals[index] = peripheral

        if connectedPeripheral == peripheral {
            connectedPeripheral = peripheral
        }
    }

    fileprivate func setConnectedPeripheral(from cbPeripheral: CBPeripheral) {
        guard connectedPeripheral?.id != cbPeripheral.identifier else { return }

        guard let discovered = peripherals.first(where: { $0.id == cbPeripheral.identifier }) else {
            connectedPeripheral = Peripheral(from: cbPeripheral, rssi: nil)
            cbPeripheral.readRSSI()
            return
        }

        connectedPeripheral = Peripheral(from: cbPeripheral, rssi: discovered.rssi)
    }

    fileprivate func disconnectPeripheral(_ cbPeripheral: CBPeripheral) {
        guard connectedPeripheral?.id == cbPeripheral.identifier else {
            reset()
            os_log("Tried to disconnect peripheral but it is not the currently connected peripheral.")
            return
        }

        os_log("Disconnecting current peripheral.")
        reset()
    }

    // todo: might not be needed
    fileprivate func appendOrUpdate(service: CBService) {
        guard let index = services?.firstIndex(of: service) else {
            services?.append(service)
            return
        }

        services?[index] = service
    }

    fileprivate func appendOrUpdate(characteristic: CBCharacteristic) {
        guard let index = characteristics.firstIndex(of: characteristic) else {
            characteristics.append(characteristic)
            myChars.append(Characterestic(id: characteristic.uuid, value: characteristic.value))
            return
        }

        characteristics[index] = characteristic
        myChars[index].value = characteristic.value
    }

    private func reset() {
        connectedPeripheral = nil
        services = nil
        characteristics = []
        myChars = []
    }
}

// MARK: - BLE Server

// TODO: Make it a singleton.
class BLEServer: NSObject {
    @ObservedObject var state = BLEServerState()

    private let services: [BLEServiceIdentifiers]

    private lazy var centralManager: CBCentralManager = CBCentralManager(
        delegate: self,
        queue: nil,
        options: [CBCentralManagerOptionShowPowerAlertKey: true])

    private var servicesIds: [CBUUID] {
        services.map { $0.uuid }
    }

    init(services: [BLEServiceIdentifiers]) {
        self.services = services
    }

    func start() {
        os_log("Starting bluetooth central manager.")
        _ = centralManager

        state.updateState(centralManager.state)
    }

    func scanForPeripherals() {
        os_log("Scanning for peripherals...")
        centralManager.scanForPeripherals(
            withServices: servicesIds,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    func connect(peripheral: Peripheral) {
        guard let cbPeripheral = peripheral.cbPeripheral else { return }

        os_log("Connecting to peripheral with id: \(peripheral.id)")
        cbPeripheral.delegate = self
        centralManager.connect(cbPeripheral)
    }

    func readData(for characteristic: CharacteristicProtocol) {
        guard let cbCharacteristic = characteristic.cbCharacteristic else { return }

        state.connectedPeripheral?.cbPeripheral?.readValue(for: cbCharacteristic)
    }

    func write(data: Data, char: CharacteristicProtocol) {
        guard let cbCharacteristic = char.cbCharacteristic else { return }

        state.connectedPeripheral?.cbPeripheral?.writeValue(data, for: cbCharacteristic, type: .withResponse)
        // To update the characteristic's value after the write. There is probably a better way.
        state.connectedPeripheral?.cbPeripheral?.readValue(for: cbCharacteristic)
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEServer: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state.updateState(central.state)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        state.appendOrUpdate(peripheral: Peripheral(from: peripheral, rssi: RSSI.intValue))
    }
}

// MARK: - CBPeripheralDelegate

extension BLEServer: CBPeripheralDelegate {

    // MARK: - Connect/Disconnect to peripheral

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("Connected to peripheral with id: \(peripheral.identifier)")
        centralManager.stopScan()
        state.setConnectedPeripheral(from: peripheral)
        peripheral.discoverServices(servicesIds)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("Disconnected from peripheral with id: \(peripheral.identifier)")
        state.disconnectPeripheral(peripheral)
    }

    // MARK: - Discover/Invalidate services

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            os_log("Error while discovering services: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else {
            os_log("No services found in the peripheral.")
            return
        }

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service) // Discover all characteristics of this service.
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        // todo: code
        os_log("Did invalidate services: \(invalidatedServices.debugDescription)")
    }

    // MARK: - Discover/Update characteristics

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            os_log("No characteristics found in the peripheral.")
            return
        }

        for char in characteristics {
            peripheral.readValue(for: char)

            if char.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: char)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        state.appendOrUpdate(characteristic: characteristic)
    }
}
