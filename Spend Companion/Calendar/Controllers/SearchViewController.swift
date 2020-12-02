//
//  SearchViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/15/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
// MARK:- Properties
    
    private var viewModel = SearchViewModel()
    private let searchTable = UITableView()

// MARK:- Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CustomColors.systemBackground
        
        // Setup search table
        searchTable.delegate = self
        searchTable.dataSource = self
        searchTable.register(RecentItemCell.self, forCellReuseIdentifier: RecentItemCell.reuseIdentifier)
        searchTable.keyboardDismissMode = .interactive
        
        view.addSubview(searchTable)
        searchTable.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, bottom: view.bottomAnchor)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecentItemCell.reuseIdentifier, for: indexPath) as! RecentItemCell
        let item = viewModel.searchResults[indexPath.row]
        cell.configureCell(for: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let item = self.viewModel.searchResults[indexPath.row]
        guard let itemMonth = item.month else { return }
        
        // Present the category table view controller
        let categoryVC = CategoryViewController(month: itemMonth, category: item.category)
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
            tableView.performBatchUpdates({ [weak self] in
                do {
                    try self?.viewModel.deleteItem(item: item, at: indexPath)
                } catch let err {
                    self?.presentError(error: err)
                }
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return windowHeightScale < 1 ? 44 : 44 * fontScale
    }
}

// MARK:- Search Results Updating

extension SearchViewController: UISearchResultsUpdating {
   
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            do {
                try viewModel.search(name: searchText)
            } catch let err {
                presentError(error: err)
            }
            searchTable.reloadData()
        }
    }
}
