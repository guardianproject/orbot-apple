//
//  LogViewController.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 22.08.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Cocoa
import Tor

class LogViewController: NSViewController {

	@IBOutlet weak var logSc: NSSegmentedControl! {
		didSet {
			logSc.setLabel(L10n.log, forSegment: 0)
			logSc.setLabel(L10n.circuits, forSegment: 1)

#if DEBUG
			if Config.extendedLogging {
				logSc.segmentCount = 6

				logSc.setLabel("VPN", forSegment: 2)
				logSc.setLabel("LL", forSegment: 3)
				logSc.setLabel("LC", forSegment: 4)
				logSc.setLabel("WS", forSegment: 5)
			}
#endif
		}
	}

	@IBOutlet weak var logSv: NSScrollView!


	private var logTv: NSTextView? {
		logSv.documentView as? NSTextView
	}


	override func viewDidAppear() {
		super.viewDidAppear()

		view.window?.title = L10n.log

		changeLog(logSc!)
	}


	// MARK: Actions

	@IBAction func changeLog(_ view: Any) {
		switch logSc.selectedSegment {
		case 1:
			Logger.tailFile(nil)

			logTv?.string = ""

			SharedUtils.getCircuits { [weak self] text in
				self?.logTv?.string = text
				self?.logSv.scrollToBottom()
			}

#if DEBUG
		case 2:
			// Shows the content of the VPN log file.
			Logger.tailFile(FileManager.default.vpnLogFile, update)

		case 3:
			// Shows the content of the leaf log file.
			Logger.tailFile(FileManager.default.leafLogFile, update)

		case 4:
			// Shows the content of the leaf config file.
			Logger.tailFile(FileManager.default.leafConfFile, update)

		case 5:
			// Shows the content of the GCD webserver log file.
			Logger.tailFile(FileManager.default.wsLogFile, update)
#endif

		default:
			Logger.tailFile(FileManager.default.torLogFile, update)
		}
	}


	// MARK: Private Methods

	private func update(_ logText: String) {
		let atBottom = logSv.isAtBottom

		logTv?.string = logText

		if atBottom {
			logSv.scrollToBottom()
		}
	}
}
