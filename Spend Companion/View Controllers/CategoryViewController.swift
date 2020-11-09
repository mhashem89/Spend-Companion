//
//  CategoryViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 8/26/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

protocol CategoryViewControllerDelegate: class {
    func categoryChanged()
}



class CategoryViewController: UIViewController {
    
    // MARK:- Properties
    
    let itemId = "itemId"
    var viewModel: CategoryViewModel?
    var month: Month!
    var delegate: CategoryViewControllerDelegate?
    var tableView = UITableView(frame: .zero, style: .plain)
    var viewFrameHeight: CGFloat = 0
    var tableViewFrameHeight: CGFloat = 0
    var activeCell: ItemCell? {
        didSet {
            scrollToActiveRow()
        }
    }
    var headerView = ItemTableHeader()
    var recurrenceViewer: RecurringViewController?
    let sortingVC = SortingViewController()
    var dimmingView = UIView().withBackgroundColor(color: UIColor.black.withAlphaComponent(0.5))
    
    var itemsToBeScheduled = [Item: ItemRecurrence]()
    
    var cancelChanges: Bool = false
    
    
// MARK:- Lifecycle Methods
    
    init(month: Month, category: Category? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.month = month
        if let category = category {
            self.viewModel = CategoryViewModel(month: month, category: category)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if cancelChanges, navigationItem.rightBarButtonItem!.isEnabled {
            viewModel?.cancel()
        }
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CustomColors.systemBackground
        title = month.date
        view.addSubviews([tableView, headerView])
        setupTableView()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
       
        setupHeaderView()
    
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewFrameHeight = view.frame.height
        tableViewFrameHeight = tableView.frame.height
    }
    
// MARK:- Methods
    
    func setupHeaderView() {
        headerView.plusButton.addTarget(self, action: #selector(self.addItem), for: .touchUpInside)
        headerView.sortButton.addTarget(self, action: #selector(self.presentSortingVC), for: .touchUpInside)
        headerView.favoriteButton.addTarget(self, action: #selector(favoriteCategory), for: .touchUpInside)
        headerView.titleButton.addTarget(self, action: #selector(selectTitle), for: .touchUpInside)
        headerView.toggleFavoriteButton(with: viewModel)
        headerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, heightConstant: 75 * viewsHeightScale)
        headerView.setupUI(with: viewModel)
        headerView.titleButton.setTitle(viewModel?.category?.name ?? "Choose name", for: .normal)
        headerView.enableButtons(with: viewModel)
    }
    
    func setupTableView() {
        tableView.register(ItemCell.self, forCellReuseIdentifier: itemId)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .interactive
        tableView.anchor(top: headerView.bottomAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, bottom: view.bottomAnchor)
    }
    
    @objc func selectTitle() {
        let categoryTitleVC = CategoryTitleViewController(categoryName: viewModel?.category?.name)
        categoryTitleVC.delegate = self
        let navVC = UINavigationController(rootViewController: categoryTitleVC)
        navVC.modalPresentationStyle = .overCurrentContext
        present(navVC, animated: true)
    }
    
   
    func handleFutureItems(for item: Item?, amount: Double? = nil, detail: String? = nil) {
        presentFutureTransactionAlert(withChangeType: .edit) { [weak self] (_) in
            self?.viewModel?.editFutureItems(for: item, amount: amount, detail: detail)
            self?.tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
        }
    }
    
    
    @objc private func save() {
        do {
            try viewModel?.save()
            try itemsToBeScheduled.keys.forEach { (item) in
                try CoreDataManager.shared.scheduleReminder(for: item, with: itemsToBeScheduled[item]!)
                if let sisterItems = item.futureItems(), sisterItems.count > 0 {
                    for item in sisterItems {
                        if let itemRecurrence = ItemRecurrence.createItemRecurrence(from: item) {
                            try CoreDataManager.shared.scheduleReminder(for: item, with: itemRecurrence)
                        }
                    }
                }
            }
        } catch let err {
            presentError(error: err)
        }
        delegate?.categoryChanged()
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func cancel() {
        cancelChanges = true
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func addItem() {
        tableView.performBatchUpdates({ [weak self] in
            guard let self = self else { return }
            self.viewModel?.createEmptyItem()
            let itemCount = self.viewModel?.items?.count ?? 1
            let newIndexPath = IndexPath(row: itemCount - 1, section: 0)
            self.tableView.insertRows(at: [newIndexPath], with: itemCount == 1 ? .none : .automatic)
        }, completion: { _ in
            self.activeCell = self.tableView.cellForRow(at: self.tableView.lastIndexPath(inSection: 0)) as? ItemCell
            self.dataChanged()
        })
        if viewModel!.items!.count > 1 {
            headerView.sortButton.isEnabled = true
        }
    }
    
    @objc private func favoriteCategory() {
        guard viewModel != nil else { return }
        viewModel?.favoriteCategory()
        headerView.toggleFavoriteButton(with: viewModel)
        dataChanged()
    }
    
    @objc private func presentSortingVC() {
        dimBackground()
        sortingVC.modalPresentationStyle = .popover
        sortingVC.delegate = self
        sortingVC.preferredContentSize = .init(width: 200 * viewsWidthScale, height: 240 * viewsHeightScale)
        sortingVC.popoverPresentationController?.delegate = self
        sortingVC.popoverPresentationController?.sourceView = headerView.sortButton
        sortingVC.popoverPresentationController?.sourceRect = headerView.sortButton.bounds
        present(sortingVC, animated: true)
    }
    
    @objc func handleKeyboardWillShow(notification: NSNotification) {
        guard UIDevice.current.userInterfaceIdiom != .pad,
              let keyboardFrame = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect
        else { return }
        view.frame.size.height = viewFrameHeight - keyboardFrame.height
        tableView.frame.size.height = tableViewFrameHeight - keyboardFrame.height
    }
    
    @objc func handleKeyboardWillHide(notification: NSNotification) {
        guard UIDevice.current.userInterfaceIdiom != .pad else { return }
        if view.frame.height != viewFrameHeight {
            view.frame.size.height = viewFrameHeight
            tableView.frame.size.height = tableViewFrameHeight
            tableView.setContentOffset(.zero, animated: true)
        }
    }
    
    private func dimBackground() {
        navigationController?.view.addSubview(dimmingView)
        dimmingView.fillSuperView()
    }
   
    func scrollToActiveRow() {
        guard let activeCell = activeCell, let activeIndexPath = tableView.indexPath(for: activeCell) else { return }
        tableView.scrollToRow(at: activeIndexPath, at: .none, animated: true)
        if let visiblePaths = tableView.indexPathsForVisibleRows {
            for indexPath in visiblePaths {
                tableView.cellForRow(at: indexPath)?.isHighlighted = false
            }
        }
        activeCell.isHighlighted = true
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
        let cell = tableView.dequeueReusableCell(withIdentifier: itemId, for: indexPath) as! ItemCell
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
        activeCell = tableView.cellForRow(at: indexPath) as? ItemCell
        let move = UIContextualAction(style: .normal, title: "Move") { [weak self] (_, _, _) in
            guard let categories = item.month?.categories?.allObjects as? [Category] else { return }
            let moveItemVC = MoveItemViewController(item: item, selectedCategory: categoryName)
            moveItemVC.delegate = self
            moveItemVC.categoryNames = categories.compactMap({ $0.name })
            self?.present(UINavigationController(rootViewController: moveItemVC), animated: true, completion: nil)
        }
        move.backgroundColor = CustomColors.indigo
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, _) in
            if let futureItems = item.futureItems() {
                self?.presentFutureTransactionAlert(withChangeType: .delete) { (_) in
                    futureItems.forEach({
                        if let itemIndex = self?.viewModel?.items?.firstIndex(of: $0) {
                            self?.viewModel?.deleteItem(item: $0, at: itemIndex)
                            self?.tableView.reloadData()
                        } else {
                            self?.viewModel?.context.delete($0)
                        }
                    })
                }
            }
            tableView.performBatchUpdates({
                tableView.deleteRows(at: [indexPath], with: .fade)
                self?.viewModel?.deleteItem(item: item, at: indexPath.row)
            }) { (finished) in
                self?.dataChanged()
            }
        }
        let swipe = UISwipeActionsConfiguration(actions: [delete, move])
        return swipe
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = viewModel?.items?[indexPath.row], item.recurringNum == nil else { return nil }
        activeCell = tableView.cellForRow(at: indexPath) as? ItemCell
        let setRecurring = UIContextualAction(style: .normal, title: "Recurring") { [weak self] (_, _, _) in
            if let cell = tableView.cellForRow(at: indexPath) as? ItemCell {
                cell.recurringCircleButton.isHidden = false
                self?.recurrenceButtonPressed(in: cell)
            }
        }
        setRecurring.backgroundColor = CustomColors.blue
        let swipe = UISwipeActionsConfiguration(actions: [setRecurring])
        return swipe
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewsHeightScale < 1 ? 50 : 50 * viewsHeightScale
    }
    
}


// MARK:- Category Title View Controller Delegate

extension CategoryViewController: CategoryTitleViewControllerDelegate {
    
    func saveCategoryTitle(title: String) {
        guard let monthString = month.date else { return }
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
            let selectedDay = viewModel.calcDaysRange(month: self.month)[day]
            let selectedDate = DateFormatters.fullDateWithLetters.date(from: selectedDay)!
            self.viewModel?.items?[selectedIndexPath.row].date = selectedDate
            cell.dayLabel.text = selectedDate.dayMatches(Date()) ? "Today" : selectedDay.extractDate()
        }
    }
    
    func detailTextFieldReturn(text: String, for cell: ItemCell, withMessage: Bool) {
        guard !cancelChanges,
              let selectedIndexPath = tableView.indexPath(for: cell),
              let item = viewModel?.items?[selectedIndexPath.row]
              else { return }
        item.detail = text
        if withMessage == true && item.futureItems() != nil {
            handleFutureItems(for: item, amount: nil, detail: text)
        }
    }
    
    func amountTextFieldReturn(amount: Double, for cell: ItemCell, withMessage: Bool) {
        guard !cancelChanges,
              let selectedIndexPath = tableView.indexPath(for: cell),
              let item = viewModel?.items?[selectedIndexPath.row]
        else { return }
        item.amount = amount
        if withMessage == true && item.futureItems() != nil {
           handleFutureItems(for: item, amount: amount, detail: nil)
        }
    }
    
    func dataChanged() {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func editingStarted(in textField: UITextField, of cell: ItemCell) {
        self.activeCell = cell
    }
    
    func recurrenceButtonPressed(in cell: ItemCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              let item = viewModel?.items?[indexPath.row]
        else { return }
        activeCell = cell
        
        recurrenceViewer = RecurringViewController(itemRecurrence: ItemRecurrence.createItemRecurrence(from: item))
        recurrenceViewer?.setupController(popoverDelegate: fontScale < 0.9 ? nil : self, sourceView: cell, sourceRect: cell.recurringCircleButton.frame, preferredWidth: 230 * fontScale, preferredHeight: 330 * fontScale)
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
    
    func recurringViewCancel(viewEmpty: Bool) {
        recurrenceViewer?.dismiss(animated: true, completion: nil)
        dimmingView.removeFromSuperview()
        if viewEmpty {
            activeCell?.recurringCircleButton.isHidden = true
        }
    }
    
    func recurringViewDone(with itemRecurrence: ItemRecurrence, new: Bool) {
        dimmingView.removeFromSuperview()
        recurrenceViewer?.dismiss(animated: true) { [unowned self] in
            guard let activeCell = activeCell,
                  let indexPath = tableView.indexPath(for: activeCell),
                  let item = viewModel?.items?[indexPath.row]
                  else { return }
            let alertController = UIAlertController(title: nil, message: "This change will be applied to all future transactions", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            alertController.addAction(UIAlertAction(title: "Apply", style: .default, handler: { (action) in
                updateItemRecurrence(for: item, with: itemRecurrence, isNew: new)
            }))
            new || item.futureItems() == nil ? updateItemRecurrence(for: item, with: itemRecurrence, isNew: new) : present(alertController, animated: true, completion: nil)
        }
    }
    
    func updateItemRecurrence(for item: Item, with itemRecurrence: ItemRecurrence, isNew: Bool) {
        do {
            try viewModel?.updateItemRecurrence(for: item, with: itemRecurrence, isNew: isNew)
            itemsToBeScheduled[item] = itemRecurrence
            viewModel?.reloadData()
            tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
            dataChanged()
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
        dataChanged()
    }
}



