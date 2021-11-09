//
//  ChangeBridgeMessage.swift
//  Orbot
//
//  Created by Benjamin Erhart on 09.11.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import UIKit

class ChangeBridgeMessage: NSObject, Message {

    static var supportsSecureCoding = true

    let bridge: Bridge

    init(_ bridge: Bridge) {
        self.bridge = bridge

        super.init()
    }

    required init?(coder: NSCoder) {
        bridge = Bridge(rawValue: coder.decodeInteger(forKey: "bridge")) ?? .none

        super.init()
    }

    func encode(with coder: NSCoder) {
        coder.encode(bridge.rawValue, forKey: "bridge")
    }
}
