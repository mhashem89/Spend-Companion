//
//  ColorChooser.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/24/20.
//

import SwiftUI

@available(iOS 14, *)

struct BarColorChooser: View {
    
    @State private var bgColor = Color(UserDefaults.standard.colorForKey(key: SettingNames.barColor) ?? .link)
    
    var body: some View {
        
        VStack {
            ColorPicker("Choose bar color", selection: Binding(get: {
                bgColor
            }, set: { (newValue) in
                bgColor = newValue
                updateUserDefaults(with: bgColor)
            }), supportsOpacity: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.padding(20)
    }
    
    func updateUserDefaults(with color: Color) {
        UserDefaults.standard.setColor(color: UIColor(color), forKey: SettingNames.barColor)
//        InitialViewController.shared.summaryView.barChart.reloadData()
    }
}

@available(iOS 14, *)

struct LabelColorChooser: View {
    
    @State var bgColor = Color(UserDefaults.standard.colorForKey(key: SettingNames.labelColor) ?? .systemBlue)
    
    var body: some View {
        
        VStack {
            ColorPicker("Choose label color", selection: Binding(get: {
                bgColor
            }, set: { (newValue) in
                bgColor = newValue
                updateUserDefaults(with: bgColor)
            }), supportsOpacity: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.padding(20)
    }
    
    func updateUserDefaults(with color: Color) {
        UserDefaults.standard.setColor(color: UIColor(color), forKey: SettingNames.labelColor)
//        InitialViewController.shared.summaryView.barChart.reloadData()
    }
}


@available(iOS 14, *)

struct ButtonColorChooser: View {
    
    @State var bgColor = Color(UserDefaults.standard.colorForKey(key: SettingNames.buttonColor) ?? .systemBlue)
    
    var body: some View {
        
        VStack {
            ColorPicker("Choose button color", selection: Binding(get: {
                bgColor
            }, set: { (newValue) in
                bgColor = newValue
                updateUserDefaults(with: bgColor)
            }), supportsOpacity: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.padding(20)
    }
    
    func updateUserDefaults(with color: Color) {
        UserDefaults.standard.setColor(color: UIColor(color), forKey: SettingNames.buttonColor)
        InitialViewController.shared.summaryView.barChart.reloadData()
    }
}
