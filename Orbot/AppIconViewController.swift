//
//  AppIconViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 18.11.25.
//  Copyright © 2020 - 2026 Guardian Project. All rights reserved.
//

import UIKit
import IPtProxyUI

class AppIconViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

	private lazy var icons: [AppIcon] = {
		var icons = [AppIcon(title: Bundle.main.displayName)]

		let bundleIcons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any]

		let alternateIcons = bundleIcons?["CFBundleAlternateIcons"] as? [String: Any] ?? [:]

		for icon in alternateIcons.keys {
			icons.append(.init(
				title: String(icon.suffix(from: icon.index(icon.startIndex, offsetBy: 7))),
				name: icon))
		}

		return icons.sorted()
	}()


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("App Icon", comment: "")
	}


	// MARK: UICollectionViewDataSource

	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return icons.count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "appIconCell", for: indexPath) as! AppIconCell

		cell.layer.cornerRadius = 16
		cell.layer.borderColor = UIColor.accent.cgColor

		return cell.set(icons[indexPath.item])
	}

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		Task {
			do {
				try await UIApplication.shared.setAlternateIconName(icons[indexPath.row].name)
			}
			catch {
				AlertHelper.present(self, message: error.localizedDescription)

				await MainActor.run {
					collectionView.deselectItem(at: indexPath, animated: false)
				}
			}
		}
	}


	// MARK: UICollectionViewDelegateFlowLayout

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout

		let space = (flowLayout?.minimumInteritemSpacing ?? 0) + (flowLayout?.sectionInset.left ?? 0) + (flowLayout?.sectionInset.right ?? 0)
		let size = (collectionView.frame.size.width - space) / 2

		return .init(width: size, height: size)
	}
}

class AppIconCell: UICollectionViewCell {

	@IBOutlet weak var imageView: UIImageView!

	@IBOutlet weak var titleLabel: UILabel!


	override var isSelected: Bool {
		didSet {
			if isSelected {
				layer.borderWidth = 4
			}
			else {
				layer.borderWidth = 0
			}
		}
	}


	@discardableResult
	func set(_ icon: AppIcon) -> Self {
		imageView.image = icon.image
		titleLabel.text = icon.title

		return self
	}
}

struct AppIcon: Comparable {

	private static let forcedOrder = [Bundle.main.displayName, "Orbie"]

	static func < (lhs: AppIcon, rhs: AppIcon) -> Bool {
		for item in forcedOrder {
			if lhs.title == item {
				return true
			}

			if rhs.title == item {
				return false
			}
		}

		return lhs.title < rhs.title
	}


	var title: String

	var name: String? = nil

	var image: UIImage? {
		.init(named: "Preview-\(name ?? "AppIcon")")
	}
}
