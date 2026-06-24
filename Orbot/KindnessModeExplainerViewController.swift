//
//  KindnessModeExplainerViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 23.06.26.
//  Copyright © 2026 Guardian Project. All rights reserved.
//

import UIKit

class KindnessModeExplainerViewController: UIViewController, UITableViewDataSource {

	protocol Delegate: AnyObject {

		func explainFinished()
	}

	weak var delegate: Delegate?


	@IBOutlet weak var titleLb: UILabel! {
		didSet {
			titleLb.text = String(format: NSLocalizedString("About Running Kindness Mode on %@", comment: ""), "iOS")
		}
	}

	@IBOutlet weak var tableView: UITableView!

	@IBOutlet weak var continueBt: UIButton! {
		didSet {
			continueBt.setTitle(NSLocalizedString("Continue", comment: ""))
		}
	}


	private lazy var icons = [
		UIImage(systemName: "iphone"),
		UIImage(systemName: "sun.haze"),
		UIImage(systemName: "bolt"),
		UIImage(systemName: "arrow.turn.up.forward.iphone"),
		UIImage(systemName: "heart.slash"),
		UIImage(systemName: "heart"),
	]

	private lazy var texts = [
		{ String(format: NSLocalizedString("Keep %@ open for Kindness Mode to work.", comment: "Placeholder is 'Orbot'"), Bundle.main.displayName) },
		{ NSLocalizedString("Your screen will dim to minimize power usage.", comment: "") },
		{ NSLocalizedString("We recommend charging the device when running Kindness Mode.", comment: "") },
		{ NSLocalizedString("You can also turn the device face down to minimize power usage. Kindness Mode will continue to run.", comment: "") },
		{ NSLocalizedString("Turn off Kindness Mode when you use a VPN on this device.", comment: "") },
		{ String(format: NSLocalizedString("%@ VPN will automatically turn off when Kindness Mode is on. Both cannot run at the same time.", comment: "Placeholder is 'Orbot'"), Bundle.main.displayName) },
	]


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = NSLocalizedString("Activate Kindness Mode", comment: "")
	}


	// MARK: UITableViewDataSource

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		texts.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "ExplainerCell", for: indexPath) as? ExplainerCell else {
			return UITableViewCell()
		}
		
		return cell.set(icon: icons[indexPath.row], text: texts[indexPath.row]())
	}


	// MARK: Actions

	@IBAction func next() {
		let vc = UIStoryboard.main.instantiateViewController(TestExplainerViewController.self)
		vc.delegate = delegate

		navigationController?.setViewControllers([vc], animated: true)
	}
}
