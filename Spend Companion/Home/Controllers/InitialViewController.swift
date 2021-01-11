//
//  InitialViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/7/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit
import StoreKit

class InitialViewController: UIViewController {
    
// MARK:- Properties
    
    private var safeAreaTop: CGFloat {
        return UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44
    }
    
    static let shared = InitialViewController()
    private let viewModel = InitialViewModel()
    
    private lazy var scaleFactor: Double = calcScaleFactor()  // Used to scale the length of the bar chart
    private var selectedMonth = Date()  // The selected month in the summary view
    private var selectedYear = Date()   // The selected year in the summary view
    
    // Used to keep track of the bar chart length for the animation
    private var selectedMonthScaledData: (CGFloat, CGFloat) = (0,0)
    private var selectedYearScaledData: (CGFloat, CGFloat) = (0,0)
    
    private var monthChanged: Bool = false  // Keep track if one of the items of the selected month has changed
    private var recentItemsDidChange: Bool = false // Keep track if one of the recent items has changed
    
// MARK:- Subviews
    
    let scrollView = UIScrollView()
    let summaryView = SummaryView()
    var quickAddView = QuickAddView()
    let summaryLabels = ["Total Income", "Total Spending"]
    let savedLabel = UILabel.savedLabel() // Shows up when a new transaction is successfully saved
    var dimmingView = UIView().withBackgroundColor(color: UIColor.black.withAlphaComponent(0.5))
    var recentItemsTable: UITableView?
    var emptyItemsLabel = UILabel.emptyItemsLabel() // Shows up initially when there are no recent items to display
    
// MARK:- Life cycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        quickAddView.delegate = self
        viewModel.delegate = self
        UserDefaults.standard.setValue(false, forKey: SettingNames.contextIsActive)
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = CustomColors.systemBackground
        
        // Add the main scroll view and the subviews
        view.addSubview(scrollView)
        scrollView.frame = view.bounds
        scrollView.addSubviews([summaryView, quickAddView, savedLabel, emptyItemsLabel])
        
        // Setup the subviews' frames
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
        quickAddView.buttonColor = UserDefaults.standard.colorForKey(key: SettingNames.buttonColor) ?? CustomColors.blue
        let iCloudKeyStore = (UIApplication.shared.delegate as! AppDelegate).iCloudKeyStore
        if !iCloudKeyStore.bool(forKey: SettingNames.openedBefore) {
            showWelcomeVC()
            iCloudKeyStore.set(true, forKey: SettingNames.openedBefore)
        }
    }
    
// MARK:- Methods
    
    private func setupSummaryView() {
        summaryView.setupUI()
        summaryView.configureSummaryLabel(with: viewModel)
        summaryView.setupBarChart(delegate: self, dataSource: self, cellId: ChartCell.reuseIdentifier)
        summaryView.segmentedControl.addTarget(self, action: #selector(handleSummaryViewSegmentedControl(segmentedControl:)), for: .valueChanged)
        
        // Add left and right swipe gestures to the summary view
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeSummaryView(for:)))
        swipeRight.direction = .right
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeSummaryView(for:)))
        swipeLeft.direction = .left
        [swipeLeft, swipeRight].forEach({ $0.numberOfTouchesRequired = 1; summaryView.addGestureRecognizer($0) })
    }
    
    private func setupRecentItemTable() {
        emptyItemsLabel.removeFromSuperview()
        recentItemsTable = UITableView()
        recentItemsTable?.setup(delegate: self, dataSource: viewModel, cellClass: RecentItemCell.self, cellId: RecentItemCell.reuseIdentifier)
        scrollView.addSubview(recentItemsTable!)
        recentItemsTable?.anchor(top: quickAddView.bottomAnchor, topConstant: 18, bottom: view.safeAreaLayoutGuide.bottomAnchor, widthConstant: view.frame.width)
    }
    
    private func dimBackground() {
        navigationController?.view.addSubview(dimmingView)
        dimmingView.fillSuperView()
    }
    /// Animates the alert that shows up when a new transaction is saved
    private func showSavedAlert() {
        savedLabel.isHidden = false
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.savedLabel.frame.origin.y += 90
        } completion: { [weak self] (_) in
            self?.quickAddView.clearView()
            UserDefaults.standard.setValue(false, forKey: SettingNames.contextIsActive)
            UIView.animate(withDuration: 0.3, delay: 2, options: .curveLinear) { [weak self] in
                self?.savedLabel.frame.origin.y -= 90
            } completion: { [weak self] (_) in
                self?.savedLabel.isHidden = true
            }
        }
    }
    /// Reloads the bar chart and recent items table if the data had changed while the view controller was not visible
    func reloadDataAfterChange() {
        if monthChanged && summaryView.segmentedControl.selectedSegmentIndex == 0 {
            reloadBarChartData()
            monthChanged = false
        }
        if recentItemsDidChange {
            reloadRecentItems(withFetch: false)
        }
    }
    /// Asks the recent items table to reload data. If "withFetch" is true then performs a fetch from the context
    @objc func reloadRecentItems(withFetch fetch: Bool) {
        if fetch { viewModel.fetchRecentItems() }
        if viewModel.recentItems.count > 0 {
            if recentItemsTable == nil { setupRecentItemTable() }
            emptyItemsLabel.isHidden = true
        }
        recentItemsTable?.reloadData()
        recentItemsDidChange = false
        if viewModel.recentItems.count > 14, !UserDefaults.standard.bool(forKey: SettingNames.feedbackRequested) {
            SKStoreReviewController.requestReview()
            UserDefaults.standard.setValue(true, forKey: SettingNames.feedbackRequested)
        }
    }
    /// Fetches total spending and total income for the selected month and reloads the bar chart
    private func reloadBarChartData() {
        viewModel.fetchMonthTotals(forDate: selectedMonth)
        viewModel.calcYearTotals(year: DateFormatters.yearFormatter.string(from: selectedYear))
        scaleFactor = calcScaleFactor()
        summaryView.barChart.reloadData()
    }
    
    /// Updates both the bar chart data and the recent items table, performs a new fetch from the context
    func updateData() {
        reloadRecentItems(withFetch: true)
        reloadBarChartData()
    }

    @objc private func handleSummaryViewSegmentedControl(segmentedControl: UISegmentedControl) {
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
    
    @objc private func swipeSummaryView(for gesture: UISwipeGestureRecognizer) {
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
    /// Returns the scale ratio used to calculate the length of the bar chart
    private func calcScaleFactor() -> Double {
        let higherValue: Double =  summaryView.segmentedControl.selectedSegmentIndex == 0 ? viewModel.maxMonthAmountInYear : max(viewModel.currentYearTotalIncome, viewModel.currentYearTotalSpending)
        let valueLabelSize = UILabel.calcSize(for: String(format: "%g", higherValue), withFont: 13 * fontScale)
        let chartLabelMaxWidth = UILabel.calcSize(for: summaryLabels.longestString()!, withFont: 16 * fontScale).width
        return Double(view.frame.width - chartLabelMaxWidth - valueLabelSize.width - (70 * fontScale)) / higherValue
    }
    /// Gets called when the user changes currency symbol in settings to update the symbol in all the subviews
    func currencyChanged() {
        summaryView.configureSummaryLabel(with: viewModel)
        quickAddView.updateCurrencySymbol()
        recentItemsDidChange = true
    }
    
    func showWelcomeVC() {
        let welcomeVC = WelcomeViewController()
        welcomeVC.setupPopoverController(popoverDelegate: self,
                                         sourceView: quickAddView,
                                         sourceRect: quickAddView.quickAddLabel.frame,
                                         preferredWidth: view.frame.width * 0.8, preferredHeight: 50,
                                         style: .popover)
        dimBackground()
        present(welcomeVC, animated: true, completion: nil)
    }
}

// MARK:- Bar Chart Delegate

extension InitialViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChartCell.reuseIdentifier, for: indexPath) as! ChartCell
        cell.cellLabel.text = summaryLabels[indexPath.item]
        
        // Calculate the width for a label that accomodates the longer of "Total Income" and "Total Spending"
        let maxWidth = UILabel.calcSize(for: summaryLabels.longestString() ?? "", withFont: fontScale < 1 ? 14 : 16 * fontScale).width
        cell.setupUI(withLabelWidth: maxWidth + 8)
        
        // The values used to animate the bar chart from the prior value to the new value
        var newValue: Double = 0
        var oldValue: CGFloat = 0
        
        if summaryView.segmentedControl.selectedSegmentIndex == 0 {
            newValue = indexPath.row == 0 ? viewModel.currentMonthTotalIncome : viewModel.currentMonthTotalSpending
            oldValue = indexPath.row == 0 ? selectedMonthScaledData.0 : selectedMonthScaledData.1
        } else {
            newValue = indexPath.row == 0 ? viewModel.currentYearTotalIncome : viewModel.currentYearTotalSpending
            oldValue = indexPath.row == 0 ? selectedYearScaledData.0 : selectedYearScaledData.1
        }
        
        cell.formatValueLabel(with: newValue)
        cell.barView.frame = .init(x: maxWidth + 15, y: (cell.frame.height - 25) / 2, width: oldValue, height: 25)
        cell.valueLabel.frame = .init(origin: CGPoint(x: maxWidth + 20 + oldValue, y: cell.frame.height * 0.35), size: cell.valueLabel.intrinsicContentSize)
        
        // Scale down the value if it cannot be accomodated by the screen
        let scaledValue = self.scaleFactor < 1 ? CGFloat(newValue * self.scaleFactor) : CGFloat(newValue)
        let distanceToMove = scaledValue - oldValue
        
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
        
        // Update the bar chart if the segmented control has "Year" selected
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
        
        // Creates a new instance of the view controller that displays the category table, and highlights the selected item after the view controller is presented
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
        // Check if the month whose items changed is the month displayed in the summary view otherwise do nothing
        if forMonth.date == DateFormatters.abbreviatedMonthYearFormatter.string(from: selectedMonth) && summaryView.segmentedControl.selectedSegmentIndex == 0 {
            
            // If the view controller is visible the updates the bar chart data, otherwise sets monthChanged to true to keep track of it
            if view.window != nil && presentedViewController == nil {
                reloadBarChartData()
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
        if let presentedVC = presentedViewController, presentedVC.isKind(of: RecurringViewController.self) {
            return false
        } else {
            dimmingView.removeFromSuperview()
            return true
        }
    }
}
