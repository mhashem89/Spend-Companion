//
//  CurrencyViewController.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/26/20.
//

import UIKit
import Combine

enum CurrencyPosition: String {
    case right, left
}

class CurrencyViewController: UITableViewController {
    
    var cellId = "CurrencyCellId"
    
    var userCurrency: String {
        get {
            return UserDefaults.standard.value(forKey: SettingNames.currency) as! String
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: SettingNames.currency)
        }
    }
    
    
    var currencies: [String] = ["USD ($)", "EUR (€)", "JPY (¥)", "GBP (£)", "AUD ($)", "CAD ($)", "CHF (fr.)", "CNY (¥)", "HKD ($)", "NZD ($)", "SEK (kr)", "KRW (₩)", "SGD ($)", "NOK (kr)", "MXN ($)", "INR (₹)", "RUB (₽)", "ZAR (R)", "TRY (₺)", "BRL (R$)", "TWD ($)", "DKK (kr)", "PLN (zł)", "THB (฿)", "IDR (Rp)", "HUF (Ft)", "CZK (Kč)", "ILS (₪)", "CLP ($)", "PHP (₱)", "AED (د.إ)", "COP ($)", "SAR (﷼)", "MYR (RM)", "RON (L)"]
    
    var fixed = ["Local currency", "None"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        title = "Currency"
       
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : currencies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cell.textLabel?.text = indexPath.section == 0 ? fixed[indexPath.row] : currencies[indexPath.row]
        if indexPath.section == 0 {
            cell.accessoryType = fixed[indexPath.row] == userCurrency ? .checkmark : .none
        } else {
            cell.accessoryType =  currencies[indexPath.row] == userCurrency ? .checkmark : .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? "Common currencies" : nil
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        for cell in tableView.visibleCells {
            cell.accessoryType = .none
        }
        let selectedCell = tableView.cellForRow(at: indexPath)
        selectedCell?.accessoryType = .checkmark
        userCurrency = indexPath.section == 0 ? fixed[indexPath.row] : currencies[indexPath.row]
        InitialViewController.shared.currencyChanged()
    }
    
}
