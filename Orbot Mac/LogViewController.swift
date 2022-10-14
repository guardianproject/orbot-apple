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
			logSc.setLabel("Tor", forSegment: 0)
			logSc.setLabel(L10n.bridges, forSegment: 1)
			logSc.setLabel(L10n.circuits, forSegment: 2)

#if DEBUG
			if Config.extendedLogging {
				logSc.segmentCount = 8

				logSc.setLabel("Snowflake Proxy", forSegment: 3)
				logSc.setLabel("VPN", forSegment: 4)
				logSc.setLabel("LL", forSegment: 5)
				logSc.setLabel("LC", forSegment: 6)
				logSc.setLabel("WS", forSegment: 7)
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

		NotificationCenter.default.addObserver(forName: .vpnStatusChanged, object: nil, queue: .main) { [weak self] _ in
			self?.changeLog((self?.logSc)!)
		}
	}

	override func viewWillDisappear() {
		super.viewWillDisappear()

		NotificationCenter.default.removeObserver(self)
	}


	// MARK: Actions

	@IBAction func changeLog(_ view: Any) {
		logSc.setEnabled(Settings.transport != .none, forSegment: 1)

		switch logSc.selectedSegment {
		case 1:
			// Shows the content of the Snowflake or Obfs4proxy log file.
			Logger.tailFile(Settings.transport.logFile, update)

		case 2:
			Logger.tailFile(nil)

			SharedUtils.getCircuits { [weak self] text in
				self?.logTv?.string = text
				self?.logSv.scrollToBottom()
			}

#if DEBUG
		case 3:
			// Shows the content of the Snowflake Proxy log file.
			Logger.tailFile(FileManager.default.sfpLogFile, update)

		case 4:
			// Shows the content of the VPN log file.
			Logger.tailFile(FileManager.default.vpnLogFile, update)

		case 5:
			// Shows the content of the leaf log file.
			Logger.tailFile(FileManager.default.leafLogFile, update)

		case 6:
			// Shows the content of the leaf config file.
			Logger.tailFile(FileManager.default.leafConfFile, update)

		case 7:
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
