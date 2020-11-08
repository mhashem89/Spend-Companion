//
//  RecurringChoiceView.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/13/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit
import StoreKit



protocol RecurringViewControllerDelegate: class {
    
    func recurringViewCancel(viewEmpty: Bool)
    
    func recurringViewDone(with itemRecurrence: ItemRecurrence, new: Bool)
    
}

class RecurringViewController: UIViewController {
    
    weak var delegate: RecurringViewControllerDelegate?
    
    let remindersPurchased = "remindersPurchased"
    
    let iCloudStore = (UIApplication.shared.delegate as! AppDelegate).iCloudKeyStore
    
    let reminderPurchaseProductId = "MohamedHashem.Spend_Companion.reminders_purchase"
    
    let dayPicker = UIDatePicker()
    
    var dataChanged = false
    
    var dayPickerDate: Date?
    
    var upperStack: UIStackView!
    
    var newRecurrence: Bool = true
    
    var questionLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Recurring every:"
        lbl.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale)
        lbl.anchor(heightConstant: fontScale < 1 ? 30 : 30 * fontScale)
        lbl.baselineAdjustment = .alignCenters
        return lbl
    }()
    

    let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl()
        sc.insertSegment(withTitle: "day", at: 0, animated: false)
        sc.insertSegment(withTitle: "week", at: 1, animated: false)
        sc.insertSegment(withTitle: "month", at: 2, animated: false)
        sc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale)], for: .normal)
        sc.layer.borderColor = UIColor.systemRed.cgColor
        return sc
    }()
    
    
    let periodTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter number"
        tf.keyboardType = .numberPad
        tf.backgroundColor = CustomColors.systemBackground
        tf.layer.cornerRadius = 5
        tf.layer.borderColor = CustomColors.label.cgColor
        tf.layer.borderWidth = 1
        tf.addLeftPadding(10)
        tf.font = UIFont.systemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale)
        return tf
    }()
    
    var endDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale)
        label.isUserInteractionEnabled = true
        label.textAlignment = .center
        label.text = "End Date"
        label.textColor = CustomColors.darkGray
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 1
        label.layer.borderColor = CustomColors.label.cgColor
        return label
    }()
    
    var reminderSwitch: UISwitch = {
        let reminder = UISwitch()
        return reminder
    }()
    
    var reminderLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Reminder"
        lbl.font = UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 14 * fontScale)
        return lbl
    }()
    
    var reminderSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl()
        sc.insertSegment(withTitle: "1 day", at: 0, animated: false)
        sc.insertSegment(withTitle: "2 days", at: 1, animated: false)
        sc.insertSegment(withTitle: "3 days", at: 2, animated: false)
        sc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale)], for: .normal)
        sc.layer.borderColor = UIColor.systemRed.cgColor
        return sc
    }()
    
    lazy var endDateTextField: UITextField = {
        let tf = UITextField()
        tf.inputView = dayPicker
        tf.tintColor = .clear
        let toolBar = UIToolbar()
        toolBar.sizeToFit()

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(toolBarDone))
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(toolBarCancel))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        toolBar.setItems([cancelButton, spacer, doneButton], animated: false)
        
        dayPicker.datePickerMode = .date
        if #available(iOS 14.0, *) {
            dayPicker.preferredDatePickerStyle = .wheels
        } 
        dayPicker.addTarget(self, action: #selector(datePicked), for: .valueChanged)
        tf.inputView = dayPicker
        tf.inputAccessoryView = toolBar
        
        return tf
    }()
    
    let restorePurchaseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Restore purchases", for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.setAttributedTitle(NSAttributedString(string: "restore purchase", attributes: [.font: UIFont.systemFont(ofSize: 12)]), for: .normal)
        button.titleLabel?.textAlignment = .center
        return button
    }()
    
    let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.borderColor = CustomColors.label.cgColor
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = 5
        button.setAttributedTitle(NSAttributedString(string: "Cancel", attributes: [.font: UIFont.systemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale), .foregroundColor: UIColor.systemRed]), for: .normal)
        return button
    }()
    
    let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.borderColor = CustomColors.label.cgColor
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = 5
        button.anchor(heightConstant: fontScale < 1 ? 30 : 30 * fontScale)
        button.setAttributedTitle(NSAttributedString(string: "Done", attributes: [.font: UIFont.systemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale)]), for: .normal)
        return button
    }()
    
    
    
// MARK:- Life Cycle Methods
    
    init(itemRecurrence: ItemRecurrence? = nil) {
        super.init(nibName: nil, bundle: nil)
        if let itemRecurrence = itemRecurrence {
            periodTextField.text = String(itemRecurrence.period)
            segmentedControl.selectedSegmentIndex = itemRecurrence.unit.rawValue
            segmentedControl.isSelected = true
            endDateLabel.text = "End: \(DateFormatters.fullDateFormatter.string(from: itemRecurrence.endDate))"
            endDateLabel.textColor = CustomColors.label
            newRecurrence = false
            if let reminderTime = itemRecurrence.reminderTime {
                reminderSwitch.isOn = true
                reminderSegmentedControl.isSelected = true
                reminderSegmentedControl.selectedSegmentIndex = reminderTime - 1
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.backgroundColor = CustomColors.systemBackground.withAlphaComponent(fontScale < 1 ? 1 : 0.6)
        let reminderStack = UIStackView(arrangedSubviews: [reminderSwitch, reminderLabel])
        reminderStack.axis = .horizontal; reminderStack.spacing = 10; reminderStack.alignment = .center
        if #available(iOS 13, *) {} else {
            reminderStack.insertArrangedSubview(restorePurchaseButton, at: 2)
            restorePurchaseButton.addTarget(self, action: #selector(restorePurchase), for: .touchUpInside)
        }
        reminderSwitch.addTarget(self, action: #selector(toggleReminder), for: .touchUpInside)
        upperStack = UIStackView(arrangedSubviews: [questionLabel, periodTextField, segmentedControl, reminderStack, endDateLabel])
        if reminderSwitch.isOn {
            upperStack.insertArrangedSubview(reminderSegmentedControl, at: 4)
        }
        upperStack.axis = .vertical; upperStack.spacing = 15; upperStack.distribution = .fillEqually
        upperStack.anchor(widthConstant: fontScale < 1 ? 200 : 200 * fontScale)
        
        let lowerStack = UIStackView(arrangedSubviews: [cancelButton, doneButton])
        lowerStack.axis = .horizontal; lowerStack.spacing = 15; lowerStack.distribution = .fillEqually
        
        let stack = UIStackView(arrangedSubviews: [upperStack, lowerStack])
        stack.axis = .vertical; stack.spacing = 15
        
        view.addSubview(stack)
        endDateLabel.addSubview(endDateTextField)
        endDateTextField.anchor(top: endDateLabel.topAnchor, leading: endDateLabel.leadingAnchor, trailing: endDateLabel.trailingAnchor, bottom: endDateLabel.bottomAnchor)
        stack.anchor(centerX: view.centerXAnchor, centerY: view.centerYAnchor, centerYConstant: popoverPresentationController?.arrowDirection == .up ? 10 : -10)
        
        segmentedControl.addTarget(self, action: #selector(handleSegmentedControl), for: .valueChanged)
        reminderSegmentedControl.addTarget(self, action: #selector(handleReminderSegmentedControl), for: .valueChanged)
        
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        
        setupAmountToolbar()
        periodTextField.delegate = self
        dayPicker.date = DateFormatters.fullDateFormatter.date(from: endDateLabel.text ?? "") ?? Date()
        SKPaymentQueue.default().add(self)
    }
    
    
// MARK:- UI Methods
    
    private func setupAmountToolbar() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(toolBarCancel))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(toolBarDone))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolBar.setItems([cancelButton, spacer, doneButton], animated: false)
        periodTextField.inputAccessoryView = toolBar
    }
    
    @objc func handleSegmentedControl() {
        segmentedControl.isSelected = true
        segmentedControl.layer.borderWidth = 0
        dataChanged = true
    }
    
    @objc func handleReminderSegmentedControl() {
        reminderSegmentedControl.isSelected = true
        reminderSegmentedControl.layer.borderWidth = 0
        dataChanged = true
    }
    
    @objc func datePicked() {
        endDateLabel.text = "End: \(DateFormatters.fullDateFormatter.string(from: dayPicker.date))"
        endDateLabel.textColor = CustomColors.label
        endDateLabel.layer.borderColor = CustomColors.label.cgColor
        dataChanged = true
    }
    
    @objc func restorePurchase() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    @objc private func toolBarDone() {
        if endDateTextField.isFirstResponder {
            endDateTextField.resignFirstResponder()
            dayPickerDate = dayPicker.date
            endDateLabel.layer.borderColor = CustomColors.label.cgColor
        } else if periodTextField.isFirstResponder {
            periodTextField.resignFirstResponder()
        }
    }
    
    @objc private func toolBarCancel() {
        if endDateTextField.isFirstResponder {
            endDateLabel.text = dayPickerDate == nil ? "End Date" : "End: \(DateFormatters.fullDateFormatter.string(from: dayPickerDate!))"
            endDateTextField.resignFirstResponder()
        } else if periodTextField.isFirstResponder {
            periodTextField.text = nil
            periodTextField.resignFirstResponder()
        }
    }
    
    @objc func toggleReminder() {
        if reminderSwitch.isOn {
            guard iCloudStore.bool(forKey: remindersPurchased) else {
                buyReminders()
                return
            }
            upperStack.insertArrangedSubview(reminderSegmentedControl, at: 4)
        } else {
            reminderSegmentedControl.removeFromSuperview()
        }
        dataChanged = true
    }
    
    func buyReminders() {
        let alertController = UIAlertController(title: "Purchase Reminders", message: "for 0.99 USD (or equivalent in local currency) you can set custom reminders for any recurring transaction", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Puchase", style: .default, handler: { (_) in
            if SKPaymentQueue.canMakePayments() {
                let remindersPayment = SKMutablePayment()
                remindersPayment.productIdentifier = "MohamedHashem.Spend_Companion.reminders_purchase"
                SKPaymentQueue.default().add(remindersPayment)
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { [weak self] (_) in
            self?.reminderSwitch.setOn(false, animated: true)
        }))
        present(alertController, animated: true)
    }
    
    @objc func cancel() {
        delegate?.recurringViewCancel(viewEmpty: !periodTextField.hasText && !segmentedControl.isSelected)
    }
    
    @objc func done() {
        if !dataChanged { delegate?.recurringViewCancel(viewEmpty: false); return }
        
        guard let period = periodTextField.text, let periodNum = Int(period), periodNum > 0 else {
            periodTextField.layer.borderColor = UIColor.systemRed.cgColor
            return
        }
        guard segmentedControl.isSelected, let selectedSegment = RecurringUnit(rawValue: segmentedControl.selectedSegmentIndex) else {
            segmentedControl.layer.borderWidth = 1
            return
        }
        guard let endLabelText = endDateLabel.text?.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true).last, let endDate =  DateFormatters.fullDateFormatter.date(from: String(endLabelText)) else {
            endDateLabel.layer.borderColor = UIColor.systemRed.cgColor
            return
        }
        
        var reminderTime: Int?
        
        if reminderSwitch.isOn && reminderSegmentedControl.isSelected {
            reminderTime = reminderSegmentedControl.selectedSegmentIndex + 1
        } else if reminderSwitch.isOn && !reminderSegmentedControl.isSelected {
            reminderSegmentedControl.layer.borderWidth = 1
            return
        }
        
        delegate?.recurringViewDone(with: ItemRecurrence(period: periodNum, unit: selectedSegment, reminderTime: reminderTime, endDate: endDate), new: newRecurrence)
    }
    
}

// MARK:- Text Field Delegate

extension RecurringViewController: UITextFieldDelegate {
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if !string.isEmpty {
            textField.layer.borderColor = CustomColors.label.cgColor
        }
        dataChanged = true
        return true
    }
    
}

// MARK:- SKPayment Transaction Observer

extension RecurringViewController: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            guard transaction.payment.productIdentifier == reminderPurchaseProductId else { return }
            switch transaction.transactionState {
            case .purchased:
                if iCloudStore.bool(forKey: remindersPurchased) == false {
                    iCloudStore.set(true, forKey: remindersPurchased)
                    upperStack.insertArrangedSubview(reminderSegmentedControl, at: 4)
                    queue.finishTransaction(transaction)
                }
            case .failed:
                reminderSwitch.setOn(false, animated: true)
                queue.finishTransaction(transaction)
            case .restored:
                if iCloudStore.bool(forKey: remindersPurchased) == false {
                    iCloudStore.set(true, forKey: remindersPurchased)
                }
                queue.finishTransaction(transaction)
            default:
                break
            }
        }
    }
    
}
