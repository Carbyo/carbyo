//
//  MainTabView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var session: SessionStore
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack {
            // Contenu de l'onglet sélectionné
            Group {
                if selectedTab == 0 {
                    CockpitView()
                        .environmentObject(session)
                } else if selectedTab == 1 {
                    TripsView()
                } else if selectedTab == 2 {
                    FriendsView()
                } else if selectedTab == 3 {
                    SettingsView()
                        .environmentObject(session)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // TabBar custom compacte en bas
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

// MARK: - Custom Compact TabBar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    struct TabItem {
        let title: String
        let icon: String
        let tag: Int
    }
    
    private let tabs: [TabItem] = [
        TabItem(title: "Cockpit", icon: "leaf.fill", tag: 0),
        TabItem(title: "Mes trajets", icon: "figure.walk", tag: 1),
        TabItem(title: "Mes amis", icon: "person.2.fill", tag: 2),
        TabItem(title: "Paramètres", icon: "gearshape.fill", tag: 3)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tag) { tab in
                Button {
                    selectedTab = tab.tag
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(selectedTab == tab.tag ? CarbyoColors.primary : Color.gray)
                        
                        Text(tab.title)
                            .font(.caption2)
                            .foregroundColor(selectedTab == tab.tag ? CarbyoColors.primary : Color.gray.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .background(
                        Group {
                            if selectedTab == tab.tag {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(CarbyoColors.primarySoft)
                                    .frame(height: 30)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .frame(height: 50)
        .background(CarbyoColors.surface)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(CarbyoColors.border),
            alignment: .top
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -2)
    }
}

#Preview {
    MainTabView()
        .environmentObject(SessionStore())
}
