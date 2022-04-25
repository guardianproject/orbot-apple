//
//  WebServer.swift
//  AdParticipesCumCepis
//
//  Created by Benjamin Erhart on 12.10.21.
//  Copyright © 2021 Guardian Project. All rights reserved.
//

import Foundation
import GCDWebServerExtension
import Tor

open class WebServer: NSObject, GCDWebServerDelegate {

	public static var shared = WebServer()

	public var running: Bool {
		return webServer.isRunning
	}

	private static let onionAddressRegex = try? NSRegularExpression(pattern: "^(.*)\\.(onion|exit)$", options: .caseInsensitive)

	private lazy var webServer: GCDWebServer = {
		GCDWebServer.setBuiltInLogger { level, message in
			let lvl: String

			switch level {
			case 0:
				lvl = "DEBUG"

			case 1:
				lvl = "VERBOSE"

			case 2:
				lvl = "INFO"

			case 3:
				lvl = "WARNING"

			case 4:
				lvl = "ERROR"

			default:
				lvl = "LEVEL \(level)"
			}

			Logger.log("[\(lvl)] \(message)", to: Logger.wsLogFile)
		}

		let webServer = GCDWebServer()
		webServer.delegate = self

		return webServer
	}()

	private lazy var jsonEncoder: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.dateEncodingStrategy = .millisecondsSince1970

		return encoder
	}()


	// MARK: Public Methods

	open func start() throws {
		if webServer.isRunning {
			return
		}

		webServer.removeAllHandlers()

		webServer.addHandler(forMethod: "GET", pathRegex: "^\\/status\\/?$", request: GCDWebServerRequest.self,
							 asyncProcessBlock: getStatus)

		webServer.addHandler(forMethod: "GET", pathRegex: "^\\/circuits\\/?$", request: GCDWebServerRequest.self,
							 asyncProcessBlock: getCircuits)

		webServer.addHandler(forMethod: "DELETE", pathRegex: "^\\/circuits\\/(\\d+)\\/?$", request: GCDWebServerRequest.self,
							 asyncProcessBlock: closeCircuit)

		try webServer.start(options: [
			GCDWebServerOption_AutomaticallySuspendInBackground: false,
			GCDWebServerOption_ConnectedStateCoalescingInterval: 10,
			GCDWebServerOption_BindToLocalhost: true,
			GCDWebServerOption_Port: Config.webserverPort,
			GCDWebServerOption_ServerName: Bundle.main.displayName])
	}

	open func stop() {
		// This will crash, if never run before, so check first.
		if webServer.isRunning {
			webServer.stop()
		}
	}


	// MARK: Private Methods

	private func getStatus(req: GCDWebServerRequest, completion: @escaping GCDWebServerCompletionBlock) {
		completion(respond([
			"status": TorManager.shared.status.rawValue,
			"name": Bundle.main.displayName,
			"version": Bundle.main.version,
			"build": Bundle.main.build
		], gzip: req.acceptsGzipContentEncoding))
	}

	private func getCircuits(req: GCDWebServerRequest, completion: @escaping GCDWebServerCompletionBlock) {
		let host = req.query?["host"]

		TorManager.shared.getCircuits { circuits in
			var candidates = TorCircuit.filter(circuits)

			if let host = host {
				var query: String?

				let matches = Self.onionAddressRegex?.matches(
					in: host, options: [],
					range: NSRange(host.startIndex ..< host.endIndex, in: host))

				if matches?.first?.numberOfRanges ?? 0 > 1,
					let nsRange = matches?.first?.range(at: 1),
					let range = Range(nsRange, in: host) {
					query = String(host[range])
				}

				// Circuits used for .onion addresses can be identified by their
				// rendQuery, which is equal to the "domain".
				if let query = query {
					candidates = candidates.filter { circuit in
						circuit.purpose == TorCircuit.purposeHsClientRend
						&& circuit.rendQuery == query
					}
				}
				else {
					candidates = candidates.filter { circuit in
						circuit.purpose == TorCircuit.purposeGeneral
					}
				}
			}

			completion(self.respond(candidates, gzip: req.acceptsGzipContentEncoding))
		}
	}

	private func closeCircuit(req: GCDWebServerRequest, completion: @escaping GCDWebServerCompletionBlock) {
		guard let captures = req.attribute(forKey: GCDWebServerRequestAttribute_RegexCaptures) as? [String],
			  let id = captures.first
		else {
			return completion(error())
		}

		TorManager.shared.close([id]) { success in
			if success {
				completion(GCDWebServerResponse(statusCode: 204))
			}
			else {
				completion(self.error(404))
			}
		}
	}

	private func respond<T: Encodable>(_ data: T, statusCode: Int? = nil, gzip: Bool = false)
	-> GCDWebServerResponse
	{
		let res: GCDWebServerResponse

		do {
			let json = try jsonEncoder.encode(data)

			res = GCDWebServerDataResponse(data: json, contentType: "application/json")
		}
		catch {
			log(error.localizedDescription)

			res = GCDWebServerResponse(statusCode: 500)
		}

		res.isGZipContentEncodingEnabled = gzip


		if let statusCode = statusCode {
			res.statusCode = statusCode
		}

		return res
	}

	private func error(_ statusCode: Int = 500) -> GCDWebServerErrorResponse {
		GCDWebServerErrorResponse(statusCode: statusCode)
	}

	private func log(_ message: String) {
		Logger.log(message, to: Logger.vpnLogFile)
	}
}
