//
//  DateFormatters.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/21/20.
//

import Foundation


class DateFormatters {
    
    
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    static let abbreviatedMonthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
    
    static let abbreviatedMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
    
    static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
    
    
    static let fullDateFormatterWithLetters: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d, MMM yyyy"
        return formatter
    }()
    
    
}
