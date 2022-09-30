//
//  Logger.swift
//  Orbot
//
//  Created by Benjamin Erhart on 17.05.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation

class Logger {

	static let ENABLE_LOGGING = true

	static var vpnLogFile: URL? = {
		if let url = FileManager.default.vpnLogFile {
			// Reset log on first write.
			try? "".write(to: url, atomically: true, encoding: .utf8)

			return url
		}

		return nil
	}()

	static var wsLogFile: URL? = {
		if let url = FileManager.default.wsLogFile {
			// Reset log on first write.
			try? "".write(to: url, atomically: true, encoding: .utf8)

			return url
		}

		return nil
	}()

	static func log(_ message: String, to: URL?) {
		guard ENABLE_LOGGING,
			  let url = to,
			  let data = message.trimmingCharacters(in: .whitespacesAndNewlines).appending("\n").data(using: .utf8),
			  let fh = try? FileHandle(forUpdating: url)
		else {
			return
		}

		defer {
			fh.closeFile()
		}

		fh.seekToEndOfFile()
		fh.write(data)
	}

	private static var logFsObject: DispatchSourceFileSystemObject? {
		didSet {
			oldValue?.cancel()
		}
	}

	private static var logText = ""

	static func tailFile(_ url: URL?, _ update: ((_ logText: String) -> Void)? = nil) {

		// Stop and remove the previous watched content.
		// (Will implicitely call #stop through `didSet` hook!)
		logFsObject = nil

		guard let url = url,
			let fh = try? FileHandle(forReadingFrom: url)
		else {
			return
		}

		let ui = {
			let data = fh.readDataToEndOfFile()

			if let content = String(data: data, encoding: .utf8) {
				logText.append(content)

				update?(logText)
			}
		}

		logText = ""
		ui()

		logFsObject = DispatchSource.makeFileSystemObjectSource(
			fileDescriptor: fh.fileDescriptor,
			eventMask: [.extend, .delete, .link],
			queue: .main)

		logFsObject?.setEventHandler {
			guard let data = logFsObject?.data else {
				return
			}

			if data.contains(.delete) || data.contains(.link) {
				DispatchQueue.main.async {
					tailFile(url, update)
				}
			}

			if data.contains(.extend) {
				ui()
			}
		}

		logFsObject?.setCancelHandler {
			try? fh.close()

			logText = ""
		}

		logFsObject?.resume()
	}
}
