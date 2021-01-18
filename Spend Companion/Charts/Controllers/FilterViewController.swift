//
//  File.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/5/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

protocol FilterViewControllerDelegate: class {
    
    func rowPicked(rowName: String)
    func removeFilter()
    
}

class FilterViewController: UITableViewController {
    
    var cellId = "FilterTableCellId"
    var rowNames = [String]()
    weak var delegate: FilterViewControllerDelegate?
    var filterActive: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = CustomColors.systemBackground
        tableView.register(SortingCell.self, forCellReuseIdentifier: cellId)
        tableView.tableFooterView = nil
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return filterActive ? 2 : 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filterActive {
            return section == 0 ? 1 : rowNames.count
        } else {
            return rowNames.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! SortingCell
        if filterActive {
            cell.nameLabel.text = indexPath.section == 0 ? "Remove filter" : rowNames[indexPath.item]
            cell.nameLabel.textColor = indexPath.section == 0 ? .systemRed : CustomColors.label
        } else {
            cell.nameLabel.text = rowNames[indexPath.item]
            cell.nameLabel.textColor = CustomColors.label
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if filterActive {
            indexPath.section == 0 ? delegate?.removeFilter() : delegate?.rowPicked(rowName: rowNames[indexPath.row])
        } else {
            delegate?.rowPicked(rowName: rowNames[indexPath.row])
        }
        
    }
    
    
}

