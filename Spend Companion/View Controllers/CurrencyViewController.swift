//
//  CurrencyViewController.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/26/20.
//

import UIKit

enum CurrencyPosition: String {
    case right, left
}

class CurrencyViewController: UITableViewController {
    
    var cellId = "cellId"
    
    var userCurrency: String {
        get {
            return UserDefaults.standard.value(forKey: "currency") as! String
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "currency")
        }
    }
        
    
    static let currenciesDict : [String: CurrencyPosition] = ["USD ($)": .left, "EUR (€)": .left, "JPY (¥)": .left, "GBP (£)": .left, "AUD ($)": .left, "CAD ($)": .left, "CHF (fr.)": .left, "CNY (¥)": .left, "HKD ($)": .left, "NZD ($)": .left, "SEK (kr)": .left, "KRW (₩)": .left, "SGD ($)": .left, "NOK (kr)": .left, "MXN ($)": .left, "INR (₹)": .left, "RUB (₽)": .right, "ZAR (R)": .left, "TRY (₺)": .right, "BRL (R$)": .left, "TWD ($)": .left, "DKK (kr)": .left, "PLN (zł)": .right, "THB (฿)": .right, "IDR (Rp)": .left, "HUF (Ft)": .right, "CZK (Kč)": .right, "ILS (₪)": .left, "CLP ($)": .left, "PHP (₱)": .left, "AED (د.إ)": .right, "COP ($)": .left, "SAR (﷼)": .right, "MYR (RM)": .left, "RON (L)": .left]
    
    
    var currencies: [String] = ["USD ($)", "EUR (€)", "JPY (¥)", "GBP (£)", "AUD ($)", "CAD ($)", "CHF (fr.)", "CNY (¥)", "HKD ($)", "NZD ($)", "SEK (kr)", "KRW (₩)", "SGD ($)", "NOK (kr)", "MXN ($)", "INR (₹)", "RUB (₽)", "ZAR (R)", "TRY (₺)", "BRL (R$)", "TWD ($)", "DKK (kr)", "PLN (zł)", "THB (฿)", "IDR (Rp)", "HUF (Ft)", "CZK (Kč)", "ILS (₪)", "CLP ($)", "PHP (₱)", "AED (د.إ)", "COP ($)", "SAR (﷼)", "MYR (RM)", "RON (L)"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        title = "Currency"
    }
    
    
    static func extractSymbol(from currency: String) -> String {
        let symbol = currency.split(separator: "(").last?.split(separator: ")").first
        return String(symbol!)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cell.textLabel?.text = currencies[indexPath.row]
        cell.accessoryType =  currencies[indexPath.row] == userCurrency ? .checkmark : .none
        return cell
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
        userCurrency = currencies[indexPath.row]
        InitialViewController.shared.quickAddView.updateCurrencySymbol()
    }
    
}
