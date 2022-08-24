//
//  BaseWindowController.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 24.08.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Cocoa

class BaseWindowController: NSWindowController {

	override func windowDidLoad() {
		super.windowDidLoad()

		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	}

	override func keyDown(with event: NSEvent) {
		if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "w" {
			window?.close()
		}
	}

}
