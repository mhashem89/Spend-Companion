//
//  InitialViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/7/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

class InitialViewController: UIViewController {
    
    
// MARK:- Properties
    
    let barChartCellId = "barChartCellId"
    let tableCellId = "tableCellId"
    
    var safeAreaTop: CGFloat {
        let top = UIApplication.shared.windows.first?.safeAreaInsets.top
        return top ?? 44
    }
    
    static let shared = InitialViewController()
    
    var scaleFactor: Double = 1
    
    var selectedMonth = Date()
    var selectedYear = Date()
    var selectedMonthScaledData: (CGFloat, CGFloat) = (0,0)
    var selectedYearScaledData: (CGFloat, CGFloat) = (0,0)
    var monthChanged: Bool = false
    var recentItemsDidChange: Bool = false
    
    let scrollView = UIScrollView()
    let summaryView = SummaryView()
    var quickAddView = QuickAddView()
    let viewModel = InitialViewModel()
    let summaryLabels = ["Total Income", "Total Spending"]
    
    var dimmingView = UIView().withBackgroundColor(color: UIColor.black.withAlphaComponent(0.5))
   
    var recentItemsRefreshControl = UIRefreshControl()
    
    var recentItemsTable: UITableView?
    
    var emptyItemsLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Items from last 7 days will appear here"
        lbl.textColor = CustomColors.darkGray
        lbl.font = UIFont.italicSystemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale)
        return lbl
    }()
    
    
// MARK:- Life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        quickAddView.delegate = self
        viewModel.delegate = self
        
        if #available(iOS 13, *) {
            tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house.fill"), tag: 0)
        } else {
            let button = UITabBarItem(title: "Home", image: nil, selectedImage: nil)
            button.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], for: .normal)
            button.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -8)
            navigationController?.tabBarItem = button
        }
        
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = CustomColors.systemBackground
        view.addSubview(scrollView)
        scrollView.frame = view.bounds
        scrollView.addSubviews([summaryView, quickAddView])
        summaryView.frame = .init(x: 0, y: safeAreaTop, width: view.frame.width, height: view.frame.height * 0.3)
        quickAddView.frame = .init(x: 0, y: summaryView.frame.height + 20, width: view.frame.width, height: 200 * viewsHeightScale)
        setupSummaryView()
        quickAddView.setupUI()
        viewModel.calcYearTotals(year: DateFormatters.yearFormatter.string(from: selectedYear))
        self.scaleFactor = calcScaleFactor()
        viewModel.fetchRecentItems()
        recentItemsRefreshControl.addTarget(self, action: #selector(refreshRecentItems), for: .valueChanged)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewModel.recentItems.count == 0 {
            scrollView.addSubview(emptyItemsLabel)
            emptyItemsLabel.anchor(top: quickAddView.bottomAnchor, topConstant: view.frame.height * 0.1, centerX: view.centerXAnchor)
        } else if recentItemsTable == nil {
            setupRecentItemTable()
        }
        reloadDataAfterChange()
        quickAddView.recurringButton.tintColor = UserDefaults.standard.colorForKey(key: SettingNames.buttonColor) ?? CustomColors.blue
        quickAddView.recurringCircleButton.tintColor = UserDefaults.standard.colorForKey(key: SettingNames.buttonColor) ?? CustomColors.blue
    }
    
    
// MARK:- Methods
    
    private func dimBackground() {
        navigationController?.view.addSubview(dimmingView)
        dimmingView.fillSuperView()
    }
    
    func showSavedAlert() {
        let alertController = UIAlertController(title: "Saved successfully!", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak self] (_) in
            self?.quickAddView.clearView()
        }))
        present(alertController, animated: true) { [weak self] in
            self?.quickAddView.resignFirstResponders()
        }
    }
    
    func reloadDataAfterChange() {
        if monthChanged && summaryView.segmentedControl.selectedSegmentIndex == 0 {
            viewModel.fetchMonthTotals(forDate: selectedMonth)
            viewModel.calcYearTotals(year: DateFormatters.yearFormatter.string(from: selectedYear))
            scaleFactor = calcScaleFactor()
            summaryView.barChart.reloadData()
            monthChanged = false
        }
        if recentItemsDidChange {
            reloadRecentItems()
        }
    }
    
    private func reloadRecentItems() {
        viewModel.fetchRecentItems()
        if recentItemsTable == nil { setupRecentItemTable() }
        recentItemsTable?.reloadData()
        if viewModel.recentItems.count > 0 {
            if emptyItemsLabel.superview != nil { emptyItemsLabel.removeFromSuperview() }
        }
        recentItemsDidChange = false
    }
    
    func updateData() {
        viewModel.fetchRecentItems()
        recentItemsTable?.reloadData()
        viewModel.calcYearTotals(year: DateFormatters.yearFormatter.string(from: selectedYear))
        viewModel.fetchMonthTotals()
        scaleFactor = calcScaleFactor()
        summaryView.barChart.reloadData()
    }
    
    func setupSummaryView() {
        summaryView.titleLabel.text = "Summary of \(DateFormatters.monthYearFormatter.string(from: Date()))"
        summaryView.setupUI()
        summaryView.barChart.delegate = self
        summaryView.barChart.dataSource = self
        summaryView.barChart.register(ChartCell.self, forCellWithReuseIdentifier: barChartCellId)
        summaryView.segmentedControl.addTarget(self, action: #selector(handleSummaryViewSegmentedControl(segmentedControl:)), for: .valueChanged)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeSummaryView(for:)))
        swipeRight.direction = .right
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeSummaryView(for:)))
        swipeLeft.direction = .left
        [swipeLeft, swipeRight].forEach({ $0.numberOfTouchesRequired = 1; summaryView.addGestureRecognizer($0) })
        setupSummaryLabel(for: .month)
    }
    
    @objc func handleSummaryViewSegmentedControl(segmentedControl: UISegmentedControl) {
        let currentMonth = DateFormatters.monthYearFormatter.string(from: Date())
        let currentYear = DateFormatters.yearFormatter.string(from: Date())
        viewModel.calcYearTotals(year: currentYear)
        if segmentedControl.selectedSegmentIndex == 0 {
            summaryView.titleLabel.text = "Summary of \(currentMonth)"
            viewModel.fetchMonthTotals()
            setupSummaryLabel(for: .month)
        } else {
            summaryView.titleLabel.text = "Summary of \(currentYear)"
            setupSummaryLabel(for: .year)
        }
        self.scaleFactor = calcScaleFactor()
        summaryView.barChart.reloadData()
    }
    
    @objc func refreshRecentItems() {
        viewModel.fetchRecentItems()
        recentItemsTable?.reloadData()
        recentItemsRefreshControl.endRefreshing()
    }
    
    func setupSummaryLabel(for component: Calendar.Component) {
        summaryView.setupSummaryLabel(with: viewModel, for: component)
    }
    
    @objc func swipeSummaryView(for gesture: UISwipeGestureRecognizer) {
        if summaryView.segmentedControl.selectedSegmentIndex == 0 {
            selectedMonth = Calendar.current.date(byAdding: .month, value: gesture.direction == .left ? 1 : -1, to: selectedMonth)!
            summaryView.titleLabel.text = "Summary of \(DateFormatters.monthYearFormatter.string(from: selectedMonth))"
            viewModel.fetchMonthTotals(forDate: selectedMonth)
            viewModel.calcYearTotals(year: DateFormatters.yearFormatter.string(from: selectedMonth))
        } else {
            selectedYear = Calendar.current.date(byAdding: .year, value: gesture.direction == .left ? 1 : -1, to: selectedYear)!
            summaryView.titleLabel.text = "Summary of \(DateFormatters.yearFormatter.string(from: selectedYear))"
            viewModel.calcYearTotals(year: DateFormatters.yearFormatter.string(from: selectedYear))
        }
        
        self.scaleFactor = calcScaleFactor()
        summaryView.barChart.reloadData()
    }
    
    
    func setupRecentItemTable() {
        emptyItemsLabel.removeFromSuperview()
        recentItemsTable = UITableView()
        recentItemsTable?.delegate = self
        recentItemsTable?.dataSource = self
        recentItemsTable?.tableFooterView = UIView()
        recentItemsTable?.register(RecentItemCell.self, forCellReuseIdentifier: tableCellId)
        recentItemsTable?.refreshControl = recentItemsRefreshControl
        scrollView.addSubview(recentItemsTable!)
        recentItemsTable?.anchor(top: quickAddView.bottomAnchor, topConstant: 18, bottom: view.safeAreaLayoutGuide.bottomAnchor, widthConstant: view.frame.width)
    }
    
    
    func calcScaleFactor() -> Double {
        var higherValue: Double!
        if summaryView.segmentedControl.selectedSegmentIndex == 0 {
            higherValue = viewModel.maxMonthSpendingInYear
        } else {
            higherValue = max(viewModel.currentYearTotalIncome, viewModel.currentYearTotalSpending)
        }
        let valueLabelSize = UILabel.calcSize(for: String(format: "%g", higherValue), withFont: 13 * fontScale)
        let chartLabelMaxWidth = UILabel.calcSize(for: summaryLabels.longestString()!, withFont: 16 * fontScale).width
        return Double(view.frame.width - chartLabelMaxWidth - valueLabelSize.width - (70 * fontScale)) / higherValue
    }
    
}

// MARK:- Bar Chart Delegate


extension InitialViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: barChartCellId, for: indexPath) as! ChartCell
        cell.cellLabel.text = summaryLabels[indexPath.item]
        let maxWidth = UILabel.calcSize(for: summaryLabels.longestString() ?? "", withFont: fontScale < 1 ? 14 : 16 * fontScale).width
        cell.cellLabel.frame = .init(x: 0, y: 0, width: maxWidth + 8, height: cell.frame.height)
        cell.cellLabel.textColor = UserDefaults.standard.colorForKey(key: SettingNames.labelColor) ?? .systemBlue
        var value: Double = 0
        var priorValue: CGFloat = 0
        switch (summaryView.segmentedControl.selectedSegmentIndex, indexPath.row) {
        case (0, 0):
            value = viewModel.currentMonthTotalIncome
            priorValue = selectedMonthScaledData.0
        case (0, 1):
            value = viewModel.currentMonthTotalSpending
            priorValue = selectedMonthScaledData.1
        case (1, 0):
            value = viewModel.currentYearTotalIncome
            priorValue = selectedYearScaledData.0
        case (1, 1):
            value = viewModel.currentYearTotalSpending
            priorValue = selectedYearScaledData.1
        default:
            break
        }
        cell.formatValueLabel(with: value)
        cell.barView.frame = .init(x: maxWidth + 15, y: (cell.frame.height - 25) / 2, width: priorValue, height: 25)
        cell.barView.backgroundColor = UserDefaults.standard.colorForKey(key: SettingNames.barColor) ?? .systemRed
        cell.valueLabel.frame = .init(origin: CGPoint(x: maxWidth + 20 + priorValue, y: cell.frame.height * 0.35), size: cell.valueLabel.intrinsicContentSize)
        let scaledValue = self.scaleFactor < 1 ? CGFloat(value * self.scaleFactor) : CGFloat(value)
        let distanceToMove = scaledValue - priorValue
        UIView.animate(withDuration: 0.5) {
            cell.barView.frame.size.width += distanceToMove
            cell.valueLabel.frame.origin.x += distanceToMove
        } completion: { [self] (_) in
            switch (summaryView.segmentedControl.selectedSegmentIndex, indexPath.row) {
            case (0, 0):
                selectedMonthScaledData.0 = scaledValue
            case (0, 1):
                selectedMonthScaledData.1 = scaledValue
            case (1, 0):
                selectedYearScaledData.0 = scaledValue
            case (1, 1):
                selectedYearScaledData.1 = scaledValue
            default:
                break
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: collectionView.frame.width, height: summaryView.frame.height * 0.19)
    }
    
}


// MARK:- Quick Add View Delegate

extension InitialViewController: QuickAddViewDelegate {
    
    func openRecurringWindow() {
        
        let recurringVC = RecurringViewController(itemRecurrence: quickAddView.itemRecurrence)
        recurringVC.delegate = self
        recurringVC.setupController(popoverDelegate: self, sourceView: quickAddView.recurringButton, sourceRect: quickAddView.recurringButton.bounds, preferredWidth: fontScale < 1 ? 220 : 220 * fontScale, preferredHeight: fontScale < 1 ? 330 : 330 * fontScale)
        recurringVC.popoverPresentationController?.permittedArrowDirections = [.down, .right]
       
        recurringVC.dayPicker.minimumDate = Calendar.current.date(byAdding: .day, value: 1, to: quickAddView.dayPickerDate ?? Date())
        present(recurringVC, animated: true)
        dimBackground()
    }
    
    func saveItem(itemStruct: ItemStruct) {
        viewModel.saveItem(itemStruct: itemStruct)
        
        showSavedAlert()
       
        if self.summaryView.segmentedControl.selectedSegmentIndex == 1, let dayLabelText = quickAddView.dayLabel.text {
            let itemDate = dayLabelText == "Today" ? Date() : DateFormatters.fullDateFormatter.date(from: dayLabelText)
            let itemYear = DateFormatters.yearFormatter.string(from: itemDate!)
            if itemYear == DateFormatters.yearFormatter.string(from: selectedYear) {
                self.viewModel.calcYearTotals(year: DateFormatters.yearFormatter.string(from: selectedYear))
                self.scaleFactor = self.calcScaleFactor()
                self.summaryView.barChart.reloadData()
            }
        }
    }
    
    func showCategoryTitleVC() {
        let categoryTitleVC = CategoryTitleViewController(categoryName: quickAddView.categoryLabel.text)
        categoryTitleVC.fixedCategories.removeAll()
        categoryTitleVC.delegate = self
        let navVC = UINavigationController(rootViewController: categoryTitleVC)
        present(navVC, animated: true)
    }
    
    func showItemNameVC() {
        let itemNameVC = ItemNameViewController(itemName: quickAddView.detailLabel.text)
        itemNameVC.delegate = self
        itemNameVC.itemNames = CoreDataManager.shared.getCommonItemNames()
        let navVC = UINavigationController(rootViewController: itemNameVC)
        present(navVC, animated: true)
    }
    
}


// MARK:- Category Title View Controller Delegate

extension InitialViewController: CategoryTitleViewControllerDelegate {
    
    func saveCategoryTitle(title: String) {
        guard title != "Category" else { return }
        quickAddView.categoryLabel.text = title
        quickAddView.categoryLabel.textColor = CustomColors.label
        quickAddView.showSaveButton()
    }
    
}

// MARK:- Item Name View Controller Delegate

extension InitialViewController: ItemNameViewControllerDelegate {
    
    func saveItemName(name: String) {
        quickAddView.detailLabel.text = name
        quickAddView.detailLabel.textColor = CustomColors.label
        quickAddView.showSaveButton()
    }
    
}

// MARK:- Recent Items Table Delegate


extension InitialViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: "   Recent Items", attributes: [.font: UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 18 * fontScale)])
        label.backgroundColor = CustomColors.lightGray
        return label
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30 * viewsHeightScale
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.recentItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = recentItemsTable?.dequeueReusableCell(withIdentifier: tableCellId, for: indexPath) as! RecentItemCell
        let item = viewModel.recentItems[indexPath.row]
        cell.configureCell(for: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = self.viewModel.recentItems[indexPath.row]
        guard let itemMonth = item.month else { return }
        let categoryVC = CategoryViewController(month: itemMonth, category: item.category)
        let navVC = UINavigationController(rootViewController: categoryVC)
        navVC.modalPresentationStyle = .fullScreen
        if let itemIndex = categoryVC.viewModel?.items?.firstIndex(of: item) {
            present(navVC, animated: true) {
                let selectedIndexPath = IndexPath(item: itemIndex, section: 0)
                categoryVC.activeCell = categoryVC.tableView.cellForRow(at: selectedIndexPath) as? ItemCell
            }
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.performBatchUpdates({
                tableView.deleteRows(at: [indexPath], with: .automatic)
                viewModel.deleteRecentItem(at: indexPath)
            }, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewsHeightScale < 1 ? 44 : 44 * fontScale
    }
    
}

// MARK:- View Model Delegate

extension InitialViewController: InitialViewModelDelegate {
    
    func monthTotalChanged(forMonth: Month) {
        if forMonth.date == DateFormatters.abbreviatedMonthYearFormatter.string(from: selectedMonth) && summaryView.segmentedControl.selectedSegmentIndex == 0 {
            if view.window != nil && presentedViewController == nil {
                viewModel.fetchMonthTotals(forDate: selectedMonth)
                viewModel.calcYearTotals(year: DateFormatters.yearFormatter.string(from: selectedMonth))
                scaleFactor = calcScaleFactor()
                summaryView.barChart.reloadData()
            } else {
                monthChanged = true
            }
        }
    }
    
    
    func recentItemsChanged() {
        if view.window != nil && presentedViewController == nil {
            reloadRecentItems()
        } else {
            recentItemsDidChange = true
        }
        
    }
    
}

// MARK:- Recurring View Controller Delegate

extension InitialViewController: RecurringViewControllerDelegate {
    
    func recurringViewCancel(viewEmpty: Bool) {
        dismiss(animated: true, completion: nil)
        dimmingView.removeFromSuperview()
    }
    
    func recurringViewDone(with itemRecurrence: ItemRecurrence, new: Bool) {
        quickAddView.itemRecurrence = itemRecurrence
        dimmingView.removeFromSuperview()
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK:- UIPopover presentation controller delegate

extension InitialViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return false
    }
    
    
}
