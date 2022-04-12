//
//  ContentBlockerRequestHandler.swift
//  ContentBlocker
//
//  Created by Benjamin Erhart on 08.04.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import UIKit
import MobileCoreServices

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
		let urls = try! FileManager.default.contentsOfDirectory(at: FileManager.default.groupDir!, includingPropertiesForKeys: nil)

		let item = NSExtensionItem()
		item.attachments = urls
			.filter { $0.pathExtension == "json" }
			.compactMap { NSItemProvider(contentsOf: $0) }

        context.completeRequest(returningItems: [item], completionHandler: nil)
    }
    
}
