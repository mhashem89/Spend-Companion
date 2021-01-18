//
//  MonthViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 8/18/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

class MonthViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, MonthViewModelDelegate {
    
    // MARK:- Properties
    
    private var headerId = "HeaderId"
    private var viewModel: MonthViewModel
    private var colors: [UIColor] = [CustomColors.blue, CustomColors.indigo, CustomColors.orange, CustomColors.pink, CustomColors.purple, CustomColors.red, CustomColors.teal, CustomColors.yellow]
    private var selectedCategories = [Category]() // Keep track of the categories user has selected to delete
    
// MARK:- Subviews
    
    private var centerTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.boldSystemFont(ofSize: 20)
        textView.textColor = CustomColors.darkGray
        textView.text = "Press the plus button to start adding categories"
        textView.textAlignment =  .center
        textView.isEditable = false
        return textView
    }()
    
    private var plusButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13, *) {
            button.setImage(UIImage(systemName: "plus")?.withRenderingMode(.automatic), for: .normal)
        } else {
            button.setAttributedTitle(NSAttributedString(string: "+", attributes: [.font: UIFont.boldSystemFont(ofSize: 30)]), for: .normal)
        }
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.backgroundColor = CustomColors.lightGray
        return button
    }()
    
// MARK:- Lifecycle Methods
    
    init(monthString: String) {
        self.viewModel = MonthViewModel(monthString: monthString)
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        viewModel.fetchData()
        
        // Setup the navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editCollectionView))
        title = viewModel.month.date
        navigationController?.navigationBar.isHidden = false
        
        // Setup the subviews
        view.addSubviews([plusButton, centerTextView])
        plusButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, topConstant: 15, trailing: view.trailingAnchor, trailingConstant: 20, widthConstant: 40, heightConstant: 40)
        centerTextView.anchor(centerX: view.centerXAnchor, centerY: view.centerYAnchor, widthConstant: view.frame.width * 0.8, heightConstant: view.frame.height * 0.1)
        plusButton.addTarget(self, action: #selector(self.addCategory), for: .touchUpInside)
        
        // Setup the collection view
        collectionView.backgroundColor = CustomColors.systemBackground
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.reuseIdentifier)
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        
        if viewModel.fixedCategories.isEmpty && viewModel.otherExpenses.isEmpty {
            centerTextView.isHidden = false
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
            centerTextView.isHidden = true
        }
    }
    
    // MARK:- Collection View Methods
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.fixedCategories.count > 0 ? 2 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1 {
            return .init(width: view.frame.width, height: view.frame.height * 0.05)
        } else {
            return .zero
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId, for: indexPath) as! SectionHeader
        header.nameLabel.text = "Expenses"
        return header
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewModel.fixedCategories.count > 0 {
            return section == 0 ? viewModel.fixedCategories.count : viewModel.otherExpenses.count
        } else {
            return viewModel.otherExpenses.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.reuseIdentifier, for: indexPath) as! CategoryCell
        var total: String = "0" // The total value for the category
        
        // If there is an "Income" category then there would be 2 sections otherwise there would be 1 section for expenses
        if viewModel.fixedCategories.count > 0 && indexPath.section == 0 {
            cell.nameLabel.text = ItemType.income.description
            total = viewModel.calcCategoryTotal(category: viewModel.fixedCategories[ItemType.income.description])
            cell.backgroundColor = CustomColors.green
        } else {
            cell.nameLabel.text = viewModel.otherExpenses[indexPath.item].name
            total = viewModel.calcCategoryTotal(category: viewModel.otherExpenses[indexPath.item])
            cell.backgroundColor = colors[indexPath.item % 8]
        }
        cell.totalLabel.text = CommonObjects.shared.formattedCurrency(with: Double(total)!) // Format total into currency
        cell.editingEnabled = collectionView.allowsMultipleSelection
        cell.setupSubviews()
        if selectedCategories.map({ $0.name }).contains(cell.nameLabel.text) { cell.toggleCheckMark() }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width * 0.36, height: view.frame.width * 0.36)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: section == 0 ? 75 : 30, left: 40 * windowWidthScale, bottom: 20, right: 40 * windowWidthScale)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var selectedCategory: Category?
        if viewModel.fixedCategories.count > 0 && indexPath.section == 0 {
            selectedCategory = viewModel.fixedCategories[ItemType.income.description]
        } else {
            selectedCategory = viewModel.otherExpenses[indexPath.item]
        }
        
        // If "allowsMultipleSelection" is true then the collection view is in editing mode, otherwise selecting a cell pushes the category table view controller
        switch collectionView.allowsMultipleSelection {
        case false:
            let categoryVC = CategoryViewController(month: viewModel.month, category: selectedCategory)
            categoryVC.delegate = self
            let navVC = UINavigationController(rootViewController: categoryVC)
            navVC.modalPresentationStyle = .overCurrentContext
            present(navVC, animated: true)
        case true:
            guard let cell = collectionView.cellForItem(at: indexPath) as? CategoryCell else { return }
            
            // If the category has already been selected then it deselects the cell, otherwise it gets appended to selected categories
            if let selectedCategoryIndex = selectedCategories.firstIndex(of: selectedCategory!) {
                selectedCategories.remove(at: selectedCategoryIndex)
            } else {
                selectedCategories.append(selectedCategory!)
            }
            collectionView.deselectItem(at: indexPath, animated: true)
            cell.toggleCheckMark()
        }
    }
    
    /// Gets called when the "Edit" nav bar button is pressed.
    @objc private func editCollectionView() {
        collectionView.allowsMultipleSelection = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(finishEditingCollectionView))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteSelectedItems))
        navigationItem.hidesBackButton = true
        collectionView.reloadData()
    }
    /// Gets called when the user either cancels or finishes editing the collection view. Restores the UI and empties the selected categories array.
    @objc private func finishEditingCollectionView() {
        collectionView.allowsMultipleSelection = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editCollectionView))
        navigationItem.leftBarButtonItem = .none
        navigationItem.hidesBackButton = false
        collectionView.reloadData()
        selectedCategories.removeAll()
    }
    
    @objc private func deleteSelectedItems() {
        if selectedCategories.count > 0 {
            selectedCategories.forEach({ viewModel.deleteCategory(category: $0) })
            viewModel.fetchData()
        }
        finishEditingCollectionView()
    }
    
    // MARK:- Selectors
    /// Gets called when the plus button is pressed. Presents a new category table view controller.
    @objc func addCategory() {
        let categoryVC = CategoryViewController(month: viewModel.month)
        categoryVC.delegate = self
        let navVC = UINavigationController(rootViewController: categoryVC)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true)
    }
}

// MARK:- Category View Controller Delegate

extension MonthViewController: CategoryViewControllerDelegate {
    
    func categoryChanged() {
        viewModel.fetchData()
        collectionView.reloadData()
        if viewModel.fixedCategories.isEmpty && viewModel.otherExpenses.isEmpty {
            centerTextView.removeFromSuperview()
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
}

// MARK:- Section Header

class SectionHeader: UICollectionReusableView {
    
    var nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = CustomColors.label
        lbl.font = UIFont.boldSystemFont(ofSize: 22 * fontScale)
        return lbl
    }()
    
    func setupUI() {
        addSubview(nameLabel)
        nameLabel.anchor(leading: leadingAnchor, leadingConstant: 10, centerY: centerYAnchor)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
