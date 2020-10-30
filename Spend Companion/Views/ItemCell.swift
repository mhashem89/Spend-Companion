//
//  ItemCell.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/2/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit


protocol ItemCellDelegate: class {
    func donePressedInDayPicker(selected day: Int, for cell: ItemCell)
    func detailTextFieldReturn(text: String, for cell: ItemCell, withMessage: Bool)
    func amountTextFieldReturn(amount: Double, for cell: ItemCell, withMessage: Bool)
    func dataChanged()
    func editingStarted(in textField: UITextField, of cell: ItemCell)
    func recurrenceButtonPressed(in cell: ItemCell)
}


class ItemCell: UITableViewCell, UITextFieldDelegate {
        
// MARK:- Properties
    
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
        let toolBar = UIToolbar()
        toolBar.sizeToFit()

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
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
        return button
    }()
    
    
    
    lazy var amountTextField: UITextField = {
        let tf = UITextField()
        tf.tag = 3
        tf.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        tf.placeholder = "...     "
        if currencySymbol.position == .left {
            tf.addLeftPadding(10, withSymbol: currencySymbol.symbol)
        } else {
            tf.addRightPadding(10, withSymbol: currencySymbol.symbol)
        }
        
        tf.keyboardType = .decimalPad
        return tf
    }()
    
    var verticalSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = CustomColors.darkGray
        return view
    }()
    
    var userCurrency: String? {
        return UserDefaults.standard.value(forKey: "currency") as? String
    }
    
    var currencySymbol: (symbol: String, position: CurrencyPosition) {
        if let storedCurrency = userCurrency, let currencyPosition = CurrencyViewController.currenciesDict[storedCurrency] {
            return (CurrencyViewController.extractSymbol(from: storedCurrency), currencyPosition)
        } else {
            return ("$", .left)
        }
    }
    
    let dayPicker = UIPickerView()
    
    weak var delegate: ItemCellDelegate?
    
    var setupUIDone: Bool = false
    
    var detailTextChanged: Bool = false
    
    var amountTextChanged: Bool = false
    
    
// MARK:- Methods
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setupUI() {
        if !setupUIDone {
            addSubviews([dayLabel, dayTextField, detailTextField, amountTextField])
            dayLabel.anchor(leading: leadingAnchor, leadingConstant: frame.width * 0.05, centerY: centerYAnchor)
            dayTextField.anchor(top: topAnchor, leading: leadingAnchor, widthConstant: frame.width * 0.25, heightConstant: frame.height)
            detailTextField.anchor(leading: leadingAnchor, leadingConstant: frame.width * 0.27, centerY: centerYAnchor)
            amountTextField.anchor(leading: leadingAnchor, leadingConstant: frame.width * 0.78, centerY: centerYAnchor)
            addVerticalSeparator(for: dayLabel)
            addVerticalSeparator(for: detailTextField)
                    
            detailTextField.delegate = self
            amountTextField.delegate = self
            dayTextField.delegate = self
            
            setupAmountToolbar()
            setupUIDone = true
        }
        
    }
    
    private func setupAmountToolbar() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneEnteringAmount))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolBar.setItems([cancelButton, spacer, doneButton], animated: false)
        amountTextField.inputAccessoryView = toolBar
    }
    
    private func addVerticalSeparator(for view: UIView) {
        let separator = UIView()
        addSubview(separator)
        separator.backgroundColor = CustomColors.darkGray
        separator.anchor(centerX: centerXAnchor, centerXConstant: view == dayLabel ? -frame.width * 0.25 : frame.width * 0.26, centerY: centerYAnchor, widthConstant: 0.5, heightConstant: frame.height * 0.8)
    }
    
    func addRecurrence(period: Int, unit: RecurringUnit) {
        addSubview(recurringCircleButton)
        recurringCircleButton.anchor(trailing: trailingAnchor, trailingConstant: frame.width * 0.25, centerY: centerYAnchor)
        recurringCircleButton.addTarget(self, action: #selector(recurrenceButtonPressed), for: .touchUpInside)
    }
    
    @objc func recurrenceButtonPressed() {
        delegate?.recurrenceButtonPressed(in: self)
    }

    @objc private func doneButtonPressed() {
        delegate?.donePressedInDayPicker(selected: dayPicker.selectedRow(inComponent: 0), for: self)
        dayTextField.resignFirstResponder()
        delegate?.dataChanged()
    }
    
    @objc private func cancelButtonPressed() {
        if amountTextField.isFirstResponder {
            amountTextField.resignFirstResponder()
        } else if dayTextField.isFirstResponder {
            dayTextField.resignFirstResponder()
        }
    }
    
    @objc private func doneEnteringAmount() {
        amountTextField.resignFirstResponder()
        guard let text = amountTextField.text, let amount = Double(text) else { return }
        delegate?.amountTextFieldReturn(amount: amount, for: self, withMessage: subviews.contains(recurringCircleButton) && amountTextChanged)
        amountTextChanged = false
        delegate?.dataChanged()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            backgroundColor = #colorLiteral(red: 0.7977350321, green: 0.7977350321, blue: 0.7977350321, alpha: 0.3016909247)
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
    
    
// MARK:- TextField Delegate
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.editingStarted(in: textField, of: self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return false }
        if textField == detailTextField {
            detailTextField.resignFirstResponder()
            delegate?.detailTextFieldReturn(text: text, for: self, withMessage: subviews.contains(recurringCircleButton) && detailTextChanged)
            detailTextChanged = false
        }
        return true
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else { return }
        switch textField {
        case detailTextField:
            delegate?.detailTextFieldReturn(text: text, for: self, withMessage: false)
            delegate?.dataChanged()
        case amountTextField:
            guard let amount = Double(text) else { return }
            delegate?.amountTextFieldReturn(amount: amount, for: self, withMessage: false)
            delegate?.dataChanged()
        case dayTextField:
            dayTextField.backgroundColor = .clear
            dayLabel.textColor = .systemBlue
        default:
            return
        }
        return
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentString: NSString = textField.text! as NSString
        let newString = currentString.replacingCharacters(in: range, with: string) as NSString
        switch textField {
        case detailTextField:
            delegate?.detailTextFieldReturn(text: newString as String, for: self, withMessage: false)
            delegate?.dataChanged()
            detailTextChanged = true
            return newString.length < 18
        case amountTextField:
            if let amount = Double(newString as String) {
                delegate?.amountTextFieldReturn(amount: amount, for: self, withMessage: false)
            }
            amountTextChanged = true
            delegate?.dataChanged()
            return newString.length < 8
        default:
            return true
        }
        
    }
    
}


