//
//  RemoteControl.swift
//  Orbot
//
//  Created by Benjamin Erhart on 17.05.23.
//  Copyright © 2023 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxyUI


class RemoteControl {

	static let shared = RemoteControl()


	private var handlerQueue = [(() -> Void)]()

	private var observerToken: NSObjectProtocol? = nil {
		willSet {
			if let token = observerToken, !(newValue?.isEqual(token) ?? false) {
				NotificationCenter.default.removeObserver(token)
			}
		}
	}


	private init() {
	}


	/**
	 Works the handler queue.
	 */
	func workQueue() {
		while !handlerQueue.isEmpty {
			handlerQueue.removeFirst()()
		}
	}

	/**
	 Puts action handlers into a queue, which gets worked after the app became active, so
	 all UI is initialized properly.

	 - parameter url: The URL to create a handler for.
	 */
	func evaluate(url: URL) -> Bool {
		guard let urlc = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
			return false
		}

		// Allow "/" (slash) or "." (period, legacy) as separators.
		var pc: ArraySlice<String.SubSequence> = urlc.path.lowercased().split { $0 == "/" || $0 == "." }[...]

		// Remove "rc" pseudo-folder. (From universal link, e.g. "https://orbot.app/rc/start")
		if pc.first == "rc" {
			pc = pc.dropFirst()
		}

		if let handler = createHandler(pc.joined(separator: "/"), urlc.queryItems) {
			handlerQueue.append(handler)

			return true
		}

		return false
	}


	// MARK: Private Methods

	/**
	 Create an action handler for the given command and arguments.

	 - parameters command: The command to create the handler for.
	 - parameters args: Arguments as `URLQueryItem` objects.
	 */
	private func createHandler(_ command: String, _ args: [URLQueryItem]?) -> (() -> Void)? {
		let dismiss = { (inner: (() -> Void)?) in
			return {
				UIApplication.shared.rootVc?.dismiss(animated: true, completion: inner) ?? Void()
			}
		}

		switch command {
		case "show":
			// Dummy path so other apps can just start this one.
			return dismiss(nil)

		case "start":
			let callback = args?.first(where: { $0.name == "callback" })?.value
			let url = callback != nil ? URL(string: callback!) : nil

			return { [weak self] in
				self?.start(url)
			}

		case "stop":
			let token = args?.first(where: { $0.name == "token"} )?.value

			let callback = args?.first(where: { $0.name == "callback" })?.value
			let url = callback != nil ? URL(string: callback!) : nil

			return { [weak self] in
				self?.stop(token, url)
			}

		case "show/settings":
			return dismiss {
				UIApplication.shared.mainVc?.showSettings()
			}

		case "show/bridges":
			return dismiss {
				UIApplication.shared.mainVc?.changeBridges()
			}

		case "show/auth":
			return dismiss {
				UIApplication.shared.mainVc?.showAuth()
			}

		case "add/auth":
			let url = args?.first(where: { $0.name == "url" })?.value
			let key = args?.first(where: { $0.name == "key" })?.value

			return dismiss {
				UIApplication.shared.mainVc?.showAuth().addKey(URL(string: url ?? ""), key)
			}

		case "request/token":
			let appId = args?.first(where: { $0.name == "app-id" })?.value
			let appName = args?.first(where: { $0.name == "app-name" })?.value
			let needsBypass = Bool(args?.first(where: { $0.name == "need-bypass" })?.value ?? "") ?? false
			let callback = args?.first(where: { $0.name == "callback" })?.value

			return dismiss { [weak self] in
				self?.requestToken(appId, appName, needsBypass, callback)
			}

		default:
			return nil
		}
	}

	/**
	 Starts the VPN, if not already started and if in a state to do so.

	 Redirects the user to the transmitted callback URL, on successful start, if available.

	 - parameter callback: A callback URL to redirect the user to after a *successful* start.
	 */
	private func start(_ callback: URL?) {
		if let callback = callback {
			switch VpnManager.shared.status {

			// Ignore callback in failure modes to not create seemingly erratic behaviour.
			case .notInstalled, .invalid, .unknown:
				return

			// Modes from where a successful start is possible.
			// Hook up state change observer and try to start VPN.
			case .disabled, .disconnected, .evaluating, .connecting, .reasserting, .disconnecting:

				guard let rootVc = UIApplication.shared.rootVc else {
					return
				}

				observerToken = NotificationCenter.default.addObserver(forName: .vpnStatusChanged, object: nil, queue: .main)
				{ _ in
					switch VpnManager.shared.status {

					case .notInstalled, .disabled, .invalid, .unknown:
						// Something went very wrong when we changed to here.
						// Remove observer and forget callback.
						self.observerToken = nil

					case .disconnected, .evaluating, .connecting:
						// Ignore. This is the happy path.
						// Yeah, even `disconnected`. Even when it starts from `disconnected`,
						// We'll get a status change to `disconnected`, anyway.
						break

					case .connected:
						// We're connected! remove observer and call back other app.
						self.observerToken = nil

						UIApplication.shared.open(callback)

					case .reasserting:
						// Still ignore. Doesn't look good, but maybe?
						break

					case .disconnecting:
						// Ok, this is not going to fly.
						// Remove observer, forget callback.
						self.observerToken = nil
					}
				}

				rootVc.dismiss(animated: true) {
					SharedUtils.control(onlyTo: .connected)
				}

			// Ok, we're already running. Just call back other app after a small delay.
			case .connected:
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					UIApplication.shared.open(callback)
				}
			}
		}
		// No callback. Just try to connect.
		else {
			UIApplication.shared.rootVc?.dismiss(animated: true) {
				SharedUtils.control(onlyTo: .connected)
			}
		}
	}

	/**
	 Stops the VPN, if not already stopped and if in a state to do so.

	 Redirects the user to the transmitted callback URL, on successful stop, if available.

	 - parameter token: App access token. Only properly authorized apps are allowed to stop the VPN.
	 - parameter callback: A callback URL to redirect the user to after a *successful* start.
	 */
	private func stop(_ token: String?, _ callback: URL?) {
		guard let token = token,
			  !token.isEmpty,
			  Settings.apiAccessTokens.first(where: { $0.key == token }) != nil
		else {
			if let mainVc = UIApplication.shared.mainVc {
				let message = String(
					format: NSLocalizedString(
						"An app tried to stop %1$@, but you didn't allow it to do this, yet.",
						comment: ""),
					Bundle.main.displayName)
				+ "\n\n"
				+ String(
					format: NSLocalizedString(
						"If you want the app be able to stop %1$@ automatically, please go back to that app and make it restart the authorization process again!",
						comment: ""),
					Bundle.main.displayName)

				AlertHelper.present(mainVc, message: message, actions: [
					AlertHelper.cancelAction(),
					AlertHelper.destructiveAction(NSLocalizedString("Stop", comment: ""), handler: { _ in
						UIApplication.shared.rootVc?.dismiss(animated: true) {
							SharedUtils.control(onlyTo: .disconnected)
						}
					})])
			}

			return
		}

		if let callback = callback {
			switch VpnManager.shared.status {

			// Ignore callback in failure modes to not create seemingly erratic behaviour.
			case .notInstalled, .invalid, .unknown:
				return

			// Modes from where a successful stop is possible.
			// Hook up state change observer and try to stop VPN.
			case .disabled, .evaluating, .connecting, .connected, .reasserting, .disconnecting:

				guard let rootVc = UIApplication.shared.rootVc else {
					return
				}

				observerToken = NotificationCenter.default.addObserver(forName: .vpnStatusChanged, object: nil, queue: .main)
				{ _ in
					switch VpnManager.shared.status {

					case .notInstalled, .disabled, .invalid, .unknown:
						// Something went very wrong when we changed to here.
						// Remove observer and forget callback.
						self.observerToken = nil

					case .connected, .evaluating, .disconnecting:
						// Ignore. This is the happy path.
						// Yeah, even `connected`. Even when it starts from `connected`,
						// We'll get a status change to `connected`, anyway.
						break

					case .disconnected:
						// We're disconnected! remove observer and call back other app.
						self.observerToken = nil

						UIApplication.shared.open(callback)

					case .reasserting:
						// Still ignore. Doesn't look good, but maybe?
						break

					case .connecting:
						// Ok, this is not going to fly.
						// Remove observer, forget callback.
						self.observerToken = nil
					}
				}

				rootVc.dismiss(animated: true) {
					SharedUtils.control(onlyTo: .disconnected)
				}

			// Ok, we're already stopped. Just call back other app after a small delay.
			case .disconnected:
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					UIApplication.shared.open(callback)
				}
			}
		}
		// No callback. Just try to disconnect.
		else {
			UIApplication.shared.rootVc?.dismiss(animated: true) {
				SharedUtils.control(onlyTo: .disconnected)
			}
		}
	}

	/**
	 Show the `ApiAccessViewController` with the transmitted configuration or some error alerts, if misconfigured.

	 - parameter appId: The app ID of a requesting app.
	 - parameter appName: The name of a requesting app.
	 - parameter needsBypass: If the requesting app needs to bypass Orbot.
	 - parameter callback: A callback URL to redirect the user to after access registration.
	 */
	private func requestToken(_ appId: String?, _ appName: String?, _ needsBypass: Bool, _ callback: String?) {
		guard let mainVc = UIApplication.shared.mainVc else {
			return
		}

		guard let appId = appId,
			  !appId.isEmpty
		else {
			let message = NSLocalizedString("Another app requested an API access token.", comment: "")
			+ "\n\n"
			+ NSLocalizedString("It didn't provide a valid app identifier.", comment: "")
			+ "\n\n"
			+ NSLocalizedString("Please report this error to the requesting app's developers.", comment: "")
			+ "\n"
			+ NSLocalizedString("That app will be unable to access Orbot's API as long as this is not fixed.", comment: "")

			AlertHelper.present(mainVc, message: message)

			return
		}

		var urlc: URLComponents? = nil

		if let callback = callback, !callback.isEmpty {
			urlc = URLComponents(string: callback)
		}

		let apiVc = mainVc.showApiAccess()

		let completion = { (token: ApiToken?) in
			if let token = token {
				if urlc?.queryItems == nil {
					urlc?.queryItems = []
				}

				urlc?.queryItems?.append(URLQueryItem(name: "token", value: token.key))
			}

			let success = { (success: Bool) in
				if !success && token != nil {
					let message = NSLocalizedString("Another app requested an API access token.", comment: "")
					+ "\n\n"
					+ NSLocalizedString("We could not return to that app, because it didn't provide a valid callback URL.", comment: "")
					+ "\n\n"
					+ NSLocalizedString("The API access token was copied to your clipboard.", comment: "")
					+ "\n"
					+ NSLocalizedString("Go back to the requesting app and paste the token in the appropriate dialog.", comment: "")

					AlertHelper.present(mainVc, message: message)
				}
			}

			guard let url = urlc?.url else {
				success(false)

				return
			}

			UIApplication.shared.open(url, completionHandler: success)
		}

		apiVc.addToken(appId, appName, needsBypass, completion)
	}
}
