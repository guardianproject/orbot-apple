//
//  TestExplainerViewController.swift
//  Orbot
//
//  Created by Benjamin Erhart on 24.06.26.
//  Copyright © 2026 Guardian Project. All rights reserved.
//

import UIKit

class TestExplainerViewController: UIViewController, UITableViewDataSource {

	weak var delegate: TestingViewController.Delegate?

	@IBOutlet weak var titleLb: UILabel! {
		didSet {
			titleLb.text = L10n.testConnection
		}
	}

	@IBOutlet weak var descriptionLb: UILabel! {
		didSet {
			descriptionLb.text = L10n.orbotWillTestYourConnection
		}
	}

	@IBOutlet weak var tableView: UITableView!

	@IBOutlet weak var safetyLb: UILabel! {
		didSet {
			safetyLb.text = L10n.iAcknowledgeIHaveReadTheAbove
		}
	}

	@IBOutlet weak var safetySw: UISwitch!

	@IBOutlet weak var continueBt: UIButton! {
		didSet {
			continueBt.setTitle(L10n.testConnection)
		}
	}


	private lazy var icons = [
		UIImage(named: "point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath"),
		UIImage(systemName: "slash.circle"),
	]

	private lazy var texts = [
		{ L10n.theTestWillTryToConnectDirectly },
		{ L10n.ifYouAreUsingTorBridges },
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

	@IBAction func toggleSafety() {
		continueBt.isEnabled = safetySw.isOn
	}

	@IBAction func next() {
		guard continueBt.isEnabled else {
			return
		}

		let vc = UIStoryboard.main.instantiateViewController(TestingViewController.self)
		vc.delegate = delegate

		navigationController?.setViewControllers([vc], animated: true)
	}
}
