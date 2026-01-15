//
//  VehiclesView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct VehiclesView: View {
    @EnvironmentObject var session: SessionStore
    @State private var showAddVehicle = false
    
    var body: some View {
        NavigationStack {
            if let vehicles = session.profile?.vehicles, !vehicles.isEmpty {
                List {
                    ForEach(vehicles) { vehicle in
                        NavigationLink {
                            VehicleDetailView(vehicle: vehicle)
                                .environmentObject(session)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(vehicle.displayTitle)
                                    .font(.headline)
                                
                                if let v7 = vehicle.v7Co2Gkm {
                                    Text("V7: \(String(format: "%.2f", v7)) gCO2/km")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let photoData = vehicle.photoData,
                                   let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .padding(.top, 4)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { offsets in
                        session.removeVehicle(at: offsets)
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
            } else {
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
        }
        .sheet(isPresented: $showAddVehicle) {
            NavigationStack {
                VehicleFormView(vehicle: nil)
                    .environmentObject(session)
            }
        }
        .onAppear {
            // Le profil est déjà chargé via SessionStore.init()
        }
    }
}

#Preview {
    VehiclesView()
        .environmentObject(SessionStore())
}
