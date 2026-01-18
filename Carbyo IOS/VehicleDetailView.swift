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
    let vehicle: VehicleSupabase
    @State private var showEditView = false
    @State private var showDeleteConfirmation = false
    @State private var photoResolvedURL: URL?
    
    private let vehiclesService = VehiclesService(client: SupabaseManager.shared.client)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo
                Group {
                    if let url = photoResolvedURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: "car")
                                    .font(.system(size: 100))
                                    .foregroundColor(.gray)
                            @unknown default:
                                Image(systemName: "car")
                                    .font(.system(size: 100))
                                    .foregroundColor(.gray)
                            }
                        }
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
                }
                
                // Informations
                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(label: "Plaque d'immatriculation", value: vehicle.registration ?? "—")
                    
                    InfoRow(label: "Énergie", value: vehicle.energy ?? "—")
                    
                    if let v7 = vehicle.v7_emissions {
                        InfoRow(label: "V7", value: String(format: "%.2f gCO2/km", v7))
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .navigationTitle(vehicle.registration ?? "Véhicule")
        .task {
            // Charger l'URL signée de la photo au chargement
            photoResolvedURL = await vehiclesService.resolvePhotoURL(vehicle.photo_url)
        }
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
                VehicleFormView(vehicle: Vehicle(
                    id: vehicle.id,
                    label: vehicle.registration ?? "—",
                    energy: vehicle.energy ?? "—",
                    v7Co2Gkm: vehicle.v7_emissions
                ))
                .environmentObject(session)
            }
        }
        .alert("Supprimer le véhicule", isPresented: $showDeleteConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                // TODO: Implémenter la suppression via VehiclesService
                // session.removeVehicle(vehicle)
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
        VehicleDetailView(vehicle: VehicleSupabase(
            id: UUID(),
            owner_id: UUID(),
            registration: "AB-123-CD",
            brand: nil,
            model: nil,
            energy: "Essence",
            v7_emissions: 120.5,
            photo_url: nil,
            created_at: nil
        ))
        .environmentObject(SessionStore())
    }
}
