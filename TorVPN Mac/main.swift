//
//  main.swift
//  TorVPN Mac
//
//  Created by Benjamin Erhart on 12.04.23.
//  Copyright © 2023 Guardian Project. All rights reserved.
//

import Foundation
import NetworkExtension

autoreleasepool {
    NEProvider.startSystemExtensionMode()
}

dispatchMain()
