//
//  MonthViewController.swift
//  Spending App
//
//  Created by Mohamed Hashem on 8/18/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

class MonthViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, CategoryViewControllerDelegate, MonthViewModelDelegate {
    
    
    func categoryChanged() {
        viewModel.fetchData()
        collectionView.reloadData()
        if viewModel.dataFetcher.fetchedObjects != nil, viewModel.dataFetcher.fetchedObjects!.count > 0 {
            centerTextView.removeFromSuperview()
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    
    // MARK:- Properties
    
    var cellId = "cellId"
    var headerId = "HeaderId"
    var viewModel: MonthViewModel!
    var colors: [UIColor] = [CustomColors.blue, CustomColors.indigo, CustomColors.orange, CustomColors.pink, CustomColors.purple, CustomColors.red, CustomColors.teal, CustomColors.yellow]
    var labels = ["Income", "Recurring Expenses"]
    
    var selectedCategories = [Category]()
    
    var monthString: String!
    
    var plusButton: UIButton = {
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
    
    let centerTextView = UITextView()
    
    // MARK:- Lifecycle Methods
    
    init(monthString: String) {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        self.monthString = monthString
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = MonthViewModel(monthString: monthString)
        self.viewModel.delegate = self
        self.viewModel.fetchData()
        view.addSubview(plusButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editCollectionView))
        plusButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, topConstant: 15, trailing: view.trailingAnchor, trailingConstant: 20, widthConstant: 40, heightConstant: 40)
        plusButton.addTarget(self, action: #selector(self.addCategory), for: .touchUpInside)
        
        collectionView.backgroundColor = CustomColors.systemBackground
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = viewModel.month.date
        navigationController?.navigationBar.isHidden = false
        tabBarController?.tabBar.isHidden = true
        
        if viewModel.dataFetcher.fetchedObjects == nil || viewModel.dataFetcher.fetchedObjects?.count == 0 {
            centerTextView.font = UIFont.boldSystemFont(ofSize: 20)
            centerTextView.textColor = CustomColors.darkGray
            centerTextView.text = "Press the plus button to start adding categories"
            centerTextView.textAlignment =  .center
            centerTextView.isEditable = false
            view.addSubview(centerTextView)
            centerTextView.anchor(centerX: view.centerXAnchor, centerY: view.centerYAnchor, widthConstant: view.frame.width * 0.8, heightConstant: view.frame.height * 0.1)
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
        
    }
    
    
    
    // MARK:- Collection View Methods
    
    @objc func editCollectionView() {
        collectionView.allowsMultipleSelection = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelEditingCollectionView))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteSelectedItems))
        navigationItem.hidesBackButton = true
        collectionView.reloadData()
    }
    
    @objc func cancelEditingCollectionView() {
        collectionView.allowsMultipleSelection = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editCollectionView))
        navigationItem.leftBarButtonItem = .none
        navigationItem.hidesBackButton = false
        collectionView.reloadData()
        selectedCategories.removeAll()
    }
    
    @objc func deleteSelectedItems() {
        if selectedCategories.count > 0 {
            for category in selectedCategories {
                viewModel.deleteCategory(category: category)
            }
            viewModel.fetchData()
        }
        cancelEditingCollectionView()
    }
    
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
            switch section {
            case 0:
                return viewModel.fixedCategories.count
            case 1:
                return viewModel.otherExpenses.count
            default:
                return 0
            }
        } else {
            return viewModel.otherExpenses.count
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! CategoryCell
        cell.addBorderShadow()
        var total: String = "0"
        if viewModel.fixedCategories.count > 0 {
            switch indexPath.section {
            case 0:
                let categoryNames = viewModel.fixedCategories.keys.map({ String($0) }).sorted(by: { $0 < $1 })
                let categoryName = categoryNames[indexPath.item]
                cell.nameLabel.text = categoryName
                total = viewModel.calcCategoryTotal(category: viewModel.fixedCategories[categoryName])
                cell.backgroundColor = CustomColors.green
            case 1:
                cell.nameLabel.text = viewModel.otherExpenses[indexPath.item].name
                total = viewModel.calcCategoryTotal(category: viewModel.otherExpenses[indexPath.item])
                cell.backgroundColor = colors[indexPath.item]
            default:
                break
            }
        } else {
            cell.nameLabel.text = viewModel.otherExpenses[indexPath.item].name
            total = viewModel.calcCategoryTotal(category: viewModel.otherExpenses[indexPath.item])
            cell.backgroundColor = colors[indexPath.item]
        }
        cell.totalLabel.text = CommonObjects.shared.formattedCurrency(with: Double(total)!)
        cell.editingEnabled = collectionView.allowsMultipleSelection
        cell.setupSubviews()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width * 0.36, height: view.frame.width * 0.36)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: section == 0 ? 75 : 30, left: 40 * viewsWidthScale, bottom: 20, right: 40 * viewsWidthScale)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var category: Category?
        if viewModel.fixedCategories.count > 0 {
            let categoryNames = viewModel.fixedCategories.keys.map({ String($0) }).sorted(by: { $0 < $1 })
            switch indexPath.section {
            case 0:
                let categoryName = categoryNames[indexPath.item]
                category = viewModel.fixedCategories[categoryName]
            case 1:
                category = viewModel.otherExpenses[indexPath.item]
            default:
                break
            }
        } else {
            category = viewModel.otherExpenses[indexPath.item]
        }
        
        switch collectionView.allowsMultipleSelection {
        case false:
            let categoryVC = CategoryViewController(month: viewModel.month, category: category)
            categoryVC.delegate = self
            let navVC = UINavigationController(rootViewController: categoryVC)
            navVC.modalPresentationStyle = .overCurrentContext
            present(navVC, animated: true)
        case true:
            let cell = collectionView.cellForItem(at: indexPath) as! CategoryCell
            if let selectedCategoryIndex = selectedCategories.firstIndex(of: category!) {
                selectedCategories.remove(at: selectedCategoryIndex)
            } else {
                selectedCategories.append(category!)
            }
            collectionView.deselectItem(at: indexPath, animated: true)
            cell.toggleCheckMark()
        }
        
    }
    
    
    // MARK:- Selectors
       
    @objc func addCategory() {
        let categoryVC = CategoryViewController(month: viewModel.month)
        categoryVC.delegate = self
        let navVC = UINavigationController(rootViewController: categoryVC)
        present(navVC, animated: true)
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
