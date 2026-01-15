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
    var username: String
    var firstName: String?
    var lastName: String?
    var vehicles: [Vehicle]
    var onboarding_completed: Bool
    
    init(id: UUID? = nil, email: String? = nil, username: String, firstName: String? = nil, lastName: String? = nil, vehicles: [Vehicle] = [], onboarding_completed: Bool = false) {
        self.id = id
        self.email = email
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.vehicles = vehicles
        self.onboarding_completed = onboarding_completed
    }
    
    // Convertir depuis ProfileDB (Supabase)
    init(from profileDB: ProfileDB, vehicles: [Vehicle] = [], firstName: String? = nil, lastName: String? = nil) {
        self.id = profileDB.id
        self.email = profileDB.email
        // Ne plus tronquer l'email - utiliser le username si disponible, sinon l'email complet
        self.username = profileDB.username ?? profileDB.email
        self.firstName = firstName
        self.lastName = lastName
        self.vehicles = vehicles
        self.onboarding_completed = profileDB.onboarding_completed
    }
    
    // Alias de compatibilité pour le code existant qui utilise .pseudo
    var pseudo: String {
        get { username }
        set { username = newValue }
    }
}
