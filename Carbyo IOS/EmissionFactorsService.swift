//
//  EmissionFactorsService.swift
//  Carbyo IOS
//
//  Created for emission factors from Supabase
//

import Foundation
import Supabase

final class EmissionFactorsService {
    let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    /// Récupère le facteur d'émission générique pour une énergie de véhicule
    /// - Parameter energy: Le type d'énergie du véhicule
    /// - Returns: EmissionFactor si trouvé, nil sinon
    /// - Throws: Erreur si la requête échoue
    func fetchGenericCarFactor(for energy: VehicleEnergy) async throws -> EmissionFactor? {
        guard let subMode = energy.subMode else {
            return nil
        }
        
        print("[EMISSION_FACTORS] Fetching factor for sub_mode: \(subMode)")
        
        let response: [EmissionFactor] = try await client
            .from("emission_factors")
            .select("nom, valeur, factor_kgco2e_per_km")
            .eq("mode", value: "car")
            .eq("is_active", value: true)
            .eq("sub_mode", value: subMode)
            .limit(1)
            .execute()
            .value
        
        if let factor = response.first {
            print("[EMISSION_FACTORS] Found factor: \(factor.nom ?? "—")")
        } else {
            print("[EMISSION_FACTORS] No factor found for sub_mode: \(subMode)")
        }
        
        return response.first
    }
}
