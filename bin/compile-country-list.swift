#!/usr/bin/env swift

import Foundation


// MARK: Config

var request = URLRequest(url: URL(string: "http://onionoo.torproject.org/details?type=relay&running=true&flag=Exit")!)

let outfile = resolve("../Shared/exit-node-countries.plist")

// MARK: Helper Methods

func exit(_ msg: String) {
	print(msg)
	exit(1)
}

func resolve(_ path: String) -> URL {
	let script = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()

	if script.path.hasPrefix("/") {
		return URL(fileURLWithPath: path, relativeTo: script)
	}

	let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
	let base = URL(fileURLWithPath: script.path, relativeTo: cwd)

	return URL(fileURLWithPath: path, relativeTo: base)
}


// MARK: Classes

struct DetailsContainer: Decodable {

	let relays: [Details]
}

struct Details: Decodable {

	let country: String
}


// MARK: Main

let modified = (try? outfile.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date(timeIntervalSince1970: 0)

guard Calendar.current.dateComponents([.day], from: modified, to: Date()).day ?? 2 > 1 else {
	print("File too young, won't update!")
	exit(0)
}

let formatter = DateFormatter()
formatter.locale = Locale(identifier: "en_US_POSIX")
formatter.dateFormat = "EE, dd MMM yyyy HH:mm:ss z"
formatter.timeZone = TimeZone(secondsFromGMT: 0)

request.setValue(formatter.string(from: modified), forHTTPHeaderField: "If-Modified-Since")

let task = URLSession.shared.dataTask(with: request) { data, response, error in

//	print("data=\(String(describing: String(data: data ?? Data(), encoding: .utf8))), response=\(String(describing: response)), error=\(String(describing: error))")

	if let error = error {
		return exit(error.localizedDescription)
	}

	guard let response = response as? HTTPURLResponse else {
		return exit("No valid HTTP response.")
	}

	if response.statusCode == 304 {
		print("Data didn't change, yet!")
		exit(0)
	}

	guard response.statusCode == 200 else {
		return exit("\(response.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))")
	}

	guard let data = data, !data.isEmpty else {
		return exit("Response body missing.")
	}

	let body: DetailsContainer

	do {
		body = try JSONDecoder().decode(DetailsContainer.self, from: data)
	}
	catch {
		return exit(error.localizedDescription)
	}

//	print(body)

	var countries = Set<String>()

	body.relays.forEach { countries.insert($0.country) }

//	print(countries)

	let encoder = PropertyListEncoder()
	encoder.outputFormat = .xml

	let output: Data

	do {
		output = try encoder.encode(countries.sorted())
	}
	catch {
		return exit("Plist could not be encoded! error=\(error)")
	}

	do {
		try output.write(to: outfile, options: .atomic)
	}
	catch {
		exit("Plist file could not be written! error=\(error)")
	}

	exit(0)
}
task.resume()

// Wait on explicit exit.
_ = DispatchSemaphore(value: 0).wait(timeout: .distantFuture)
