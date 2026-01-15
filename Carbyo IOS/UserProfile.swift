//
//  UserProfile.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import Foundation

struct UserProfile: Codable {
    var id: UUID?
    var email: String?
    var pseudo: String
    var firstName: String?
    var lastName: String?
    var vehicles: [Vehicle]
    var onboarding_completed: Bool
    
    init(id: UUID? = nil, email: String? = nil, pseudo: String, firstName: String? = nil, lastName: String? = nil, vehicles: [Vehicle] = [], onboarding_completed: Bool = false) {
        self.id = id
        self.email = email
        self.pseudo = pseudo
        self.firstName = firstName
        self.lastName = lastName
        self.vehicles = vehicles
        self.onboarding_completed = onboarding_completed
    }
    
    // Convertir depuis ProfileDB (Supabase)
    init(from profileDB: ProfileDB, vehicles: [Vehicle] = [], firstName: String? = nil, lastName: String? = nil) {
        self.id = profileDB.id
        self.email = profileDB.email
        self.pseudo = profileDB.pseudo ?? profileDB.email.components(separatedBy: "@").first ?? "Utilisateur"
        self.firstName = firstName
        self.lastName = lastName
        self.vehicles = vehicles
        self.onboarding_completed = profileDB.onboarding_completed
    }
}
