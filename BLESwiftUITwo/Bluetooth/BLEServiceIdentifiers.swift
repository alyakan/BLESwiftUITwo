//
//  Service.swift
//  BLESwiftUITwo
//
//  Created by Aly Yakan on 25/11/2020.
//

import CoreBluetooth

enum BLEServiceIdentifiers {
    case test
    // case bleAuthorization  // "06600000-E844-4E43-8AB5-8930F76B0FED"

    var uuid: CBUUID {
        switch self {
        case .test: return Constants.testServiceUUID
        }
    }

    var characteristicsUUIDs: [CBUUID] {
        switch self {
        case .test: return [Constants.readableCharacteristicUUID, Constants.writeableCharacteristicUUID, Constants.notifyCharacteristicUUID]
        }
    }
}
