//
//  ProfileDB.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import Foundation

// Modèle pour la table Supabase profiles
struct ProfileDB: Codable {
    let id: UUID
    let email: String
    var username: String?
    var onboarding_completed: Bool
    let created_at: String?
    
    init(id: UUID, email: String, username: String? = nil, onboarding_completed: Bool = false, created_at: String? = nil) {
        self.id = id
        self.email = email
        self.username = username
        self.onboarding_completed = onboarding_completed
        self.created_at = created_at
    }
}
