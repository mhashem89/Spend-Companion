//
//  ChartViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 9/30/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

var viewsWidthScale: CGFloat {
    if let window = UIApplication.shared.windows.first {
        return window.frame.width / 414
    } else {
        return 1
    }
}

var viewsHeightScale: CGFloat {
    if let window = UIApplication.shared.windows.first {
        return window.frame.height / 896
    } else {
        return 1
    }
}

var fontScale: CGFloat {
    return (viewsWidthScale + viewsHeightScale) / 2
}

class ChartViewController: UIViewController, YearHeaderDelegate  {
    
    // MARK:- Properties
    
    var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    var categoryNames = [String]()
    var categoryTotals = [String: Double]()
    var filteredRowName: String?
    
    var header: CalendarHeader!
    
    var barChart = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    var filterButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13, *) {
            button.setImage(UIImage(systemName: "line.horizontal.3.decrease.circle"), for: .normal)
        }
        return button
    }()
    
    var filteredRowLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 18 : 18 * fontScale)
        label.textColor = CustomColors.label
        return label
    }()
    
    var chartLabelMaxWidth: CGFloat {
        if selectedSegment == 1 || selectedSegment == 2 {
            return calcMaxWidth(for: months, withSize: fontScale < 1 ? 14 : 16 * fontScale)
        } else {
            return calcMaxWidth(for: categoryNames, withSize: fontScale < 1 ? 14 : 16 * fontScale)
        }
    }
    
    var yearBarChartCell = "yearBarChartCell"
    
    var selectedYear: String = DateFormatters.yearFormatter.string(from: Date()) {
        didSet {
            categoryNames = viewModel.fetchUniqueCategoryNames(for: selectedYear)
            categoryTotals = viewModel.fetchCategoryTotals(for: selectedYear)
        }
    }
    
    var viewModel = ChartViewModel()
    
    var selectedSegment = 0
    
    var dimmingView = UIView()
    
    var safeAreaTop: CGFloat {
        let top = UIApplication.shared.windows.first!.safeAreaInsets.top
        return top
    }
    
    var scaleFactor: Double = 1
    
    // MARK:- Lifecycle Methods
    
    init() {
        super.init(nibName: nil, bundle: nil)
        if #available(iOS 14, *) {
            tabBarItem = UITabBarItem(title: "Chart", image: UIImage(systemName: "chart.bar.doc.horizontal"), tag: 2)
        } else if #available(iOS 13, *) {
            tabBarItem = UITabBarItem(title: "Chart", image: UIImage(systemName: "chart.bar.fill"), tag: 2)
        } else {
            let button = UITabBarItem(title: "Chart", image: nil, selectedImage: nil)
            button.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], for: .normal)
            button.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -8)
            tabBarItem = button
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CustomColors.systemBackground
        setupBarChart()
        setupHeader()
        view.addSubviews([filterButton, filteredRowLabel])
        setupFilterButton()
        
        let currentMonthString = DateFormatters.monthFormatter.string(from: Date())
        self.filteredRowName = "\(currentMonthString)"
        self.filteredRowLabel.text = currentMonthString
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        categoryNames = viewModel.fetchUniqueCategoryNames(for: selectedYear)
        let filteredMonth = filteredRowName != nil ? "\(filteredRowName!) \(selectedYear)" : nil
        categoryTotals = viewModel.fetchCategoryTotals(for: selectedYear, for: filteredMonth)
        scaleFactor = calcScaleFactor()
        barChart.reloadData()
        filterButton.tintColor = UserDefaults.standard.colorForKey(key: SettingNames.buttonColor) ?? CustomColors.blue
    }
    
    // MARK:- Selectors
    
    func setupFilterButton() {
         filterButton.anchor(top: header.bottomAnchor, topConstant: 10, trailing: view.trailingAnchor, trailingConstant: 10 * viewsWidthScale)
         filterButton.setAttributedTitle(NSAttributedString(string: " Filter", attributes: [.font: UIFont.systemFont(ofSize: fontScale < 1 ? 15 : 15 * fontScale)]), for: .normal)
         filterButton.addTarget(self, action: #selector(showFilter), for: .touchUpInside)
         filteredRowLabel.anchor(top: filterButton.topAnchor, leading: view.leadingAnchor, leadingConstant: 10 * viewsWidthScale)
     }
    
    
    @objc func showFilter() {
        dimBackground()
        let picker = FilterViewController()
        picker.delegate = self
        picker.rowNames = selectedSegment == 0 ? months : categoryNames
        picker.filterActive = filteredRowName != nil
        picker.modalPresentationStyle = .popover
        picker.preferredContentSize = .init(width: fontScale < 1 ? 200 : 200 * fontScale, height: fontScale < 1 ? 200 : 200 * fontScale)
        picker.popoverPresentationController?.delegate = self
        picker.popoverPresentationController?.sourceView = filterButton
        picker.popoverPresentationController?.sourceRect = filterButton.bounds
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        present(picker, animated: true, completion: nil)
    }
    
    
    @objc func handleSegmentedControl() {
        if header.segmentedControl.selectedSegmentIndex == 0 {
            selectedSegment = 0
            filterButton.isHidden = false
            filteredRowLabel.text = "Total spending by category"
        } else if header.segmentedControl.selectedSegmentIndex == 1 {
            selectedSegment = 1
            filterButton.isHidden = false
            filteredRowLabel.text = "Total spending by month"
        } else {
            selectedSegment = 2
            filterButton.isHidden = true
            filteredRowLabel.text = "Total income by month"
        }
        filteredRowName = nil
        categoryTotals = viewModel.fetchCategoryTotals(for: selectedYear)
        scaleFactor = calcScaleFactor()
        barChart.reloadData()
    }
    

    // MARK:- Methods
    
    func calcScaleFactor() -> Double {
        switch selectedSegment {
        case 1:
            if let maxInYear = viewModel.calcMaxInYear(year: selectedYear) {
                let valueLabelSize = UILabel.calcSize(for: String(format: "%g", maxInYear), withFont: 13 * fontScale)
                return Double(view.frame.width - chartLabelMaxWidth - valueLabelSize.width - 70) / maxInYear
            }
        case 0:
            if  let maxCategory = categoryTotals.values.max() {
                let sum = Array(categoryTotals.values).sum() ?? 1
                let maxPercentage = Int(maxCategory / sum) * 100
                let valueLabelSize = UILabel.calcSize(for: "\(String(format: "%g", maxCategory)) (\(maxPercentage)%", withFont: 13 * fontScale)
                return Double(view.frame.width - chartLabelMaxWidth - valueLabelSize.width - 70) / maxCategory
            }
        case 2:
            if let maxInYear = viewModel.calcMaxInYear(year: selectedYear, forIncome: true) {
                let valueLabelSize = UILabel.calcSize(for: String(format: "%g", maxInYear), withFont: 13 * fontScale)
                return Double(view.frame.width - chartLabelMaxWidth - valueLabelSize.width - 70) / maxInYear
            }
        default:
            break
        }
        return 1
    }
    
    func setupHeader() {
        header = CalendarHeader(frame: .init(x: 0, y: safeAreaTop, width: view.frame.width, height: viewsHeightScale < 1 ? 100 : 100 * viewsHeightScale))
        view.addSubview(header)
        header.headerLabel.text = selectedYear
        header.delegate = self
        header.segmentedControl.insertSegment(withTitle: "Category", at: 0, animated: false)
        header.segmentedControl.insertSegment(withTitle: "Month", at: 1, animated: false)
        header.segmentedControl.insertSegment(withTitle: "Income", at: 2, animated: false)
        header.addSegmentedControl()
        header.segmentedControl.anchor(heightConstant: viewsHeightScale < 1 ? 32 : 32 * viewsHeightScale)
        header.segmentedControl.selectedSegmentIndex = 0
        header.segmentedControl.addTarget(self, action: #selector(handleSegmentedControl), for: .valueChanged)
    }
    
    func setupBarChart() {
        barChart.backgroundColor = CustomColors.systemBackground
        barChart.alwaysBounceVertical = true
        barChart.register(ChartCell.self, forCellWithReuseIdentifier: yearBarChartCell)
        barChart.delegate = self
        barChart.dataSource = self
        view.addSubview(barChart)
        (barChart.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .vertical
        barChart.frame = .init(x: 10 * viewsWidthScale, y: viewsHeightScale < 1 ? 200 : 200 * viewsHeightScale, width: view.frame.width, height: view.frame.height - 200)
        barChart.showsHorizontalScrollIndicator = false
        barChart.showsVerticalScrollIndicator = false
    }
    
    
    func dimBackground() {
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        tabBarController?.view.addSubview(dimmingView)
        dimmingView.frame = view.bounds
    }
  
    
    func yearSelected(year: String) {
        self.selectedYear = year
        self.scaleFactor = calcScaleFactor()
        barChart.reloadData()
    }
    
    func calcMaxWidth(for names: [String], withSize fontSize: CGFloat) -> CGFloat {
        var maxWidth: CGFloat = 0
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: fontSize)
        var splitNames = [String]()
        for name in names.map({ $0.split(separator: " ") }) {
            splitNames.append(contentsOf: name.map({ String($0) }))
        }
        for name in splitNames {
            label.text = name
            let labelWidth = label.intrinsicContentSize.width
            if labelWidth > maxWidth {
                maxWidth = labelWidth
            }
        }
        return min(maxWidth, view.frame.width * 0.22)
    }
    
}


// MARK:- Bar Chart (Collection View) Delegate


extension ChartViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if selectedSegment == 1 || selectedSegment == 2 {
            return 12
        } else {
            return categoryNames.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: yearBarChartCell, for: indexPath) as! ChartCell
        cell.cellLabel.text = selectedSegment == 1 || selectedSegment == 2 ? months[indexPath.item] : viewModel.fetchUniqueCategoryNames(for: selectedYear)[indexPath.row]
        cell.cellLabel.frame = .init(x: 0, y: 0, width: chartLabelMaxWidth, height: cell.frame.height)
        cell.cellLabel.textColor = UserDefaults.standard.colorForKey(key: SettingNames.labelColor) ?? .systemBlue
        cell.barView.frame = .init(x: chartLabelMaxWidth + (5 * viewsWidthScale), y: (cell.frame.height - 25) / 2, width: 0, height: 25)
        cell.barView.backgroundColor = UserDefaults.standard.colorForKey(key: SettingNames.barColor) ?? .systemRed
        if selectedSegment == 1 || selectedSegment == 2 {
            let monthString = "\(months[indexPath.item]) \(selectedYear)"
            if let total = CalendarViewModel.shared.calcMonthTotal(monthString, for: selectedSegment == 1 ? filteredRowName : "Income") {
                cell.valueLabel.text = String(format: "%g", total)
                cell.valueLabel.frame = .init(origin: CGPoint(x: chartLabelMaxWidth + (8 * viewsWidthScale), y: cell.frame.height * 0.27), size: cell.valueLabel.intrinsicContentSize)
                let distanceToMove = self.scaleFactor < 1 ? CGFloat(total * self.scaleFactor) : CGFloat(total)
                UIView.animate(withDuration: 0.5) {
                    cell.barView.frame.size.width = distanceToMove
                    cell.valueLabel.frame.origin.x += distanceToMove
                }
            } else {
                cell.barView.frame.size.width = 0.5
                cell.valueLabel.text = nil
            }
            return cell
        } else {
            let categoryName = categoryNames[indexPath.row]
            cell.cellLabel.text = categoryName
            if let value = categoryTotals[categoryName] {
                let sum = Array(categoryTotals.values).sum() ?? 1
                let percenage = value > 0 ? (value / sum) * 100 : 0
                cell.valueLabel.text = value > 0 ? "\(String(format: "%g", value)) (\(Int(percenage))%)" : nil
                let distanceToMove = value > 0 ? self.scaleFactor < 1 ? CGFloat(value * self.scaleFactor) : CGFloat(value) : 0.5
                cell.valueLabel.frame = .init(origin: CGPoint(x: chartLabelMaxWidth + (8 * viewsWidthScale), y: cell.frame.height * 0.27), size: cell.valueLabel.intrinsicContentSize)
                UIView.animate(withDuration: 0.5) {
                    cell.barView.frame.size.width = distanceToMove
                    cell.valueLabel.frame.origin.x += distanceToMove
                }
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: collectionView.frame.width, height: fontScale < 1 ? 40 : 40 * fontScale)
    }

}


// MARK:- Popover Controller Delegate

extension ChartViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        dimmingView.removeFromSuperview()
    }
    
}


// MARK:- Filter View Controller Delegate

extension ChartViewController: FilterViewControllerDelegate {
    
    func removeFilter() {
        self.filteredRowName = nil
        switch selectedSegment {
        case 0: filteredRowLabel.text = "Total spending by category"
        case 1: filteredRowLabel.text = "Total spending by month"
        case 2: filteredRowLabel.text = "Total income by month"
        default: break
        }
        categoryTotals = viewModel.fetchCategoryTotals(for: selectedYear)
        scaleFactor = calcScaleFactor()
        barChart.reloadData()
        dimmingView.removeFromSuperview()
        dismiss(animated: true, completion: nil)
    }
    
    func rowPicked(rowName: String) {
        self.filteredRowName = rowName
        self.filteredRowLabel.text = rowName
        if selectedSegment == 0 {
            let monthString = "\(rowName) \(selectedYear)"
            categoryTotals = viewModel.fetchCategoryTotals(for: selectedYear, for: monthString)
            scaleFactor = calcScaleFactor()
        }
        barChart.reloadData()
        dimmingView.removeFromSuperview()
        dismiss(animated: true, completion: nil)
    }
    
}
