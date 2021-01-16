//
//  SummaryWidget.swift
//  SummaryWidget
//
//  Created by Mohamed Hashem on 1/11/21.
//

import WidgetKit
import SwiftUI
import Combine

enum BalanceType {
    case positive, negative
}

struct Provider: TimelineProvider {
    @AppStorage("monthSummary", store: UserDefaults(suiteName: "group.MohamedHashem.Spend-Companion")) var summaryData: Data = Data()
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(monthSummary: MonthSummary(month: "Jan 2021", income: 0, spending: 0))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        guard let monthSummary = try? JSONDecoder().decode(MonthSummary.self, from: summaryData) else { return }
        let entry = SimpleEntry(monthSummary: monthSummary)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        guard let monthSummary = try? JSONDecoder().decode(MonthSummary.self, from: summaryData) else { return }
        let entry = SimpleEntry(monthSummary: monthSummary)

        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    var date: Date = Date()
    var monthSummary: MonthSummary
}

struct SummaryWidgetEntryView : View {
    
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var widget
    var windowWidth: CGFloat {
        return widthScale <= 1 ? UIScreen.main.bounds.size.width : 380
    }
    var widthScale = UIScreen.main.bounds.size.width / 414
    
    func scaleFactor() -> CGFloat {
        return (windowWidth * 0.5) / CGFloat(max(entry.monthSummary.income, entry.monthSummary.spending))
    }
    
    func calculateBalance() -> (amount: String, balanceType: BalanceType)? {
        let balance = entry.monthSummary.income - entry.monthSummary.spending
        if let formattedValue = numberFormatter.string(from: NSNumber(value: balance)) {
            switch balance < 0 {
            case true:
                return ("-\(formattedValue)", .negative)
            case false:
                return ("+\(formattedValue)", .positive)
            }
        } else {
            return nil
        }
    }
    
    var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.minusSign = ""
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(entry.monthSummary.month)
                    .bold()
                    .padding(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(lineWidth: 0.8)
                    )
                    .padding(.leading, 5)
                if let balance = calculateBalance() {
                    Text("\(balance.amount)")
                        .foregroundColor(balance.balanceType == .positive ? .green : .red)
                }
                Spacer()
                Image("small_icon")
                    .cornerRadius(5, antialiased: true)
                    .padding(.trailing, 10)
            }
            HStack {
                VStack(alignment: .trailing, spacing: 10) {
                    Text("Income")
                        .fixedSize()
                        .font(.system(size: widthScale < 1 ? 16 * widthScale : 16))
                    Text("Spending")
                        .lineLimit(1)
                        .fixedSize()
                        .font(.system(size: widthScale < 1 ? 16 * widthScale : 16))
                }
                VStack(alignment: .leading) {
                    HStack {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: CGFloat(entry.monthSummary.income) * scaleFactor(), height: 20)
                            .cornerRadius(10)
                        Text(numberFormatter.string(from: NSNumber(value: entry.monthSummary.income)) ?? "0")
                            .fixedSize()
                            .font(.system(size: widthScale < 1 ? 16 * widthScale : 16))
                    }
                    HStack {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: CGFloat(entry.monthSummary.spending) * scaleFactor(), height: 20)
                            .cornerRadius(10)
                        Text(numberFormatter.string(from: NSNumber(value: entry.monthSummary.spending)) ?? "0")
                            .fixedSize()
                            .font(.system(size: widthScale < 1 ? 16 * widthScale : 16))
                    }
                }
            }
        }
        .frame(maxWidth: windowWidth * 0.85, alignment: .leading)
        .padding(.leading, 5)
    }
}

@main
struct SummaryWidget: Widget {
    let kind: String = "SummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SummaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Money Tracker")
        .description("Track your income and spending of the current month")
        .supportedFamilies([.systemMedium])
    }
}

struct SummaryWidget_Previews: PreviewProvider {
    static var previews: some View {
        SummaryWidgetEntryView(entry: SimpleEntry(monthSummary: MonthSummary(month: "Jan 2021", income: 2300, spending: 3500)))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
