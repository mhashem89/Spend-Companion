//
//  SearchViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/15/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
    var cellId = "cellId"
    
    var viewModel = SearchViewModel()
    
    let searchTable = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CustomColors.systemBackground
        searchTable.delegate = self
        searchTable.dataSource = self
        searchTable.register(RecentItemCell.self, forCellReuseIdentifier: cellId)
        searchTable.keyboardDismissMode = .interactive
        
        view.addSubview(searchTable)
        searchTable.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, bottom: view.bottomAnchor)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! RecentItemCell
        let item = viewModel.searchResults[indexPath.row]
        let titleString = NSMutableAttributedString(string: item.detail ?? "Item", attributes: [.font: UIFont.boldSystemFont(ofSize: fontScale < 1 ? 13 : 16 * fontScale), .foregroundColor: CustomColors.label])
        let todayDate = DateFormatters.fullDateFormatter.string(from: Date())
        let dayString = DateFormatters.fullDateFormatter.string(from: item.date!) == todayDate ? "Today" : DateFormatters.fullDateFormatter.string(from: item.date!)
        let formattedDayString = NSAttributedString(string: "   \(dayString)", attributes: [.font: UIFont.italicSystemFont(ofSize: fontScale < 1 ? 11 : 12 * fontScale), .foregroundColor: UIColor.darkGray])
        titleString.append(formattedDayString)
        cell.textLabel?.attributedText = titleString
        cell.detailTextLabel?.text = item.category?.name
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: fontScale < 1 ? 11 : 11 * fontScale)
        cell.amountLabel.text = String(format: "%g", item.amount)
        if item.recurringNum != nil && item.recurringUnit != nil {
            cell.addRecurrence()
        } else {
            cell.recurringCircleButton.removeFromSuperview()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let item = self.viewModel.searchResults[indexPath.row]
        let categoryVC = CategoryViewController(month: item.month!, category: item.category)
        if let itemIndex = categoryVC.viewModel?.items?.firstIndex(of: item) {
            present(UINavigationController(rootViewController: categoryVC), animated: true) {
                let selectedIndexPath = IndexPath(item: itemIndex, section: 0)
                categoryVC.tableView.scrollToRow(at: selectedIndexPath, at: .none, animated: true)
                categoryVC.tableView.cellForRow(at: selectedIndexPath)?.isHighlighted = true
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = viewModel.searchResults[indexPath.row]
            tableView.performBatchUpdates({
                viewModel.deleteItem(item: item, at: indexPath)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }, completion: nil)
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewsHeightScale < 1 ? 44 : 44 * fontScale
    }
    
    
}



extension SearchViewController: UISearchResultsUpdating {
   
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            viewModel.search(name: searchText)
            searchTable.reloadData()
        }
      
    }
    
    
    
    
}
