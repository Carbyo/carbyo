//
//  VehiclesService.swift
//  Carbyo IOS
//
//  Created for Supabase integration
//

import Foundation
import Supabase

final class VehiclesService {
    let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    /// Récupère tous les véhicules de l'utilisateur connecté
    /// Filtre explicite par owner_id = auth.uid() pour garantir l'isolation des données
    /// - Returns: Array de VehicleSupabase triés par date de création (plus récent en premier)
    /// - Throws: Erreur si la requête échoue ou si l'utilisateur n'est pas authentifié
    func fetchMyVehicles() async throws -> [VehicleSupabase] {
        // Vérifier que l'utilisateur est authentifié
        // Si la session n'existe pas, try await lancera une erreur automatiquement
        let session = try await client.auth.session
        let userId = session.user.id
        
        print("[VEHICLES] Fetching vehicles for owner: \(userId)")
        
        // Filtre explicite par owner_id pour garantir l'isolation (RLS en backup)
        // Aucune déduplication par registration : chaque user voit ses propres véhicules
        let response: [VehicleSupabase] = try await client
            .from("vehicles")
            .select("id, owner_id, registration, brand, model, energy, v7_emissions, photo_url, created_at")
            .eq("owner_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("[VEHICLES] Found \(response.count) vehicles")
        return response
    }
    
    /// Résout l'URL de la photo du véhicule
    /// - Si photo_url est nil/vide -> retourne nil
    /// - Si photo_url commence par "http" -> retourne l'URL directement (legacy)
    /// - Sinon -> crée une URL signée depuis le bucket "vehicles" (expire 3600s)
    /// - Parameter photoUrl: Le chemin ou URL de la photo
    /// - Returns: L'URL complète de la photo, ou nil si absente/erreur
    func resolvePhotoURL(_ photoUrl: String?) async -> URL? {
        guard let photoUrl = photoUrl, !photoUrl.isEmpty else {
            return nil
        }
        
        // Si c'est déjà une URL complète (legacy), la retourner directement
        if photoUrl.hasPrefix("http://") || photoUrl.hasPrefix("https://") {
            return URL(string: photoUrl)
        }
        
        // Sinon, c'est un path relatif dans le bucket Storage -> créer une URL signée
        do {
            let signedURL = try await client.storage
                .from("vehicles")
                .createSignedURL(path: photoUrl, expiresIn: 3600)
            return signedURL
        } catch {
            print("[VEHICLES] Error creating signed URL for \(photoUrl): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Crée un nouveau véhicule dans Supabase avec upload photo optionnel
    /// - Parameters:
    ///   - registration: Plaque d'immatriculation (sera convertie en uppercase et trim)
    ///   - energy: Type d'énergie (rawValue de VehicleEnergy: gasoline/diesel/electric/hybrid/hydrogen/other)
    ///   - v7: Émissions V7 en g/km
    ///   - photoData: Données de la photo (optionnel)
    /// - Returns: UUID du véhicule créé
    /// - Throws: Erreur si la création échoue ou si l'utilisateur n'est pas authentifié
    func createVehicle(registration: String, energy: String, v7: Double, photoData: Data?) async throws -> UUID {
        let session = try await client.auth.session
        let ownerId = session.user.id
        
        // Normaliser registration (trim + uppercase)
        let trimmedRegistration = registration.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Valider energy enum (doit être rawValue: gasoline/diesel/electric/hybrid/hydrogen/other)
        let validEnergies = ["gasoline", "diesel", "electric", "hybrid", "hydrogen", "other"]
        guard validEnergies.contains(energy) else {
            let error = NSError(
                domain: "VehiclesService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Énergie invalide: '\(energy)'. Attendu: gasoline/diesel/electric/hybrid/hydrogen/other"]
            )
            throw error
        }
        
        print("[VEHICLES] Creating vehicle for owner: \(ownerId)")
        print("[VEHICLES] Owner UUID: \(ownerId.uuidString)")
        print("[VEHICLES] Energy enum: \(energy)")
        print("[VEHICLES] Registration: \(trimmedRegistration)")
        print("[VEHICLES] V7 emissions: \(v7) g/km")
        print("[VEHICLES] Has photo: \(photoData != nil)")
        
        // Préparer l'insertion du véhicule
        struct VehicleInsert: Codable {
            let owner_id: String
            let registration: String
            let energy: String
            let v7_emissions: Double
        }
        
        let vehicleInsert = VehicleInsert(
            owner_id: ownerId.uuidString,
            registration: trimmedRegistration,
            energy: energy,
            v7_emissions: v7
        )
        
        // Log payload (sans photoData)
        if let jsonData = try? JSONEncoder().encode(vehicleInsert),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("[VEHICLES] Insert payload: \(jsonString)")
        }
        
        // Insérer le véhicule et récupérer l'id
        struct VehicleResponse: Codable {
            let id: UUID
        }
        
        do {
            let response: [VehicleResponse] = try await client
                .from("vehicles")
                .insert(vehicleInsert)
                .select("id")
                .execute()
                .value
            
            guard let insertedVehicle = response.first else {
                throw NSError(domain: "VehiclesService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Aucun véhicule inséré"])
            }
            
            let vehicleId = insertedVehicle.id
            print("[VEHICLES] Vehicle inserted successfully with id: \(vehicleId)")
            
            // Si une photo est fournie, l'uploader et mettre à jour photo_url
            if let photoData = photoData {
                let timestamp = Int(Date().timeIntervalSince1970 * 1000)
                let path = "\(ownerId.uuidString)/\(timestamp).jpg"
                
                print("[VEHICLES] Uploading photo to path: \(path)")
                
                // Upload dans le bucket Storage "vehicles"
                try await client.storage
                    .from("vehicles")
                    .upload(path, data: photoData, options: FileOptions(contentType: "image/jpeg"))
                
                // Mettre à jour photo_url dans la table vehicles
                try await client
                    .from("vehicles")
                    .update(["photo_url": path])
                    .eq("id", value: vehicleId.uuidString)
                    .eq("owner_id", value: ownerId.uuidString)
                    .execute()
                
                print("[VEHICLES] Photo uploaded and photo_url updated: \(path)")
            }
            
            print("[VEHICLES] Vehicle created with id: \(vehicleId)")
            return vehicleId
        } catch {
            print("[VEHICLES] ERROR inserting vehicle:")
            print("[VEHICLES] Error type: \(type(of: error))")
            print("[VEHICLES] Error description: \(error.localizedDescription)")
            if let supabaseError = error as? any Error {
                print("[VEHICLES] Full error: \(supabaseError)")
            }
            throw error
        }
    }
    
    /// Met à jour un véhicule existant dans Supabase avec upload photo optionnel
    /// - Parameters:
    ///   - vehicleId: ID du véhicule à mettre à jour
    ///   - registration: Plaque d'immatriculation (sera convertie en uppercase et trim)
    ///   - energy: Type d'énergie (rawValue de VehicleEnergy: gasoline/diesel/electric/hybrid/hydrogen/other)
    ///   - v7: Émissions V7 en g/km
    ///   - photoData: Données de la photo (optionnel)
    /// - Throws: Erreur si la mise à jour échoue ou si l'utilisateur n'est pas authentifié
    func updateVehicle(vehicleId: UUID, registration: String, energy: String, v7: Double, photoData: Data?) async throws {
        let session = try await client.auth.session
        let ownerId = session.user.id
        
        // Normaliser registration (trim + uppercase)
        let trimmedRegistration = registration.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Valider energy enum (doit être rawValue: gasoline/diesel/electric/hybrid/hydrogen/other)
        let validEnergies = ["gasoline", "diesel", "electric", "hybrid", "hydrogen", "other"]
        guard validEnergies.contains(energy) else {
            let error = NSError(
                domain: "VehiclesService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Énergie invalide: '\(energy)'. Attendu: gasoline/diesel/electric/hybrid/hydrogen/other"]
            )
            throw error
        }
        
        print("[VEHICLES] Updating vehicle \(vehicleId) for owner: \(ownerId)")
        print("[VEHICLES] Owner UUID: \(ownerId.uuidString)")
        print("[VEHICLES] Energy enum: \(energy)")
        print("[VEHICLES] Registration: \(trimmedRegistration)")
        print("[VEHICLES] V7 emissions: \(v7) g/km")
        print("[VEHICLES] Has photo: \(photoData != nil)")
        
        // Préparer la mise à jour du véhicule
        struct VehicleUpdate: Codable {
            let registration: String
            let energy: String
            let v7_emissions: Double
        }
        
        let vehicleUpdate = VehicleUpdate(
            registration: trimmedRegistration,
            energy: energy,
            v7_emissions: v7
        )
        
        // Log payload (sans photoData)
        if let jsonData = try? JSONEncoder().encode(vehicleUpdate),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("[VEHICLES] Update payload: \(jsonString)")
        }
        
        do {
            try await client
                .from("vehicles")
                .update(vehicleUpdate)
                .eq("id", value: vehicleId.uuidString)
                .eq("owner_id", value: ownerId.uuidString)
                .execute()
            
            print("[VEHICLES] Vehicle updated successfully")
            
            // Si une photo est fournie, l'uploader et mettre à jour photo_url
            if let photoData = photoData {
                let timestamp = Int(Date().timeIntervalSince1970 * 1000)
                let path = "\(ownerId.uuidString)/\(timestamp).jpg"
                
                print("[VEHICLES] Uploading photo to path: \(path)")
                
                // Upload dans le bucket Storage "vehicles"
                try await client.storage
                    .from("vehicles")
                    .upload(path, data: photoData, options: FileOptions(contentType: "image/jpeg"))
                
                // Mettre à jour photo_url dans la table vehicles
                try await client
                    .from("vehicles")
                    .update(["photo_url": path])
                    .eq("id", value: vehicleId.uuidString)
                    .eq("owner_id", value: ownerId.uuidString)
                    .execute()
                
                print("[VEHICLES] Photo uploaded and photo_url updated: \(path)")
            }
            
            print("[VEHICLES] Vehicle \(vehicleId) updated successfully")
        } catch {
            print("[VEHICLES] ERROR updating vehicle:")
            print("[VEHICLES] Error type: \(type(of: error))")
            print("[VEHICLES] Error description: \(error.localizedDescription)")
            if let supabaseError = error as? any Error {
                print("[VEHICLES] Full error: \(supabaseError)")
            }
            throw error
        }
    }
}
