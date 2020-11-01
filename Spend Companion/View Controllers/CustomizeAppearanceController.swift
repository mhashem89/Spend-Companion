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
    
    var cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Customize Appearance"
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        tableView.register(SettingsCell.self, forCellReuseIdentifier: cellId)
        tableView.allowsSelection = false
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
    
}




