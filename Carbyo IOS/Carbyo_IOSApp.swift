//
//  Carbyo_IOSApp.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

@main
struct Carbyo_IOSApp: App {
    init() {
        // Configuration de la TabBar
        UITabBar.appearance().tintColor = UIColor(CarbyoColors.primary)
        UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
