//
//  ChartViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 9/30/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

var windowWidthScale: CGFloat {
    if let window = UIApplication.shared.windows.first {
        return window.frame.width / 414
    } else {
        return 1
    }
}

var windowHeightScale: CGFloat {
    if let window = UIApplication.shared.windows.first {
        return window.frame.height / 896
    } else {
        return 1
    }
}

var fontScale: CGFloat {
    return (windowWidthScale + windowHeightScale) / 2
}

class ChartViewController: UIViewController  {
    
    // MARK:- Properties
    
    var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    var categoryNames = [String]() {
        didSet {
            categoryNames = categoryNames.sorted(by: {
                guard let amount0 = categoryTotals[$0], let amount1 = categoryTotals[$1] else { return false }
                return amount0 > amount1
            })
        }
    }
    var categoryTotals = [String: Double]()
    var filteredMonthName: String?
    var filteredCategoryName: String?
    
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
            categoryTotals = CoreDataManager.shared.fetchCategoryTotals(for: selectedYear, forMonth: filteredMonthName)
            categoryNames = CoreDataManager.shared.fetchUniqueCategoryNames(for: selectedYear)
        }
    }
        
    var selectedSegment = 0
    
    var dimmingView = UIView().withBackgroundColor(color: UIColor.black.withAlphaComponent(0.5))
    
    var safeAreaTop: CGFloat {
        let top = UIApplication.shared.windows.first?.safeAreaInsets.top
        return top ?? 15
    }
    
    var scaleFactor: Double = 1
    
    // MARK:- Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CustomColors.systemBackground
        setupBarChart()
        setupHeader()
        view.addSubviews([filterButton, filteredRowLabel])
        setupFilterButton()
        
        let currentMonthString = DateFormatters.monthFormatter.string(from: Date())
        self.filteredMonthName = "\(currentMonthString)"
        self.filteredRowLabel.text = currentMonthString
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        categoryTotals = CoreDataManager.shared.fetchCategoryTotals(for: selectedYear, forMonth: filteredMonthName)
        categoryNames = CoreDataManager.shared.fetchUniqueCategoryNames(for: selectedYear)
        scaleFactor = calcScaleFactor()
        barChart.reloadData()
        filterButton.tintColor = UserDefaults.standard.colorForKey(key: SettingNames.buttonColor) ?? CustomColors.blue
    }
    
    // MARK:- Selectors
    
    func setupFilterButton() {
         filterButton.anchor(top: header.bottomAnchor, topConstant: 10, trailing: view.trailingAnchor, trailingConstant: 10 * windowWidthScale)
         filterButton.setAttributedTitle(NSAttributedString(string: " Filter", attributes: [.font: UIFont.systemFont(ofSize: fontScale < 1 ? 15 : 15 * fontScale)]), for: .normal)
         filterButton.addTarget(self, action: #selector(showFilter), for: .touchUpInside)
         filteredRowLabel.anchor(top: filterButton.topAnchor, leading: view.leadingAnchor, leadingConstant: 10 * windowWidthScale)
     }
    
    @objc func showFilter() {
        dimBackground()
        let picker = FilterViewController()
        picker.delegate = self
        picker.rowNames = selectedSegment == 0 ? months : categoryNames
        picker.filterActive = selectedSegment == 0 ? filteredMonthName != nil : filteredCategoryName != nil
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
            filteredRowLabel.text = filteredMonthName ?? "Total spending by category"
            categoryTotals = CoreDataManager.shared.fetchCategoryTotals(for: selectedYear, forMonth: filteredMonthName)
        } else if header.segmentedControl.selectedSegmentIndex == 1 {
            selectedSegment = 1
            filterButton.isHidden = false
            filteredRowLabel.text = filteredCategoryName ?? "Total spending by month"
        } else {
            selectedSegment = 2
            filterButton.isHidden = true
            filteredRowLabel.text = "Total income by month"
        }
        scaleFactor = calcScaleFactor()
        barChart.reloadData()
    }
    

    // MARK:- Methods
    
    
    func setupHeader() {
        header = CalendarHeader(frame: .init(x: 0, y: safeAreaTop, width: view.frame.width, height: windowHeightScale < 1 ? 100 : 100 * windowHeightScale))
        view.addSubview(header)
        header.headerLabel.text = selectedYear
        header.delegate = self
        header.segmentedControl.insertSegment(withTitle: "Category", at: 0, animated: false)
        header.segmentedControl.insertSegment(withTitle: "Month", at: 1, animated: false)
        header.segmentedControl.insertSegment(withTitle: "Income", at: 2, animated: false)
        header.addSegmentedControl()
        header.segmentedControl.anchor(heightConstant: windowHeightScale < 1 ? 32 : 32 * windowHeightScale)
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
        barChart.frame = .init(x: 10 * windowWidthScale, y: 200, width: view.frame.width, height: view.frame.height - 200)
        barChart.showsHorizontalScrollIndicator = false
        barChart.showsVerticalScrollIndicator = false
    }
    
    
    func calcScaleFactor() -> Double {
        switch selectedSegment {
        case 1:
            if let maxInYear = CoreDataManager.shared.calcMaxInYear(year: selectedYear) {
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
            if let maxInYear = CoreDataManager.shared.calcMaxInYear(year: selectedYear, forIncome: true) {
                let valueLabelSize = UILabel.calcSize(for: String(format: "%g", maxInYear), withFont: 13 * fontScale)
                return Double(view.frame.width - chartLabelMaxWidth - valueLabelSize.width - 70) / maxInYear
            }
        default:
            break
        }
        return 1
    }
    
    
    func dimBackground() {
        tabBarController?.view.addSubview(dimmingView)
        dimmingView.frame = view.bounds
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
        cell.cellLabel.text = selectedSegment == 1 || selectedSegment == 2 ? months[indexPath.item] : categoryNames[indexPath.row]
        cell.setupUI(withLabelWidth: chartLabelMaxWidth)
        cell.barView.frame = .init(x: chartLabelMaxWidth + (5 * windowWidthScale), y: (cell.frame.height - 25) / 2, width: 0, height: 25)
        if selectedSegment == 1 || selectedSegment == 2 {
            let monthString = "\(months[indexPath.item]) \(selectedYear)"
            if let total = CoreDataManager.shared.calcCategoryTotalForMonth(monthString, for: selectedSegment == 1 ? filteredCategoryName : "Income") {
                cell.formatValueLabel(with: total)
                cell.valueLabel.frame = .init(origin: CGPoint(x: chartLabelMaxWidth + (8 * windowWidthScale), y: cell.frame.height * 0.27), size: cell.valueLabel.intrinsicContentSize)
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
                let percentage = value > 0 ? (value / sum) * 100 : 0
                cell.formatValueLabel(with: value, withPercentage: percentage)
                let distanceToMove = value > 0 ? self.scaleFactor < 1 ? CGFloat(value * self.scaleFactor) : CGFloat(value) : 0.5
                cell.valueLabel.frame = .init(origin: CGPoint(x: chartLabelMaxWidth + (8 * windowWidthScale), y: cell.frame.height * 0.27), size: cell.valueLabel.intrinsicContentSize)
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

// MARK:- Calendar Header Delegate

extension ChartViewController: CalendarHeaderDelegate {
    
    func yearSelected(year: String) {
        self.selectedYear = year
        self.scaleFactor = calcScaleFactor()
        barChart.reloadData()
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
        switch selectedSegment {
        case 0:
            filteredRowLabel.text = "Total spending by category"
            filteredMonthName = nil
            categoryTotals = CoreDataManager.shared.fetchCategoryTotals(for: selectedYear)
        case 1: filteredRowLabel.text = "Total spending by month"; filteredCategoryName = nil
        case 2: filteredRowLabel.text = "Total income by month"
        default: break
        }
        scaleFactor = calcScaleFactor()
        barChart.reloadData()
        dimmingView.removeFromSuperview()
        dismiss(animated: true, completion: nil)
    }
    
    func rowPicked(rowName: String) {
        self.filteredRowLabel.text = rowName
        if selectedSegment == 0 {
            filteredMonthName = rowName
            categoryTotals = CoreDataManager.shared.fetchCategoryTotals(for: selectedYear, forMonth: rowName)
            categoryNames = CoreDataManager.shared.fetchUniqueCategoryNames(for: selectedYear)
            scaleFactor = calcScaleFactor()
        } else {
            filteredCategoryName = rowName
        }
        barChart.reloadData()
        dimmingView.removeFromSuperview()
        dismiss(animated: true, completion: nil)
    }
    
}
