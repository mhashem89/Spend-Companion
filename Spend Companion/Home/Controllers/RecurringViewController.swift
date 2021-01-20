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
    /// Gets called when the user presses "Cancel" button. Informs the delegate if the user was opening the recurrence view controller for the first time or not.
    func recurringViewCancel(wasNew: Bool)
    /// Gets called when the user presses "Done" button. Passes the item recurrence struct to the delegate and informs it if the struct is a newly created one, and if not then what items have changed.
    func recurringViewDone(with itemRecurrence: ItemRecurrence, new: Bool, dataChanged: [ItemRecurrenceCase])
}

class RecurringViewController: UIViewController {
    
// MARK:- Properties
    
    weak var delegate: RecurringViewControllerDelegate?
    
    // Boolean to keep track of the reminders purchased status
    private var remindersPurchased: Bool {
        return iCloudStore.bool(forKey: SettingNames.remindersPurchased)
    }
    
    // Reference to the ubiquitous key-value store
    private let iCloudStore = (UIApplication.shared.delegate as! AppDelegate).iCloudKeyStore
    
    // The product Id for the reminders in-app purchase
    private let reminderPurchaseProductId = PurchaseIds.reminders.description
    let dayPicker = UIDatePicker() // The picker that shows up when user tries to pick an end date
    private var dayPickerDate: Date?
    private var dataChanged = [ItemRecurrenceCase]() // Keep track of items the user has edited after opening an exisiting recurrence
    private var isNewRecurrence: Bool = true
    private var oldRecurrence: ItemRecurrence? // This gets passed from the presenting view controller if the user is opening an existing recurrence
    
// MARK:- Subviews
    
    private var upperStack: UIStackView!
    private var reminderStack: UIStackView?
    
    private var questionLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Recurring every:"
        lbl.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale)
        lbl.anchor(heightConstant: fontScale < 1 ? 30 : 30 * fontScale)
        lbl.baselineAdjustment = .alignCenters
        return lbl
    }()

    private lazy var periodTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter number"
        tf.keyboardType = .numberPad
        tf.backgroundColor = CustomColors.systemBackground
        tf.layer.cornerRadius = 5
        tf.layer.borderColor = CustomColors.darkGray.cgColor
        tf.layer.borderWidth = 1
        tf.addLeftPadding(padding: 10, withFontSize: fontScale < 1 ? 14 : 16 * fontScale)
        tf.font = UIFont.systemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale)
        tf.inputAccessoryView = setupToolbar()
        return tf
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl()
        sc.insertSegment(withTitle: "day", at: 0, animated: false)
        sc.insertSegment(withTitle: "week", at: 1, animated: false)
        sc.insertSegment(withTitle: "month", at: 2, animated: false)
        sc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale)], for: .normal)
        sc.layer.borderColor = UIColor.systemRed.cgColor
        return sc
    }()

    var reminderSwitch: UISwitch = {
        let reminder = UISwitch()
        return reminder
    }()
    
    private var reminderLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Reminder"
        lbl.font = UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 14 * fontScale)
        return lbl
    }()
    
    private let purchaseButton = UIButton.purchaseButton(withFont: UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 14 * fontScale))
    
    private let restorePurchaseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Restore purchases", for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.setAttributedTitle(NSAttributedString(string: "restore purchase", attributes: [.font: UIFont.systemFont(ofSize: 12)]), for: .normal)
        button.titleLabel?.textAlignment = .center
        return button
    }()
    
    private var reminderSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl()
        sc.insertSegment(withTitle: "1 day", at: 0, animated: false)
        sc.insertSegment(withTitle: "2 days", at: 1, animated: false)
        sc.insertSegment(withTitle: "3 days", at: 2, animated: false)
        sc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale)], for: .normal)
        sc.layer.borderColor = UIColor.systemRed.cgColor
        return sc
    }()
    
    private var endDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale)
        label.isUserInteractionEnabled = true
        label.textAlignment = .center
        label.text = "End Date"
        label.textColor = CustomColors.darkGray
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 1
        label.layer.borderColor = CustomColors.darkGray.cgColor
        return label
    }()
    
    private lazy var endDateTextField: UITextField = {
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
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.borderColor = CustomColors.darkGray.cgColor
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = 5
        button.setAttributedTitle(NSAttributedString(string: "Cancel", attributes: [.font: UIFont.systemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale), .foregroundColor: UIColor.systemRed]), for: .normal)
        return button
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.borderColor = CustomColors.darkGray.cgColor
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = 5
        button.anchor(heightConstant: fontScale < 1 ? 30 : 30 * fontScale)
        button.setAttributedTitle(NSAttributedString(string: "Done", attributes: [.font: UIFont.systemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale)]), for: .normal)
        return button
    }()
    
// MARK:- Life Cycle Methods
    
    init(itemRecurrence: ItemRecurrence? = nil) {
        super.init(nibName: nil, bundle: nil)
        // If opened with an existing item recurrence struct, load the subviews with the data
        if let itemRecurrence = itemRecurrence {
            periodTextField.text = String(itemRecurrence.period)
            segmentedControl.selectedSegmentIndex = itemRecurrence.unit.rawValue
            segmentedControl.isSelected = true
            endDateLabel.text = "End: \(DateFormatters.fullDateFormatter.string(from: itemRecurrence.endDate))"
            endDateLabel.textColor = CustomColors.label
            isNewRecurrence = false
            oldRecurrence = itemRecurrence
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
        super.viewDidLoad()
        view.backgroundColor = CustomColors.systemBackground.withAlphaComponent(fontScale < 1 ? 1 : 0.6)
        setupStackViews()
        
        reminderSwitch.addTarget(self, action: #selector(toggleReminder), for: .touchUpInside)
        purchaseButton.addTarget(self, action: #selector(buyReminders), for: .touchUpInside)
        
        endDateLabel.addSubview(endDateTextField)
        endDateTextField.fillSuperView()
        
        segmentedControl.addTarget(self, action: #selector(handleSegmentedControl), for: .valueChanged)
        reminderSegmentedControl.addTarget(self, action: #selector(handleReminderSegmentedControl), for: .valueChanged)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
        
        periodTextField.delegate = self
        dayPicker.date = DateFormatters.fullDateFormatter.date(from: endDateLabel.text ?? "") ?? Date()
        SKPaymentQueue.default().add(self)
    }
    
// MARK:- UI Methods

    private func setupStackViews() {
    
        reminderStack = UIStackView(arrangedSubviews: [remindersPurchased ? reminderSwitch : purchaseButton, reminderLabel])
        reminderStack?.axis = .horizontal; reminderStack?.spacing = 10; reminderStack?.alignment = .center
        reminderStack?.distribution = remindersPurchased ? .fill : .fillEqually
        if #available(iOS 13, *) {} else {
            reminderStack?.insertArrangedSubview(restorePurchaseButton, at: 2)
            restorePurchaseButton.addTarget(self, action: #selector(restorePurchase), for: .touchUpInside)
        }
        
        upperStack = UIStackView(arrangedSubviews: [questionLabel, periodTextField, segmentedControl, reminderStack!, endDateLabel])
        upperStack.axis = .vertical; upperStack.spacing = 15; upperStack.distribution = .fillEqually
        upperStack.anchor(widthConstant: fontScale < 1 ? 200 : 200 * fontScale)
        if reminderSwitch.isOn { upperStack.insertArrangedSubview(reminderSegmentedControl, at: 4) }

        let lowerStack = UIStackView(arrangedSubviews: [cancelButton, doneButton])
        lowerStack.axis = .horizontal; lowerStack.spacing = 15; lowerStack.distribution = .fillEqually
        
        let fullStack = UIStackView(arrangedSubviews: [upperStack, lowerStack])
        fullStack.axis = .vertical; fullStack.spacing = 15
        
        view.addSubview(fullStack)
        fullStack.anchor(centerX: view.centerXAnchor, centerY: view.centerYAnchor, centerYConstant: popoverPresentationController?.arrowDirection == .up ? 10 : -10)
    }
    /// Returns a toolbar that has "Cancel" and "Done" buttons
    private func setupToolbar() -> UIToolbar {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(toolBarCancel))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(toolBarDone))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolBar.setItems([cancelButton, spacer, doneButton], animated: false)
        return toolBar
    }
    
    @objc private func toolBarDone() {
        if endDateTextField.isFirstResponder {
            dayPickerDate = dayPicker.date
            endDateLabel.layer.borderColor = CustomColors.darkGray.cgColor
        }
        resignFirstResponders()
    }
    
    @objc private func toolBarCancel() {
        if endDateTextField.isFirstResponder {
            endDateLabel.text = dayPickerDate == nil ? "End Date" : "End: \(DateFormatters.fullDateFormatter.string(from: dayPickerDate!))"
        } else if periodTextField.isFirstResponder {
            periodTextField.text = nil
        }
        resignFirstResponders()
    }
    
    private func resignFirstResponders() {
        if endDateTextField.isFirstResponder {
            endDateTextField.resignFirstResponder()
        } else if periodTextField.isFirstResponder {
            periodTextField.resignFirstResponder()
        }
    }
    
    @objc private func handleSegmentedControl() {
        segmentedControl.isSelected = true
        segmentedControl.layer.borderWidth = 0
        dataChanged.append(.unit)
    }
    
    @objc private func handleReminderSegmentedControl() {
        reminderSegmentedControl.isSelected = true
        reminderSegmentedControl.layer.borderWidth = 0
        dataChanged.append(.reminderTime)
    }
    /// Gets called when the user changes the selection in the day picker
    @objc private func datePicked() {
        endDateLabel.text = "End: \(DateFormatters.fullDateFormatter.string(from: dayPicker.date))"
        endDateLabel.textColor = CustomColors.label
        endDateLabel.layer.borderColor = CustomColors.darkGray.cgColor
        dataChanged.append(.endDate)
    }
    
    @objc private func restorePurchase() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    /// Setups the UI after the successful purchase or restoring purchase
    private func purchaseSuccessful() {
        purchaseButton.removeFromSuperview()
        reminderStack?.insertArrangedSubview(reminderSwitch, at: 0)
        reminderStack?.distribution = .fill
    }
    /// Hides/ shows the reminder segmented control. If reminder is turned off, tracks the change.
    @objc private func toggleReminder() {
        if reminderSwitch.isOn {
            upperStack.insertArrangedSubview(reminderSegmentedControl, at: 4)
        } else {
            reminderSegmentedControl.removeFromSuperview()
            if !dataChanged.contains(.reminderTime) { dataChanged.append(.reminderTime) }
        }
    }
    /// Gets called when user presses "Purchase" button
    @objc private func buyReminders() {
        let idiom = UIDevice.current.userInterfaceIdiom
        let alertController = UIAlertController(title: "Purchase Reminders", message: "set custom reminders for any recurring transaction for a one-time payment of 0.99 USD (or equivalent in local currency)", preferredStyle: idiom == .pad ? .alert : .actionSheet)
        alertController.addAction(UIAlertAction(title: "Puchase", style: .default, handler: { (_) in
            if SKPaymentQueue.canMakePayments() {
                let remindersPayment = SKMutablePayment()
                remindersPayment.productIdentifier = PurchaseIds.reminders.description
                SKPaymentQueue.default().add(remindersPayment) // Triggers the reminders payment
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { [weak self] (_) in
            self?.reminderSwitch.setOn(false, animated: true)
        }))
        present(alertController, animated: true)
    }
    /// Gets called when the main "Cancel" button is pressed
    @objc private func cancel() {
        delegate?.recurringViewCancel(wasNew: isNewRecurrence)
    }
    /// Gets called when the main "Done" button is pressed
    @objc private func done() {
        // If no data has changed, dismisses the view controller
        if dataChanged.isEmpty { delegate?.recurringViewCancel(wasNew: isNewRecurrence); return }
        
        // Validate user input, if one field is empty or has incompatible data turns the border red
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
        // Construct the new item recurrence
        let newItemRecurrence = ItemRecurrence(period: periodNum, unit: selectedSegment, reminderTime: reminderTime, endDate: endDate)
        
        // Check if the new recurrence is different from the old one, if so then it gets passed to the delegate
        if let oldRecurrence = oldRecurrence, newItemRecurrence == oldRecurrence {
            delegate?.recurringViewCancel(wasNew: isNewRecurrence); return
        } else {
            delegate?.recurringViewDone(with: newItemRecurrence, new: isNewRecurrence, dataChanged: dataChanged)
        }
    }
}

// MARK:- Text Field Delegate

extension RecurringViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if !string.isEmpty {
            textField.layer.borderColor = CustomColors.darkGray.cgColor
        }
        dataChanged.append(.period)
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
                if remindersPurchased == false {
                    iCloudStore.set(true, forKey: SettingNames.remindersPurchased)
                    purchaseSuccessful()
                    queue.finishTransaction(transaction)
                }
            case .failed:
                queue.finishTransaction(transaction)
            case .restored:
                if remindersPurchased == false {
                    iCloudStore.set(true, forKey: SettingNames.remindersPurchased)
                    purchaseSuccessful()
                }
                queue.finishTransaction(transaction)
            default:
                break
            }
        }
    }
}
