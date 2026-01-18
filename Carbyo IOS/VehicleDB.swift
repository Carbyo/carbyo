//
//  VehicleDB.swift
//  Carbyo IOS
//
//  Created for Supabase integration
//

import Foundation

struct VehicleSupabase: Identifiable, Codable {
    let id: UUID
    let owner_id: UUID?
    let registration: String?
    let brand: String?
    let model: String?
    let energy: String?
    let v7_emissions: Double?
    let photo_url: String?
    let created_at: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case owner_id
        case registration
        case brand
        case model
        case energy
        case v7_emissions
        case photo_url
        case created_at
    }
    
    var createdDate: Date? {
        guard let created_at = created_at else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: created_at) ?? ISO8601DateFormatter().date(from: created_at)
    }
}
