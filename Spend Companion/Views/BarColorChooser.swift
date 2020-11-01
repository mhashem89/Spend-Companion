//
//  ColorChooser.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/24/20.
//

import SwiftUI

@available(iOS 14, *)

struct BarColorChooser: View {
    
    @State var bgColor = Color(UserDefaults.standard.colorForKey(key: "bar color") ?? .systemRed)
    
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
        UserDefaults.standard.setColor(color: UIColor(color), forKey: "bar color")
        InitialViewController.shared.summaryView.barChart.reloadData()
    }
}

@available(iOS 14, *)

struct LabelColorChooser: View {
    
    @State var bgColor = Color(UserDefaults.standard.colorForKey(key: "label color") ?? .systemBlue)
    
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
        UserDefaults.standard.setColor(color: UIColor(color), forKey: "label color")
        InitialViewController.shared.summaryView.barChart.reloadData()
    }
}


@available(iOS 14, *)

struct ButtonColorChooser: View {
    
    @State var bgColor = Color(UserDefaults.standard.colorForKey(key: "button color") ?? .systemBlue)
    
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
        UserDefaults.standard.setColor(color: UIColor(color), forKey: "button color")
        InitialViewController.shared.summaryView.barChart.reloadData()
    }
}
