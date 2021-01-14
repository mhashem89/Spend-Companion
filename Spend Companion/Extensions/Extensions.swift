//
//  Extensions.swift
//  ChatApp
//
//  Created by Mohamed Hashem on 7/15/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit
import CoreData

extension UIView {
    
    func anchor(top: NSLayoutYAxisAnchor? = nil,
                topConstant: CGFloat = 0,
                leading: NSLayoutXAxisAnchor? = nil,
                leadingConstant: CGFloat = 0,
                trailing: NSLayoutXAxisAnchor? = nil,
                trailingConstant: CGFloat = 0,
                bottom: NSLayoutYAxisAnchor? = nil,
                bottomConstant: CGFloat = 0,
                centerX: NSLayoutXAxisAnchor? = nil,
                centerXConstant: CGFloat = 0,
                centerY: NSLayoutYAxisAnchor? = nil,
                centerYConstant: CGFloat = 0,
                widthConstant: CGFloat? = nil,
                heightConstant: CGFloat? = nil) {
                
        translatesAutoresizingMaskIntoConstraints = false
        
        if let topAnchor = top {
            self.topAnchor.constraint(equalTo: topAnchor, constant: topConstant).isActive = true
        }
        if let leadingAnchor = leading {
            self.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leadingConstant).isActive = true
        }
        if let trailingAnchor = trailing {
            self.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -trailingConstant).isActive = true
        }
        if let bottomAnchor = bottom {
            self.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottomConstant).isActive = true
        }
        if let centerXAnchor = centerX {
            self.centerXAnchor.constraint(equalTo: centerXAnchor, constant: centerXConstant).isActive = true
        }
        if let centerYAnchor = centerY {
            self.centerYAnchor.constraint(equalTo: centerYAnchor, constant: centerYConstant).isActive = true
        }
        if let widthConstant = widthConstant {
            self.widthAnchor.constraint(equalToConstant: widthConstant).isActive = true
        }
        if let heightConstant = heightConstant {
            self.heightAnchor.constraint(equalToConstant: heightConstant).isActive = true
        }
    }
    
    func fillSuperView() {
        guard let superView = self.superview else { return }
        anchor(top: superView.topAnchor, leading: superView.leadingAnchor, trailing: superView.trailingAnchor, bottom: superView.bottomAnchor)
    }
    
    func addBottomSeparatorLine(padding bottomConstant: CGFloat = 0, edges: CGFloat? = nil) {
        let line = UIView()
        self.addSubview(line)
        line.backgroundColor = .lightGray
        line.anchor(leading: leadingAnchor, leadingConstant: edges ?? 10, trailing: trailingAnchor, trailingConstant: edges ?? 10, bottom: bottomAnchor, bottomConstant: bottomConstant, heightConstant: 0.7)
    }
    
    func addContainerView(imageName: String, textField: UITextField) -> UIView {
        let containerView = UIView()
        let imageView = UIImageView(image: UIImage(named: imageName))
        containerView.addSubview(imageView)
        containerView.addSubview(textField)
        imageView.anchor(top: containerView.topAnchor, leading: containerView.leadingAnchor, leadingConstant: 10, widthConstant: 25)
        textField.anchor(top: imageView.topAnchor, topConstant: 2, leading: imageView.trailingAnchor, leadingConstant: 10 , trailing: containerView.trailingAnchor)
        containerView.anchor(heightConstant: 50)
        containerView.addBottomSeparatorLine(padding: 15)
        return containerView
    }
    
    func addBorderShadow(color: UIColor, opacity: Float, size: CGSize) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = size
    }
    
    func addSubviews(_ views: [UIView]) {
        for view in views {
            addSubview(view)
        }
    }
    
    func withBackgroundColor(color: UIColor) -> UIView {
        backgroundColor = color
        return self
    }
    
    func addBorder() {
        layer.cornerRadius = 5
        layer.borderWidth = 1
        layer.borderColor = CustomColors.darkGray.cgColor
        clipsToBounds = true
    }
    
}

extension UITabBarItem {
    
    func setupForOldiOS() -> UITabBarItem {
        self.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], for: .normal)
        self.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -8)
        return self
    }
    
}

extension UIViewController {
    
    func presentError(error: Error) {
        let isSaveError: Bool = error is SaveError
        let message = "\(error.localizedDescription)\(isSaveError ? "\n Please restart the application" : "")"
        DispatchQueue.main.async { [weak self] in
            let alertController = UIAlertController(title: "\(isSaveError ? "Save " : "")Error", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                if isSaveError {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }))
            self?.present(alertController, animated: true)
        }
    }
    
    func presentFutureTransactionAlert(withChangeType type: ItemChangeType, handler: @escaping (UIAlertAction) -> Void) {
        let alertController = UIAlertController(title: nil, message: "\(type == .edit ? "Apply the change to all" : "Delete") future transactions?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Only this transaction", style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: "All future transactions", style: .default, handler: handler))
        present(alertController, animated: true, completion: nil)
    }
    
    func setupPopoverController(popoverDelegate: UIPopoverPresentationControllerDelegate?, sourceView: UIView, sourceRect: CGRect, preferredWidth: CGFloat, preferredHeight: CGFloat, style: UIModalPresentationStyle) {
        modalPresentationStyle = style
        popoverPresentationController?.delegate = popoverDelegate
        popoverPresentationController?.sourceView = sourceView
        popoverPresentationController?.sourceRect = sourceRect
        preferredContentSize = .init(width: preferredWidth, height: preferredHeight)
    }
    
}

extension UIImageView {
    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }

        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }

        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}



extension UITextField {
    
    static func setupTextField(placeholderText: String, isSecureEntry: Bool = false) -> UITextField {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [.foregroundColor : UIColor.lightGray, .font: UIFont.systemFont(ofSize: 16)])
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.keyboardAppearance = .dark
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.layer.cornerRadius = 10
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.isSecureTextEntry = isSecureEntry
        tf.textColor = .black
        tf.addLeftPadding(padding: 10)
        return tf
    }
    
    func addLeftPadding(padding: CGFloat? = nil, withSymbol symbol: String? = nil) {
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: padding ?? 10, height: self.frame.height))
        if let symbol = symbol {
            let symbolLabel = UILabel()
            symbolLabel.text = symbol
            symbolLabel.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
            leftView.addSubview(symbolLabel)
            leftView.frame.size.width = UILabel.calcSize(for: symbol, withFont: fontScale < 1 ? 14 : 16 * fontScale).width + 2
            symbolLabel.fillSuperView()
        }
        self.leftView = leftView
        self.leftViewMode = .always
    }
    
    func addRightPadding(padding: CGFloat? = nil, withSymbol symbol: String? = nil) {
        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: padding ?? 10, height: self.frame.height))
        if let symbol = symbol {
            let symbolLabel = UILabel()
            symbolLabel.text = " \(symbol)"
            symbolLabel.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
            rightView.addSubview(symbolLabel)
            rightView.frame.size.width = UILabel.calcSize(for: symbol, withFont: fontScale < 1 ? 14 : 16 * fontScale).width
            symbolLabel.fillSuperView()
        }
        self.rightView = rightView
        self.rightViewMode = .always
    }
}


extension String {

    func extractDate() -> String {
        let subStrings = self.split(separator: ",")
        let date = String(subStrings[0] + "," + subStrings[1])
        return date
    }
    
    func removeTrailingSpace() -> String {
        let substrings = self.split(separator: " ")
        return substrings.joined(separator: " ")
    }
    
}


extension Date {
    func dayMatches(_ date: Date) -> Bool {
        return DateFormatters.fullDateFormatter.string(from: date) == DateFormatters.fullDateFormatter.string(from: self)
    }
    
    func monthMatches(_ date: Date) -> Bool {
        return DateFormatters.abbreviatedMonthYearFormatter.string(from: date) == DateFormatters.abbreviatedMonthYearFormatter.string(from: self)
    }
    
    func yearMatches(_ date: Date) -> Bool {
        return DateFormatters.yearFormatter.string(from: date) == DateFormatters.yearFormatter.string(from: self)
    }
    
    func zeroHour() -> Date {
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self) ?? self
    }
}

extension UIColor {
    
    static let backgroundColor = UIColor(red: 25/255, green: 25/255, blue: 25/255, alpha: 1)
}

extension UIButton {
    static func purchaseButton(withFont font: UIFont) -> UIButton {
        let button = UIButton(type: .system)
        let title = NSAttributedString(string: "Purchase", attributes: [.font: font, .foregroundColor: UIColor.white])
        button.setAttributedTitle(title, for: .normal)
        button.layer.cornerRadius = 5
        button.backgroundColor = CustomColors.blue
        return button
    }
}


extension UILabel {
    static func calcSize(for text: String, withFont fontSize: CGFloat) -> CGSize {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: fontSize)
        return label.intrinsicContentSize
    }
    
    static func savedLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.text = "Saved successfully!"
        label.backgroundColor = CustomColors.darkGray.withAlphaComponent(0.5)
        label.textColor = .white
        label.layer.cornerRadius = 10
        label.isHidden = true
        label.textAlignment = .center
        label.clipsToBounds = true
        return label
    }
    
    static func emptyItemsLabel() -> UILabel {
        let lbl = UILabel()
        lbl.text = "Items from last 7 days will appear here"
        lbl.textColor = CustomColors.darkGray
        lbl.font = UIFont.italicSystemFont(ofSize: fontScale < 1 ? 16 : 16 * fontScale)
        return lbl
    }
    
}


extension Array where Element == String {
    
    func longestString() -> String? {
        let sortedList = sorted(by: { $0.count > $1.count })
        return sortedList.first
    }
}


extension Array where Element: Hashable {
    
    func unique() -> Array {
        var set = Set<Element>()
        var newArray = [Element]()
        for item in self {
            if !set.contains(item) {
                newArray.append(item)
                set.insert(item)
            }
        }
        return newArray
    }
}


extension Array where Element == Double {
    func sum() -> Double? {
        var total: Double = 0
        for i in self {
            total += i
        }
        return total > 0 ? total : nil
    }
}

extension Array where Element: Equatable {
    
    func countOf(element: Element) -> Int {
        return filter({ $0 == element }).count
    }
    
}

extension UITableView {
    
    func lastIndexPath(inSection section: Int) -> IndexPath {
        let numberOfRowsInSection = self.numberOfRows(inSection: section)
        return IndexPath(row: numberOfRowsInSection > 0 ? numberOfRowsInSection - 1 : 0 , section: section)
    }
    
    func setup(delegate: UITableViewDelegate, dataSource: UITableViewDataSource, cellClass: AnyClass, cellId: String) {
        self.delegate = delegate
        self.dataSource = dataSource
        self.register(cellClass.self, forCellReuseIdentifier: cellId)
        self.tableFooterView = UIView()
    }
}

extension UITableViewCell {
    
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UICollectionViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}


extension Item {
    
    func futureItems() -> [Item]? {
        guard
            let itemDate = self.date,
            recurringNum != nil,
            let sisterItems = (self.sisterItems?.allObjects as? [Item])?.filter({ $0.date != nil })
        else { return nil }
        let futureItems = sisterItems.filter({
            guard let sisterItemDate = $0.date else { return false }
            return sisterItemDate > itemDate
        })
        return futureItems.count > 0 ? futureItems : nil
    }
    
    func sisterItemsArray() -> [Item]? {
        return sisterItems?.allObjects as? [Item]
    }
}
