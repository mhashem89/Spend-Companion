//
//  CalenderViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 9/29/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

class CalenderViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
// MARK:- Properties
    
    private var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    private var colors: [UIColor] = [CustomColors.blue, CustomColors.indigo, CustomColors.orange, CustomColors.pink, CustomColors.purple, CustomColors.red, CustomColors.teal, CustomColors.yellow]
    private var chosenColor: UIColor? = #colorLiteral(red: 0.8501421211, green: 0.8527938297, blue: 1, alpha: 1)
    private var selectedYear: String = DateFormatters.yearFormatter.string(from: Date())
    
    // Total income and spending for each month of the selected year
    private var yearTotals = [String: (spending: Double?, income: Double?)]()
    
// MARK:- Methods
    
    override func viewDidLoad() {
        
        // Setup the collection view
        collectionView.backgroundColor = CustomColors.systemBackground
        collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: CalendarCell.reuseIdentifier)
        collectionView.register(CalendarHeader.self, forCellWithReuseIdentifier: CalendarHeader.reuseIdentifier)
        
        // Setup the navigation bar
        setupNavBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
        loadData()
        collectionView.reloadData()
    }
    
    func setupNavBar() {
        
        // Setup the navigation bar
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "Calendar"
        
        // Setup the search view controller
        let searchVC = SearchViewController()
        let searchController = UISearchController(searchResultsController: searchVC)
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = searchVC
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.placeholder = "Search transactions"
    }
    
    func loadData() {
        
        // For each month, ask the Core Data manager to calculate total income and spending and save them in the "yearTotals" dict
        months.forEach { [weak self] (month) in
            let monthString = "\(month) \(selectedYear)"
            let spending = CoreDataManager.shared.calcCategoryTotalForMonth(monthString)
            let income = CoreDataManager.shared.calcCategoryTotalForMonth(monthString, for: "Income")
            self?.yearTotals[monthString] = (spending, income)
        }
    }
    
// MARK:-  Collection View Methods
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? 1 : months.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 { // Setup the header that has the selected year
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarHeader.reuseIdentifier, for: indexPath) as! CalendarHeader
            cell.headerLabel.text = selectedYear
            cell.headerLabel.font = UIFont.boldSystemFont(ofSize: 22 * fontScale)
            cell.delegate = self
            return cell
        } else {  // Setup the month cells
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarCell.reuseIdentifier, for: indexPath) as! CalendarCell
            cell.layer.borderColor = chosenColor?.cgColor
            cell.layer.cornerRadius = (view.frame.width * 0.24) / 2
            cell.monthLabel.text = months[indexPath.item]
            let monthString = "\(months[indexPath.item]) \(selectedYear)"
            let totalSpending = yearTotals[monthString]?.spending
            let totalIncome = yearTotals[monthString]?.income
            if totalSpending != nil || totalIncome != nil { // Check if the month has either recorded income or spending
                let totalSpendingString = CommonObjects.shared.formattedCurrency(with: totalSpending ?? 0)
                let totalIncomeString = CommonObjects.shared.formattedCurrency(with: totalIncome ?? 0)
                cell.addTotalLabel(income: totalIncomeString, spending: totalSpendingString)
            } else {
                cell.removeTotalLabel()
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return .init(width: view.frame.width, height: 50)
        } else {
            let width = view.frame.width * 0.24
            return .init(width: width, height: width)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        } else {
            return .init(top: 0, left: 15, bottom: 0, right: 15)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let year = selectedYear
            let month = "\(months[indexPath.item]) \(year)"
            let monthVC = MonthViewController(monthString: month)
            navigationController?.pushViewController(monthVC, animated: true)
        } else {
            return
        }
    }
}

// MARK:- Calendar Header Delegate

extension CalenderViewController: CalendarHeaderDelegate {
    
    func yearSelected(year: String) {
        self.selectedYear = year
        loadData()
        chosenColor = colors.randomElement()
        collectionView.reloadSections(IndexSet(arrayLiteral: 1))
    }
}
