//
//  SummaryView.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/7/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit


class SummaryView: UIView {
    
// MARK:- Properties
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = CustomColors.label
        label.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 18 * fontScale)
        return label
    }()
    
    var segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl()
        sc.insertSegment(withTitle: "Month", at: 0, animated: false)
        sc.insertSegment(withTitle: "Year", at: 1, animated: false)
        sc.selectedSegmentIndex = 0
        sc.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 15 * fontScale)], for: .normal)
        return sc
    }()
    
    var summaryLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: fontScale < 1 ? 11.5 : 14 * fontScale)
        lbl.numberOfLines = 0
        lbl.layer.borderWidth = 0.5
        lbl.layer.borderColor = CustomColors.label.cgColor
        lbl.layer.cornerRadius = 5
        lbl.textAlignment = .center
        return lbl
    }()
    
    var barChart = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    
//  MARK:- Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = CustomColors.systemBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        addSubviews([segmentedControl, titleLabel, barChart, summaryLabel])
        
    // Anrhor subviews
        titleLabel.anchor(top: safeAreaLayoutGuide.topAnchor, topConstant: 15 * windowHeightScale, leading: safeAreaLayoutGuide.leadingAnchor, leadingConstant: 10 * windowWidthScale)
        segmentedControl.anchor(trailing: safeAreaLayoutGuide.trailingAnchor, trailingConstant: 10 * windowWidthScale, centerY: titleLabel.centerYAnchor, widthConstant: 117 * windowWidthScale, heightConstant: 31 * windowWidthScale)
        barChart.anchor(top: titleLabel.bottomAnchor, topConstant: 20 * windowHeightScale, leading: safeAreaLayoutGuide.leadingAnchor, trailing: safeAreaLayoutGuide.trailingAnchor, heightConstant: frame.height * 0.4)
        summaryLabel.anchor(top: barChart.bottomAnchor, topConstant: 15, centerX: centerXAnchor, widthConstant: frame.width * 0.9, heightConstant: frame.height * 0.17)
    }
    
    func setupBarChart(delegate: UICollectionViewDelegate, dataSource: UICollectionViewDataSource, cellId: String) {
        barChart.delegate = delegate
        barChart.dataSource = dataSource
        barChart.register(ChartCell.self, forCellWithReuseIdentifier: cellId)
        
        barChart.backgroundColor = CustomColors.systemBackground
        (barChart.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .vertical
        barChart.showsHorizontalScrollIndicator = false
        barChart.showsVerticalScrollIndicator = false
    }
    
/// Configures summary label according to whether the user selected to view bar chart by month or year
    func configureSummaryLabel(with viewModel: InitialViewModel) {
        let component: Calendar.Component = segmentedControl.selectedSegmentIndex == 0 ? .month : .year
        if component == .month {
            let dateComponent = Calendar.current.dateComponents([.year, .month], from: Date())
            
            // Calculate the number of days since beginning of the month till today
            let monthBeggining = Calendar.current.date(from: dateComponent)!
            if let numDays = Calendar.current.dateComponents([.day], from: monthBeggining, to: Date()).day, viewModel.currentYearTotalSpending > 0, numDays > 7 {
                
                // Calculate the   average spending over the duration of time since beginning of the month
                let average = (viewModel.currentMonthTotalSpending / Double(numDays)).rounded()
                
                summaryLabel.isHidden = false
                
                let averageString = CommonObjects.shared.formattedCurrency(with: average) // Add currency symbol
                summaryLabel.text = "Average daily spending this month: \(averageString)"
            } else {
                summaryLabel.isHidden = true
            }
        } else if component == .year {
            // Calculate the difference between average income and average spending this year
            if let averageThisYear = try? CoreDataManager.shared.calcYearAverage(for: DateFormatters.yearFormatter.string(from: Date())) {
                summaryLabel.isHidden = false
                let averageString = CommonObjects.shared.formattedCurrency(with: Double(averageThisYear))  // Add currency symbol
                if averageThisYear > 0 {
                    summaryLabel.text = "On average this year, you make \(averageString) more than you spend per month"
                } else {
                    summaryLabel.text = "On average this year, you spend \(averageString) more than you make per month"
                }
            } else {
                summaryLabel.isHidden = true
            }
        }
    }
    
}
