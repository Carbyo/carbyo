//
//  MesVehiculesViewModel.swift
//  Carbyo IOS
//
//  Created for Supabase integration
//

import Foundation
import Combine

@MainActor
class MesVehiculesViewModel: ObservableObject {
    @Published var vehicles: [VehicleSupabase] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let vehiclesService: VehiclesService
    
    init(vehiclesService: VehiclesService) {
        self.vehiclesService = vehiclesService
    }
    
    /// Charge les véhicules de l'utilisateur connecté depuis Supabase
    func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedVehicles = try await vehiclesService.fetchMyVehicles()
            vehicles = fetchedVehicles
            print("[VEHICLES] Loaded \(vehicles.count) vehicles successfully")
        } catch {
            errorMessage = error.localizedDescription
            print("[VEHICLES] Error loading vehicles: \(error.localizedDescription)")
            vehicles = []
        }
        
        isLoading = false
    }
}
