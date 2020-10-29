//
//  Extensions.swift
//  ChatApp
//
//  Created by Mohamed Hashem on 7/15/20.
//  Copyright © 2020 Mohamed Hashem. All rights reserved.
//

import UIKit

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
    
    func addBorderShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.55
        layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
    }
    
    func addSubviews(_ views: [UIView]) {
        for view in views {
            addSubview(view)
        }
    }
    
}

extension UIViewController {
    
    func presentError(error: Error) {
        DispatchQueue.main.async { [weak self] in
            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self?.present(alertController, animated: true)
        }
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
        tf.addLeftPadding(10)
        return tf
    }
    
    func addLeftPadding(_ padding: CGFloat, withSymbol symbol: String? = nil) {
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: self.frame.height))
        if let symbol = symbol {
            let symbolLabel = UILabel()
            symbolLabel.text = symbol
            symbolLabel.font = UIFont.boldSystemFont(ofSize: fontScale < 1 ? 14 : 16 * fontScale)
            leftView.addSubview(symbolLabel)
            symbolLabel.fillSuperView()
        }
        self.leftView = leftView
        self.leftViewMode = .always
    }
}

extension String {
    
    var safeEmail: String {
        return replacingOccurrences(of: ".", with: "-")
    }
    
}


extension UIColor {
    
    static let backgroundColor = UIColor(red: 25/255, green: 25/255, blue: 25/255, alpha: 1)
}



extension UILabel {
    static func calcSize(for text: String, withFont fontSize: CGFloat) -> CGSize {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: fontSize)
        return label.intrinsicContentSize
    }
}


extension Array where Element == String {
    
    func longestString() -> String? {
        let sortedList = sorted(by: { $0.count > $1.count })
        return sortedList.first
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



extension UserDefaults {
    
  func colorForKey(key: String) -> UIColor? {
    var colorReturned: UIColor?
    if let colorData = data(forKey: key) {
      do {
        if let color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
          colorReturned = color
        } else {
            colorReturned = nil
        }
      } catch {
        print("Error UserDefaults")
      }
    }
    return colorReturned
  }
  
  func setColor(color: UIColor?, forKey key: String) {
    var colorData: NSData?
    if let color = color {
      do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) as NSData?
        colorData = data
      } catch {
        print("Error UserDefaults")
      }
    }
    set(colorData, forKey: key)
  }
}
