//
//  ItemCell.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/2/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

protocol ItemCellDelegate: class {
    /// Called when the user presses "Done" after choosing the item date. Passes to the delegate the selected day index and a reference to the  cell.
    func donePressedInDayPicker(selected day: Int, for cell: ItemCell)
    /// Tells the delegate that the detail textfield has returned and passes reference to the cell. If the item has future similar items then it tells the delegate to display an alert message to the user asking whether to apply the change to future items.
    func detailTextFieldReturn(text: String, for cell: ItemCell, withMessage: Bool)
    /// Tells the delegate that the amount textfield has returned and passes reference to the cell. If the item has future similar items then it tells the delegate to display an alert message to the user asking whether to apply the change to future items.
    func amountTextFieldReturn(amount: Double, for cell: ItemCell, withMessage: Bool)
    /// Tells the delegate when any data is changed in order to enable the "Save" button.
    func dataDidChange()
    /// Tells the delegate that editing has started in a textfield in a particular cell. Passes reference to the cell in order to highlight it.
    func editingStarted(in textField: UITextField, of cell: ItemCell)
    /// Tells the delegate that circular recurrence button is pressed to show the recurrence view controller
    func recurrenceButtonPressed(in cell: ItemCell)
}

class ItemCell: UITableViewCell {
        
// MARK:- Properties
        
    let dayPicker = UIPickerView() // The picker to choose the item date
    weak var delegate: ItemCellDelegate?
    var setupUIDone: Bool = false // Boolean to keep track if the cell has already been used, if true it means the cell is dequed
    var detailTextChanged: Bool = false // Boolean to keep track of changes in detail textfield
    var amountTextChanged: Bool = false // Boolean to keep track of changes in amount textfield
    var amountString: String? // Keep track of the value in the amount textfield to restore it if the user presses cancel
    
    // MARK:- Subviews
    
    var dayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        label.isUserInteractionEnabled = true
        label.textAlignment = .left
        return label
    }()
    
    lazy var dayTextField: UITextField = {
        let tf = UITextField()
        tf.tag = 1
        tf.inputView = dayPicker
        tf.tintColor = .clear
        let toolBar = UIToolbar(frame: .init(origin: .zero, size: CGSize(width: frame.width, height: 44 * windowHeightScale)))
        toolBar.sizeToFit()
        toolBar.backgroundColor = CustomColors.mediumGray
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDayPicker))
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        toolBar.setItems([cancelButton, spacer, doneButton], animated: false)
        
        tf.inputAccessoryView = toolBar
        return tf
    }()
    
    var detailTextField: UITextField = {
        let tf = UITextField()
        tf.tag = 2
        tf.placeholder = "Enter details here..."
        tf.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        tf.textColor = CustomColors.label
        tf.returnKeyType = .done
        return tf
    }()
    
    var recurringCircleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setAttributedTitle(NSAttributedString(string: "⟳", attributes: [.font: UIFont.boldSystemFont(ofSize: 34 * fontScale)]), for: .normal)
        button.isHidden = true
        return button
    }()
    
    lazy var amountTextField: UITextField = {
        let tf = UITextField()
        tf.tag = 3
        tf.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        tf.placeholder = "...     "
        let currencySymbol = CommonObjects.shared.currencySymbol
        if currencySymbol.position == .left {
            tf.addLeftPadding(withSymbol: currencySymbol.symbol, withFontSize: fontScale < 1 ? 14 : 16 * fontScale)
        } else {
            tf.addRightPadding(withSymbol: currencySymbol.symbol, withFontSize: fontScale < 1 ? 14 : 16 * fontScale)
        }
        tf.keyboardType = .decimalPad
        tf.inputAccessoryView = setupAmountToolbar()
        return tf
    }()
    
    var verticalSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = CustomColors.darkGray
        return view
    }()
    
    
// MARK:- Life Cycle Methods
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
// MARK:- UI Methods
    
    func setupUI() {
        if !setupUIDone {
            
            // Add all the subviews
            addSubviews([dayLabel, dayTextField, detailTextField, amountTextField, recurringCircleButton])
            
            dayLabel.anchor(leading: leadingAnchor, leadingConstant: frame.width * 0.05, centerY: centerYAnchor)
            dayTextField.anchor(top: topAnchor, leading: leadingAnchor, widthConstant: frame.width * 0.25, heightConstant: frame.height)
            detailTextField.anchor(leading: leadingAnchor, leadingConstant: frame.width * 0.27, centerY: centerYAnchor)
            amountTextField.anchor(leading: leadingAnchor, leadingConstant: frame.width * 0.78, centerY: centerYAnchor)
            recurringCircleButton.anchor(trailing: trailingAnchor, trailingConstant: frame.width * 0.25, centerY: centerYAnchor)
            
            addVerticalSeparator(for: dayLabel)
            addVerticalSeparator(for: detailTextField)
               
            [detailTextField, amountTextField, dayTextField].forEach({ $0.delegate = self })
            
            recurringCircleButton.addTarget(self, action: #selector(recurrenceButtonPressed), for: .touchUpInside)
            setupUIDone = true
        }
    }
    /// Configures the subviews to display data from the item
    func configure(for item: Item?) {
        if let itemDate = item?.date {
            dayLabel.text = itemDate.dayMatches(Date()) ? "Today" : DateFormatters.fullDateWithLetters.string(from: itemDate).extractDate()
        } else {
            dayLabel.text = "Today"
        }
        dayLabel.textColor = CustomColors.label
        detailTextField.text = item?.detail
        if let amount = item?.amount, amount > 0.0 {
            amountTextField.text = String(format: "%g", (amount * 100).rounded() / 100)
            amountString = amountTextField.text
        } else {
            amountTextField.text = nil
        }
        recurringCircleButton.isHidden = item?.recurringNum == nil && item?.recurringUnit == nil
    }
    
    /// Returns the toolbar used as an accessory view to the amount textfield
    private func setupAmountToolbar() -> UIToolbar {
        let toolBar = UIToolbar(frame: .init(origin: .zero, size: CGSize(width: frame.width, height: 44 * windowHeightScale)))
        toolBar.sizeToFit()
        toolBar.backgroundColor = CustomColors.mediumGray
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneEnteringAmount))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolBar.setItems([cancelButton, spacer, doneButton], animated: false)
        return toolBar
    }
    /// Adds vertical line after the subview
    private func addVerticalSeparator(for view: UIView) {
        let separator = UIView()
        addSubview(separator)
        separator.backgroundColor = CustomColors.darkGray
        separator.anchor(centerX: centerXAnchor, centerXConstant: view == dayLabel ? -frame.width * 0.25 : frame.width * 0.26, centerY: centerYAnchor, widthConstant: 0.5, heightConstant: frame.height * 0.8)
    }
    
    func resignFirstResponders() {
        [dayTextField, amountTextField, detailTextField].forEach { (textField) in
            if textField.isFirstResponder { textField.resignFirstResponder() }
        }
    }
    /// Gets called when circle recurrence button is pressed and calls the delegate.
    @objc func recurrenceButtonPressed() {
        delegate?.recurrenceButtonPressed(in: self)
    }
    /// Gets called when the "Done" button in day picker is pressed.
    @objc private func doneDayPicker() {
        delegate?.donePressedInDayPicker(selected: dayPicker.selectedRow(inComponent: 0), for: self)
        dayTextField.resignFirstResponder()
        delegate?.dataDidChange()
    }
    /// Gets called when the "Cancel" button in day picker is pressed.
    @objc private func cancelButtonPressed() {
        if amountTextField.isFirstResponder {
            amountTextField.text = amountString
            amountTextChanged = false
            amountTextField.resignFirstResponder()
        } else if dayTextField.isFirstResponder {
            dayTextField.resignFirstResponder()
        }
    }
    
    @objc private func doneEnteringAmount() {
        amountTextField.resignFirstResponder()
    }
    /// The changes needed to highlight the cell, including highlight color and changing font color to blue
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            backgroundColor = CustomColors.lightGray
            dayLabel.textColor = .systemBlue
            detailTextField.textColor = .systemBlue
            amountTextField.textColor = .systemBlue
            (amountTextField.leftView?.subviews.first as? UILabel)?.textColor = .systemBlue
            (amountTextField.rightView?.subviews.first as? UILabel)?.textColor = .systemBlue
        } else {
            backgroundColor = CustomColors.systemBackground
            dayLabel.textColor = dayLabel.text == "Day" ? CustomColors.mediumGray : CustomColors.label
            detailTextField.textColor = CustomColors.label
            amountTextField.textColor = CustomColors.label
            (amountTextField.leftView?.subviews.first as? UILabel)?.textColor = amountTextField.hasText ? CustomColors.label : CustomColors.mediumGray
            (amountTextField.rightView?.subviews.first as? UILabel)?.textColor = amountTextField.hasText ? CustomColors.label : CustomColors.mediumGray
        }
    }
}

extension ItemCell: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.editingStarted(in: textField, of: self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text, !text.isEmpty else { return }
        switch textField { // if either detail or amount textField end editing, sends the changes to the delegate
        case detailTextField:
            if detailTextChanged {
                delegate?.detailTextFieldReturn(text: text, for: self, withMessage: !recurringCircleButton.isHidden && detailTextChanged)
                detailTextChanged = false
            }
        case amountTextField:
            guard let amount = Double(text) else { return }
            if amountTextChanged {
                delegate?.amountTextFieldReturn(amount: amount, for: self, withMessage: !recurringCircleButton.isHidden && amountTextChanged)
                amountTextChanged = false
                amountString = text
            }
        case dayTextField:
            dayTextField.backgroundColor = .clear
            dayLabel.textColor = .systemBlue
        default:
            return
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return false }
        let currentString: NSString = text as NSString
        let newString = currentString.replacingCharacters(in: range, with: string) as NSString
        delegate?.dataDidChange()
        switch textField {
        case detailTextField:
            detailTextChanged = true
            return newString.length < 18
        case amountTextField:
            amountTextChanged = true
            return newString.length < 8
        default:
            return true
        }
        
    }
}

