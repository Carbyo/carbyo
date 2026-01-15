//
//  VehicleDetailView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct VehicleDetailView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) var dismiss
    let vehicle: Vehicle
    @State private var showEditView = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo
                if let photoData = vehicle.photoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                } else {
                    Image(systemName: "car")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)
                        .frame(width: 300, height: 200)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                }
                
                // Informations
                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(label: "Plaque d'immatriculation", value: vehicle.label)
                    
                    InfoRow(label: "Énergie", value: vehicle.energy)
                    
                    if let v7 = vehicle.v7Co2Gkm {
                        InfoRow(label: "V7", value: String(format: "%.2f gCO2/km", v7))
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .navigationTitle(vehicle.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Supprimer")
                        .foregroundColor(.red)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Modifier") {
                    showEditView = true
                }
            }
        }
        .sheet(isPresented: $showEditView) {
            NavigationStack {
                VehicleFormView(vehicle: vehicle)
                    .environmentObject(session)
            }
        }
        .alert("Supprimer le véhicule", isPresented: $showDeleteConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                session.removeVehicle(vehicle)
                dismiss()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer ce véhicule ? Cette action est irréversible.")
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        VehicleDetailView(vehicle: Vehicle(label: "AB-123-CD", energy: "Essence", v7Co2Gkm: 120.5))
            .environmentObject(SessionStore())
    }
}
