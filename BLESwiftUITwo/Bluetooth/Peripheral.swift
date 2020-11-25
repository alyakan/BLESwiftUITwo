//
//  Peripheral.swift
//  BLESwiftUITwo
//
//  Created by Aly Yakan on 23/11/2020.
//

import CoreBluetooth
import Combine

// I created a separate struct for this because the RSSI value comes in the callback and should not be read from
// the CBPeripheral object as it's deprecated.
class Peripheral: ObservableObject, Identifiable {
    enum State {
        case disconnected, connecting, connected, disconnecting, unknown

        init(_ value: Int) {
            switch value {
            case 0: self = .disconnected
            case 1: self = .connecting
            case 2: self = .connected
            case 3: self = .disconnecting
            default: self = .unknown
            }
        }
    }

    let id: UUID
    let name: String?

    @Published var state: State
    @Published var rssi: Int?

    private(set) var cbPeripheral: CBPeripheral? // TODO: Might not need.

    init(from cbPeripheral: CBPeripheral, rssi: Int?) {
        id = cbPeripheral.identifier
        name = cbPeripheral.name
        state = State(cbPeripheral.state.rawValue)
        self.rssi = rssi
        self.cbPeripheral = cbPeripheral
    }

    private init(id: UUID, name: String?, state: State, rssi: Int?) {
        self.id = id
        self.name = name
        self.state = state
        self.rssi = rssi
    }
}

// MARK: - Mock Data {

extension Peripheral {
    static let mockData = [
        Peripheral(id: UUID(uuidString: "d0984ccc-2b42-11eb-adc1-0242ac120002")!, name: "NM Series 2 Charger", state: .disconnected, rssi: -94),
        Peripheral(id: UUID(uuidString: "d0984ccc-2b42-11eb-adc1-0242ac120003")!, name: "NM Series 2 Charger", state: .disconnected, rssi: -90),
        Peripheral(id: UUID(uuidString: "d0984ccc-2b42-11eb-adc1-0242ac120004")!, name: "NM Series 2 Charger", state: .disconnected, rssi: -85),
        Peripheral(id: UUID(uuidString: "d0984ccc-2b42-11eb-adc1-0242ac120005")!, name: "NM Series 2 Charger", state: .disconnected, rssi: -99),
        Peripheral(id: UUID(uuidString: "d0984ccc-2b42-11eb-adc1-0242ac120006")!, name: "NM Series 2 Charger", state: .disconnected, rssi: -65),
        Peripheral(id: UUID(uuidString: "d0984ccc-2b42-11eb-adc1-0242ac120007")!, name: "NM Series 2 Charger", state: .disconnected, rssi: -72),
    ]
}

// MARK: - Equatable

extension Peripheral: Equatable {
    static func == (lhs: Peripheral, rhs: Peripheral) -> Bool {
        lhs.id == rhs.id
    }
}
