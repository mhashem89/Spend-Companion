//
//  QuickAddView.swift
//  Spending App
//
//  Created by Mohamed Hashem on 10/7/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

protocol QuickAddViewDelegate: class {
    /// Brings up view controller to choose the category title
    func showCategoryTitleVC()
    /// Tells the delegate to save the item but providing a struct from the info user has entered
    func saveItem(itemStruct: ItemStruct)
    /// Tells the delegate to open the view controller for choosing item recurrence
    func openRecurringWindow()
    /// Tells the delegate to show view controller to choose item name (description)
    func showItemNameVC()
}


class QuickAddView: UIView {

// MARK:- Properties
    
    let dayPicker = UIDatePicker()
    weak var delegate: QuickAddViewDelegate?
    var itemRecurrence: ItemRecurrence? {
        didSet {
            if itemRecurrence != nil, !isRecurring {
                isRecurring = true
            }
        }
    }
    var dayPickerDate: Date?
    var isRecurring: Bool = false {
        didSet {
            if #available(iOS 13, *) {
                recurringButton.setImage(UIImage(systemName: isRecurring ? "checkmark.square" : "square"), for: .normal)
            } else {
                recurringButton.setAttributedTitle(NSAttributedString(string: isRecurring ? "☑ Recurring" : "▢ Recurring", attributes: [.font: UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale), .foregroundColor: UIColor.black]), for: .normal)
            }
            switch isRecurring {
            case true:
                recurringCircleButton.alpha = 1
            case false:
                recurringCircleButton.alpha = 0
                itemRecurrence = nil
            }
        }
    }
    var buttonColor: UIColor? {
        didSet {
            [recurringButton, recurringCircleButton].forEach({ $0.tintColor = buttonColor })
        }
    }
    
// MARK:- Subviews
    
    var quickAddLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Quickly add a transaction"
        lbl.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 18 * fontScale)
        return lbl
    }()
    
    // The label that displays transaction date
    var dayLabel: UILabel = {
        let label = UILabel()
        label.addBorder()
        label.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        label.isUserInteractionEnabled = true
        label.textAlignment = .center
        label.text = "Today"
        label.textColor = CustomColors.label
        return label
    }()
    
    // The textfield that becomes first responder when dayLabel is clicked in order to display the date picker
    lazy var dayTextField: UITextField = {
        let tf = UITextField()
        tf.tag = 1
        tf.inputView = dayPicker
        tf.tintColor = .clear
        
        // Setup the toolbar that shows up when the textField becomes first responder
        let toolBar = UIToolbar(frame: .init(origin: .zero, size: CGSize(width: frame.width, height: 44 * windowHeightScale)))
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        let todayButton = UIBarButtonItem(title: "Today", style: .plain, target: self, action: #selector(todayButtonDayPicker))
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolBar.setItems([cancelButton, todayButton, spacer, doneButton], animated: false)
        
        // Setup the date picker
        dayPicker.datePickerMode = .date
        dayPicker.addTarget(self, action: #selector(datePicked), for: .valueChanged)
        if #available(iOS 14.0, *) { dayPicker.preferredDatePickerStyle = .wheels }
        
        tf.inputView = dayPicker
        tf.inputAccessoryView = toolBar
        return tf
    }()
    
    // The "Income/Expense" segmented control
    var segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl()
        sc.insertSegment(withTitle: "Expense", at: 0, animated: false)
        sc.insertSegment(withTitle: "Income", at: 1, animated: false)
        sc.layer.borderWidth = 1
        sc.layer.borderColor = UIColor.clear.cgColor
        sc.isSelected = false
        sc.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 15 * fontScale)], for: .normal)
        return sc
    }()
    
    // The label that displays description of the transaction
    var detailLabel: UILabel = {
        let lbl = UILabel()
        lbl.addBorder()
        lbl.tag = 2
        lbl.font = UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        lbl.text = "Description"
        lbl.textColor = CustomColors.darkGray
        lbl.textAlignment = .center
        lbl.isUserInteractionEnabled = true
        return lbl
    }()
    
    // The button to toggle recurrence of a transaction
    var recurringButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13, *) {
            button.setImage(UIImage(systemName: "square"), for: .normal)
            let title = NSAttributedString(string: "Recurring", attributes: [.font: UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)])
            button.setAttributedTitle(title, for: .normal)
        } else {
            let title = NSAttributedString(string: "▢ Recurring", attributes: [.font: UIFont.systemFont(ofSize: fontScale < 1 ? 13 : 16 * fontScale), .foregroundColor: UIColor.black])
            button.setAttributedTitle(title, for: .normal)
        }
        if windowWidthScale < 1 { button.imageEdgeInsets = UIEdgeInsets(top: 1 / windowWidthScale, left: 1 / windowWidthScale, bottom: 1 / windowWidthScale, right: 1 / windowWidthScale) }
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    // Button that indicates item recurrence is set
    var recurringCircleButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13, *) {
            button.setImage(UIImage(systemName: "arrow.clockwise.circle"), for: .normal)
        } else {
            button.setAttributedTitle(NSAttributedString(string: "⟳", attributes: [.font: UIFont.boldSystemFont(ofSize: 18)]), for: .normal)
        }
        button.contentHorizontalAlignment = .left
        button.alpha = 0
        return button
    }()
    
    lazy var amountTextField: UITextField = {
        let tf = UITextField()
        tf.addBorder()
        tf.tag = 3
        tf.font = UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        tf.placeholder = "\(CommonObjects.shared.currencySymbol.symbol ?? "")...    "
        tf.textAlignment = .center
        tf.keyboardType = .decimalPad
        tf.delegate = self
        tf.inputAccessoryView = amountToolbar()
        return tf
    }()

    var categoryLabel: UILabel = {
        let lbl = UILabel()
        lbl.addBorder()
        lbl.text = "Category"
        lbl.textAlignment = .center
        lbl.isUserInteractionEnabled = true
        lbl.textColor = CustomColors.darkGray
        lbl.font = UIFont.systemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
        lbl.alpha = 0
        return lbl
    }()
    
    var saveButton: UIButton = {
        let button = UIButton(type: .system)
        let saveString = NSAttributedString(string: "Save", attributes: [.font: UIFont.boldSystemFont(ofSize: 20 * fontScale), .foregroundColor: UIColor.white])
        button.setAttributedTitle(saveString, for: .normal)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.backgroundColor = CustomColors.lessDarkGray
        button.isEnabled = false
        return button
    }()
    
    // These are the stackViews that will be used to build the view
    lazy var leftStack = UIStackView(arrangedSubviews: [dayLabel, detailLabel, amountTextField])
    lazy var rightStack = UIStackView(arrangedSubviews: [segmentedControl, recurringStack, buttonStack])
    lazy var recurringStack = UIStackView(arrangedSubviews: [recurringButton, recurringCircleButton])
    lazy var buttonStack = UIStackView(arrangedSubviews: [categoryLabel, saveButton])
    lazy var fullStack = UIStackView(arrangedSubviews: [leftStack, rightStack])
    
// MARK:- UI Methods
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.masksToBounds = false
        addBorderShadow(color: CustomColors.mediumGray, opacity: 0.55, size: .init(width: 0.5, height: 0.5))
    }
    
    func setupUI() {
        // The width and height values adjusted for window size that I will use for the subviews' frames
        let width = frame.width * 0.4
        let height: CGFloat = 40 * windowHeightScale
        
        backgroundColor = CustomColors.systemBackground
        layer.cornerRadius = 10
        clipsToBounds = true
        
        anchorSubviews(withWidth: width, withHeigh: height)
        setupStackViews()
        addSubviews([quickAddLabel, fullStack])
        
        quickAddLabel.anchor(top: topAnchor, topConstant: 10 * windowHeightScale, leading: safeAreaLayoutGuide.leadingAnchor, leadingConstant: 10 * windowWidthScale)
        fullStack.anchor(top: quickAddLabel.bottomAnchor, topConstant: 15 * windowHeightScale, centerX: centerXAnchor, widthConstant: frame.width * 0.95)
        
        // Add textField on top of the day label so that it becomes first responder when label is clicked. The textField is transparent.
        dayLabel.addSubview(dayTextField)
        dayTextField.fillSuperView()
        
        // Add tap gestures to to recognize when item detail label or category name label are tapped
        categoryLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.chooseCategory)))
        detailLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(chooseItemName)))
        
        // Add targets to the rest of subviews
        segmentedControl.addTarget(self, action: #selector(self.handleSegmentedControl), for: .valueChanged)
        saveButton.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        recurringButton.addTarget(self, action: #selector(isRecurringToggle), for: .touchUpInside)
        recurringCircleButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openRecurringWindow)))
    }
    
    private func setupStackViews() {
        buttonStack.spacing = 5; buttonStack.distribution = .fillEqually
        [leftStack, rightStack].forEach({ $0.axis = .vertical; $0.spacing = 10 * windowHeightScale })
        fullStack.axis = .horizontal; fullStack.spacing = 10 * windowHeightScale
    }
    /// Setup the height and width of the subviews
    private func anchorSubviews(withWidth width: CGFloat, withHeigh height: CGFloat) {
        [dayLabel, detailLabel, amountTextField].forEach({
            $0.anchor(widthConstant: width, heightConstant: height)
        })
        categoryLabel.anchor(heightConstant: height)
        recurringButton.anchor(widthConstant: fontScale < 1 ? min(frame.width * 0.25, 125) : 95 * windowWidthScale)
    }
    
    /// Responds when recurring button is tapped. If the user had already chosen recurring then it just cancels the existing recurrence, otherwise it opens the recurring view controlled.
    @objc private func isRecurringToggle() {
        isRecurring ? isRecurring = false : openRecurringWindow()
    }
    /// Open the recurring view controller
    @objc private func openRecurringWindow() {
        delegate?.openRecurringWindow()
    }
    /// Gets called when the user chooses a date in the date picker.. Converts the date picked into text displayed by the day label.
    @objc private func datePicked() {
        if dayPicker.date.dayMatches(Date()) {
            dayLabel.text = "Today"
        } else {
            dayLabel.text = DateFormatters.fullDateFormatter.string(from: dayPicker.date)
        }
        dayLabel.textColor = CustomColors.label
        dayLabel.layer.borderColor = CustomColors.darkGray.cgColor
    }
    /// Handles  when user persses the "income/expense" segmented control. If expense is chosen then it shows the category label, otherwise hides it.
    @objc private func handleSegmentedControl() {
        segmentedControl.layer.borderColor = UIColor.clear.cgColor
        segmentedControl.isSelected = true
        showSaveButton()
        switch segmentedControl.selectedSegmentIndex {
        case 1:
            categoryLabel.alpha = 0
        case 0:
            categoryLabel.alpha = 1
        default:
            break
        }
    }
    /// Returns toolbar to be used when the amount textField becomes firest resopnder. It has "Cancel" and "Done" buttons.
    private func amountToolbar() -> UIToolbar {
        let toolBar = UIToolbar(frame: .init(origin: .zero, size: CGSize(width: frame.width, height: 44 * windowHeightScale)))
        toolBar.sizeToFit()
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolBar.setItems([cancelButton, spacer, doneButton], animated: false)
        return toolBar
    }
    /// Gets called when the user presses "Done" in the toolbar of the date picker or the amount text field.
    @objc private func doneButtonPressed() {
        if dayTextField.isFirstResponder {
            dayTextField.resignFirstResponder()
            dayPickerDate = dayPicker.date
            dayLabel.layer.borderColor = CustomColors.darkGray.cgColor
        } else if amountTextField.isFirstResponder {
            amountTextField.resignFirstResponder()
        }
    }
    /// Gets called when the user presses "Today" button in the toolbar of the date picker. Switches the date to today's date.
    @objc func todayButtonDayPicker() {
        dayPicker.date = Date()
        dayLabel.text = "Today"
    }
    /// Gets called when cancel button is pressed in either date picker or amount text field. Reverts the date displayed on day label to last chosen value.
    @objc private func cancelButtonPressed() {
        if amountTextField.isFirstResponder {
            amountTextField.resignFirstResponder()
        } else if dayTextField.isFirstResponder {
            dayLabel.text = dayPickerDate == nil ? "Today" : DateFormatters.fullDateFormatter.string(from: dayPickerDate!)
            dayTextField.resignFirstResponder()
        }
    }
    /// Tells the delegate to open the view controller to choose category name.
    @objc private func chooseCategory() {
        delegate?.showCategoryTitleVC()
        resignFirstResponders()
    }
    /// Tells the delegate to open the view controller to choose item name.
    @objc private func chooseItemName() {
        delegate?.showItemNameVC()
    }
    
    func showSaveButton() {
        saveButton.backgroundColor = .systemBlue
        saveButton.isEnabled = true
    }
    /// Gets called when the user changes the currency symbol in settings.
    func updateCurrencySymbol() {
        amountTextField.placeholder = "\(CommonObjects.shared.currencySymbol.symbol ?? "")..    "
    }
    /// Resign all the active text fields if they are first responders
    func resignFirstResponders() {
        if dayTextField.isFirstResponder {
            dayTextField.resignFirstResponder()
        }
        if amountTextField.isFirstResponder {
            amountTextField.resignFirstResponder()
        }
    }
    /// Gets called when the save button is pressed. Performs validation logic to make sure neither transaction type nor amount  is missing, otherwise turns the missing field's border into red.
    @objc private func saveButtonPressed() {
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
        // Construct the item struct that will be sent to the delegate
        var category: String?
        switch type {
        case .spending:
            category = categoryLabel.text == "Category" ? nil : categoryLabel.text
        case .income:
            category = "Income"
        }
        let itemDate = DateFormatters.fullDateFormatter.date(from: dayLabel.text ?? "") ?? Date()
        let itemStruct = ItemStruct(amount: amount, type: type, date: itemDate, detail: detailLabel.text, itemRecurrence: self.itemRecurrence, categoryName: category)
      
        // Keep track if the new item that will be added is coming from the current device or from a different device. This is needed to ***
        UserDefaults.standard.setValue(true, forKey: SettingNames.contextIsActive)
        
        delegate?.saveItem(itemStruct: itemStruct)
        amountTextField.resignFirstResponder()
    }
    /// Clears all the labels and text fields and resets the view to original state.
    func clearView() {
        dayTextField.text = nil
        detailLabel.text = "Description"
        detailLabel.textColor = CustomColors.darkGray
        segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        segmentedControl.isSelected = false
        amountTextField.text = nil
        saveButton.isEnabled = false
        saveButton.backgroundColor = CustomColors.lessDarkGray
        isRecurring = false
        categoryLabel.text = "Category"
        categoryLabel.textColor = CustomColors.darkGray
        categoryLabel.alpha = 0
        resignFirstResponders()
    }
}

// MARK:- UITextField Delegate

extension QuickAddView: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return false }
        let currentString: NSString = text as NSString
        let newString = currentString.replacingCharacters(in: range, with: string) as NSString
        textField.layer.borderColor = CustomColors.darkGray.cgColor
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
