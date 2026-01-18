//
//  SessionStore.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import Foundation
import Combine
import Supabase

enum InvitationStatus: String, Codable {
    case none
    case pending
    case accepted
    case refused
}

/// Erreurs d'authentification avec messages utilisateur localisés
enum AuthError: LocalizedError {
    case userNotFound
    case invalidCredentials
    case emailAlreadyExists
    case weakPassword
    case registrationFailed
    case networkError
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Utilisateur introuvable"
        case .invalidCredentials:
            return "Email ou mot de passe incorrect"
        case .emailAlreadyExists:
            return "Cet email est déjà utilisé"
        case .weakPassword:
            return "Le mot de passe doit contenir au moins 6 caractères"
        case .registrationFailed:
            return "Erreur lors de l'inscription. Veuillez réessayer."
        case .networkError:
            return "Erreur de connexion. Vérifiez votre connexion internet."
        case .custom(let message):
            return message
        }
    }
    
    static func from(supabaseError: Error) -> AuthError {
        let errorString = supabaseError.localizedDescription.lowercased()
        
        if errorString.contains("invalid") && errorString.contains("credentials") {
            return .invalidCredentials
        } else if errorString.contains("email") && (errorString.contains("already") || errorString.contains("exists")) {
            return .emailAlreadyExists
        } else if errorString.contains("password") && errorString.contains("weak") {
            return .weakPassword
        } else if errorString.contains("network") || errorString.contains("connection") {
            return .networkError
        } else {
            return .custom(supabaseError.localizedDescription)
        }
    }
}

@MainActor
final class SessionStore: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUserEmail: String?
    @Published var authError: String?
    @Published var profile: UserProfile? {
        didSet {
            if profile != nil {
                updateHasProfile()
            }
        }
    }
    @Published var hasVehicle: Bool = false
    @Published var invitationStatus: InvitationStatus = .pending {
        didSet {
            saveInvitationStatus()
        }
    }
    
    private let supabase = SupabaseManager.shared.client
    private let homeAddressKey = "homeAddress"
    private let workAddressKey = "workAddress"
    private let invitationStatusKey = "invitationStatus"
    
    var isOnboardingComplete: Bool {
        guard let profile = profile else { return false }
        
        // Utiliser onboarding_completed depuis la base si disponible
        if profile.onboarding_completed {
            return true
        }
        
        // Sinon, vérifier les conditions locales comme avant
        guard !profile.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        guard UserDefaults.standard.data(forKey: homeAddressKey) != nil else {
            return false
        }
        
        guard UserDefaults.standard.data(forKey: workAddressKey) != nil else {
            return false
        }
        
        guard hasVehicle else {
            return false
        }
        
        return true
    }
    
    var shouldShowInvitation: Bool {
        invitationStatus == .pending && !isOnboardingComplete
    }
    
    init() {
        loadInvitationStatus()
    }
    
    /// Restaure la session Supabase si une session valide existe
    func restoreSession() async {
        authError = nil
        do {
            let session = try await supabase.auth.session
            
            // Vérifier que la session n'est pas expirée (changement supabase-swift 2.x)
            // Une session expirée ne doit pas être considérée comme "connectée"
            guard !session.isExpired else {
                // Session expirée : déconnecter l'utilisateur
                isLoggedIn = false
                currentUserEmail = nil
                profile = nil
                return
            }
            
            currentUserEmail = session.user.email
            try await loadProfile(userId: session.user.id)
            isLoggedIn = true
        } catch {
            // Pas de session active ou session expirée
            isLoggedIn = false
            currentUserEmail = nil
            profile = nil
        }
    }
    
    func login(email: String, password: String) async throws {
        authError = nil
        do {
            let response = try await supabase.auth.signIn(email: email, password: password)
            let user = response.user
            
            currentUserEmail = user.email
            try await loadProfile(userId: user.id)
            isLoggedIn = true
        } catch let error as AuthError {
            authError = error.errorDescription
            throw error
        } catch {
            // Convertir les erreurs Supabase en messages utilisateur lisibles
            let authError = AuthError.from(supabaseError: error)
            self.authError = authError.errorDescription
            throw authError
        }
    }
    
    func signUp(email: String, password: String) async throws {
        authError = nil
        do {
            // 1. Créer l'utilisateur dans Supabase Auth
            let response = try await supabase.auth.signUp(email: email, password: password)
            let user = response.user
            
            // 2. Créer ou upsert le profil dans la table profiles
            // Ne plus tronquer l'email - utiliser l'email complet comme username par défaut
            let username = email
            
            struct ProfileInsert: Codable {
                let id: String
                let email: String
                let username: String?
                let onboarding_completed: Bool
            }
            
            let insert = ProfileInsert(
                id: user.id.uuidString,
                email: email,
                username: username,
                onboarding_completed: false
            )
            
            try await supabase
                .from("profiles")
                .upsert(insert, onConflict: "id")
                .execute()
            
            // 3. Charger le profil
            currentUserEmail = user.email
            try await loadProfile(userId: user.id)
            isLoggedIn = true
        } catch let error as AuthError {
            authError = error.errorDescription
            throw error
        } catch {
            // Convertir les erreurs Supabase en messages utilisateur lisibles
            let authError = AuthError.from(supabaseError: error)
            self.authError = authError.errorDescription
            throw authError
        }
    }
    
    func loadProfile(userId: UUID) async throws {
        // Sélection explicite des colonnes nécessaires, notamment email et username
        let response: [ProfileDB] = try await supabase
            .from("profiles")
            .select("id, email, username, onboarding_completed, created_at")
            .eq("id", value: userId.uuidString)
            .execute()
            .value
        
        guard let profileDB = response.first else {
            throw NSError(domain: "ProfileError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Profil introuvable"])
        }
        
        #if DEBUG
        print("[PROFILE_DEBUG] profile.email=\(profileDB.email)")
        print("[PROFILE_DEBUG] profile.username=\(profileDB.username ?? "nil")")
        #endif
        
        // Charger les véhicules depuis la table vehicles si nécessaire
        // Pour l'instant, on garde la logique existante avec UserProfile.vehicles
        profile = UserProfile(from: profileDB)
        
        // Charger les véhicules depuis Supabase si vous avez une table dédiée
        // Sinon, conserver la logique actuelle
    }
    
    func signOut() async {
        authError = nil
        do {
            try await supabase.auth.signOut()
        } catch {
            // En cas d'erreur, on continue quand même la déconnexion locale
            authError = "Erreur lors de la déconnexion, mais vous avez été déconnecté localement"
        }
        
        // Toujours nettoyer l'état local
        isLoggedIn = false
        currentUserEmail = nil
        profile = nil
        invitationStatus = .none
        UserDefaults.standard.removeObject(forKey: invitationStatusKey)
    }
    
    // MARK: - Méthodes d'authentification supplémentaires
    
    /// Réinitialise le mot de passe (envoie un email de réinitialisation)
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }
    
    /// Rafraîchit la session actuelle
    func refreshSession() async throws {
        let session = try await supabase.auth.refreshSession()
        
        // Vérifier que la session rafraîchie n'est pas expirée (changement supabase-swift 2.x)
        guard !session.isExpired else {
            // Session expirée après refresh : déconnecter
            isLoggedIn = false
            currentUserEmail = nil
            profile = nil
            throw AuthError.networkError
        }
        
        try await loadProfile(userId: session.user.id)
        isLoggedIn = true
    }
    
    private func saveInvitationStatus() {
        if let encoded = try? JSONEncoder().encode(invitationStatus) {
            UserDefaults.standard.set(encoded, forKey: invitationStatusKey)
        }
    }
    
    private func loadInvitationStatus() {
        if let data = UserDefaults.standard.data(forKey: invitationStatusKey),
           let decoded = try? JSONDecoder().decode(InvitationStatus.self, from: data) {
            invitationStatus = decoded
        }
    }
    
    private func updateHasProfile() {
        // Placeholder: la logique onboarding sera branchée plus tard.
        // Pour l'instant, le simple fait d'avoir un profil non-nil suffit
        // et cette méthode évite l'erreur de compilation.
    }
    
    func updateProfileOnboarding(_ completed: Bool) async throws {
        guard let userId = profile?.id else { return }
        
        try await supabase
            .from("profiles")
            .update(["onboarding_completed": completed])
            .eq("id", value: userId)
            .execute()
        
        profile?.onboarding_completed = completed
    }
    
    func addVehicle(_ vehicle: Vehicle) {
        if profile == nil {
            profile = UserProfile(username: "", vehicles: [])
        }
        profile?.vehicles.append(vehicle)
    }
    
    func removeVehicle(at offsets: IndexSet) {
        guard var vehicles = profile?.vehicles else { return }
        for index in offsets.sorted(by: >) {
            if vehicles.indices.contains(index) {
                vehicles.remove(at: index)
            }
        }
        profile?.vehicles = vehicles
    }
    
    func removeVehicle(_ vehicle: Vehicle) {
        guard var vehicles = profile?.vehicles else { return }
        vehicles.removeAll { $0.id == vehicle.id }
        profile?.vehicles = vehicles
    }
    
    func updateVehicle(_ vehicle: Vehicle) {
        guard var vehicles = profile?.vehicles else { return }
        if let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            vehicles[index] = vehicle
            profile?.vehicles = vehicles
        }
    }
}
