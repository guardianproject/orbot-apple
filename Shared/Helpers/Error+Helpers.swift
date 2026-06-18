//
//  Error+Helpers.swift
//  Orbot
//
//  Created by Benjamin Erhart on 18.06.26.
//  Copyright © 2026 Guardian Project. All rights reserved.
//

import Foundation

extension Error {

	var nsError: NSError {
		var errorCode = -1
		if let rawError = self as? any RawRepresentable,
		   let value = rawError.rawValue as? Int
		{
			errorCode = value
		}

		var userInfo: [String: Any] = [NSLocalizedDescriptionKey: localizedDescription]

		if let error = self as? LocalizedError {
			if let failureReason = error.failureReason {
				userInfo[NSLocalizedFailureReasonErrorKey] = failureReason
			}

			if let recoverySuggestion = error.recoverySuggestion {
				userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion
			}
		}

		return NSError(
			domain: String(reflecting: type(of: self)),
			code: errorCode,
			userInfo: userInfo)
	}
}
