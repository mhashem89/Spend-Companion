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
    
    var safeAreaTop: CGFloat {
        let top = UIApplication.shared.windows.first?.safeAreaInsets.top
        return top ?? 44
    }
    
    static let shared = InitialViewController()
    let viewModel = InitialViewModel()
    
    lazy var scaleFactor: Double = calcScaleFactor()
    var selectedMonth = Date()
    var selectedYear = Date()
    var selectedMonthScaledData: (CGFloat, CGFloat) = (0,0)
    var selectedYearScaledData: (CGFloat, CGFloat) = (0,0)
    var monthChanged: Bool = false
    var recentItemsDidChange: Bool = false
    
    let scrollView = UIScrollView()
    let summaryView = SummaryView()
    var quickAddView = QuickAddView()
    let summaryLabels = ["Total Income", "Total Spending"]
    let savedLabel = UILabel.savedLabel()
    var dimmingView = UIView().withBackgroundColor(color: UIColor.black.withAlphaComponent(0.5))
    var recentItemsTable: UITableView?
    var emptyItemsLabel = UILabel.emptyItemsLabel()
    
// MARK:- Life cycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        quickAddView.delegate = self
        viewModel.delegate = self
        UserDefaults.standard.setValue(false, forKey: SettingNames.contextIsActive)
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = CustomColors.systemBackground
        view.addSubview(scrollView)
        scrollView.frame = view.bounds
        scrollView.addSubviews([summaryView, quickAddView, savedLabel, emptyItemsLabel])
        summaryView.frame = .init(x: 0, y: safeAreaTop, width: view.frame.width, height: view.frame.height * 0.3)
        quickAddView.frame = .init(x: 0, y: summaryView.frame.height + 20, width: view.frame.width, height: 200 * windowHeightScale)
        savedLabel.frame = .init(x: view.frame.width * 0.25, y: -80, width: view.frame.width * 0.5, height: 40)
        emptyItemsLabel.anchor(top: quickAddView.bottomAnchor, topConstant: view.frame.height * 0.1, centerX: view.centerXAnchor)
        setupSummaryView()
        quickAddView.setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewModel.recentItems.count == 0 {
            emptyItemsLabel.isHidden = false
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
        savedLabel.isHidden = false
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.savedLabel.frame.origin.y += 90
        } completion: { [weak self] (_) in
            self?.quickAddView.clearView()
            self?.quickAddView.resignFirstResponders()
            UserDefaults.standard.setValue(false, forKey: SettingNames.contextIsActive)
            UIView.animate(withDuration: 0.3, delay: 2, options: .curveLinear) { [weak self] in
                self?.savedLabel.frame.origin.y -= 90
            } completion: { [weak self] (_) in
                self?.savedLabel.isHidden = true
            }
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
            reloadRecentItems(withFetch: false)
        }
    }
    
    @objc func reloadRecentItems(withFetch fetch: Bool) {
        if fetch { viewModel.fetchRecentItems() }
        if viewModel.recentItems.count > 0 {
            if recentItemsTable == nil { setupRecentItemTable() }
            recentItemsTable?.reloadData()
            emptyItemsLabel.isHidden = true
        }
        recentItemsTable?.reloadData()
        recentItemsDidChange = false
    }
    
    func updateData() {
        reloadRecentItems(withFetch: true)
        viewModel.calcYearTotals(year: DateFormatters.yearFormatter.string(from: selectedYear))
        viewModel.fetchMonthTotals()
        scaleFactor = calcScaleFactor()
        summaryView.barChart.reloadData()
    }
    
    func setupSummaryView() {
        summaryView.titleLabel.text = "Summary of \(DateFormatters.monthYearFormatter.string(from: Date()))"
        summaryView.setupUI()
        summaryView.setupBarChart(delegate: self, dataSource: self, cellId: barChartCellId)
        summaryView.segmentedControl.addTarget(self, action: #selector(handleSummaryViewSegmentedControl(segmentedControl:)), for: .valueChanged)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeSummaryView(for:)))
        swipeRight.direction = .right
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeSummaryView(for:)))
        swipeLeft.direction = .left
        [swipeLeft, swipeRight].forEach({ $0.numberOfTouchesRequired = 1; summaryView.addGestureRecognizer($0) })
        summaryView.configureSummaryLabel(with: viewModel)
    }
    
    @objc func handleSummaryViewSegmentedControl(segmentedControl: UISegmentedControl) {
        let currentMonth = DateFormatters.monthYearFormatter.string(from: Date())
        let currentYear = DateFormatters.yearFormatter.string(from: Date())
        viewModel.calcYearTotals(year: currentYear)
        if segmentedControl.selectedSegmentIndex == 0 {
            summaryView.titleLabel.text = "Summary of \(currentMonth)"
            viewModel.fetchMonthTotals()
        } else {
            summaryView.titleLabel.text = "Summary of \(currentYear)"
        }
        summaryView.configureSummaryLabel(with: viewModel)
        self.scaleFactor = calcScaleFactor()
        summaryView.barChart.reloadData()
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
        recentItemsTable?.setup(delegate: self, dataSource: viewModel, cellClass: RecentItemCell.self, cellId: RecentItemCell.reuseIdentifier)
        scrollView.addSubview(recentItemsTable!)
        recentItemsTable?.anchor(top: quickAddView.bottomAnchor, topConstant: 18, bottom: view.safeAreaLayoutGuide.bottomAnchor, widthConstant: view.frame.width)
    }
    
    func calcScaleFactor() -> Double {
        var higherValue: Double = 1
        if summaryView.segmentedControl.selectedSegmentIndex == 0 {
            higherValue = viewModel.maxMonthSpendingInYear
        } else {
            higherValue = max(viewModel.currentYearTotalIncome, viewModel.currentYearTotalSpending)
        }
        let valueLabelSize = UILabel.calcSize(for: String(format: "%g", higherValue), withFont: 13 * fontScale)
        let chartLabelMaxWidth = UILabel.calcSize(for: summaryLabels.longestString()!, withFont: 16 * fontScale).width
        return Double(view.frame.width - chartLabelMaxWidth - valueLabelSize.width - (70 * fontScale)) / higherValue
    }
    
    func currencyChanged() {
        quickAddView.updateCurrencySymbol()
        recentItemsDidChange = true
        summaryView.configureSummaryLabel(with: viewModel)
    }
}

// MARK:- Bar Chart Delegate


extension InitialViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: barChartCellId, for: indexPath) as! ChartCell
        cell.setupUI()
        cell.cellLabel.text = summaryLabels[indexPath.item]
        let maxWidth = UILabel.calcSize(for: summaryLabels.longestString() ?? "", withFont: fontScale < 1 ? 14 : 16 * fontScale).width
        cell.cellLabel.frame = .init(x: 0, y: 0, width: maxWidth + 8, height: cell.frame.height)
        cell.cellLabel.textColor = UserDefaults.standard.colorForKey(key: SettingNames.labelColor) ?? .systemBlue
        var value: Double = 0
        var priorValue: CGFloat = 0
        
        if summaryView.segmentedControl.selectedSegmentIndex == 0 {
            value = indexPath.row == 0 ? viewModel.currentMonthTotalIncome : viewModel.currentMonthTotalSpending
            priorValue = indexPath.row == 0 ? selectedMonthScaledData.0 : selectedMonthScaledData.1
        } else {
            value = indexPath.row == 0 ? viewModel.currentYearTotalIncome : viewModel.currentYearTotalSpending
            priorValue = indexPath.row == 0 ? selectedYearScaledData.0 : selectedYearScaledData.1
        }
        
        cell.formatValueLabel(with: value)
        cell.barView.frame = .init(x: maxWidth + 15, y: (cell.frame.height - 25) / 2, width: priorValue, height: 25)
        cell.valueLabel.frame = .init(origin: CGPoint(x: maxWidth + 20 + priorValue, y: cell.frame.height * 0.35), size: cell.valueLabel.intrinsicContentSize)
        let scaledValue = self.scaleFactor < 1 ? CGFloat(value * self.scaleFactor) : CGFloat(value)
        let distanceToMove = scaledValue - priorValue
        UIView.animate(withDuration: 0.5) {
            cell.barView.frame.size.width += distanceToMove
            cell.valueLabel.frame.origin.x += distanceToMove
        } completion: { [self] (_) in
            switch (summaryView.segmentedControl.selectedSegmentIndex, indexPath.row) {
            case (0, 0): selectedMonthScaledData.0 = scaledValue
            case (0, 1): selectedMonthScaledData.1 = scaledValue
            case (1, 0): selectedYearScaledData.0 = scaledValue
            case (1, 1): selectedYearScaledData.1 = scaledValue
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
        recurringVC.setupPopoverController(popoverDelegate: self,
                                           sourceView: quickAddView.recurringButton,
                                           sourceRect: quickAddView.recurringButton.bounds,
                                           preferredWidth: fontScale < 1 ? 220 : 220 * fontScale,
                                           preferredHeight: fontScale < 1 ? 330 : 330 * fontScale,
                                           style: fontScale < 0.9 ? .overCurrentContext : .popover)
        recurringVC.popoverPresentationController?.permittedArrowDirections = [.down, .right]
        recurringVC.dayPicker.minimumDate = Calendar.current.date(byAdding: .day, value: 1, to: quickAddView.dayPickerDate ?? Date())
        present(recurringVC, animated: true)
        dimBackground()
    }
    
    func saveItem(itemStruct: ItemStruct) {
        viewModel.saveItem(itemStruct: itemStruct, completion: { [weak self] (success) in
            if success { self?.showSavedAlert() }
        })
        
        if summaryView.segmentedControl.selectedSegmentIndex == 1, itemStruct.date.yearMatches(selectedYear) {
            self.viewModel.calcYearTotals(year: DateFormatters.yearFormatter.string(from: selectedYear))
            self.scaleFactor = self.calcScaleFactor()
            self.summaryView.barChart.reloadData()
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

extension InitialViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: "   Recent Items", attributes: [.font: UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 18 * fontScale)])
        label.backgroundColor = CustomColors.lightGray
        return label
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30 * windowHeightScale
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
                categoryVC.tableView.scrollToRow(at: selectedIndexPath, at: .none, animated: false)
                let selectedCell = categoryVC.tableView.cellForRow(at: selectedIndexPath) as? ItemCell
                selectedCell?.isHighlighted = true
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return windowHeightScale < 1 ? 44 : 44 * fontScale
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
            reloadRecentItems(withFetch: false)
        } else {
            recentItemsDidChange = true
        }
    }
}

// MARK:- Recurring View Controller Delegate

extension InitialViewController: RecurringViewControllerDelegate {
    
    func recurringViewCancel(wasNew: Bool) {
        dismiss(animated: true, completion: nil)
        dimmingView.removeFromSuperview()
    }
    
    func recurringViewDone(with itemRecurrence: ItemRecurrence, new: Bool, dataChanged: [ItemRecurrenceCase]) {
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
