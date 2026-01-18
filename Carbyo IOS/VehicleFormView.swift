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
    @State private var energy: VehicleEnergy = .gasoline
    @State private var v7Text: String = ""
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var genericFactor: EmissionFactor?
    @State private var factorLoading = false
    @State private var factorError: String?
    
    private let vehiclesService = VehiclesService(client: SupabaseManager.shared.client)
    private let emissionFactorsService = EmissionFactorsService(client: SupabaseManager.shared.client)
    
    var isEditMode: Bool {
        vehicle != nil
    }
    
    var isFormValid: Bool {
        !plate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !v7Text.isEmpty &&
        (Double(v7Text) ?? 0) > 0
    }
    
    var v7Value: Double? {
        guard let value = Double(v7Text), value > 0 else { return nil }
        return value
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
                
                Picker("Énergie *", selection: $energy) {
                    ForEach(VehicleEnergy.allCases, id: \.self) { energyOption in
                        Text(energyOption.displayName).tag(energyOption)
                    }
                }
                
                TextField("V7 (gCO2/km) *", text: $v7Text)
                    .keyboardType(.decimalPad)
                
                // Facteur d'émission générique
                VStack(alignment: .leading, spacing: 8) {
                    Text("Facteur d'émission utilisé si V7 non renseignée")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if factorLoading {
                        Text("Chargement…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if genericFactor == nil {
                        Text("Non disponible (fallback)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        if let valeur = genericFactor?.valeur {
                            Text("\(String(format: "%.1f", valeur)) gCO₂/km")
                                .font(.caption)
                                .foregroundColor(.primary)
                        } else if let kgValue = genericFactor?.factor_kgco2e_per_km {
                            Text("\(String(format: "%.4f", kgValue)) kgCO₂e/km")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        
                        if let nom = genericFactor?.nom {
                            Text(nom)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                // Message si V7 prioritaire
                if let v7 = v7Value, v7 > 0 {
                    Text("V7 prioritaire — ce facteur ne sera pas utilisé")
                        .font(.caption)
                        .foregroundColor(CarbyoColors.primary)
                        .padding(.top, 4)
                }
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
                    Task {
                        await saveVehicle()
                    }
                }
                .disabled(!isFormValid || isSaving)
            }
        }
        .onAppear {
            if let vehicle = vehicle {
                plate = vehicle.label
                // Mapper depuis String vers VehicleEnergy
                energy = VehicleEnergy(rawValue: vehicle.energy) ?? .gasoline
                if let v7 = vehicle.v7Co2Gkm {
                    v7Text = String(format: "%.2f", v7)
                }
                photoData = vehicle.photoData
            }
            // Charger le facteur d'émission au chargement
            Task {
                await loadEmissionFactor()
            }
        }
        .onChange(of: energy) { oldValue, newValue in
            // Recharger le facteur d'émission quand l'énergie change
            Task {
                await loadEmissionFactor()
            }
        }
        .alert("Erreur", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadEmissionFactor() async {
        factorLoading = true
        factorError = nil
        
        do {
            genericFactor = try await emissionFactorsService.fetchGenericCarFactor(for: energy)
        } catch {
            factorError = error.localizedDescription
            print("[VEHICLE_FORM] Error loading emission factor: \(error.localizedDescription)")
            genericFactor = nil
        }
        
        factorLoading = false
    }
    
    private func saveVehicle() async {
        let trimmedPlate = plate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let v7Value = Double(v7Text), v7Value > 0 else {
            return
        }
        
        isSaving = true
        
        do {
            // Utiliser energy.rawValue (gasoline/diesel/etc.) au lieu d'un libellé FR
            if let existingVehicle = vehicle {
                // Mode édition : mettre à jour le véhicule existant dans Supabase
                try await vehiclesService.updateVehicle(
                    vehicleId: existingVehicle.id,
                    registration: trimmedPlate,
                    energy: energy.rawValue,
                    v7: v7Value,
                    photoData: photoData
                )
            } else {
                // Mode création : créer un nouveau véhicule dans Supabase
                _ = try await vehiclesService.createVehicle(
                    registration: trimmedPlate,
                    energy: energy.rawValue,
                    v7: v7Value,
                    photoData: photoData
                )
            }
            
            // Notifier que les véhicules ont changé
            NotificationCenter.default.post(name: .vehiclesChanged, object: nil)
            
            // Fermer la vue
            await MainActor.run {
                dismiss()
            }
        } catch {
            // Construire un message d'erreur détaillé
            var errorDetails = "Erreur lors de l'enregistrement : \(error.localizedDescription)"
            
            // Ajouter le code d'erreur si disponible
            if let nsError = error as NSError? {
                errorDetails += "\n\nCode: \(nsError.code)"
                if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                    errorDetails += "\nErreur sous-jacente: \(underlyingError.localizedDescription)"
                }
            }
            
            // Ajouter les valeurs utilisées
            errorDetails += "\n\nÉnergie envoyée: \(energy.rawValue)"
            
            await MainActor.run {
                alertMessage = errorDetails
                showAlert = true
            }
        }
        
        isSaving = false
    }
}

#Preview {
    NavigationStack {
        VehicleFormView(vehicle: nil)
            .environmentObject(SessionStore())
    }
}
