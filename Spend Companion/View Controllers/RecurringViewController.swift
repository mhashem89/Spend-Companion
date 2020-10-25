//
//  RecurringChoiceView.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/13/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit



protocol RecurringViewControllerDelegate: class {
    
    func recurringViewCancel()
    
    func recurringViewDone(with itemRecurrence: ItemRecurrence)
    
}

class RecurringViewController: UIViewController {
    
    weak var delegate: RecurringViewControllerDelegate?
    
    let dayPicker = UIDatePicker()
    
    var dataChanged = false
    
    var dayPickerDate: Date?
    
    var upperStack: UIStackView!
    
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
        dayPicker.addTarget(self, action: #selector(datePicked), for: .valueChanged)
        tf.inputView = dayPicker
        tf.inputAccessoryView = toolBar
        
        return tf
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
    
    
    override func viewDidLoad() {
        view.backgroundColor = CustomColors.systemBackground.withAlphaComponent(fontScale < 1 ? 1 : 0.6)
        let reminderStack = UIStackView(arrangedSubviews: [reminderSwitch, reminderLabel])
        reminderStack.axis = .horizontal; reminderStack.spacing = 10; reminderStack.alignment = .center
        reminderSwitch.addTarget(self, action: #selector(toggleReminder), for: .touchUpInside)
        upperStack = UIStackView(arrangedSubviews: [questionLabel, periodTextField, segmentedControl, reminderStack, endDateLabel])
        if reminderSwitch.isOn {
            upperStack.insertArrangedSubview(reminderSegmentedControl, at: 4)
        }
        upperStack.axis = .vertical; upperStack.spacing = 15; upperStack.distribution = .fillEqually
        upperStack.anchor(widthConstant: fontScale < 1 ? 200 : 200 * fontScale)
        
        let lowerStack = UIStackView(arrangedSubviews: [cancelButton, doneButton])
        lowerStack.axis = .horizontal; lowerStack.spacing = 15; lowerStack.distribution = .fillEqually
        upperStack.anchor(widthConstant: fontScale < 1 ? 200 : 200 * fontScale)
        
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
    }
    
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
    }
    
    @objc func datePicked() {
        endDateLabel.text = "End: \(DateFormatters.fullDateFormatter.string(from: dayPicker.date))"
        endDateLabel.textColor = CustomColors.label
        endDateLabel.layer.borderColor = CustomColors.label.cgColor
        dataChanged = true
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
            upperStack.insertArrangedSubview(reminderSegmentedControl, at: 4)
        } else {
            reminderSegmentedControl.removeFromSuperview()
        }
        dataChanged = true
    }
    
    
    @objc func cancel() {
        delegate?.recurringViewCancel()
    }
    
    @objc func done() {
        if !dataChanged { delegate?.recurringViewCancel(); return }
        
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
        
        delegate?.recurringViewDone(with: ItemRecurrence(period: periodNum, unit: selectedSegment, reminderTime: reminderTime, endDate: endDate))
    }
    
}


extension RecurringViewController: UITextFieldDelegate {
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if !string.isEmpty {
            textField.layer.borderColor = CustomColors.label.cgColor
        }
        dataChanged = true
        return true
    }
    
}
