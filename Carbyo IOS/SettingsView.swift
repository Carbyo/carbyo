//
//  SettingsView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Section Profil
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Profil")
                            .font(.headline)
                            .foregroundColor(CarbyoColors.muted)
                            .padding(.horizontal, 16)
                        
                        NavigationLink {
                            AccountView()
                                .environmentObject(session)
                        } label: {
                            CarbyoRowLink(
                                title: "Mon compte",
                                subtitle: session.profile?.pseudo ?? "Non renseigné",
                                systemIcon: "person.circle",
                                accent: CarbyoColors.primary
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                    }
                    
                    // Section Entreprise
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Entreprise")
                            .font(.headline)
                            .foregroundColor(CarbyoColors.muted)
                            .padding(.horizontal, 16)
                        
                        NavigationLink {
                            CompanyView()
                        } label: {
                            CarbyoRowLink(
                                title: "Mon entreprise",
                                systemIcon: "building.2",
                                accent: CarbyoColors.primary
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                    }
                    
                    // Section Véhicules
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Véhicules")
                            .font(.headline)
                            .foregroundColor(CarbyoColors.muted)
                            .padding(.horizontal, 16)
                        
                        NavigationLink {
                            VehiclesView()
                                .environmentObject(session)
                        } label: {
                            CarbyoRowLink(
                                title: "Mes véhicules",
                                subtitle: session.profile?.vehicles.isEmpty == false ? "\(session.profile!.vehicles.count) véhicule(s)" : nil,
                                systemIcon: "car",
                                accent: CarbyoColors.primary
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                    }
                    
                    // Section Sécurité
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sécurité")
                            .font(.headline)
                            .foregroundColor(CarbyoColors.muted)
                            .padding(.horizontal, 16)
                        
                        CarbyoCard {
                            Button(action: {
                                Task {
                                    await session.signOut()
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Se déconnecter")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.85))
                                .cornerRadius(.carbyoButtonRadius)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical, 12)
            }
            .carbyoScreen()
            .navigationTitle("Paramètres")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SessionStore())
}
