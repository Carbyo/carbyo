//
//  VehicleEnergy.swift
//  Carbyo IOS
//
//  Created for vehicle energy enum
//

import Foundation

enum VehicleEnergy: String, CaseIterable, Codable, Hashable {
    case gasoline = "gasoline"
    case diesel = "diesel"
    case electric = "electric"
    case hybrid = "hybrid"
    case hydrogen = "hydrogen"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .gasoline: return "Essence"
        case .diesel: return "Diesel"
        case .electric: return "Électrique"
        case .hybrid: return "Hybride"
        case .hydrogen: return "Hydrogène"
        case .other: return "Autre"
        }
    }
    
    var subMode: String? {
        switch self {
        case .gasoline: return "petrol"
        case .diesel: return "diesel"
        case .electric: return "electric"
        case .hybrid: return "hybrid"
        case .hydrogen: return nil
        case .other: return nil
        }
    }
    
    init?(from string: String?) {
        guard let string = string?.lowercased() else { return nil }
        
        // Mapping depuis libellés français ou anglais
        switch string {
        case "essence", "gasoline":
            self = .gasoline
        case "diesel":
            self = .diesel
        case "électrique", "electric", "electrique":
            self = .electric
        case "hybride", "hybrid":
            self = .hybrid
        case "hydrogène", "hydrogen":
            self = .hydrogen
        default:
            self = .other
        }
    }
}
