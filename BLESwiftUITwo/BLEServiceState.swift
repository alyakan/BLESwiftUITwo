//
//  BLEServiceState.swift
//  BLESwiftUITwo
//
//  Created by Aly Yakan on 23/11/2020.
//

import SwiftUI
import CoreBluetooth
import Combine

enum Service: String {
    case test = "00ff0000-1000-1000-1000-ffffffff0000" // Test Service using Keith's GATT Server.
    case bleAuthorization = "06600000-E844-4E43-8AB5-8930F76B0FED"
}

class WriteableChar: ObservableObject {
    let uuid = Constants.writeableCharacteristicUUID
    let service: Service = .test
    let bleServer : BLEServer

    private var cbCharacteristic: CBCharacteristic?
    private var cancellable: AnyCancellable?

    init(bleServer: BLEServer) {
        self.bleServer = bleServer
        cancellable = bleServer.bleState.$characteristics
            .sink { [weak self] characteristics in
                guard let self = self else { return }

                self.cbCharacteristic = characteristics?.first(where: { $0.uuid == self.uuid })
            }
    }
}

struct Constants {
    static let serviceUUID = CBUUID(string: "00ff0000-1000-1000-1000-ffffffff0000")
    static let writeableCharacteristicUUID = CBUUID(string: "00ff0000-1000-1000-1000-000000000001")
    static let readableCharacteristicUUID = CBUUID(string: "00ff0000-1000-1000-1000-000000000002")
}

class BLEServerState: ObservableObject {
    @Published private(set) var state = CBManagerState.unknown
    @Published private(set) var peripherals: [Peripheral] = []
    @Published private(set) var connectedPeripheral: Peripheral? = nil
    @Published private(set) var services: [CBService]? = nil
    @Published private(set) var characteristics: [CBCharacteristic]? = nil

    fileprivate func updateState(_ state: CBManagerState) {
        self.state = state
    }

    fileprivate func appendOrUpdate(peripheral: Peripheral) {
        guard  let index = peripherals.firstIndex(of: peripheral) else {
            peripherals.append(peripheral)
            return
        }

        peripherals[index] = peripheral
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
            print("Tried to disconnect peripheral but it is not the currently connected peripheral.")
            return
        }

        print("Disconnecting current peripheral.")
        connectedPeripheral = nil
        services = nil
        characteristics = nil
    }
}

class BLEServer: NSObject {
    // TODO: Make it a singleton.
    private lazy var centralManager: CBCentralManager = CBCentralManager(
        delegate: self,
        queue: nil,
        options: [CBCentralManagerOptionShowPowerAlertKey: true])

    @ObservedObject var bleState = BLEServerState()

    func start() {
        _ = centralManager
    }

    func scanForPeripherals(withServices services: [CBUUID]) {
        centralManager.scanForPeripherals(
            withServices: services,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
}

extension BLEServer: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bleState.updateState(central.state)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        bleState.appendOrUpdate(peripheral: Peripheral(from: peripheral, rssi: RSSI.intValue))
    }
}

extension BLEServer: CBPeripheralDelegate {
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        bleState.setConnectedPeripheral(from: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {

    }
}
