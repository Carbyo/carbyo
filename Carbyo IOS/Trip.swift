//
//  Trip.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import Foundation

struct Trip: Codable, Identifiable {
    let id: UUID
    let user_id: UUID?
    let vehicle_id: UUID?
    let trip_date: String? // Format "YYYY-MM-DD"
    let origin_address: String?
    let destination_address: String?
    let distance_km: Double?
    let co2_emissions_kg: Double?
    let transport_mode: String?
    let type_trajet: String? // "perso" (personnel) / "pro" (professionnel)
    let created_at: String? // timestamptz
    let calculation_method: String?
    
    // Jointure véhicule (optionnel)
    let vehicles: VehicleDB?
    
    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case vehicle_id
        case trip_date
        case origin_address
        case destination_address
        case distance_km
        case co2_emissions_kg
        case transport_mode
        case type_trajet
        case created_at
        case calculation_method
        case vehicles
    }
    
    // Propriété calculée pour formater la date en français court
    var shortDateFR: String {
        guard let dateString = trip_date else { return "" }
        
        // Parser la date au format "YYYY-MM-DD" (en_US_POSIX pour éviter les problèmes de locale)
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        
        guard let date = parser.date(from: dateString) else {
            return dateString
        }
        
        // Formater pour l'affichage en français
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

extension Trip {
    var typeShort: String {
        let t = (type_trajet ?? "").lowercased()
        return t == "pro" ? "PRO" : "PERSO"
    }
    
    var kmShort: String {
        String(format: "%.1f", distance_km ?? 0) + " km"
    }
    
    var co2Short: String {
        String(format: "%.2f", co2_emissions_kg ?? 0) + " kg"
    }
}

// Modèle pour la jointure véhicule depuis Supabase
struct VehicleDB: Codable {
    let id: UUID?
    let owner_id: UUID?
    let registration: String?
    let brand: String?
    let model: String?
    let energy: String?
    let v7_emissions: Double? // g/km
    let consumption_per_100km: Double?
}
