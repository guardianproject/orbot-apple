//
//  Tor+Helpers.swift
//  Orbot
//
//  Created by Benjamin Erhart on 25.08.23.
//  Copyright © 2023 Guardian Project. All rights reserved.
//

import Foundation

class TorHelpers {
	
	class func clearCache() {
		let fm = FileManager.default

		for dir in [fm.torDir, fm.artiStateDir, fm.artiCacheDir] {
			guard let dir = dir,
				  let enumerator = fm.enumerator(at: dir, includingPropertiesForKeys: [.isDirectoryKey])
			else {
				continue
			}

			for case let file as URL in enumerator {
				if (try? file.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false {
					if file == fm.torAuthDir {
						enumerator.skipDescendants()
					}

					continue
				}

				do {
					try fm.removeItem(at: file)

					print("File deleted: \(file.path)")
				}
				catch {
					print("File could not be deleted: \(file.path)")
				}
			}
		}
	}
}
