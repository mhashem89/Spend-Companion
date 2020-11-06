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
    
    let titleId = "cellId"
    let itemId = "itemId"
    var viewModel: CategoryViewModel?
    var month: Month!
    var delegate: CategoryViewControllerDelegate?
    var tableView = UITableView(frame: .zero, style: .plain)
    var viewFrameHeight: CGFloat = 0
    var tableViewFrameHeight: CGFloat = 0
    var activeCell: ItemCell?
    var headerView = ItemTableHeader()
    var recurrenceViewer: RecurringViewController?
    let sortingVC = SortingViewController()
    var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
    
    var itemsToBeScheduled = [Item: ItemRecurrence]()
    
    
// MARK:- Lifecycle Methods
    
    init(month: Month, category: Category? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.month = month
        if let category = category {
            self.viewModel = CategoryViewModel(month: month, category: category)
            enableHeaderButtons()
            headerView.favoriteButton.isHidden = category.name == "Income"
            headerView.titleButton.isUserInteractionEnabled = category.name != "Income"
        } else {
            headerView.plusButton.isEnabled = false
            headerView.favoriteButton.isEnabled = false
            headerView.titleButton.setTitle("Choose name", for: .normal)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let navVC = presentingViewController as? UINavigationController, navVC.viewControllers.contains(InitialViewController.shared) {
            InitialViewController.shared.reloadMonthDataAfterChange()
        }
    }
    
    
// MARK:- Methods
    
    func setupHeaderView() {
        headerView.plusButton.addTarget(self, action: #selector(self.addItem), for: .touchUpInside)
        headerView.sortButton.addTarget(self, action: #selector(self.sort), for: .touchUpInside)
        headerView.favoriteButton.addTarget(self, action: #selector(favoriteCategory), for: .touchUpInside)
        toggleFavoriteButton()
        headerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, heightConstant: 75 * viewsHeightScale)
        headerView.setupUI()
        headerView.titleButton.setTitle(viewModel?.category?.name ?? "Choose name", for: .normal)
        headerView.delegate = self
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
    
    func enableHeaderButtons() {
        headerView.plusButton.isEnabled = true
        headerView.favoriteButton.isEnabled = true
        if viewModel?.items != nil, viewModel!.items!.count > 1 {
            headerView.sortButton.isEnabled = true
        }
    }
    
    func handleFutureItems(for item: Item?, amount: Double? = nil, detail: String? = nil) {
        let alertController = UIAlertController(title: nil, message: "Apply the change to all future transactions?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Only this transaction", style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: "All future transactions", style: .default, handler: { [weak self] (action) in
            self?.viewModel?.editFutureItems(for: item, amount: amount, detail: detail)
            self?.tableView.reloadData()
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    
    @objc private func save() {
        do {
            try viewModel?.save()
            itemsToBeScheduled.keys.forEach { (item) in
                InitialViewModel.shared.scheduleReminder(for: item, with: itemsToBeScheduled[item]!)
                if let sisterItems = item.sisterItems?.allObjects as? [Item], sisterItems.count > 0 {
                    for item in sisterItems {
                        if let itemRecurrence = ItemRecurrence.createItemRecurrence(from: item) {
                            InitialViewModel.shared.scheduleReminder(for: item, with: itemRecurrence)
                        }
                    }
                }
            }
        } catch let err {
            print(err.localizedDescription)
        }
        delegate?.categoryChanged()
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func cancel() {
        if navigationItem.rightBarButtonItem!.isEnabled {
            viewModel?.cancel()
        }
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func addItem() {
        tableView.performBatchUpdates({
            viewModel?.createNewItem()
            let itemCount = viewModel?.items?.count ?? 1
            let newIndexPath = IndexPath(row: itemCount - 1, section: 0)
            tableView.insertRows(at: [newIndexPath], with: itemCount == 1 ? .none : .automatic)
        }, completion: { [self]_ in
            scrollToLastRow()
            dataChanged()
        })
        if viewModel!.items!.count > 1 {
            headerView.sortButton.isEnabled = true
        }
    }
    
    @objc private func favoriteCategory() {
        guard viewModel != nil else { return }
        viewModel?.favoriteCategory()
        toggleFavoriteButton()
        dataChanged()
    }
    
    func toggleFavoriteButton() {
        guard viewModel != nil else { return }
        switch viewModel!.isFavorite {
        case true:
            if #available(iOS 13, *) {
                headerView.favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            }
            headerView.favoriteButton.tintColor = .red
        case false:
            if #available(iOS 13, *) {
                headerView.favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
            }
            headerView.favoriteButton.tintColor = .systemBlue
        }
    }
    
    @objc private func sort() {
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
        guard UIDevice.current.userInterfaceIdiom != .pad else { return }
        guard let keyboardFrame = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect else { return }
        view.frame.size.height = viewFrameHeight - keyboardFrame.height
        tableView.frame.size.height = tableViewFrameHeight - keyboardFrame.height
        scrollToActiveRow()
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
    
    func scrollToLastRow() {
        guard let itemCount = viewModel?.items?.count else { return }
        let lastIndexPath = IndexPath(item: itemCount - 1, section: 0)
        tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
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
    
    private func calcDaysRange(month: Month) -> [String] {
        
        let firstDay = DateFormatters.monthYearFormatter.date(from: month.date!)!
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: firstDay)
        let monthDays = calendar.range(of: .day, in: .month, for: firstDay)!
        let days = (monthDays.lowerBound..<monthDays.upperBound)
            .compactMap( { calendar.date(byAdding: .day, value: $0 - dayOfMonth, to: firstDay) } )
        let dayStrings = days.compactMap({ DateFormatters.fullDateWithLetters.string(from: $0) })
        return dayStrings
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
        let move = UIContextualAction(style: .normal, title: "Move") { [weak self] (_, _, _) in
            guard let categories = item.month?.categories?.allObjects as? [Category] else { return }
            let moveItemVC = MoveItemViewController()
            moveItemVC.delegate = self
            moveItemVC.item = item
            moveItemVC.selectedCategory = categoryName
            moveItemVC.categoryNames = categories.compactMap({ $0.name })
            self?.present(UINavigationController(rootViewController: moveItemVC), animated: true, completion: nil)
        }
        move.backgroundColor = CustomColors.indigo
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, _) in
            if let futureItems = item.futureItems() {
                let alertController = UIAlertController(title: nil, message: "Delete all future transactions?", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Only this transaction", style: .default, handler: nil))
                alertController.addAction(UIAlertAction(title: "All future transactions", style: .default, handler: { (_) in
                    futureItems.forEach({
                        if let itemIndex = self?.viewModel?.items?.firstIndex(of: $0) {
                            self?.viewModel?.deleteItem(item: $0, at: itemIndex)
                            self?.tableView.reloadData()
                        } else {
                            self?.viewModel?.context.delete($0)
                        }
                    })
                }))
                self?.present(alertController, animated: true, completion: nil)
            }
            tableView.performBatchUpdates({
                tableView.deleteRows(at: [indexPath], with: .fade)
                self?.viewModel?.deleteItem(item: item, at: indexPath.row)
            }) { (finished) in
                self?.dataChanged()
                tableView.reloadData()
            }
        }
        let swipe = UISwipeActionsConfiguration(actions: [delete, move])
        return swipe
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = viewModel?.items?[indexPath.row], item.recurringNum == nil else { return nil }
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


// MARK:- Item Table Header Delegate

extension CategoryViewController: ItemTableHeaderDelegate {
    
    func titleLabelTapped() {
        selectTitle()
    }
}

// MARK:- Category Title View Controller Delegate

extension CategoryViewController: CategoryTitleViewControllerDelegate {
    
    func saveCategoryTitle(title: String) {
        if self.viewModel == nil {
            let category = InitialViewModel.shared.checkCategory(categoryName: title, monthString: month.date!)
            self.viewModel = CategoryViewModel(month: month, category: category)
            tableView.reloadData()
            enableHeaderButtons()
        } else {
            viewModel?.editCategoryName(name: title)
        }
        headerView.favoriteButton.isHidden = title == "Income" || title == "Recurring Expenses"
        headerView.titleButton.setTitle(title, for: .normal)
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
}

// MARK:- Item Cell Delegate

extension CategoryViewController: ItemCellDelegate {
    
    func donePressedInDayPicker(selected day: Int, for cell: ItemCell) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let selectedIndexPath = self.tableView.indexPath(for: cell) else { return }
            let selectedDay = self.calcDaysRange(month: self.month)[day]
            let selectedDate = DateFormatters.fullDateWithLetters.date(from: selectedDay)!
            self.viewModel?.items?[selectedIndexPath.row].date = selectedDate
            (self.tableView.cellForRow(at: selectedIndexPath) as! ItemCell).dayLabel.text = selectedDate.dayMatches(Date()) ? "Today" : self.calcDaysRange(month: self.month)[day].extractDate()
            (self.tableView.cellForRow(at: selectedIndexPath) as! ItemCell).dayLabel.textColor = CustomColors.label
            self.scrollToActiveRow()
        }
    }
    
    func detailTextFieldReturn(text: String, for cell: ItemCell, withMessage: Bool) {
        scrollToActiveRow()
        guard let selectedIndexPath = tableView.indexPath(for: cell) else { return }
        let item = viewModel?.items?[selectedIndexPath.row]
        item?.detail = text
     
        if withMessage == true {
            handleFutureItems(for: item, amount: nil, detail: text)
        }
    }
    
    func amountTextFieldReturn(amount: Double, for cell: ItemCell, withMessage: Bool) {
        scrollToActiveRow()
        guard let selectedIndexPath = tableView.indexPath(for: cell) else { return }
        let item = viewModel?.items?[selectedIndexPath.row]
        item?.amount = amount
        
        if withMessage == true {
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
        guard let indexPath = tableView.indexPath(for: cell), let item = viewModel?.items?[indexPath.row] else { return }
        activeCell = cell
        scrollToActiveRow()
        
        self.recurrenceViewer = RecurringViewController(itemRecurrence: ItemRecurrence.createItemRecurrence(from: item))
        recurrenceViewer?.modalPresentationStyle = fontScale < 1 ? .overCurrentContext : .popover
        recurrenceViewer?.popoverPresentationController?.delegate = fontScale < 0.9 ? nil : self
        recurrenceViewer?.popoverPresentationController?.sourceView = cell
        recurrenceViewer?.popoverPresentationController?.sourceRect = cell.recurringCircleButton.frame
        recurrenceViewer?.preferredContentSize = .init(width: 230 * fontScale, height: 330 * fontScale)
        
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
        return calcDaysRange(month: month).count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return calcDaysRange(month: month)[row].extractDate()
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
        var nilItems = [Item]()
        var nonNilItems = [Item]()
        guard let viewModelItems = viewModel?.items else { return }
        switch option {
        case .date:
            nonNilItems = viewModelItems.filter({ $0.date != nil })
            nilItems  = viewModelItems.filter({ !nonNilItems.contains($0) })
            nonNilItems = nonNilItems.sorted(by: {
                direction == .ascending ? $0.date! < $1.date! : $0.date! > $1.date!
            })
            viewModel?.items = nonNilItems + nilItems
        case .name:
            nonNilItems = viewModelItems.filter({ $0.detail != nil })
            nilItems  = viewModelItems.filter({ !nonNilItems.contains($0) })
            nonNilItems = nonNilItems.sorted(by: {
                direction == .ascending ? $0.detail! < $1.detail! : $0.detail! > $1.detail!
            })
            viewModel?.items = nonNilItems + nilItems
        case .amount:
            viewModel?.items = viewModel?.items?.sorted(by: {
                direction == .ascending ? $0.amount < $1.amount : $0.amount > $1.amount
            })
        }
        tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
        sortingVC.dismiss(animated: true) {
            self.dimmingView.removeFromSuperview()
            nilItems.removeAll(); nonNilItems.removeAll()
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
            guard let activeCell = self.activeCell,
                  let indexPath = tableView.indexPath(for: activeCell),
                  let item = viewModel?.items?[indexPath.row]
                  else { return }
            let alertController = UIAlertController(title: nil, message: "This change will be applied to all future transactions", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            alertController.addAction(UIAlertAction(title: "Apply", style: .default, handler: { (action) in
                updateItemRecurrence(for: item, with: itemRecurrence)
            }))
            new ? updateItemRecurrence(for: item, with: itemRecurrence) : self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func updateItemRecurrence(for item: Item, with itemRecurrence: ItemRecurrence) {
        viewModel?.updateItemRecurrence(for: item, with: itemRecurrence, sisterItems: item.futureItems())
        itemsToBeScheduled[item] = itemRecurrence
        viewModel?.reloadData()
        tableView.reloadData()
        dataChanged()
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


extension String {
    func extractDate() -> String {
        let subStrings = self.split(separator: ",")
        let date = String(subStrings[0] + "," + subStrings[1])
        return date
    }
}


