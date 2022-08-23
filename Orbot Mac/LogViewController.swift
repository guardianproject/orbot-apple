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
			logSc.setLabel(NSLocalizedString("Log", comment: ""), forSegment: 0)
			logSc.setLabel(NSLocalizedString("Circuits", comment: ""), forSegment: 1)

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


	private var logFsObject: DispatchSourceFileSystemObject? {
		didSet {
			oldValue?.cancel()
		}
	}

	private var logText = ""

	override func viewDidAppear() {
		super.viewDidAppear()

		view.window?.title = NSLocalizedString("Log", comment: "")

		changeLog(logSc!)
	}


	// MARK: Actions

	@IBAction func changeLog(_ view: Any) {
		switch logSc.selectedSegment {
		case 1:
			tailFile(nil)

			logTv?.string = ""

			VpnManager.shared.getCircuits { [weak self] circuits, error in
				let circuits = TorCircuit.filter(circuits)

				var text = ""

				var i = 1

				for c in circuits {
					text += "Circuit \(c.circuitId ?? String(i))\n"

					var j = 1

					for n in c.nodes ?? [] {
						var country = n.localizedCountryName ?? n.countryCode ?? ""

						if !country.isEmpty {
							country = " (\(country))"
						}

						text += "\(j): \(n.nickName ?? n.fingerprint ?? n.ipv4Address ?? n.ipv6Address ?? "unknown node")\(country)\n"

						j += 1
					}

					text += "\n"

					i += 1
				}

				self?.logTv?.string = text
				self?.logSv.scrollToBottom()
			}

#if DEBUG
		case 2:
			// Shows the content of the VPN log file.
			tailFile(FileManager.default.vpnLogFile)

		case 3:
			// Shows the content of the leaf log file.
			tailFile(FileManager.default.leafLogFile)

		case 4:
			// Shows the content of the leaf config file.
			tailFile(FileManager.default.leafConfFile)

		case 5:
			// Shows the content of the GCD webserver log file.
			tailFile(FileManager.default.wsLogFile)
#endif

		default:
			tailFile(FileManager.default.torLogFile)
		}
	}


	// MARK: Private Methods

	private func tailFile(_ url: URL?) {

		// Stop and remove the previous watched content.
		// (Will implicitely call #stop through `didSet` hook!)
		logFsObject = nil

		guard let url = url,
			  let fh = try? FileHandle(forReadingFrom: url)
		else {
			return
		}


		let ui = { [weak self] in
			let data = fh.readDataToEndOfFile()

			if let content = String(data: data, encoding: .utf8) {
				let atBottom = self?.logSv.isAtBottom ?? false

				self?.logText.append(content)

				self?.logTv?.string = self?.logText ?? ""

				if atBottom {
					self?.logSv.scrollToBottom()
				}
			}
		}

		logText = ""
		ui()

		logFsObject = DispatchSource.makeFileSystemObjectSource(
			fileDescriptor: fh.fileDescriptor,
			eventMask: [.extend, .delete, .link],
			queue: .main)

		logFsObject?.setEventHandler { [weak self] in
			guard let data = self?.logFsObject?.data else {
				return
			}

			if data.contains(.delete) || data.contains(.link) {
				DispatchQueue.main.async {
					self?.tailFile(url)
				}
			}

			if data.contains(.extend) {
				ui()
			}
		}

		logFsObject?.setCancelHandler { [weak self] in
			try? fh.close()

			self?.logText = ""
		}

		logFsObject?.resume()
	}
}
