//
//  VehiclesView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct VehiclesView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel: MesVehiculesViewModel
    @State private var showAddVehicle = false
    private let vehiclesService: VehiclesService
    
    init() {
        let service = VehiclesService(client: SupabaseManager.shared.client)
        _viewModel = StateObject(wrappedValue: MesVehiculesViewModel(vehiclesService: service))
        vehiclesService = service
    }
    
    var body: some View {
        NavigationStack {
            // Vérifier l'authentification
            if session.isLoggedIn {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .navigationTitle("Mes véhicules")
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Erreur")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("Mes véhicules")
                } else if viewModel.vehicles.isEmpty {
                    // État vide
                    VStack(spacing: 20) {
                        Image(systemName: "car")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Aucun véhicule")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Appuyez sur + pour en ajouter un")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("Mes véhicules")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showAddVehicle = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                } else {
                    // Liste des véhicules
                    List {
                        ForEach(viewModel.vehicles) { vehicle in
                            NavigationLink {
                                VehicleDetailView(vehicle: vehicle)
                                    .environmentObject(session)
                            } label: {
                                HStack(spacing: 12) {
                                    // Photo du véhicule
                                    VehiclePhotoView(photoUrl: vehicle.photo_url, vehiclesService: vehiclesService)
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .background(Color(.systemGray6))
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(vehicle.registration ?? "—")
                                            .font(.headline)
                                        
                                        Text(vehicle.energy ?? "—")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        if let v7 = vehicle.v7_emissions {
                                            Text("V7: \(String(format: "%.1f", v7)) g/km")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .navigationTitle("Mes véhicules")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showAddVehicle = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
            } else {
                // Non connecté
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Connectez-vous pour voir vos véhicules")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Mes véhicules")
            }
        }
        .sheet(isPresented: $showAddVehicle) {
            NavigationStack {
                VehicleFormView(vehicle: nil)
                    .environmentObject(session)
            }
        }
        .task {
            if session.isLoggedIn {
                await viewModel.load()
                await MainActor.run {
                    session.hasVehicle = !viewModel.vehicles.isEmpty
                }
            }
        }
        .refreshable {
            if session.isLoggedIn {
                await viewModel.load()
                await MainActor.run {
                    session.hasVehicle = !viewModel.vehicles.isEmpty
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .vehiclesChanged)) { _ in
            Task {
                if session.isLoggedIn {
                    await viewModel.load()
                    await MainActor.run {
                        session.hasVehicle = !viewModel.vehicles.isEmpty
                    }
                }
            }
        }
    }
}

#Preview {
    VehiclesView()
        .environmentObject(SessionStore())
}
