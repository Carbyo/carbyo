//
//  VehicleOnboardingView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI
import PhotosUI

struct VehicleOnboardingView: View {
    @EnvironmentObject var onboardingStore: OnboardingStore
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var plate: String = ""
    @State private var energy: String = ""
    @State private var v7Text: String = ""
    
    var isFormValid: Bool {
        !plate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !energy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !v7Text.isEmpty &&
        (Double(v7Text) ?? 0) > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Text("Photo du véhicule")
                                .foregroundColor(.primary)
                            Spacer()
                            if let photoData = photoData,
                               let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "photo.badge.plus")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .onChange(of: selectedPhoto) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                photoData = data
                            }
                        }
                    }
                    
                    TextField("Plaque d'immatriculation *", text: $plate)
                        .textInputAutocapitalization(.characters)
                    
                    TextField("Énergie (ex: Essence, Diesel, Électrique) *", text: $energy)
                    
                    TextField("V7 (gCO2/km) *", text: $v7Text)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Informations du véhicule")
                } footer: {
                    Text("* Champ obligatoire")
                }
                
                if let firstVehicle = session.profile?.vehicles.first {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(firstVehicle.displayTitle)
                                .font(.headline)
                            
                            if let v7 = firstVehicle.v7Co2Gkm {
                                HStack {
                                    Text("V7:")
                                        .font(.subheadline)
                                    Text(String(format: "%.2f", v7))
                                        .font(.body)
                                    Text("gCO2/km")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let photoData = firstVehicle.photoData,
                               let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Véhicule enregistré")
                    }
                }
            }
            .navigationTitle("Véhicule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        saveVehicle()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                if let firstVehicle = session.profile?.vehicles.first {
                    plate = firstVehicle.label
                    energy = firstVehicle.energy
                    if let v7 = firstVehicle.v7Co2Gkm {
                        v7Text = String(format: "%.2f", v7)
                    }
                    photoData = firstVehicle.photoData
                }
            }
        }
    }
    
    private func saveVehicle() {
        let trimmedPlate = plate.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEnergy = energy.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let v7Value = Double(v7Text), v7Value > 0 else {
            return
        }
        
        let vehicle = Vehicle(
            label: trimmedPlate,
            energy: trimmedEnergy,
            v7Co2Gkm: v7Value,
            photoData: photoData
        )
        
        session.addVehicle(vehicle)
        onboardingStore.hasVehicle = true
        dismiss()
    }
}

#Preview {
    VehicleOnboardingView()
        .environmentObject(OnboardingStore())
        .environmentObject(SessionStore())
}
