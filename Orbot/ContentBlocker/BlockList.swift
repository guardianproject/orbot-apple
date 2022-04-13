//
//  BlockList.swift
//  Orbot
//
//  Created by Benjamin Erhart on 11.04.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Foundation
import SafariServices

class BlockList {

	static let shared = BlockList()


	private static let encoder: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

		return encoder
	}()

	private static let decoder = JSONDecoder()

	private static let url = FileManager.default.groupDir?.appendingPathComponent("blockList.json")


	private var blocklist = [BlockItem]()


	init() {
		guard let url = Self.url else {
			return
		}

		do {
			let data = try Data(contentsOf: url)

			blocklist = try Self.decoder.decode([BlockItem].self, from: data)
		}
		catch {
			print("[\(String(describing: type(of: self)))]#init error=\(error)")
		}
	}


	// MARK: Array proxy

	var count: Int {
		blocklist.count
	}

	subscript(index: Int) -> BlockItem {
		get {
			blocklist[index]
		}
		set {
			blocklist[index] = newValue
		}
	}

	func append(_ newElement: BlockItem) {
		blocklist.append(newElement)
	}

	@discardableResult
	func remove(at index: Int) -> BlockItem {
		return blocklist.remove(at: index)
	}

	func insert(_ newElement: BlockItem, at index: Int) {
		blocklist.insert(newElement, at: index)
	}


	// MARK: File Operations

	func write() throws {
		guard let url = Self.url else {
			return
		}

		if blocklist.isEmpty {
			try FileManager.default.removeItem(at: url)
		}
		else {
			let data = try Self.encoder.encode(blocklist)

			try data.write(to: url, options: .atomic)
		}

		SFContentBlockerManager.reloadContentBlocker(withIdentifier: Config.contentBlockerBundleId) { error in
			print("[\(String(describing: type(of: self)))]#write reload bundleId=\(Config.contentBlockerBundleId), error=\(String(describing: error))")
		}

		print("[\(String(describing: type(of: self)))]#write path=\(url.path)")
	}
}

struct BlockItem: Codable, CustomStringConvertible {

	var trigger: BlockTrigger

	var action: BlockAction

	var description: String {
		let regexDesc = trigger.urlFilter.isEmpty || trigger.urlFilter == ".*"
			? ""
			: String(format: NSLocalizedString(" where the URL contains the regex \"%@\"", comment: ""), trigger.urlFilter)

		return String(
			format: NSLocalizedString("%1$@ by %2$@ for %3$@ on %4$@%5$@.", comment: ""),
			action.type.description,
			(trigger.loadType?.first ?? .all).description,
			description(for: trigger.resourceType, NSLocalizedString("all types", comment: "")),
			description(for: trigger.ifDomain, NSLocalizedString("all domains", comment: "")),
			regexDesc)
	}

	private func description<T: CustomStringConvertible>(for array: [T]?, _ empty: String) -> String {
		guard let array = array, !array.isEmpty else {
			return empty
		}

		return array.map { $0.description }.joined(separator: ", ")
	}
}

/**
 A trigger must include a `urlFilter` key, which specifies a pattern to match the URL against.

 The remaining keys are optional and modify the behavior of the trigger.
 For example, you can limit the trigger to specific domains or have it not apply when a match is found on a specific domain.

 For example, to write a trigger for image and style sheet resources found on any domain except those specified, add the following to the JSON file:

 ```
 "trigger": {
		 "url-filter": ".*",
		 "resource-type": ["image", "style-sheet"],
		 "unless-domain": ["your-content-server.com", "trusted-content-server.com"]
 }
 ```
 */
struct BlockTrigger: Codable {

	enum ResourceType: String, Codable, CaseIterable, CustomStringConvertible {

		case document = "document"

		case image = "image"

		case styleSheet = "style-sheet"

		case script = "script"

		case font = "font"

		/**
		 Any untyped load.
		 */
		case raw = "raw"

		case svgDocument = "svg-document"

		case media = "media"

		case popup = "popup"

		case ping = "ping"

		case fetch = "fetch"

		case websocket = "websocket"

		/**
		 Like `raw`, but doesn’t include fetch or websocket
		 */
		case other = "other"

		var description: String {
			switch self {
			case .document:
				return NSLocalizedString("documents", comment: "")

			case .image:
				return NSLocalizedString("images", comment: "")

			case .styleSheet:
				return NSLocalizedString("style sheets", comment: "")

			case .script:
				return NSLocalizedString("scripts", comment: "")

			case .font:
				return NSLocalizedString("fonts", comment: "")

			case .raw:
				return NSLocalizedString("raw data", comment: "")

			case .svgDocument:
				return NSLocalizedString("SVG documents", comment: "")

			case .media:
				return NSLocalizedString("audio/video media", comment: "")

			case .popup:
				return NSLocalizedString("popups", comment: "")

			case .ping:
				return NSLocalizedString("pings", comment: "")

			case .fetch:
				return NSLocalizedString("fetches", comment: "")

			case .websocket:
				return NSLocalizedString("WebSockets", comment: "")

			case .other:
				return NSLocalizedString("other", comment: "")
			}
		}

	}

	enum LoadType: String, Codable, CaseIterable, CustomStringConvertible {

		/**
		 Is triggered only if the resource has the same scheme, domain, and port as the main page resource.
		 */
		case firstParty = "first-party"

		/**
		 Is triggered if the resource isn’t from the same domain as the main page resource.
		 */
		case thirdParty = "third-party"

		/**
		 Don't use that as a value, in `BlockTrigger#loadType`, instead use `nil` there in this case!
		 */
		case all = ""

		var description: String {
			switch self {
			case .firstParty:
				return NSLocalizedString("the website", comment: "")

			case .thirdParty:
				return NSLocalizedString("third parties", comment: "")

			case .all:
				return NSLocalizedString("all", comment: "")
			}
		}
	}

	enum LoadContext: String, Codable {
		case topFrame = "top-frame"

		case childFrame = "child-frame"
	}

	enum CodingKeys: String, CodingKey {
		case urlFilter = "url-filter"
		case urlFilterIsCaseSensitive = "url-filter-is-case-sensitive"
		case ifDomain = "if-domain"
		case unlessDomain = "unless-domain"
		case resourceType = "resource-type"
		case loadType = "load-type"
		case ifTopUrl = "if-top-url"
		case unlessTopUrl = "unless-top-url"
		case loadContext = "load-context"
	}


	/**
	 Match more than just a specific URL, using regular expressions:

	 | Syntax | Description                                                                                      |
	 |--------|--------------------------------------------------------------------------------------------------|
	 | .*     | Matches all strings with a dot appearing zero or more times. Use this syntax to match every URL. |
	 | .      | Matches any character.                                                                           |
	 | \.     | Explicitly matches the dot character.                                                            |
	 | [a-b]  | Matches a range of alphabetic characters.                                                        |
	 | (abc)  | Matches groups of the specified characters.                                                      |
	 | +      | Matches the preceding term one or more times.                                                    |
	 | *      | Matches the preceding character zero or more times.                                              |
	 | ?      | Matches the preceding character zero or one time.                                                |
	 */
	var urlFilter: String

	/**
	 The default value is false.
	 */
	var urlFilterIsCaseSensitive: Bool?

	/**
	 An array of strings matched to a URL's domain; limits action to a list of specific domains.

	 Values must be lowercase ASCII, or Punycode for non-ASCII.
	 Add * in front to match domain and subdomains.
	 Can't be used with `unlessDomain`.
	 */
	var ifDomain: [String]?

	/**
	 An array of strings matched to a URL's domain; acts on any site except domains in a provided list.

	 Values must be lowercase ASCII, or Punycode for non-ASCII.
	 Add * in front to match domain and subdomains.
	 Can't be used with `ifDomain`.
	 */
	var unlessDomain: [String]?

	/**
	 An array of strings representing the resource types (how the browser intends to use the resource) that the rule should match.

	 If not specified, the rule matches all resource types.
	 */
	var resourceType: [ResourceType]?

	/**
	 An array of strings that can include one of two mutually exclusive values.

	 If not specified, the rule matches all load types.
	 */
	var loadType: [LoadType]? {
		didSet {
			if loadType?.contains(.all) ?? false {
				loadType = nil
			}
		}
	}

	/**
	 An array of strings matched to the entire main document URL; limits the action to a specific list of URL patterns.

	 Values must be lowercase ASCII, or Punycode for non-ASCII.
	 Can't be used with `unlessTopUrl`.
	 */
	var ifTopUrl: [String]?

	/**
	 An array of strings matched to the entire main document URL; acts on any site except URL patterns in provided list.

	 Values must be lowercase ASCII, or Punycode for non-ASCII.
	 Can't be used with `ifTopUrl`.
	 */
	var unlessTopUrl: [String]?

	/**
	 An array of strings that specify loading contexts.
	 */
	var loadContext: [LoadContext]?
}

/**
 When a trigger matches a resource, the browser queues the associated action for execution.
 Safari evaluates all the triggers, and executes the actions in order.
 When a domain matches a trigger, all rules after the triggered rule that specify the same action are skipped.

 Group the rules with similar actions together to improve performance.
 For example, first specify rules that block content loading, followed by rules that block cookies.
 The trigger evaluation continues at the first rule that specifies a different action.

 There are only two valid fields for actions: `type` and `selector`.
 An action type is required. If the `type` is `cssDisplayNone`, a `selector` is required as well;
 otherwise the `selector` is optional.

 For example, you can specify the follow type and selector:
 ```
 "action": {
	"type": "css-display-none",
	"selector": "#newsletter, :matches(.main-page, .article) .news-overlay"
 }
 ```
 */
struct BlockAction: Codable {

	enum BlockType: String, Codable, CaseIterable, CustomStringConvertible {

		/**
		 Stops loading of the resource. If the resource was cached, ignores the cache.
		 */
		case block = "block"

		/**
		 Strips cookies from the header before sending to the server.
		 Only blocks cookies otherwise acceptable to Safari's privacy policy.
		 Combining with ignore-previous-rules doesn't override the browser’s privacy settings.
		 */
		case blockCookies = "block-cookies"

		/**
		 Hides elements of the page based on a CSS selector.
		 A selector field contains the selector list.
		 Any matching element has its display property set to none, which hides it.
		 */
		case cssDisplayNone = "css-display-none"

		/**
		 Ignores previously triggered actions.
		 */
		case ignorePreviousRules = "ignore-previous-rules"

		/**
		 Changes a URL from http to https. URLs with a specified (nondefault) port and links using other protocols are unaffected.
		 */
		case makeHttps = "make-https"

		var description: String {
			switch self {
			case .block:
				return NSLocalizedString("Block requests", comment: "")

			case .blockCookies:
				return NSLocalizedString("Block cookies", comment: "")

			default:
				return rawValue
			}
		}
	}

	var type: BlockType

	/**
	 For the selector field, specify a string that defines a selector list.
	 This value is required when the action `type` is `cssDisplayNone`.
	 If it's not, Safari ignores the selector field.
	 Use CSS identifiers as the individual selector values, separated by commas.
	 Safari and WebKit supports all of its CSS selectors for Safari content-blocking rules.
	 */
	var selector: String?
}
