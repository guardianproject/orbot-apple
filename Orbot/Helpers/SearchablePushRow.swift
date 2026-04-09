//
//  SearchablePushRow.swift
//  IPtProxyUI-iOS
//
//  Created by Benjamin Erhart on 26.01.26.
//

// Found at: https://gist.github.com/max-pfeiffer/cd823549653ae22b8ba600b6cc4c764b

import Eureka


open class _SearchablePushRow<Cell: CellType>: OptionsRow<Cell>, PresenterRowType where Cell: BaseCell {


	public typealias PresenterRow = SearchableSelectorViewController<SelectorRow<Cell>>

	/// Defines how the view controller will be presented, pushed, etc.
	open var presentationMode: PresentationMode<PresenterRow>?

	/// Will be called before the presentation occurs.
	open var onPresentCallback: ((FormViewController, PresenterRow) -> Void)?

	required public init(tag: String?) {
		super.init(tag: tag)
		presentationMode = .show(controllerProvider: ControllerProvider.callback { return SearchableSelectorViewController<SelectorRow<Cell>> { _ in } }, onDismiss: { vc in
			let _ = vc.navigationController?.popViewController(animated: true) })
	}

	/**
	 Extends `didSelect` method
	 */
	open override func customDidSelect() {
		super.customDidSelect()
		guard let presentationMode = presentationMode, !isDisabled else { return }
		if let controller = presentationMode.makeController() {
			controller.row = self
			controller.options = (self.optionsProvider?.optionsArray)!
			controller.title = selectorTitle ?? controller.title
			onPresentCallback?(cell.formViewController()!, controller)
			presentationMode.present(controller, row: self, presentingController: self.cell.formViewController()!)
		} else {
			presentationMode.present(nil, row: self, presentingController: self.cell.formViewController()!)
		}
	}

	/**
	 Prepares the pushed row setting its title and completion callback.
	 */
	open override func prepare(for segue: UIStoryboardSegue) {
		super.prepare(for: segue)
		guard let rowVC = segue.destination as? PresenterRow else { return }
		rowVC.title = selectorTitle ?? rowVC.title
		rowVC.onDismissCallback = presentationMode?.onDismissCallback ?? rowVC.onDismissCallback
		onPresentCallback?(cell.formViewController()!, rowVC)
		rowVC.row = self
	}
}


/// A selector row where the user can pick an option from a pushed view controller
public final class SearchablePushRow<T: Equatable> : _SearchablePushRow<PushSelectorCell<T>>, RowType {
	public required init(tag: String?) {
		super.init(tag: tag)
	}
}

open class _SearchableSelectorViewController<Row: SelectableRowType, OptionsRow: OptionsProviderRow>: UITableViewController, UISearchResultsUpdating, TypedRowControllerType where Row: BaseRow, Row.Cell.Value == OptionsRow.OptionsProviderType.Option {

	/// The row that pushed or presented this controller
	public var row: RowOf<Row.Cell.Value>!
	public var options: [Row.Cell.Value]!

	/// A closure to be called when the controller disappears.
	public var onDismissCallback: ((UIViewController) -> Void)?


	// Search
	let searchController = UISearchController(searchResultsController: nil)
	var originalOptions = [Row.Cell.Value]()
	var currentOptions = [Row.Cell.Value]()

	// I would like to use a more elegant solution to get the options array from optionsprovider
	// same code as in _SelectorViewController but producing a swift_dynamicCastUnknownClassUnconditional exception
	/*
	public var optionsProviderRow: OptionsRow {
		return row as! OptionsRow
	}
	*/

	required public init() {
		super.init(style: .grouped)
		searchController.searchResultsUpdater = self
		searchController.obscuresBackgroundDuringPresentation = false
		searchController.hidesNavigationBarDuringPresentation = false
		self.definesPresentationContext = true

		navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .trash, target: self, action: #selector(clear))
	}

	convenience public init(_ callback: ((UIViewController) -> Void)?) {
		self.init()
		onDismissCallback = callback
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	open override func viewDidLoad() {
		super.viewDidLoad()

		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
		tableView!.tableHeaderView = searchController.searchBar

		originalOptions = options
		currentOptions = options

		tableView.reloadData()
	}

	open override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return row?.title
	}
	open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return currentOptions.count
	}
	open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let option = currentOptions[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		cell.textLabel?.text = row.displayValueFor?(option)
		return cell
	}
	open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let option = self.currentOptions[indexPath.row]
		row.value = option
		onDismissCallback?(self)
	}
	open func updateSearchResults(for searchController: UISearchController) {
		if let query = searchController.searchBar.text {
			if query == "" {
				currentOptions = originalOptions
			} else {
				currentOptions = originalOptions.filter{
					(row.displayValueFor?($0)?.localizedCaseInsensitiveContains(query))!
				}
			}
		}
		tableView.reloadData()
	}

	@objc
	func clear() {
		row.value = nil
		onDismissCallback?(self)
	}
}

/// Selector Controller (used to select one option among a list)
open class SearchableSelectorViewController<OptionsRow: OptionsProviderRow>: _SearchableSelectorViewController<ListCheckRow<OptionsRow.OptionsProviderType.Option>, OptionsRow> {
}
