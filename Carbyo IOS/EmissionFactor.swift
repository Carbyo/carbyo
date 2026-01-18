//
//  EmissionFactor.swift
//  Carbyo IOS
//
//  Created for emission factors from Supabase
//

import Foundation

struct EmissionFactor: Codable, Hashable {
    let nom: String?
    let valeur: Double? // g/km
    let factor_kgco2e_per_km: Double? // kg/km
}
