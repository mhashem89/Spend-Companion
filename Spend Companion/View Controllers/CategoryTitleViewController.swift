//
//  CategoryTitleViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/6/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit


protocol CategoryTitleViewControllerDelegate: class {
    func saveCategoryTitle(title: String)
}

class CategoryTitleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    var cellId = "cellId"
    
    let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "New Category"
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    var categoriesTable = UITableView(frame: .zero, style: .plain)
    
    var categoryName: String?
    
    var recentNames = [String]()
    var favorites = [String]()
    var fixedCategories = ["Income"]
    
    weak var delegate: CategoryTitleViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CustomColors.systemBackground
        setupCategoriesTable()

        view.addSubviews([titleTextField, categoriesTable])
        titleTextField.text = categoryName
        
        titleTextField.anchor(top: view.safeAreaLayoutGuide.topAnchor, topConstant: 15, leading: view.leadingAnchor, leadingConstant: 15, trailing: view.trailingAnchor, trailingConstant: 15, heightConstant: 40)
        categoriesTable.anchor(top: titleTextField.bottomAnchor, topConstant: 10, leading: view.leadingAnchor, trailing: view.trailingAnchor, bottom: view.bottomAnchor)
        
        recentNames = CoreDataManager.shared.fetchUniqueCategoryNames(for: nil).sorted(by: { $0 < $1 })
        recentNames = recentNames.filter( { !favorites.contains($0) && !["Recurring Expenses", "Income"].contains($0) } )
        
        favorites = CoreDataManager.shared.fetchFavorites()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        titleTextField.becomeFirstResponder()
        titleTextField.delegate = self
    }
    
    init(categoryName: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        if categoryName != nil, categoryName != "Category" {
            self.categoryName = categoryName
            fixedCategories.removeAll()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func done() {
        if let title = titleTextField.text?.removeTrailingSpace(), !title.isEmpty {
            delegate?.saveCategoryTitle(title: title)
        }
        dismiss(animated: true, completion: nil)
    }
    
    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    func setupCategoriesTable() {
        categoriesTable.delegate = self
        categoriesTable.dataSource = self
        categoriesTable.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        categoriesTable.tableFooterView = UIView()
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return favorites.count > 0 ? "Favorites" : nil
        } else if section == 2 {
            return "Recent"
        } else {
            return nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return fixedCategories.count
        case 1:
            return favorites.count
        case 2:
            return recentNames.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = fixedCategories[indexPath.row]
        case 1:
            cell.textLabel?.text = favorites[indexPath.row]
        case 2:
            cell.textLabel?.text = recentNames[indexPath.row]
        default:
            break
        }
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
        return newString.length < 16
    }
    
    
}


extension String {
    func removeTrailingSpace() -> String {
        let substrings = self.split(separator: " ")
        return substrings.joined(separator: " ")
    }
}
