//
//  SysExManager.swift
//  Orbot
//
//  Created by Benjamin Erhart on 12.06.26.
//  Copyright © 2026 Guardian Project. All rights reserved.
//

import Foundation
import SystemExtensions

class SysExManager: NSObject, OSSystemExtensionRequestDelegate {

	enum SysExError: Int, LocalizedError {
		case unknown
		case needsApproval
		case needsReboot

		var localizedDescription: String {
			switch self {
			case .unknown:
				return NSLocalizedString("An unknown error occurred.", comment: "")

			case .needsApproval:
				return NSLocalizedString("Accept installation of system extension. Orbot will not work without it.", comment: "")

			case .needsReboot:
				return NSLocalizedString("Restart computer to finish system extension installation.", comment: "")
			}
		}
	}

	enum Result {
		case completed
		case needsApproval(Error)
		case error(Error)
	}

	static let shared = SysExManager()


	private var continuation: AsyncStream<Result>.Continuation?

	private var request: OSSystemExtensionRequest?


	func install() -> AsyncStream<Result> {
		if (request != nil) {
			continuation?.yield(.error(OSSystemExtensionError(.requestCanceled)))
			finish()
		}

		request = OSSystemExtensionRequest.activationRequest(
			forExtensionWithIdentifier: Config.extBundleId,
			queue: .global(qos: .userInitiated))
		request?.delegate = self

		let result = AsyncStream<Result> {
			self.continuation = $0
		}

		OSSystemExtensionManager.shared.submitRequest(request!)

		return result
	}


	// MARK: OSSystemExtensionRequestDelegate

	func request(_ request: OSSystemExtensionRequest,
				 actionForReplacingExtension existing: OSSystemExtensionProperties,
				 withExtension ext: OSSystemExtensionProperties
	) -> OSSystemExtensionRequest.ReplacementAction
	{
		if #available(macOS 12.0, *) {
			if existing.isAwaitingUserApproval || existing.isUninstalling || !existing.isEnabled {
				return .replace
			}
		}

		if existing.bundleVersion.compare(ext.bundleVersion, options: .numeric) == .orderedAscending {
			return .replace
		}

		return .cancel
	}

	func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
		continuation?.yield(.needsApproval(SysExError.needsApproval))
	}

	func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
		switch result {
		case .completed:
			continuation?.yield(.completed)

		case .willCompleteAfterReboot:
			continuation?.yield(.error(SysExError.needsReboot))

		@unknown default:
			continuation?.yield(.error(SysExError.unknown))
		}

		finish()
	}

	func request(_ request: OSSystemExtensionRequest, didFailWithError error: any Error) {
		if let error = error as? OSSystemExtensionError {
			if error.code == .requestCanceled {
				// This is fine, we cancelled, because the installed extension is the same or newer.
				continuation?.yield(.completed)
			}

			var text: String

			switch error.code {
			case .unknown:
				text = "An unknown error occurred."

			case .missingEntitlement:
				text = "System extension lacks required entitlement."

			case .unsupportedParentBundleLocation:
				text = "Extension parent app location invalid for activation."

			case .extensionNotFound:
				text = "Manager can’t find system extension."

			case .extensionMissingIdentifier:
				text = "Extension identifier is missing."

			case .duplicateExtensionIdentifer:
				text = "Extension identifier duplicates existing identifier."

			case .unknownExtensionCategory:
				text = "Extension manager can’t recognize extension category identifier."

			case .codeSignatureInvalid:
				text = "Extension signature is invalid."

			case .validationFailed:
				text = "Manager can’t validate extension."

			case .forbiddenBySystemPolicy:
				text = "System policy prohibits activating system extension."

			case .requestCanceled:
				text = "System extension manager request was canceled."

			case .requestSuperseded:
				text = "System extension request failed because system already has a pending request for same identifier."

			case .authorizationRequired:
				text = "System was unable to obtain proper authorization."

			@unknown default:
				text = "An unknown error occurred."
			}

			Logger.log(level: .error, text, to: Logger.vpnLogFile)

			continuation?.yield(.error(error))
		}
		else {
			continuation?.yield(.error(error))
		}

		finish()
	}


	private func finish() {
		continuation?.finish()
		continuation = nil
		request = nil
	}
}
