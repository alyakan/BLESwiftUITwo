//
//  ContentViewModel.swift
//  BLESwiftUITwo
//
//  Created by Aly Yakan on 25/11/2020.
//

import Foundation
import Combine

enum BLEConnectionState {
    case unknown, resetting, unsupported, unauthorized, poweredOff, poweredOn

    init(_ value: Int) {
        switch value {
        case 1: self = .resetting
        case 2: self = .unsupported
        case 3: self = .unauthorized
        case 4: self = .poweredOff
        case 5: self = .poweredOn
        default: self = .unknown
        }
    }
}

class ContentViewModel: ObservableObject {
    private let bleServer: BLEServer
    private let cancelBag = CancelBag()
    private let readableChar: ReadableChar
    private let writableChar: WritableChar
    private let notifyChar: GenericChar

    @Published var connectionState: BLEConnectionState = .unknown
    @Published var peripherals: [Peripheral] = []
    @Published var connectedPeripheral: Peripheral?
    @Published var loading: Bool = false

    @Published private(set) var rCharValue: String = ""
    @Published private(set) var wCharValue: String = ""
    @Published private(set) var nCharValue: String = ""

    init(bleServer: BLEServer = testBleServer) {
        self.bleServer = bleServer
        self.readableChar = ReadableChar(bleServer: bleServer)
        self.writableChar = WritableChar(bleServer: bleServer)
        self.notifyChar = GenericChar(uuid: Constants.notifyCharacteristicUUID, service: .test, bleServer: bleServer)

        // Observe the bluetooth state
        bleServer.state.$state.sink { [weak self] cbManagerState in
            self?.connectionState = BLEConnectionState(cbManagerState.rawValue)

            if cbManagerState == .poweredOn {
                self?.bleServer.scanForPeripherals()
            }
        }.store(in: cancelBag)

        // Observe the list of peripherals
        bleServer.state.$peripherals.sink { [weak self] peripherals in
            self?.peripherals = peripherals
        }.store(in: cancelBag)

        // Observe the current connected peripheral
        bleServer.state.$connectedPeripheral.sink { [weak self] peripheral in
            self?.connectedPeripheral = peripheral
            self?.loading = false
        }.store(in: cancelBag)

        // Observe readableChar Characteristic value
        readableChar.$value.sink { [weak self] value in
            self?.rCharValue = value
        }.store(in: cancelBag)

        // Observe writeablChar Characteristic value
        writableChar.$value.sink { [weak self] value in
            self?.wCharValue = value
        }.store(in: cancelBag)

        // Observe notifyChar Characteristic value
        notifyChar.$value.sink { [weak self] value in
            self?.nCharValue = value
        }.store(in: cancelBag)
    }

    func start() {
        bleServer.start()
    }

    func connect(peripheral: Peripheral) {
        loading = true
        bleServer.connect(peripheral: peripheral)
    }

    func writeOutValue(_ value: String) {
        guard let data = value.data(using: .utf8) else {
            return
        }

        bleServer.write(data: data, char: writableChar)
    }
}
