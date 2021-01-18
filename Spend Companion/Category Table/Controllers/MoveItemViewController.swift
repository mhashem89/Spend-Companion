//
//  MoveItemViewController.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 11/1/20.
//

import UIKit


protocol MoveItemVCDelegate: class {
    
    func moveItem(item: Item, to category: String, sisterItems: [Item]?)
}

class MoveItemViewController: UITableViewController {
    
    var cellId = "MoveTableCellId"
    
    var selectedCategory: String!
    
    var item: Item!
    
    var categoryNames = [String]()
    
    weak var delegate: MoveItemVCDelegate?
    
    init(item: Item, selectedCategory: String) {
        super.init(nibName: nil, bundle: nil)
        self.item = item
        self.selectedCategory = selectedCategory
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Move Item"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Move", style: .plain, target: self, action: #selector(move))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        tableView.backgroundColor = CustomColors.systemBackground
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryNames.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cell.textLabel?.text = categoryNames[indexPath.row]
        cell.accessoryType = categoryNames[indexPath.row] == selectedCategory ? .checkmark : .none
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        tableView.visibleCells.forEach({ $0.accessoryType = .none })
        selectedCategory = categoryNames[indexPath.row]
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }
    
    
    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    
    @objc func move() {
        var sisterItemsToMove: [Item]?
        guard let itemToMove = item, let newCategory = selectedCategory else { return }
        if item.recurringNum != nil, let sisterItems = item.sisterItems?.allObjects as? [Item] {
            let alertController = UIAlertController(title: nil, message: "Move similar transactions?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Only this transaction", style: .default, handler: { [weak self] (_) in
                self?.delegate?.moveItem(item: itemToMove, to: newCategory, sisterItems: nil)
                self?.dismiss(animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: "All other transactions", style: .default, handler: { [weak self] (action) in
                sisterItemsToMove = sisterItems
                self?.delegate?.moveItem(item: itemToMove, to: newCategory, sisterItems: sisterItemsToMove)
                self?.dismiss(animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            delegate?.moveItem(item: itemToMove, to: newCategory, sisterItems: sisterItemsToMove)
            dismiss(animated: true, completion: nil)
        }
        
        
        
    }
    
}
