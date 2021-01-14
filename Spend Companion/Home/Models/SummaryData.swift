//
//  SummaryData.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 1/12/21.
//

import SwiftUI
import WidgetKit

@available(iOS 14, *)
struct SummaryData {
    
    @AppStorage("monthSummary", store: UserDefaults(suiteName: "group.MohamedHashem.Spend-Companion")) var summaryData: Data = Data()
    var monthSummary: MonthSummary
    
    func storeData() {
        guard let data = try? JSONEncoder().encode(monthSummary) else { return }
        summaryData = data
        WidgetCenter.shared.reloadAllTimelines()
    }
}
