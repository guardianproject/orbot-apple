//
//  main.swift
//  TorVPN Mac-sys
//
//  Created by Benjamin Erhart on 10.06.26.
//  Copyright © 2026 Guardian Project. All rights reserved.
//

import Foundation
import NetworkExtension

autoreleasepool {
    NEProvider.startSystemExtensionMode()
}

dispatchMain()
