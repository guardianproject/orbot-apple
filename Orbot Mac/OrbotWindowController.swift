//
//  OrbotWindowController.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 23.08.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Cocoa

class OrbotWindowController: NSWindowController {

	@IBAction func openMain(_ sender: Any) {
		window?.contentViewController = storyboard?.instantiateController(withIdentifier: "MainView") as? NSViewController
	}

	@IBAction func openLog(_ sender: Any) {
		(storyboard?.instantiateController(withIdentifier: "LogWindow") as? NSWindowController)?.showWindow(self)
	}
}
