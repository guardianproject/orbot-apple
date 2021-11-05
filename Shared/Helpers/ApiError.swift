//
//  ApiError.swift
//  Orbot
//
//  Created by Benjamin Erhart on 18.03.20.
//  Copyright © 2020 Guardian Project. All rights reserved.
//

import Foundation

enum ApiError: LocalizedError {
	case noHttpResponse
	case no200Status(status: Int)
	case noBody
	case noValidJsonBody
	case notSuccess(status: Any?)
	case noRequestPossible

	var errorDescription: String? {
		switch self {
		case .noHttpResponse:
			return NSLocalizedString("No valid HTTP response.", comment: "")

		case .no200Status(let status):
			return "\(status) \(HTTPURLResponse.localizedString(forStatusCode: status))"

		case .noBody:
			return NSLocalizedString("Response body missing.", comment: "")

		case .noValidJsonBody:
			return NSLocalizedString("Response is no valid JSON.", comment: "")

		case .notSuccess(let status):
			return String(format: NSLocalizedString("No success, but \"%@\" instead.", comment: ""), String(describing: status))

		case .noRequestPossible:
			return NSLocalizedString("Request could not be formed. Please check host and username/password!", comment: "")
		}
	}
}
