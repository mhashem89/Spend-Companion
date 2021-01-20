//
//  CustomizeAppearanceController.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/25/20.
//

import UIKit
import SwiftUI

@available(iOS 14, *)
class CustomizeAppearanceController: UITableViewController {
    
    var cellId = "CustomizeAppearanceCellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Customize Appearance"
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        tableView.register(SettingsCell.self, forCellReuseIdentifier: cellId)
        tableView.allowsSelection = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(reset))
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! SettingsCell
        
        var childView: UIViewController!
        switch indexPath.row {
        case 0:
            childView = UIHostingController(rootView: BarColorChooser())
        case 1:
            childView = UIHostingController(rootView: LabelColorChooser())
        case 2:
            childView = UIHostingController(rootView: ButtonColorChooser())
        default:
            break
        }
        addChild(childView)
        cell.addSubview(childView.view)
        childView.view.frame = cell.bounds
        childView.didMove(toParent: self)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    
    @objc func reset() {
        UserDefaults.standard.setColor(color: #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1), forKey: SettingNames.barColor)
        UserDefaults.standard.setColor(color: .systemBlue, forKey: SettingNames.labelColor)
        UserDefaults.standard.setColor(color: .systemBlue, forKey: SettingNames.buttonColor)
        tableView.reloadData()
    }
    
}




