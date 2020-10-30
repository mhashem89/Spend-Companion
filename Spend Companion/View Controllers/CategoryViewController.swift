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



class CategoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, ItemCellDelegate, UIPopoverPresentationControllerDelegate, CategoryTitleViewControllerDelegate, ItemTableHeaderDelegate {
    

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
    
    var recurrenceViewer: RecurringViewController!

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
            if category.name == "Income" {
                headerView.favoriteButton.isHidden = true
                headerView.titleButton.isUserInteractionEnabled = false
            } else {
                headerView.favoriteButton.isHidden = false
                headerView.titleButton.isUserInteractionEnabled = true
            }
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
        tableView.register(ItemCell.self, forCellReuseIdentifier: itemId)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .interactive
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
       
        headerView.plusButton.addTarget(self, action: #selector(self.addItem), for: .touchUpInside)
        headerView.sortButton.addTarget(self, action: #selector(self.sort), for: .touchUpInside)
        headerView.favoriteButton.addTarget(self, action: #selector(favoriteCategory), for: .touchUpInside)
        toggleFavoriteButton()
        
        headerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, heightConstant: 75 * viewsHeightScale)
        tableView.anchor(top: headerView.bottomAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, bottom: view.bottomAnchor)
        headerView.setupUI()
        headerView.titleButton.setTitle(viewModel?.category?.name ?? "Choose name", for: .normal)
        headerView.delegate = self
        
        
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
    
    @objc func selectTitle() {
        let categoryTitleVC = CategoryTitleViewController(categoryName: viewModel?.category?.name)
        categoryTitleVC.delegate = self
        let navVC = UINavigationController(rootViewController: categoryTitleVC)
        present(navVC, animated: true)
    }
    
    func titleLabelTapped() {
        selectTitle()
    }
    
    func enableHeaderButtons() {
        headerView.plusButton.isEnabled = true
        headerView.favoriteButton.isEnabled = true
        if viewModel?.items != nil, viewModel!.items!.count > 1 {
            headerView.sortButton.isEnabled = true
        }
    }
    
    // MARK:- Table View Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.items?.count ?? 0
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: itemId, for: indexPath) as! ItemCell
        cell.setupUI()
        let day = viewModel?.items?[indexPath.row].date
        let item = viewModel?.items?[indexPath.item]
        cell.dayLabel.text = day != nil ? DateFormatters.fullDateFormatterWithLetters.string(from: day!).extractDate() : "Day"
        cell.dayLabel.textColor = cell.dayLabel.text == "Day" ? CustomColors.lightGray : CustomColors.label
        cell.detailTextField.text = item?.detail
        if let amount = item?.amount, amount > 0.0 {
            cell.amountTextField.text = String(format: "%g", amount)
        } else {
            cell.amountTextField.text = nil
        }
        if let period = item?.recurringNum, let unit = item?.recurringUnit {
            let recurringUnit = RecurringUnit(rawValue: Int(truncating: unit))
            cell.addRecurrence(period: Int(truncating: period), unit: recurringUnit!)
        } else {
            cell.recurringCircleButton.removeFromSuperview()
        }
        cell.dayPicker.delegate = self
        cell.dayPicker.dataSource = self
        cell.delegate = self
        if cell.isHighlighted { cell.isHighlighted = false }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let item = viewModel?.items?[indexPath.row] else { return }
            viewModel?.deleteItem(item: item, at: indexPath)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            dataChanged()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50 * viewsHeightScale
    }

    
    
// MARK:- Item Cell Delegate
    
    func donePressedInDayPicker(selected day: Int, for cell: ItemCell) {
        DispatchQueue.main.async { [self] in
            guard let selectedIndexPath = tableView.indexPath(for: cell) else { return }
            let selectedDay = calcDaysRange(month: month)[day]
            viewModel?.items?[selectedIndexPath.row].date = DateFormatters.fullDateFormatterWithLetters.date(from: selectedDay)
            (tableView.cellForRow(at: selectedIndexPath) as! ItemCell).dayLabel.text = calcDaysRange(month: month)[day].extractDate()
            (tableView.cellForRow(at: selectedIndexPath) as! ItemCell).dayLabel.textColor = CustomColors.label
            scrollToActiveRow()
        }
        
    }
    
    func detailTextFieldReturn(text: String, for cell: ItemCell, withMessage: Bool) {
        scrollToActiveRow()
        guard let selectedIndexPath = tableView.indexPath(for: cell) else { return }
        viewModel?.items?[selectedIndexPath.row].detail = text
     
        if withMessage == true {
            let alertController = UIAlertController(title: nil, message: "Apply the change to all future transactions?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Only this transaction", style: .default, handler: nil))
            alertController.addAction(UIAlertAction(title: "All future transactions", style: .default, handler: { [weak self] (action) in
                let item = self?.viewModel?.items?[selectedIndexPath.row]
                if let sisterItems = item?.sisterItems?.allObjects as? [Item], let itemDate = item?.date {
                    let futureItems = sisterItems.filter({ $0.date! > itemDate })
                    for item in futureItems {
                        item.detail = text
                    }
                    self?.viewModel?.reloadData()
                    self?.tableView.reloadData()
                }
            }))
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func amountTextFieldReturn(amount: Double, for cell: ItemCell, withMessage: Bool) {
        scrollToActiveRow()
        guard let selectedIndexPath = tableView.indexPath(for: cell) else { return }
        viewModel?.items?[selectedIndexPath.row].amount = amount
        
        if withMessage == true {
            let alertController = UIAlertController(title: nil, message: "Apply the change to all future transactions?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Only this transaction", style: .default, handler: nil))
            alertController.addAction(UIAlertAction(title: "All future transactions", style: .default, handler: { [weak self] (action) in
                let item = self?.viewModel?.items?[selectedIndexPath.row]
                if let sisterItems = item?.sisterItems?.allObjects as? [Item], let itemDate = item?.date {
                    let futureItems = sisterItems.filter({ $0.date! > itemDate })
                    for item in futureItems {
                        item.amount = amount
                    }
                    self?.viewModel?.reloadData()
                    self?.tableView.reloadData()
                }
            }))
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func dataChanged() {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    func recurrenceButtonPressed(in cell: ItemCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        activeCell = cell
        scrollToActiveRow()
        let item = viewModel!.items![indexPath.row]
        guard let period = item.recurringNum, let unit = item.recurringUnit else { return }
        let periodInt = Int(truncating: period)
        
        self.recurrenceViewer = RecurringViewController()
        recurrenceViewer.modalPresentationStyle = fontScale < 1 ? .overCurrentContext : .popover
        recurrenceViewer.popoverPresentationController?.delegate = fontScale < 1 ? nil : self
        recurrenceViewer.popoverPresentationController?.sourceView = cell
        recurrenceViewer.popoverPresentationController?.sourceRect = cell.recurringCircleButton.frame
        recurrenceViewer.preferredContentSize = .init(width: 230 * fontScale, height: 330 * fontScale)
        
        recurrenceViewer.delegate = self
        recurrenceViewer.periodTextField.text = String(periodInt)
        recurrenceViewer.segmentedControl.selectedSegmentIndex = Int(truncating: unit)
        recurrenceViewer.segmentedControl.isSelected = true
        recurrenceViewer.dayPicker.minimumDate = Calendar.current.date(byAdding: .day, value: 1, to: item.date ?? Date())
        if let itemDate = item.date, itemDate < Date() { recurrenceViewer.reminderSwitch.removeFromSuperview() }
        if let endDate = item.recurringEndDate {
            recurrenceViewer.dayPicker.date = endDate
            recurrenceViewer.endDateLabel.text = "End: \(DateFormatters.fullDateFormatter.string(from: endDate))"
            recurrenceViewer.endDateLabel.textColor = CustomColors.label
        }
        if let reminderTime = item.reminderTime {
            recurrenceViewer.reminderSwitch.isOn = true
            recurrenceViewer.reminderSegmentedControl.isSelected = true
            recurrenceViewer.reminderSegmentedControl.selectedSegmentIndex = Int(truncating: reminderTime) - 1
        }
        dimBackground()
        present(recurrenceViewer, animated: true, completion: nil)
    }
    
    
    // MARK:- Methods
    
    @objc private func save() {
        do {
            try viewModel?.save()
            if itemsToBeScheduled.count > 0 {
                for item in itemsToBeScheduled.keys {
                    InitialViewModel.shared.scheduleReminder(for: item, with: itemsToBeScheduled[item]!)
                    if let sisterItems = item.sisterItems?.allObjects as? [Item], sisterItems.count > 0 {
                        for item in sisterItems {
                            if let itemRecurrence = InitialViewModel.shared.createItemRecurrence(from: item) {
                                InitialViewModel.shared.scheduleReminder(for: item, with: itemRecurrence)
                            }
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
    
    func editingStarted(in textField: UITextField, of cell: ItemCell) {
        self.activeCell = cell
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
        dimmingView.anchor(top: navigationController?.view.topAnchor, leading: navigationController?.view.leadingAnchor, trailing: navigationController?.view.trailingAnchor, bottom: navigationController?.view.bottomAnchor)
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
        let dayStrings = days.compactMap({ DateFormatters.fullDateFormatterWithLetters.string(from: $0) })
        return dayStrings
    }
    
// MARK:- Category Title View Controller Delegate
    
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
    
// MARK:- PickerView Delegate
    
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
    
    
    func dateAscending() {
        var nilItems = [Item]()
        var nonNilItems = [Item]()
        for item in viewModel!.items! {
            item.date == nil ? nilItems.append(item) : nonNilItems.append(item)
        }
        nonNilItems = nonNilItems.sorted( by: { $0.date! < $1.date! } )
        viewModel?.items = nonNilItems + nilItems
        tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
        sortingVC.dismiss(animated: true) {
            self.dimmingView.removeFromSuperview()
            nilItems.removeAll(); nonNilItems.removeAll()
        }
    }
    
    func dateDescending() {
        var nilItems = [Item]()
        var nonNilItems = [Item]()
        for item in viewModel!.items! {
            item.date == nil ? nilItems.append(item) : nonNilItems.append(item)
        }
        nonNilItems = nonNilItems.sorted( by: { $0.date! > $1.date! } )
        viewModel?.items = nonNilItems + nilItems
        tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
        sortingVC.dismiss(animated: true) {
            self.dimmingView.removeFromSuperview()
            nilItems.removeAll(); nonNilItems.removeAll()
        }
    }
    
    func amountAscending() {
        viewModel?.items = viewModel?.items?.sorted( by: { $0.amount < $1.amount } )
        tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
        sortingVC.dismiss(animated: true) {
            self.dimmingView.removeFromSuperview()
        }
    }
    
    func amountDescending() {
        viewModel?.items = viewModel?.items?.sorted( by: { $0.amount > $1.amount } )
        tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
        sortingVC.dismiss(animated: true) {
            self.dimmingView.removeFromSuperview()
        }
    }
    
    func nameAscending() {
        var nilItems = [Item]()
        var nonNilItems = [Item]()
        for item in viewModel!.items! {
            item.detail == nil ? nilItems.append(item) : nonNilItems.append(item)
        }
        nonNilItems = nonNilItems.sorted( by: { $0.detail! < $1.detail! } )
        viewModel?.items = nonNilItems + nilItems
        tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
        sortingVC.dismiss(animated: true) {
            self.dimmingView.removeFromSuperview()
            nilItems.removeAll(); nonNilItems.removeAll()
        }
    }
    
    func nameDescending() {
        var nilItems = [Item]()
        var nonNilItems = [Item]()
        for item in viewModel!.items! {
            item.detail == nil ? nilItems.append(item) : nonNilItems.append(item)
        }
        nonNilItems = nonNilItems.sorted( by: { $0.detail! > $1.detail! } )
        viewModel?.items = nonNilItems + nilItems
        tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
        sortingVC.dismiss(animated: true) {
            self.dimmingView.removeFromSuperview()
            nilItems.removeAll(); nonNilItems.removeAll()
        }
    }
    
    
}

// MARK:- Recurring View Controller Deleagte

extension CategoryViewController: RecurringViewControllerDelegate {
    
    func recurringViewCancel() {
        recurrenceViewer.dismiss(animated: true, completion: nil)
        dimmingView.removeFromSuperview()
    }
    
    func recurringViewDone(with itemRecurrence: ItemRecurrence) {
        dimmingView.removeFromSuperview()
        recurrenceViewer.dismiss(animated: true) { [unowned self] in
            guard let activeCell = self.activeCell,
                  let indexPath = tableView.indexPath(for: activeCell),
                  let item = viewModel?.items?[indexPath.row]
                  else { return }
            let alertController = UIAlertController(title: nil, message: "This change will be applied to all future transactions", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            alertController.addAction(UIAlertAction(title: "Apply", style: .default, handler: { (action) in
                self.viewModel?.updateItemRecurrence(for: item, with: itemRecurrence, sisterItems: item.sisterItems?.allObjects as? [Item])
                itemsToBeScheduled[item] = itemRecurrence
                viewModel?.reloadData()
                tableView.reloadData()
                dataChanged()
            }))
            
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    
    
    
    
}


extension String {
    func extractDate() -> String {
        let subStrings = self.split(separator: ",")
        let date = String(subStrings[0] + "," + subStrings[1])
        return date
    }
}


