//
//  KindnessModeExplainerViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 23.06.26.
//  Copyright © 2026 Guardian Project. All rights reserved.
//

import UIKit

class KindnessModeExplainerViewController: UIViewController, UITableViewDataSource {

	weak var delegate: TestingViewController.Delegate?


	@IBOutlet weak var titleLb: UILabel! {
		didSet {
			titleLb.text = L10n.aboutRunningKindnessMode
		}
	}

	@IBOutlet weak var tableView: UITableView!

	@IBOutlet weak var continueBt: UIButton! {
		didSet {
			continueBt.setTitle(L10n.cont)
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
		{ L10n.keepOrbotOpen },
		{ L10n.yourScreenWillDim },
		{ L10n.weRecommendCharging },
		{ L10n.youCanAlsoTurnTheDeviceFaceDown },
		{ L10n.turnOffKindnessMode },
		{ L10n.orbotVpnWillAutomaticallyTurnOff },
	]


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = L10n.activateKindnessMode
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
