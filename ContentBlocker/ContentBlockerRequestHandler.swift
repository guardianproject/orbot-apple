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

	enum Errors: Error {
		case groupDirUnavailable
		case noopProviderCouldNotBeConstructed
	}

	func beginRequest(with context: NSExtensionContext) {
		guard let dir = FileManager.default.groupDir else {
			return context.cancelRequest(withError: Errors.groupDirUnavailable)
		}

		let urls: [URL]

		do {
			urls = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
		}
		catch {
			return context.cancelRequest(withError: error)
		}

		let item = NSExtensionItem()
		item.attachments = urls
			.filter { $0.pathExtension == "json" }
			.compactMap { NSItemProvider(contentsOf: $0) }

		// We need a non-empty list of instructions, otherwise a reload will end with an error.
		if item.attachments?.isEmpty ?? true {
			guard let provider = NSItemProvider(contentsOf: Bundle.main.url(forResource: "noop", withExtension: "json")) else {
				return context.cancelRequest(withError: Errors.noopProviderCouldNotBeConstructed)
			}

			item.attachments = [provider]
		}

		context.completeRequest(returningItems: [item])
	}
}
