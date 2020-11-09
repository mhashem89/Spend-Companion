//
//  ItemNameViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/12/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit


protocol ItemNameViewControllerDelegate: class {
    func saveItemName(name: String)
}

class ItemNameViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    var cellId = "cellId"
    
    let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "New Name"
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    var itemNamesTable = UITableView(frame: .zero, style: .plain)
    
    var itemName: String?
    
    var itemNames = [String]()
    
    weak var delegate: ItemNameViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CustomColors.systemBackground
        setupTableView()

        view.addSubviews([titleTextField, itemNamesTable])
        titleTextField.text = itemName
        
        titleTextField.anchor(top: view.safeAreaLayoutGuide.topAnchor, topConstant: 15, leading: view.leadingAnchor, leadingConstant: 15, trailing: view.trailingAnchor, trailingConstant: 15, heightConstant: 40)
        itemNamesTable.anchor(top: titleTextField.bottomAnchor, topConstant: 10, leading: view.leadingAnchor, trailing: view.trailingAnchor, bottom: view.bottomAnchor)
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        titleTextField.becomeFirstResponder()
        titleTextField.delegate = self
    }
    
    init(itemName: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        if itemName != "Description" { self.itemName = itemName }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func done() {
        if let name = titleTextField.text?.removeTrailingSpace(), !name.isEmpty {
            delegate?.saveItemName(name: name)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func setupTableView() {
        itemNamesTable.delegate = self
        itemNamesTable.dataSource = self
        itemNamesTable.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        itemNamesTable.tableFooterView = UIView()
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Commonly used"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cell.textLabel?.text = itemNames[indexPath.row]
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        titleTextField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return false }
        let currentString: NSString = text as NSString
        let newString = currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length < 19
    }
    
}
