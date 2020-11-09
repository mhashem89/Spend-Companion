//
//  QuickAddView.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/7/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

protocol QuickAddViewDelegate: class {
    
    func showCategoryTitleVC()
    
    func saveItem(itemStruct: ItemStruct)
    
    func openRecurringWindow()
    
    func showItemNameVC()
}


class QuickAddView: UIView {
    
    let dayPicker = UIDatePicker()
    
    weak var delegate: QuickAddViewDelegate?
    
    var itemRecurrence: ItemRecurrence? {
        didSet {
            if itemRecurrence != nil, !isRecurring {
                isRecurring = true
            }
        }
    }
    
    var quickAddLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Quickly add an item"
        lbl.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 18 * fontScale)
        return lbl
    }()
    
    
    var dayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        label.isUserInteractionEnabled = true
        label.textAlignment = .center
        label.text = "Today"
        label.textColor = CustomColors.label
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 1
        label.layer.borderColor = CustomColors.label.cgColor
        return label
    }()
    
    
    lazy var dayTextField: UITextField = {
        let tf = UITextField()
        tf.tag = 1
        tf.inputView = dayPicker
        tf.tintColor = .clear
        let toolBar = UIToolbar(frame: .init(origin: .zero, size: CGSize(width: frame.width, height: 44 * windowHeightScale)))
        toolBar.sizeToFit()

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        let todayButton = UIBarButtonItem(title: "Today", style: .plain, target: self, action: #selector(todayButtonDayPicker))
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        toolBar.setItems([cancelButton, todayButton, spacer, doneButton], animated: false)
        
        dayPicker.datePickerMode = .date
        dayPicker.addTarget(self, action: #selector(datePicked), for: .valueChanged)
        if #available(iOS 14.0, *) {
            dayPicker.preferredDatePickerStyle = .wheels
        }
        tf.inputView = dayPicker
        tf.inputAccessoryView = toolBar
        
        return tf
    }()
    
    let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl()
        sc.insertSegment(withTitle: "Expense", at: 0, animated: false)
        sc.insertSegment(withTitle: "Income", at: 1, animated: false)
        sc.layer.borderWidth = 1
        sc.layer.borderColor = UIColor.clear.cgColor
        sc.isSelected = false
        sc.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 15 * fontScale)], for: .normal)
        return sc
    }()
    
    var categoryLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Category"
        lbl.textAlignment = .center
        lbl.isUserInteractionEnabled = true
        lbl.textColor = CustomColors.darkGray
        lbl.font = UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        lbl.layer.cornerRadius = 5
        lbl.clipsToBounds = true
        lbl.layer.borderWidth = 1
        lbl.layer.borderColor = CustomColors.label.cgColor
        lbl.alpha = 0
        return lbl
    }()
    
    var recurringCircleButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13, *) {
            button.setImage(UIImage(systemName: "arrow.clockwise.circle"), for: .normal)
        } else {
            button.setAttributedTitle(NSAttributedString(string: "⟳", attributes: [.font: UIFont.boldSystemFont(ofSize: 18)]), for: .normal)
        }
        return button
    }()
    
    lazy var detailLabel: UILabel = {
        let lbl = UILabel()
        lbl.tag = 2
        lbl.font = UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        lbl.text = "Description"
        lbl.textColor = CustomColors.darkGray
        lbl.textAlignment = .center
        lbl.layer.cornerRadius = 5
        lbl.clipsToBounds = true
        lbl.layer.borderWidth = 1
        lbl.layer.borderColor = CustomColors.label.cgColor
        lbl.isUserInteractionEnabled = true
        return lbl
    }()
    
    lazy var amountTextField: UITextField = {
        let tf = UITextField()
        tf.tag = 3
        tf.font = UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        tf.placeholder = "\(CommonObjects.shared.currencySymbol.symbol ?? "")...    "
        tf.textAlignment = .center
        tf.keyboardType = .decimalPad
        tf.layer.cornerRadius = 5
        tf.layer.borderWidth = 1
        tf.layer.borderColor = CustomColors.label.cgColor
        tf.delegate = self
        return tf
    }()
    
    var recurringButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13, *) {
            button.setImage(UIImage(systemName: "square"), for: .normal)
        }
        return button
    }()
    
    
    var saveButton: UIButton = {
        let button = UIButton(type: .system)
        let saveString = NSAttributedString(string: "Save", attributes: [.font: UIFont.boldSystemFont(ofSize: 22 * fontScale), .foregroundColor: UIColor.white])
        button.setAttributedTitle(saveString, for: .normal)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.backgroundColor = .systemBlue
        return button
    }()
    
    var dayPickerDate: Date?
    
    var upperStack: UIStackView!
    var lowerStack: UIStackView!
    
    var isRecurring: Bool = false {
        didSet {
            if #available(iOS 13, *) {
                recurringButton.setImage(UIImage(systemName: isRecurring ? "checkmark.square" : "square"), for: .normal)
            } else {
                recurringButton.setAttributedTitle(NSAttributedString(string: isRecurring ? "☑ Recurring" : "▢ Recurring", attributes: [.font: UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale), .foregroundColor: UIColor.black]), for: .normal)
            }
            switch isRecurring {
            case true:
                upperStack.insertArrangedSubview(recurringCircleButton, at: 2)
            case false:
                recurringCircleButton.removeFromSuperview()
                itemRecurrence = nil
            }
        }
    }
        
    
    
// MARK:- UI Methods
    
    @objc func isRecurringToggle() {
        if isRecurring {
            isRecurring = false
        } else {
            let tap = UITapGestureRecognizer(target: self, action: #selector(periodLabelTap))
            recurringCircleButton.addGestureRecognizer(tap)
            delegate?.openRecurringWindow()
        }
    }
    
    @objc func periodLabelTap() {
        delegate?.openRecurringWindow()
    }
    
    @objc func datePicked() {
        if dayPicker.date.dayMatches(Date()) {
            dayLabel.text = "Today"
        } else {
            dayLabel.text = DateFormatters.fullDateFormatter.string(from: dayPicker.date)
        }
        dayLabel.textColor = CustomColors.label
        dayLabel.layer.borderColor = CustomColors.label.cgColor
    }
    
    @objc func handleSegmentedControl() {
        segmentedControl.layer.borderColor = UIColor.clear.cgColor
        segmentedControl.isSelected = true
        switch segmentedControl.selectedSegmentIndex {
        case 1:
            categoryLabel.alpha = 0
        case 0:
            categoryLabel.alpha = 1
        default:
            break
        }
    }
    
    private func setupAmountToolbar() {
        let toolBar = UIToolbar(frame: .init(origin: .zero, size: CGSize(width: frame.width, height: 44 * windowHeightScale)))
        toolBar.sizeToFit()
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolBar.setItems([cancelButton, spacer, doneButton], animated: false)
        amountTextField.inputAccessoryView = toolBar
    }
    
    
    @objc private func doneButtonPressed() {
        if dayTextField.isFirstResponder {
            dayTextField.resignFirstResponder()
            dayPickerDate = dayPicker.date
            dayLabel.layer.borderColor = CustomColors.label.cgColor
            showSaveButton()
        } else if amountTextField.isFirstResponder {
            amountTextField.resignFirstResponder()
        }
    }
    
    @objc func todayButtonDayPicker() {
        dayPicker.date = Date()
        dayLabel.text = "Today"
    }
    
    @objc private func cancelButtonPressed() {
        if amountTextField.isFirstResponder {
            amountTextField.resignFirstResponder()
        } else if dayTextField.isFirstResponder {
            dayLabel.text = dayPickerDate == nil ? "Today" : DateFormatters.fullDateFormatter.string(from: dayPickerDate!)
            dayTextField.resignFirstResponder()
        }
    }
    
    
    @objc func chooseCategory() {
        delegate?.showCategoryTitleVC()
        resignFirstResponders()
    }
    
    @objc func chooseItemName() {
        delegate?.showItemNameVC()
    }
    
    func showSaveButton() {
        if !lowerStack.arrangedSubviews.contains(saveButton) {
            lowerStack.insertArrangedSubview(saveButton, at: 2)
        }
    }
    
    func updateCurrencySymbol() {
        amountTextField.placeholder = "\(CommonObjects.shared.currencySymbol.symbol ?? "")..    "
    }
    
    func resignFirstResponders() {
        if dayTextField.isFirstResponder {
            dayTextField.resignFirstResponder()
        }
        if amountTextField.isFirstResponder {
            amountTextField.resignFirstResponder()
        }
    }
    
    @objc func saveButtonPressed() {
        
        guard segmentedControl.isSelected,
              let type = ItemType(rawValue: Int16(segmentedControl.selectedSegmentIndex))
        else {
            segmentedControl.layer.borderColor = UIColor.red.cgColor
            return
        }
        guard let amountString = amountTextField.text, let amount = Double(amountString) else {
            amountTextField.layer.borderColor = UIColor.red.cgColor
            return
        }
        
        var category: String?
        switch type {
        case .spending:
            category = categoryLabel.text == "Category" ? nil : categoryLabel.text
        case .income:
            category = "Income"
        }
        let itemStruct = ItemStruct(amount: amount, type: type, date: dayLabel.text ?? "Today", detail: detailLabel.text, itemRecurrence: self.itemRecurrence, categoryName: category)
        amountTextField.resignFirstResponder()
        delegate?.saveItem(itemStruct: itemStruct)
    }
    
    func clearView() {
        dayTextField.text = nil
        detailLabel.text = "Description"
        detailLabel.textColor = CustomColors.darkGray
        segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        segmentedControl.isSelected = false
        amountTextField.text = nil
        saveButton.removeFromSuperview()
        isRecurring = false
        categoryLabel.text = "Category"
        categoryLabel.textColor = CustomColors.darkGray
        categoryLabel.alpha = 0
        recurringCircleButton.isHidden = true
    }
    
    func setupUI() {
        backgroundColor = CustomColors.systemBackground
        let width = frame.width * 0.4
        let height: CGFloat = 40 * windowHeightScale
        setupAmountToolbar()
        segmentedControl.addTarget(self, action: #selector(self.handleSegmentedControl), for: .valueChanged)
        upperStack = UIStackView(arrangedSubviews: [detailLabel, recurringButton])
        lowerStack = UIStackView(arrangedSubviews: [amountTextField, categoryLabel])
        upperStack.axis = .horizontal; upperStack.spacing = 10 * windowWidthScale
        lowerStack.axis = .horizontal; lowerStack.spacing = 10 * windowWidthScale
        
        addSubviews([quickAddLabel, dayLabel, dayTextField, segmentedControl, upperStack, lowerStack])
        
        categoryLabel.anchor(widthConstant: fontScale < 1 ? min(frame.width * 0.25, 125) : 95 * windowWidthScale, heightConstant: height)
        segmentedControl.anchor(widthConstant: frame.width * 0.5, heightConstant: height)
        detailLabel.anchor(widthConstant: width, heightConstant: height)
        amountTextField.anchor(widthConstant: width, heightConstant: height)
        saveButton.anchor(widthConstant: fontScale < 1 ? min(frame.width * 0.25, 125) : 95 * windowWidthScale, heightConstant: height)
        
        quickAddLabel.anchor(top: topAnchor, topConstant: 5, leading: safeAreaLayoutGuide.leadingAnchor, leadingConstant: 10 * windowWidthScale)
        dayLabel.anchor(top: quickAddLabel.bottomAnchor, topConstant: 15, leading: leadingAnchor, leadingConstant: frame.width * 0.036, widthConstant: width, heightConstant: height)
        dayTextField.anchor(top: quickAddLabel.bottomAnchor, topConstant: 15, leading: leadingAnchor, leadingConstant: frame.width * 0.036, widthConstant: width, heightConstant: height)
        if #available(iOS 13, *) {
            let title = NSAttributedString(string: "Recurring", attributes: [.font: UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)])
            recurringButton.setAttributedTitle(title, for: .normal)
        } else {
            let title = NSAttributedString(string: "▢ Recurring", attributes: [.font: UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale), .foregroundColor: UIColor.black])
            recurringButton.setAttributedTitle(title, for: .normal)
        }

        recurringButton.contentHorizontalAlignment = .left
        if windowWidthScale < 1 { recurringButton.imageEdgeInsets = UIEdgeInsets(top: 1 / windowWidthScale, left: 1 / windowWidthScale, bottom: 1 / windowWidthScale, right: 1 / windowWidthScale) }
        upperStack.anchor(top: dayLabel.bottomAnchor, topConstant: 10, leading: dayLabel.leadingAnchor)
        segmentedControl.anchor(top: dayLabel.topAnchor, leading: dayLabel.trailingAnchor, leadingConstant: 10)
        lowerStack.anchor(top: upperStack.bottomAnchor, topConstant: 10, leading: dayLabel.leadingAnchor)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.chooseCategory))
        categoryLabel.addGestureRecognizer(tap)
        
        saveButton.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        recurringButton.addTarget(self, action: #selector(isRecurringToggle), for: .touchUpInside)
        
        let itemTap = UITapGestureRecognizer(target: self, action: #selector(chooseItemName))
        detailLabel.addGestureRecognizer(itemTap)
    }
    
}


// MARK:- UITextField Delegate

extension QuickAddView: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return false }
        let currentString: NSString = text as NSString
        let newString = currentString.replacingCharacters(in: range, with: string) as NSString
        textField.layer.borderColor = CustomColors.label.cgColor
        showSaveButton()
        switch textField {
        case amountTextField:
            return newString.length < 8
        default:
            return true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
}
