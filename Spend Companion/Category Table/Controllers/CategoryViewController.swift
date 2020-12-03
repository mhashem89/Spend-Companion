//
//  CategoryViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 8/26/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

protocol CategoryViewControllerDelegate: class {
    /// Tells the delegate that some data have changed in the category in order to reload the month collection view
    func categoryChanged()
}

class CategoryViewController: UIViewController {
    
// MARK:- Properties
    
    var viewModel: CategoryViewModel?
    private var month: Month
    weak var delegate: CategoryViewControllerDelegate?
    private var viewFrameHeight: CGFloat = 0  // Keep track of the frame height to restore it after dismissing the keyboard
    private var tableViewFrameHeight: CGFloat = 0 // Keep track of the frame height to restore it after dismissing the keyboard
    private var itemsToBeScheduled = [Item: ItemRecurrence]() // Keep track of items that need reminder notifications scheduled, which gets done when the user presses "Save button"
    private var cancelChanges: Bool = false // Gets set to true when user presses "Cancel" to perform cleanup after the view controller is deallocated ***
    var activeIndexPath: IndexPath? { // Keep track which index path is active in order to highlight it
        didSet {
            guard let activeIndexPath = activeIndexPath else { return }
            activeCell = tableView.cellForRow(at: activeIndexPath) as? ItemCell
            scrollToActiveRow()
        }
    }

// MARK:- Subviews
    
    var tableView = UITableView(frame: .zero, style: .plain)  // The main table view
    var activeCell: ItemCell?  // The current active cell
    private var headerView = ItemTableHeader()  // The table header
    private var recurrenceViewer: RecurringViewController? // The controller that displays item recurrence
    private let sortingVC = SortingViewController() // The controller that shows up when sorting button is pressed
    private var dimmingView = UIView().withBackgroundColor(color: UIColor.black.withAlphaComponent(0.5)) // To dim the background

// MARK:- Lifecycle Methods
    
    init(month: Month, category: Category? = nil) {
        self.month = month
        if let category = category {
            self.viewModel = CategoryViewModel(month: month, category: category)
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if cancelChanges, let rightBarButton = navigationItem.rightBarButtonItem, rightBarButton.isEnabled {
            viewModel?.cancel()  // If the user presses cancel and there are unsaved changed, then asks the context to rollback
        }
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CustomColors.systemBackground
        
        view.addSubviews([tableView, headerView])
        setupHeaderView()
        setupTableView()
        
        // Setup the navigation bar
        title = month.date
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
       
        // Setup the keyboard notification observers
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewFrameHeight = view.frame.height
        tableViewFrameHeight = tableView.frame.height
    }
    
// MARK:- Methods
    
    private func setupHeaderView() {
        headerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, heightConstant: 75 * windowHeightScale)
        headerView.plusButton.addTarget(self, action: #selector(self.addItem), for: .touchUpInside)
        headerView.sortButton.addTarget(self, action: #selector(self.presentSortingVC), for: .touchUpInside)
        headerView.favoriteButton.addTarget(self, action: #selector(favoriteCategory), for: .touchUpInside)
        headerView.titleButton.addTarget(self, action: #selector(selectTitle), for: .touchUpInside)
        headerView.toggleFavoriteButton(with: viewModel)
        headerView.setupUI(with: viewModel)
        headerView.enableButtons(with: viewModel)
    }
    
    private func setupTableView() {
        tableView.setup(delegate: self, dataSource: self, cellClass: ItemCell.self, cellId: ItemCell.reuseIdentifier)
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .interactive
        tableView.anchor(top: headerView.bottomAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, bottom: view.bottomAnchor)
    }
    /// Gets called when the user presses the title button. Presents the title view controller.
    @objc private func selectTitle() {
        let categoryTitleVC = CategoryTitleViewController(categoryName: viewModel?.category?.name)
        categoryTitleVC.delegate = self
        let navVC = UINavigationController(rootViewController: categoryTitleVC)
        navVC.modalPresentationStyle = .overCurrentContext
        present(navVC, animated: true)
    }
    /// Gets called if the user edits an item that has future similar items, presents an alert to ask the user whether to edit all future items or only current item
    private func handleFutureItems(for item: Item?, amount: Double? = nil, detail: String? = nil) {
        presentFutureTransactionAlert(withChangeType: .edit) { [weak self] (_) in
            self?.viewModel?.editFutureItems(for: item, amount: amount, detail: detail)
            self?.tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
        }
    }
    /// Gets called when the "Save" button is pressed
    @objc private func save() {
        activeCell?.resignFirstResponders()
        do {
            try viewModel?.save()
            try itemsToBeScheduled.keys.forEach { (item) in // Schedule reminder notifications that have been saved
                try CoreDataManager.shared.scheduleReminder(for: item, with: itemsToBeScheduled[item], createNew: item.reminderUID == nil)
                if let sisterItems = item.futureItems(), sisterItems.count > 0 {
                    for item in sisterItems {
                        if let itemRecurrence = ItemRecurrence.createItemRecurrence(from: item) {
                            try CoreDataManager.shared.scheduleReminder(for: item, with: itemRecurrence, createNew: item.reminderUID == nil)
                        }
                    }
                }
            }
        } catch let err {
            presentError(error: err)
        }
        delegate?.categoryChanged()
        dismiss(animated: true) {
            UserDefaults.standard.setValue(false, forKey: SettingNames.contextIsActive)
        }
    }
    /// Gets called when the user presses "Cancel" button.
    @objc private func cancel() {
        cancelChanges = true
        dismiss(animated: true) {
            UserDefaults.standard.setValue(false, forKey: SettingNames.contextIsActive)
        }
    }
    
    @objc private func addItem() {
        tableView.performBatchUpdates({ [weak self] in
            guard let self = self else { return }
            self.viewModel?.createEmptyItem()
            let itemCount = self.viewModel?.items?.count ?? 1
            let newIndexPath = IndexPath(row: itemCount - 1, section: 0)
            self.tableView.insertRows(at: [newIndexPath], with: itemCount == 1 ? .none : .automatic) // Insert new row into last indexPath
        }, completion: { [weak self] _ in
            self?.activeIndexPath = self?.tableView.lastIndexPath(inSection: 0) // Set the new indexPath to be the active one
            self?.dataDidChange()
        })
        if let items = viewModel?.items, items.count > 1 {  // Enable sort button if item count >1
            headerView.sortButton.isEnabled = true
        }
    }
    /// Gets called when the favorite button is pressed
    @objc private func favoriteCategory() {
        guard viewModel != nil else { return }
        viewModel?.favoriteCategory()  // Tells the view model to favorite the catogory
        headerView.toggleFavoriteButton(with: viewModel)  // Tells the subview to favorite the category
        dataDidChange()
    }
    /// Gets caleld with the sorting button is pressed
    @objc private func presentSortingVC() {
        dimBackground()
        sortingVC.setupPopoverController(popoverDelegate: self,
                                         sourceView: headerView.sortButton,
                                         sourceRect: headerView.sortButton.bounds,
                                         preferredWidth: 200 * windowWidthScale, preferredHeight: 240 * windowHeightScale,
                                         style: .popover)
        sortingVC.delegate = self
        present(sortingVC, animated: true)
    }
    
    @objc private func handleKeyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect
        else { return }
        view.frame.size.height = viewFrameHeight - keyboardFrame.height
        tableView.frame.size.height = tableViewFrameHeight - keyboardFrame.height
        scrollToActiveRow()
    }
    
    @objc private func handleKeyboardWillHide(notification: NSNotification) {
        if view.frame.height != viewFrameHeight {
            view.frame.size.height = viewFrameHeight
            tableView.frame.size.height = tableViewFrameHeight
        }
    }
    
    private func dimBackground() {
        navigationController?.view.addSubview(dimmingView)
        dimmingView.fillSuperView()
    }
   
    func scrollToActiveRow() {
        guard let activeIndexPath = activeIndexPath else { return }
        tableView.scrollToRow(at: activeIndexPath, at: .none, animated: true)
        if let visiblePaths = tableView.indexPathsForVisibleRows {
            for indexPath in visiblePaths {
                tableView.cellForRow(at: indexPath)?.isHighlighted = false
            }
        }
        activeCell?.isHighlighted = true
    }
}

// MARK:- Table View Methods

extension CategoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.items?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ItemCell.reuseIdentifier, for: indexPath) as! ItemCell
        cell.setupUI()
        cell.configure(for: viewModel?.items?[indexPath.row])
        cell.dayPicker.delegate = self
        cell.dayPicker.dataSource = self
        cell.delegate = self
        if cell.isHighlighted { cell.isHighlighted = false }
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = viewModel?.items?[indexPath.row], let categoryName = item.category?.name else { return nil }
        activeIndexPath = indexPath
        let move = UIContextualAction(style: .normal, title: "Move") { [weak self] (_, _, _) in // Present table view controller with all the other categories
            guard let categories = item.month?.categories?.allObjects as? [Category] else { return }
            let moveItemVC = MoveItemViewController(item: item, selectedCategory: categoryName)
            moveItemVC.delegate = self
            moveItemVC.categoryNames = categories.compactMap({ $0.name })
            self?.present(UINavigationController(rootViewController: moveItemVC), animated: true, completion: nil)
        }
        move.backgroundColor = CustomColors.indigo
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, _) in
            if let futureItems = item.futureItems() { // If the item as similar future items then present an alert to the user
                self?.presentFutureTransactionAlert(withChangeType: .delete) { (_) in
                    futureItems.forEach({ // If the user elects to delete all similar future items
                        if let itemIndex = self?.viewModel?.items?.firstIndex(of: $0) { // Reload the table if the future item is in the same month
                            self?.viewModel?.deleteItem(item: $0, at: itemIndex)
                            self?.tableView.reloadData()
                        } else { // Otherwise delete the future item from context and schedule its reminder for deletion
                            self?.viewModel?.context.delete($0)
                            if let itemReminder = $0.reminderUID { self?.viewModel?.reminderUIDsForDeletion.append(itemReminder) }
                        }
                    })
                }
            }
            tableView.performBatchUpdates({
                tableView.deleteRows(at: [indexPath], with: .fade)
                self?.viewModel?.deleteItem(item: item, at: indexPath.row)
            }) { (finished) in
                self?.dataDidChange()
            }
        }
        let swipe = UISwipeActionsConfiguration(actions: [delete, move])
        return swipe
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = viewModel?.items?[indexPath.row], item.recurringNum == nil else { return nil }
        activeIndexPath = indexPath
        let setRecurring = UIContextualAction(style: .normal, title: "Recurring") { [weak self] (_, _, _) in
            if let cell = tableView.cellForRow(at: indexPath) as? ItemCell { // Open the recurring view controller for the cell
                cell.recurringCircleButton.isHidden = false
                self?.recurrenceButtonPressed(in: cell)
            }
        }
        setRecurring.backgroundColor = CustomColors.blue
        let swipe = UISwipeActionsConfiguration(actions: [setRecurring])
        return swipe
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return windowHeightScale < 1 ? 50 : 50 * windowHeightScale
    }
}


// MARK:- Category Title View Controller Delegate

extension CategoryViewController: CategoryTitleViewControllerDelegate {
    
    func saveCategoryTitle(title: String) {
        guard let monthString = month.date else { return }
        
        // If the user chooses a category that already exists, then the view model is changed to load the category items, othewise a new category is created
        if let category = CoreDataManager.shared.checkCategory(categoryName: title, monthString: monthString, createNew: viewModel == nil) {
            self.viewModel = CategoryViewModel(month: month, category: category)
            tableView.reloadData()
            headerView.enableButtons(with: viewModel)
        } else {
            viewModel?.editCategoryName(name: title)
        }
        headerView.favoriteButton.isHidden = title == "Income"
        headerView.titleButton.setTitle(title, for: .normal)
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
}

// MARK:- Item Cell Delegate

extension CategoryViewController: ItemCellDelegate {
    
    func donePressedInDayPicker(selected day: Int, for cell: ItemCell) {
        guard let viewModel = viewModel, !cancelChanges else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let selectedIndexPath = self.tableView.indexPath(for: cell) else { return }
            let selectedDay = viewModel.calcDaysRange(month: self.month)[day] // Return the day selected from the range of days in the month
            let selectedDate = DateFormatters.fullDateWithLetters.date(from: selectedDay)! // Convert the day into a date
            self.viewModel?.items?[selectedIndexPath.row].date = selectedDate // Update the item's date
            cell.dayLabel.text = selectedDate.dayMatches(Date()) ? "Today" : selectedDay.extractDate()
        }
    }
    
    func detailTextFieldReturn(text: String, for cell: ItemCell, withMessage: Bool) {
        guard !cancelChanges, // Validate return didn't happen because user dismissed the view controller by pressing "Cancel"
              let selectedIndexPath = tableView.indexPath(for: cell),
              let item = viewModel?.items?[selectedIndexPath.row]
              else { return }
        item.detail = text
        if withMessage == true && item.futureItems() != nil { // Present an alert if the item has similar future items
            handleFutureItems(for: item, amount: nil, detail: text)
        }
    }
    
    func amountTextFieldReturn(amount: Double, for cell: ItemCell, withMessage: Bool) {
        guard !cancelChanges, // Validate return didn't happen because user dismissed the view controller by pressing "Cancel"
              let selectedIndexPath = tableView.indexPath(for: cell),
              let item = viewModel?.items?[selectedIndexPath.row]
        else { return }
        item.amount = amount
        if withMessage == true && item.futureItems() != nil {
           handleFutureItems(for: item, amount: amount, detail: nil)
        }
    }
    
    func dataDidChange() {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func editingStarted(in textField: UITextField, of cell: ItemCell) {
        self.activeIndexPath = tableView.indexPath(for: cell)
    }
    
    func recurrenceButtonPressed(in cell: ItemCell) { // Present the recurrence view controller
        guard let indexPath = tableView.indexPath(for: cell),
              let item = viewModel?.items?[indexPath.row]
        else { return }
        activeIndexPath = tableView.indexPath(for: cell)
        
        recurrenceViewer = RecurringViewController(itemRecurrence: ItemRecurrence.createItemRecurrence(from: item))
        recurrenceViewer?.setupPopoverController(popoverDelegate: fontScale < 0.9 ? nil : self,
                                                 sourceView: cell,
                                                 sourceRect: cell.recurringCircleButton.frame,
                                                 preferredWidth: fontScale < 1 ? 220 : 220 * fontScale, preferredHeight: fontScale < 1 ? 330 : 330 * fontScale,
                                                 style: fontScale < 0.9 ? .overCurrentContext : .popover)
        recurrenceViewer?.delegate = self
        recurrenceViewer?.dayPicker.minimumDate = Calendar.current.date(byAdding: .day, value: 1, to: item.date ?? Date())

        if let itemDate = item.date, itemDate < Date() { recurrenceViewer?.reminderSwitch.removeFromSuperview() }
       
        dimBackground()
        present(recurrenceViewer!, animated: true, completion: nil)
    }

}

// MARK:- PickerView Delegate


extension CategoryViewController: UIPickerViewDelegate, UIPickerViewDataSource, UIPopoverPresentationControllerDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel?.calcDaysRange(month: month).count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return viewModel?.calcDaysRange(month: month)[row].extractDate()
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        dimmingView.removeFromSuperview()
        return true
    }
    
}

// MARK:- Sorting View Controller Delegate

extension CategoryViewController: SortingViewControllerDelegate {
    
    func sortingChosen(option: SortingOption, direction: SortingDirection) {
        viewModel?.currentSortingSelection = (option, direction)
        tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
        sortingVC.dismiss(animated: true) {
            self.dimmingView.removeFromSuperview()
        }
    }
}

// MARK:- Recurring View Controller Deleagte

extension CategoryViewController: RecurringViewControllerDelegate {
    
    func recurringViewCancel(wasNew : Bool) {
        recurrenceViewer?.dismiss(animated: true, completion: nil)
        dimmingView.removeFromSuperview()
        activeCell?.recurringCircleButton.isHidden = wasNew // Recurrence button hidden if no existing item recurrence
    }
    
    func recurringViewDone(with itemRecurrence: ItemRecurrence, new: Bool, dataChanged: [ItemRecurrenceCase]) {
        dimmingView.removeFromSuperview()
        recurrenceViewer?.dismiss(animated: true) { [unowned self] in
            guard let indexPath = activeIndexPath,
                  let item = viewModel?.items?[indexPath.row]
                  else { return }
            let alertController = UIAlertController(title: nil, message: "This change will be applied to all future transactions", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            alertController.addAction(UIAlertAction(title: "Apply", style: .default, handler: { (action) in
                updateItemRecurrence(for: item, with: itemRecurrence, isNew: new, dataChanged: dataChanged)
            }))
            new || item.futureItems() == nil ? updateItemRecurrence(for: item, with: itemRecurrence, isNew: new, dataChanged: dataChanged) : present(alertController, animated: true, completion: nil)
        }
    }
    /// Tells the view model to update the item recurrence and schedules the item for notification after the user presses "Save"
    private func updateItemRecurrence(for item: Item, with itemRecurrence: ItemRecurrence, isNew: Bool, dataChanged: [ItemRecurrenceCase]) {
        do {
            try viewModel?.updateItemRecurrence(for: item, with: itemRecurrence, isNew: isNew, dataChanged: dataChanged)
            itemsToBeScheduled[item] = itemRecurrence
            viewModel?.reloadData()
            tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
            dataDidChange()
        } catch let err {
            presentError(error: err)
        }
    }
   
}

// MARK:- Move Item View Controller Delegate

extension CategoryViewController: MoveItemVCDelegate {
    
    func moveItem(item: Item, to category: String, sisterItems: [Item]?) {
        viewModel?.moveItem(item: item, to: category, sisterItems: sisterItems)
        tableView.reloadData()
        dataDidChange()
    }
}



