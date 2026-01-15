//
//  VehicleFormView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI
import PhotosUI

struct VehicleFormView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) var dismiss
    
    let vehicle: Vehicle?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var plate: String = ""
    @State private var energy: String = ""
    @State private var v7Text: String = ""
    
    var isEditMode: Bool {
        vehicle != nil
    }
    
    var isFormValid: Bool {
        !plate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !energy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !v7Text.isEmpty &&
        (Double(v7Text) ?? 0) > 0
    }
    
    var body: some View {
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
        }
        .navigationTitle(isEditMode ? "Modifier le véhicule" : "Nouveau véhicule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Enregistrer") {
                    saveVehicle()
                }
                .disabled(!isFormValid)
            }
        }
        .onAppear {
            if let vehicle = vehicle {
                plate = vehicle.label
                energy = vehicle.energy
                if let v7 = vehicle.v7Co2Gkm {
                    v7Text = String(format: "%.2f", v7)
                }
                photoData = vehicle.photoData
            }
        }
    }
    
    private func saveVehicle() {
        let trimmedPlate = plate.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEnergy = energy.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let v7Value = Double(v7Text), v7Value > 0 else {
            return
        }
        
        if let existingVehicle = vehicle {
            // Mode édition : mettre à jour le véhicule existant
            let updatedVehicle = Vehicle(
                id: existingVehicle.id,
                label: trimmedPlate,
                energy: trimmedEnergy,
                v7Co2Gkm: v7Value,
                photoData: photoData
            )
            session.updateVehicle(updatedVehicle)
        } else {
            // Mode création : ajouter un nouveau véhicule
            let newVehicle = Vehicle(
                label: trimmedPlate,
                energy: trimmedEnergy,
                v7Co2Gkm: v7Value,
                photoData: photoData
            )
            session.addVehicle(newVehicle)
        }
        
        dismiss()
    }
}

#Preview {
    NavigationStack {
        VehicleFormView(vehicle: nil)
            .environmentObject(SessionStore())
    }
}
