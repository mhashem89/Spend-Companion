//
//  CalenderViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 9/29/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

protocol YearHeaderDelegate: class {
    
    func yearSelected(year: String)
}


class CalenderViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, YearHeaderDelegate {
    
    var yearCellId = "yearCellId"
    var monthCellId = "monthCellId"
    
    var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    var colors: [UIColor] = [#colorLiteral(red: 0.4039207829, green: 0.7234769777, blue: 0.8435715419, alpha: 1), #colorLiteral(red: 0.5912354875, green: 0.505434492, blue: 0.8350452094, alpha: 1), #colorLiteral(red: 0.8592758566, green: 0.4597663065, blue: 0.6258551127, alpha: 1), #colorLiteral(red: 0.8599896891, green: 0.5834726084, blue: 0.4939326607, alpha: 1), #colorLiteral(red: 0.8315751904, green: 0.7270336446, blue: 0.4794956649, alpha: 1), #colorLiteral(red: 0.6603464669, green: 0.8209470178, blue: 0.5613906862, alpha: 1), #colorLiteral(red: 0.2146703781, green: 0.6475533781, blue: 0.8289181472, alpha: 1), #colorLiteral(red: 0.4976351081, green: 0.5781822379, blue: 0.8421240482, alpha: 1), #colorLiteral(red: 0.8134517766, green: 0.5566364028, blue: 0.666935728, alpha: 1), #colorLiteral(red: 0.8170407678, green: 0.4356290759, blue: 0.3118896123, alpha: 1), #colorLiteral(red: 0.8326459391, green: 0.676435899, blue: 0.31810554, alpha: 1), #colorLiteral(red: 0.5905677771, green: 0.8358383566, blue: 0.439441635, alpha: 1)]
    var chosenColor: UIColor? = #colorLiteral(red: 0.8501421211, green: 0.8527938297, blue: 1, alpha: 1)
    
    var selectedYear: String = DateFormatters.yearFormatter.string(from: Date())
    
    var viewModel = CalendarViewModel()


    override init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
        if #available(iOS 13, *) {
            tabBarItem = UITabBarItem(title: "Calendar", image: UIImage(systemName: "calendar"), tag: 1)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        collectionView.backgroundColor = CustomColors.systemBackground
        collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: monthCellId)
        collectionView.register(CalendarHeader.self, forCellWithReuseIdentifier: yearCellId)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "Calendar"
        
        setupNavBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
        collectionView.reloadSections(IndexSet(arrayLiteral: 1))
        
//        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
//            DispatchQueue.main.async {
//                requests.forEach({ print("WTF", $0.content.title, $0.trigger) })
//            }
//        }
    }
    
    func setupNavBar() {
        let searchVC = SearchViewController()
        let searchController = UISearchController(searchResultsController: searchVC)
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = searchVC
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.placeholder = "Search transactions"
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 12
        default:
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: yearCellId, for: indexPath) as! CalendarHeader
            cell.headerLabel.text = selectedYear
            cell.headerLabel.font = UIFont.boldSystemFont(ofSize: 22 * fontScale)
            cell.delegate = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: monthCellId, for: indexPath) as! CalendarCell
            cell.layer.borderColor = chosenColor?.cgColor
            cell.layer.cornerRadius = (view.frame.width * 0.24) / 2
            cell.monthLabel.font = UIFont.boldSystemFont(ofSize: 22 * fontScale)
            cell.incomeLabel.font = UIFont.systemFont(ofSize: 13 * fontScale)
            cell.spendingLabel.font = UIFont.systemFont(ofSize: 13 * fontScale)
            cell.monthLabel.text = months[indexPath.item]
            let monthString = "\(months[indexPath.item]) \(selectedYear)"
            let totalSpending = viewModel.calcMonthTotal(monthString)
            let totalIncome = viewModel.calcMonthTotal(monthString, for: "Income")
            if totalSpending != nil || totalIncome != nil {
                let totalSpendingString = String(format: "%g", totalSpending ?? 0)
                let totalIncomeString = String(format: "%g", totalIncome ?? 0)
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
    
    func yearSelected(year: String) {
        self.selectedYear = year
        chosenColor = colors.randomElement()
        collectionView.reloadSections(IndexSet(arrayLiteral: 1))
    }
    
    
    
    
}
