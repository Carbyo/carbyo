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
    @State private var showQuickTrip: Bool = false
    
    var body: some View {
        Group {
            if selectedTab == 0 {
                CockpitView()
                    .environmentObject(session)
            } else if selectedTab == 1 {
                TripsView()
            } else if selectedTab == 2 {
                SettingsView()
                    .environmentObject(session)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            CustomTabBar(selectedTab: $selectedTab, onAddTrip: {
                showQuickTrip = true
            })
        }
        .sheet(isPresented: $showQuickTrip) {
            QuickTripCreateView()
                .environmentObject(session)
        }
    }
}

// MARK: - Quick Trip Create View (Placeholder)
struct QuickTripCreateView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(CarbyoColors.primary)
                
                Text("Enregistrer un trajet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CarbyoColors.text)
                
                Text("Cette fonctionnalité sera bientôt disponible")
                    .font(.body)
                    .foregroundColor(CarbyoColors.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CarbyoColors.background)
            .navigationTitle("Nouveau trajet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Custom Compact TabBar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let onAddTrip: () -> Void
    
    struct TabItem {
        let title: String
        let icon: String
        let tag: Int
    }
    
    // Onglets : Cockpit, Mes trajets et Paramètres
    private let tabs: [TabItem] = [
        TabItem(title: "Cockpit", icon: "leaf.fill", tag: 0),
        TabItem(title: "Mes trajets", icon: "figure.walk", tag: 1),
        TabItem(title: "Paramètres", icon: "gearshape", tag: 2)
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Fond du footer
            HStack(spacing: 0) {
                // Boutons de navigation à gauche
                HStack(spacing: 6) {
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
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .frame(height: 44)
                            .padding(.horizontal, 8)
                            .background(
                                Group {
                                    if selectedTab == tab.tag {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(CarbyoColors.primarySoft)
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 12)
                
                Spacer(minLength: 60) // Espace minimum pour le bouton +
            }
            .frame(height: 56)
            .background(CarbyoColors.surface)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(CarbyoColors.border),
                alignment: .top
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -2)
            
            // Bouton "+" positionné absolument à droite, légèrement plus bas
            HStack {
                Spacer()
                Button {
                    onAddTrip()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(CarbyoColors.primary))
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
                }
                .accessibilityLabel("Ajouter un trajet")
                .offset(y: -4) // Légèrement plus bas pour éviter le chevauchement
                .padding(.trailing, 16)
            }
        }
        .frame(height: 56)
    }
}

#Preview {
    MainTabView()
        .environmentObject(SessionStore())
}
