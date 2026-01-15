//
//  PersonalAddressOnboardingView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct PersonalAddressOnboardingView: View {
    @EnvironmentObject var onboardingStore: OnboardingStore
    @Environment(\.dismiss) var dismiss
    @State private var addressLine: String = ""
    @State private var city: String = ""
    @State private var postalCode: String = ""
    @State private var country: String = "France"
    
    var isFormValid: Bool {
        !addressLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Adresse", text: $addressLine)
                    TextField("Ville", text: $city)
                    TextField("Code postal", text: $postalCode)
                    TextField("Pays", text: $country)
                } header: {
                    Text("Informations d'adresse")
                }
                
                if let existingAddress = onboardingStore.homeAddress {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(existingAddress.title)
                                .font(.body)
                            Text(existingAddress.subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Adresse enregistrée")
                    }
                }
            }
            .navigationTitle("Adresse personnelle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Valider") {
                        saveAddress()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                if let existingAddress = onboardingStore.homeAddress {
                    // Pré-remplir les champs si une adresse existe déjà
                    let components = existingAddress.title.components(separatedBy: ", ")
                    if components.count > 0 {
                        addressLine = components[0]
                    }
                    city = existingAddress.subtitle
                }
            }
        }
    }
    
    private func saveAddress() {
        let trimmedAddressLine = addressLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPostalCode = postalCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedAddressLine.isEmpty && !trimmedCity.isEmpty && !trimmedPostalCode.isEmpty else {
            return
        }
        
        let fullAddress = "\(trimmedAddressLine), \(trimmedPostalCode) \(trimmedCity), \(trimmedCountry)"
        let address = Address(
            title: trimmedAddressLine,
            subtitle: "\(trimmedPostalCode) \(trimmedCity)",
            fullText: fullAddress,
            latitude: 0.0,
            longitude: 0.0
        )
        
        onboardingStore.setHomeAddress(address)
        dismiss()
    }
}

#Preview {
    PersonalAddressOnboardingView()
        .environmentObject(OnboardingStore())
}
