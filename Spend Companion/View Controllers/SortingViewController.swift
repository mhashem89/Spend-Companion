//
//  SortingView.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/1/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit


protocol SortingViewControllerDelegate: class {
    
//    func dateAscending()
//    func dateDescending()
//    func amountAscending()
//    func amountDescending()
//    func nameAscending()
//    func nameDescending()
    func sortingChosen(option: SortingOption, direction: SortingDirection)
}

class SortingViewController: UITableViewController {
    
    var cellId = "cellId"
    let names = ["Date ↑", "Date ↓", "Amount ↑", "Amount ↓", "Name ↑", "Name ↓"]
    weak var delegate: SortingViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = CustomColors.systemBackground
        tableView.register(SortingCell.self, forCellReuseIdentifier: cellId)
        tableView.tableFooterView = nil
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! SortingCell
        cell.nameLabel.text = names[indexPath.item]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60 * viewsHeightScale
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        switch indexPath.row {
        case 0:
            delegate?.sortingChosen(option: .date, direction: .ascending)
        case 1:
            delegate?.sortingChosen(option: .date, direction: .descending)
        case 2:
            delegate?.sortingChosen(option: .amount, direction: .ascending)
        case 3:
            delegate?.sortingChosen(option: .amount, direction: .descending)
        case 4:
            delegate?.sortingChosen(option: .name, direction: .ascending)
        case 5:
            delegate?.sortingChosen(option: .name, direction: .descending)
        default:
            break
        }
    }
    
}


class SortingCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: fontScale < 1 ? 18 : 16 * fontScale)
        label.numberOfLines = 0
        return label
    }()
    
    let icon: UILabel = {
        let label = UILabel()
        return label
    }()
    
    func setupUI() {
        addSubview(nameLabel)
        nameLabel.anchor(centerX: centerXAnchor, centerY: centerYAnchor)
    }
    
}


