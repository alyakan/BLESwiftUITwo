//
//  Characteristics.swift
//  BLESwiftUITwo
//
//  Created by Aly Yakan on 25/11/2020.
//

import Foundation
import CoreBluetooth

class Characterestic: ObservableObject {
    let id: CBUUID

    @Published var value: Data?

    init(id: CBUUID, value: Data? = nil) {
        self.id = id
        self.value = value
    }
}

protocol CharacteristicProtocol {
    var uuid: CBUUID { get }
    var service: BLEServiceIdentifiers { get }
    var cbCharacteristic: CBCharacteristic? { get }
    func subscribe()
}

class ReadableChar: ObservableObject, CharacteristicProtocol {
    let uuid = Constants.readableCharacteristicUUID
    let service: BLEServiceIdentifiers = .test
    let bleServer: BLEServer

    private(set) var cbCharacteristic: CBCharacteristic? {
        didSet { updateValue() }
    }

    @Published private(set) var value: String = ""

    private let cancelBag = CancelBag()

    init(bleServer: BLEServer) {
        self.bleServer = bleServer

        // This approach causes all characteristics to refresh when one of them changes because
        // we're using .sink on the list of characteristics. However the alternative is too complex.
        bleServer.state.$characteristics
            .sink { [weak self] characteristics in
            guard let self = self else { return }

            self.cbCharacteristic = characteristics.first(where: { $0.uuid == self.uuid })
            self.updateValue()
        }.store(in: cancelBag)
    }

    func subscribe() {
        let charPublisher = bleServer.state.myChars
            .first(where: { $0.id == uuid })

        charPublisher?.$value.sink { data in
            guard let data = data else { return }

            self.value = String(data: data, encoding: .utf8) ?? ""
        }.store(in: cancelBag)
    }

    private func updateValue() {
        guard let data = cbCharacteristic?.value else { return }
        value = String(data: data, encoding: .utf8) ?? ""
    }
}

class WritableChar: ObservableObject, CharacteristicProtocol {
    let uuid = Constants.writeableCharacteristicUUID
    let service: BLEServiceIdentifiers = .test
    let bleServer : BLEServer

    private(set) var cbCharacteristic: CBCharacteristic? {
        didSet { updateValue() }
    }

    @Published private(set) var value: String = ""

    private let cancelBag = CancelBag()

    init(bleServer: BLEServer) {
        self.bleServer = bleServer

        bleServer.state.$characteristics.sink { [weak self] characteristics in
            guard let self = self else { return }

            self.cbCharacteristic = characteristics.first(where: { $0.uuid == self.uuid })
            self.updateValue()
        }.store(in: cancelBag)
    }

    func subscribe() {}

    private func updateValue() {
        guard let data = cbCharacteristic?.value else { return }
        value = String(data: data, encoding: .utf8) ?? ""
    }
}

class NotifyChar: ObservableObject, CharacteristicProtocol {
    let uuid = Constants.notifyCharacteristicUUID
    let service: BLEServiceIdentifiers = .test
    let bleServer : BLEServer

    private(set) var cbCharacteristic: CBCharacteristic? {
        didSet { updateValue() }
    }

    @Published private(set) var value: String = ""

    private let cancelBag = CancelBag()

    init(bleServer: BLEServer) {
        self.bleServer = bleServer

        bleServer.state.$characteristics.sink { [weak self] characteristics in
            guard let self = self else { return }

            self.cbCharacteristic = characteristics.first(where: { $0.uuid == self.uuid })
            self.updateValue()
        }.store(in: cancelBag)
    }

    func subscribe() {}

    private func updateValue() {
        guard let data = cbCharacteristic?.value else { return }
        value = String(data: data, encoding: .utf8) ?? ""
    }
}

class GenericChar: ObservableObject, CharacteristicProtocol {
    let uuid: CBUUID
    let service: BLEServiceIdentifiers
    let bleServer : BLEServer

    private(set) var cbCharacteristic: CBCharacteristic? {
        didSet { updateValue() }
    }

    @Published private(set) var value: String = ""

    private let cancelBag = CancelBag()

    init(uuid: CBUUID, service: BLEServiceIdentifiers, bleServer: BLEServer) {
        self.uuid = uuid
        self.service = service
        self.bleServer = bleServer

        bleServer.state.$characteristics.sink { [weak self] characteristics in
            guard let self = self else { return }

            self.cbCharacteristic = characteristics.first(where: { $0.uuid == self.uuid })
            self.updateValue()
        }.store(in: cancelBag)
    }

    func subscribe() {}

    private func updateValue() {
        guard let data = cbCharacteristic?.value else { return }
        value = String(data: data, encoding: .utf8) ?? ""
    }
}
