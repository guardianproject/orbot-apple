//
//  AuthViewController.swift
//  Orbot Mac
//
//  Created by Benjamin Erhart on 24.08.22.
//  Copyright © 2022 Guardian Project. All rights reserved.
//

import Cocoa
import Tor

extension NSUserInterfaceItemIdentifier {

	static let authKeyItem = Self(rawValue: "authKeyItem")
}

class AuthViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDataSource, EditAuthDelegate {

	@IBOutlet weak var collectionView: NSCollectionView!


	private var auth: TorOnionAuth?


	override func viewDidLoad() {
		super.viewDidLoad()

		if let authDir = FileManager.default.torAuthDir {
			auth = TorOnionAuth(withPrivateDir: authDir, andPublicDir: nil)
		}

		collectionView.register(NSNib(nibNamed: "AuthKeyItem", bundle: nil), forItemWithIdentifier: .authKeyItem)
	}

	override func viewDidAppear() {
		super.viewDidAppear()

		view.window?.title = L10n.authCookies

		if let item = view.window?.toolbar?.items.first(where: { $0.itemIdentifier.rawValue == "add" }) {
			item.label = L10n.add
			item.paletteLabel = item.label
		}
	}



	// MARK: NSCollectionViewDelegate

	func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		let item = collectionView.makeItem(withIdentifier: .authKeyItem, for: indexPath)

		if let item = item as? AuthKeyItem,
		   let key = auth?.keys[indexPath.item]
		{
			item.apply(key: key)
		}

		return item
	}

	func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
		if let i = indexPaths.first?.item {
			edit(key: auth?.keys[i])
		}

		collectionView.deselectItems(at: indexPaths)
	}


	// MARK: NSCollectionViewDataSource

	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		return auth?.keys.count ?? 0
	}


	// MARK: EditAuthDelegate

	func set(key: TorAuthKey) {
		auth?.set(key)

		collectionView.reloadData()
	}

	func remove(key: TorAuthKey) {
		var i = 0

		for k in auth?.keys ?? [] {
			if k == key {
				break
			}

			i += 1
		}

		if i < auth?.keys.count ?? 0 {
			auth?.removeKey(at: i)
		}

		collectionView.reloadData()
	}


	// MARK: Actions

	@IBAction func add(_ sender: Any) {
		edit(key: nil)
	}


	// MARK: Private Methods

	private func edit(key: TorAuthKey?) {
		if let wc = NSStoryboard.main?.instantiateController(withIdentifier: "editAuthScene") as? NSWindowController,
		   let win = wc.window,
		   let vc = wc.contentViewController as? EditAuthViewController
		{
			vc.delegate = self
			vc.key = key

			NSApp.runModal(for: win)

			win.close()
		}
	}
}
