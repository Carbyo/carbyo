//
//  SupabaseClient.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import Foundation
import Supabase

/// Gestionnaire centralisé pour le client Supabase
class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // Configuration Supabase depuis Info.plist ou variables d'environnement
        guard let supabaseURLString = Self.getSupabaseURL(),
              let supabaseURL = URL(string: supabaseURLString),
              let supabaseKey = Self.getSupabaseAnonKey() else {
            fatalError("⚠️ Configuration Supabase manquante. Veuillez configurer SUPABASE_URL et SUPABASE_ANON_KEY dans Info.plist ou les variables d'environnement.")
        }
        
        // Configuration Supabase avec emitLocalSessionAsInitialSession pour éviter le warning
        // sur l'initial session (changement supabase-swift 2.x)
        // Voir: https://github.com/supabase/supabase-swift/pull/822
        // La configuration auth est appliquée via SupabaseClientOptions.AuthOptions
        // (défini dans Sources/Supabase/Types.swift ligne 37-94)
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
    
    // MARK: - Configuration
    
    /// Récupère l'URL Supabase depuis Info.plist ou les variables d'environnement
    private static func getSupabaseURL() -> String? {
        // 1. Vérifier les variables d'environnement (pour les tests/CI)
        if let url = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           !url.isEmpty && url != "https://your-project.supabase.co" {
            return url
        }
        
        // 2. Vérifier Info.plist
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let url = plist["SUPABASE_URL"] as? String,
           !url.isEmpty {
            return url
        }
        
        // 3. Vérifier les UserDefaults (pour une configuration runtime)
        if let url = UserDefaults.standard.string(forKey: "SUPABASE_URL"),
           !url.isEmpty {
            return url
        }
        
        return nil
    }
    
    /// Récupère la clé anonyme Supabase depuis Info.plist ou les variables d'environnement
    private static func getSupabaseAnonKey() -> String? {
        // 1. Vérifier les variables d'environnement (pour les tests/CI)
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
           !key.isEmpty && key != "your-anon-key" {
            return key
        }
        
        // 2. Vérifier Info.plist
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let key = plist["SUPABASE_ANON_KEY"] as? String,
           !key.isEmpty {
            return key
        }
        
        // 3. Vérifier les UserDefaults (pour une configuration runtime)
        if let key = UserDefaults.standard.string(forKey: "SUPABASE_ANON_KEY"),
           !key.isEmpty {
            return key
        }
        
        return nil
    }
    
    // MARK: - Méthodes utilitaires
    
    /// Configure Supabase de manière programmatique (optionnel, pour tests)
    static func configure(url: String, anonKey: String) {
        UserDefaults.standard.set(url, forKey: "SUPABASE_URL")
        UserDefaults.standard.set(anonKey, forKey: "SUPABASE_ANON_KEY")
    }
    
    /// Teste la connexion à Supabase en effectuant une requête simple
    /// - Returns: `true` si la connexion fonctionne, `false` sinon
    func testConnection() async -> Bool {
        do {
            // Test simple : récupérer la session actuelle (ou vérifier l'API)
            // On fait une requête simple qui ne nécessite pas d'authentification
            let _ = try await client.auth.session
            return true
        } catch {
            // Même si la session n'existe pas, on peut tester avec une requête simple
            // Si l'erreur est "no session", la connexion fonctionne quand même
            if error.localizedDescription.contains("session") || 
               error.localizedDescription.contains("not authenticated") {
                // Pas de session mais la connexion fonctionne
                return true
            }
            // Autre erreur (réseau, configuration, etc.)
            print("❌ Erreur de connexion Supabase: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Vérifie la configuration Supabase
    /// - Returns: Un tuple avec l'état de la configuration (url, key, status)
    static func checkConfiguration() -> (url: String?, key: String?, isConfigured: Bool) {
        let url = getSupabaseURL()
        let key = getSupabaseAnonKey()
        let isConfigured = url != nil && key != nil
        
        return (url, key, isConfigured)
    }
}
