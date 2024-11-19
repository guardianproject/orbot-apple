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

	private static let onionAddressRegex = try? NSRegularExpression(pattern: "^(.*\\.)?(.*?)\\.(onion|exit)$", options: .caseInsensitive)

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

		webServer.addHandler(forMethod: "GET", pathRegex: "^\\/info\\/?$", request: GCDWebServerRequest.self,
							 asyncProcessBlock: getInfo)

		webServer.addHandler(forMethod: "GET", pathRegex: "^\\/circuits\\/?$", request: GCDWebServerRequest.self,
							 asyncProcessBlock: getCircuits)

		webServer.addHandler(forMethod: "DELETE", pathRegex: "^\\/circuits\\/(\\d+)\\/?$", request: GCDWebServerRequest.self,
							 asyncProcessBlock: closeCircuit)

		webServer.addHandler(forMethod: "GET", pathRegex: "^\\/poll\\/?$", request: GCDWebServerRequest.self,
							 asyncProcessBlock: poll)

		var options: [String: Any] = [
			GCDWebServerOption_ConnectedStateCoalescingInterval: 10,
			GCDWebServerOption_BindToLocalhost: true,
			GCDWebServerOption_Port: Config.webserverPort,
			GCDWebServerOption_ServerName: Bundle.main.displayName]

		#if os(iOS)
			options[GCDWebServerOption_AutomaticallySuspendInBackground] = false
		#endif

		try webServer.start(options: options)
	}

	open func stop() {
		// This will crash, if never run before, so check first.
		if webServer.isRunning {
			webServer.stop()
		}
	}


	// MARK: Private Methods

	private func getInfo(req: GCDWebServerRequest, completion: @escaping GCDWebServerCompletionBlock) {
		getInfo(req: req, completion: completion, sleepDuration: nil)
	}

	private func getInfo(req: GCDWebServerRequest, completion: @escaping GCDWebServerCompletionBlock, sleepDuration: UInt32?) {
		let (token, error) = authenticate(req: req)

		if let error = error {
			return completion(error)
		}

		if let sleepDuration = sleepDuration {
			sleep(sleepDuration)
		}

		let info = Info(bypassPort: (token?.bypass ?? false) ? Settings.bypassPort : nil)

		completion(respond(info, gzip: req.acceptsGzipContentEncoding))
	}

	private func getCircuits(req: GCDWebServerRequest, completion: @escaping GCDWebServerCompletionBlock) {
		if let error = authenticate(req: req).error {
			return completion(error)
		}

		let host = req.query?["host"]

		TorManager.shared.getCircuits { circuits in
			var candidates = TorCircuit.filter(circuits)

			if let host = host {
				var query: String?

				let matches = Self.onionAddressRegex?.matches(
					in: host, options: [],
					range: NSRange(host.startIndex ..< host.endIndex, in: host))

				if let match = matches?.first,
				   match.numberOfRanges > 1
				{
					let nsRange = match.range(at: match.numberOfRanges - 2)

					if let range = Range(nsRange, in: host) {
						query = String(host[range])
					}
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
						circuit.purpose == TorCircuit.purposeGeneral || circuit.purpose == TorCircuit.purposeConfluxLinked
					}
				}
			}

			completion(self.respond(candidates, gzip: req.acceptsGzipContentEncoding))
		}
	}

	private func closeCircuit(req: GCDWebServerRequest, completion: @escaping GCDWebServerCompletionBlock) {
		if let error = authenticate(req: req).error {
			return completion(error)
		}

		guard let captures = req.attribute(forKey: GCDWebServerRequestAttribute_RegexCaptures) as? [String],
			  let id = captures.first
		else {
			return completion(error())
		}

		TorManager.shared.close([id]) { success in
			if success {
				completion(self.respond())
			}
			else {
				completion(self.error(404))
			}
		}
	}

	private func poll(req: GCDWebServerRequest, completion: @escaping GCDWebServerCompletionBlock) {
		let length = req.query?["length"] ?? ""

		getInfo(req: req, completion: completion, sleepDuration: UInt32(length) ?? 20)
	}

	private func authenticate(req: GCDWebServerRequest) -> (token: ApiToken?, error: GCDWebServerErrorResponse?) {
		guard let key = req.headers.keys.first(where: { $0.lowercased() == "x-token" }),
			  let token = req.headers[key],
			  !token.isEmpty,
			  let apiToken = Settings.apiAccessTokens.first(where: { $0.key == token })
		else {
			return (nil, error(403))
		}

		return (apiToken, nil)
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

	private func respond() -> GCDWebServerResponse {
		return GCDWebServerResponse(statusCode: 204)
	}

	private func error(_ statusCode: Int = 500) -> GCDWebServerErrorResponse {
		GCDWebServerErrorResponse(statusCode: statusCode)
	}

	private func log(_ message: String) {
		Logger.log(message, to: Logger.vpnLogFile)
	}
}

/**
 Orbot VPN status and metadata.
 */
private struct Info: Codable {

	enum CodingKeys: String, CodingKey {
		case status
		case name
		case version
		case build
		case onionOnly = "onion-only"
		case bypassPort = "bypass-port"
	}

	/**
	 The current status of the Orbot Tor VPN.
	 */
	public let status = TorManager.shared.status

	/**
	 The name of the network extension. (Should be "Tor VPN".)
	 */
	public let name = Bundle.main.displayName

	/**
	 The current semantic version of Orbot.
	 */
	public let version = Bundle.main.version

	/**
	 The build ID of Orbot.
	 */
	public let build = Bundle.main.build

	/**
	 If Orbot is running in onion-only mode.
	 */
	public let onionOnly = Settings.onionOnly

	/**
	 The SOCKS5 port with which Orbot can be bypassed, if activated.
	 */
	public let bypassPort: UInt16?
}
