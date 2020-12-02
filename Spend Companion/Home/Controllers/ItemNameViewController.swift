//
//  ItemNameViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/12/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit


protocol ItemNameViewControllerDelegate: class {
    /// Passes the chosen item name to the delegate
    func saveItemName(name: String)
}

class ItemNameViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
// MARK:- Poperties
    
    private var existingItemName: String?  // Gets set if the user had already chosen a name for the transaction
    
    var itemNames = [String]() // The complete list of the most common item names
    
    // The item names that get displayed by the table view, filtered according to the user input
    private lazy var tableItemNames = itemNames {
        didSet {
            itemNamesTable.beginUpdates()
            itemNamesTable.reloadSections(IndexSet(arrayLiteral: 0), with: .none)
            itemNamesTable.endUpdates()
        }
    }
    
    private var cellId = "cellId"
    weak var delegate: ItemNameViewControllerDelegate?
    
// MARK:- Subviews
    
    let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "New Name"
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    var itemNamesTable = UITableView(frame: .zero, style: .plain)
    
// MARK:- Lifecycle methods
    
    init(itemName: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        if itemName != "Description" { self.existingItemName = itemName }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CustomColors.systemBackground
        setupTableView()

        view.addSubviews([titleTextField, itemNamesTable])
        titleTextField.text = existingItemName
        
        // Anchor the subviews
        titleTextField.anchor(top: view.safeAreaLayoutGuide.topAnchor, topConstant: 15, leading: view.leadingAnchor, leadingConstant: 15, trailing: view.trailingAnchor, trailingConstant: 15, heightConstant: 40)
        itemNamesTable.anchor(top: titleTextField.bottomAnchor, topConstant: 10, leading: view.leadingAnchor, trailing: view.trailingAnchor, bottom: view.bottomAnchor)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        titleTextField.becomeFirstResponder()
        titleTextField.delegate = self
    }
    
// MARK:- Methods
    
    private func setupTableView() {
        itemNamesTable.delegate = self
        itemNamesTable.dataSource = self
        itemNamesTable.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        itemNamesTable.tableFooterView = UIView()
    }

    @objc func done() {
        
        // If the user entered a non-empty text then sends it to the delegate
        if let name = titleTextField.text?.removeTrailingSpace(), !name.isEmpty {
            delegate?.saveItemName(name: name)
        }
        dismiss(animated: true, completion: nil)
    }
    
// MARK:- Table view delegate and data source
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Commonly used"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableItemNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cell.textLabel?.text = tableItemNames[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        let selectedTitle = cell?.textLabel?.text
        self.titleTextField.text = selectedTitle
        done()
    }
    
// MARK:- Text field delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        titleTextField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return false }
        let currentString: NSString = text as NSString
        let newString = currentString.replacingCharacters(in: range, with: string) as NSString
        let lowerCaseString = String(newString).lowercased()
        
        // Filters the item names according to the user inputs
        if !lowerCaseString.isEmpty {
            tableItemNames = itemNames.filter({ $0.lowercased().starts(with: lowerCaseString) })
        } else {
            tableItemNames = itemNames
        }
        return newString.length < 19
    }
    
}
