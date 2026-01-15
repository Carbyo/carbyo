//
//  OnboardingView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var onboardingStore: OnboardingStore
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Onboarding")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 20) {
                    NavigationLink {
                        ProfileOnboardingView()
                    } label: {
                        OnboardingRow(
                            title: "Profil",
                            isComplete: onboardingStore.hasProfile || session.profile != nil,
                            action: {}
                        )
                    }
                    
                    NavigationLink {
                        PersonalAddressOnboardingView()
                    } label: {
                        OnboardingRow(
                            title: "Adresse personnelle",
                            isComplete: onboardingStore.hasHomeAddress,
                            action: {}
                        )
                    }
                    
                    NavigationLink {
                        WorkAddressOnboardingView()
                    } label: {
                        OnboardingRow(
                            title: "Adresse professionnelle",
                            isComplete: onboardingStore.hasWorkAddress,
                            action: {}
                        )
                    }
                    
                    NavigationLink {
                        VehicleOnboardingView()
                    } label: {
                        OnboardingRow(
                            title: "Véhicule",
                            isComplete: onboardingStore.hasVehicle || (session.profile?.vehicles.isEmpty == false),
                            action: {}
                        )
                    }
                }
                .padding()
                
                var onboardingCompleted: Bool {
                    (onboardingStore.hasProfile || session.profile != nil) && 
                    onboardingStore.hasHomeAddress && 
                    onboardingStore.hasWorkAddress && 
                    (onboardingStore.hasVehicle || (session.profile?.vehicles.isEmpty == false))
                }
                
                if onboardingCompleted {
                    VStack(spacing: 20) {
                        Text("Onboarding terminé")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Text("Vous pouvez maintenant accéder à l'application")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            // Navigation automatique via ContentView qui détecte onboardingCompleted
                        }) {
                            Text("Terminer")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
                
                Spacer()
            }
            .navigationTitle("Onboarding")
        }
    }
}

struct OnboardingRow: View {
    let title: String
    let isComplete: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            Text(isComplete ? "✅" : "⬜️")
                .font(.title2)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                HStack(spacing: 4) {
                    Text("Compléter")
                        .foregroundColor(.blue)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .contentShape(Rectangle())
    }
}

#Preview {
    OnboardingView()
        .environmentObject(OnboardingStore())
}
