//
//  Bridge.swift
//  Orbot
//
//  Created by Benjamin Erhart on 09.11.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation

enum Bridge: Int, CaseIterable {
    case none = 0
    case obfs4 = 1
    case snowflake = 2
    case custom = 3

    var description: String {
        switch self {
        case .obfs4:
            return NSLocalizedString("via Obfs4 bridges", comment: "")

        case .snowflake:
            return NSLocalizedString("via Snowflake bridge", comment: "")

        case .custom:
            return NSLocalizedString("via custom bridges", comment: "")

        default:
            return ""
        }
    }
}
