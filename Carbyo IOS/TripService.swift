//
//  TripService.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import Foundation
import Supabase

final class TripService {
    let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    // MARK: - Helper pour construire la requête de base (filtres communs)
    
    // Note: On ne peut pas utiliser un type de retour explicite pour le builder,
    // donc on duplique les filtres communs dans chaque méthode pour garantir la cohérence
    
    // MARK: - Calcul du total CO₂ pour le mois courant
    
    func fetchPersonalCO2ThisMonth() async throws -> (total: Double, tripCount: Int) {
        print("[COCKPIT] fetchPersonalCO2ThisMonth start")
        
        // Récupérer l'utilisateur courant
        let session = try await client.auth.session
        let userId = session.user.id
        
        // Calculer le premier et dernier jour du mois courant
        let calendar = Calendar.current
        let now = Date()
        
        // Premier jour du mois (début à minuit)
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            throw NSError(domain: "DateError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de calculer le début du mois"])
        }
        
        // Dernier jour du mois (fin du mois, pas le début du mois suivant)
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth),
              let endOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth) else {
            throw NSError(domain: "DateError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de calculer la fin du mois"])
        }
        
        // Formater les dates STRICTEMENT au format 'yyyy-MM-dd' (String) pour PostgreSQL DATE
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC pour éviter les problèmes de fuseau horaire
        let startOfMonthString = dateFormatter.string(from: startOfMonth)
        let endOfMonthString = dateFormatter.string(from: endOfMonth)
        
        // Tronquer l'UID pour les logs
        let userIdString = userId.uuidString
        let truncatedUID = String(userIdString.prefix(8))
        
        print("[COCKPIT] User ID (truncated): \(truncatedUID)...")
        print("[COCKPIT] Period: startDateString='\(startOfMonthString)' / endDateString='\(endOfMonthString)'")
        
        // REUTILISER LA MÊME LOGIQUE QUE fetchPersonalTrips (select complet pour éviter erreur Decodable)
        // Filtres: user_id + type_trajet='perso' + trip_date entre startOfMonth et endOfMonth (inclus)
        do {
            // Même select complet que fetchPersonalTrips pour décoder correctement dans Trip
            let trips: [Trip] = try await client
                .from("trips")
                .select("id, user_id, vehicle_id, trip_date, origin_address, destination_address, distance_km, co2_emissions_kg, transport_mode, type_trajet, created_at, vehicles(id, owner_id, registration, brand, model, energy, v7_emissions, consumption_per_100km)")
                .eq("user_id", value: userId.uuidString)
                .eq("type_trajet", value: "perso")
                .gte("trip_date", value: startOfMonthString)
                .lte("trip_date", value: endOfMonthString)
                .order("trip_date", ascending: false)
                .execute()
                .value
            
            print("[COCKPIT] nb trips: \(trips.count)")
            
            // Calculer localement: COUNT(trips) et SUM(co2_emissions_kg)
            let totalTrips = trips.count
            let totalCO2 = trips.reduce(0.0) { sum, trip in
                sum + (trip.co2_emissions_kg ?? 0.0)
            }
            
            print("[COCKPIT] totalCO2 calculé: \(String(format: "%.2f", totalCO2)) kg")
            print("[COCKPIT] ✅ Successfully calculated CO₂ for \(totalTrips) trips")
            
            return (total: totalCO2, tripCount: totalTrips)
        } catch {
            print("[COCKPIT] ❌ Error fetching CO₂: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchPersonalTrips() async throws -> [Trip] {
        print("[CO2] fetchPersonalTrips start")
        
        // Récupérer l'utilisateur courant
        let session = try await client.auth.session
        let userId = session.user.id
        print("[CO2] User ID: \(userId)")
        
        // Requête Supabase avec jointure véhicule
        do {
            // Récupérer les trips avec jointure véhicule
            // Filtres communs: user_id et type_trajet = "perso" (identique à fetchPersonalCO2ThisMonth)
            var trips: [Trip] = try await client
                .from("trips")
                .select("id, user_id, vehicle_id, trip_date, origin_address, destination_address, distance_km, co2_emissions_kg, transport_mode, type_trajet, created_at, vehicles(id, owner_id, registration, brand, model, energy, v7_emissions, consumption_per_100km)")
                .eq("user_id", value: userId.uuidString)
                .eq("type_trajet", value: "perso")
                .order("trip_date", ascending: false)
                .execute()
                .value
            
            // Trier par trip_date DESC, puis par created_at DESC en fallback
            trips.sort { trip1, trip2 in
                // Si les deux ont trip_date, comparer par trip_date
                if let date1 = trip1.trip_date, let date2 = trip2.trip_date {
                    return date1 > date2
                }
                // Si seulement trip1 a trip_date, il vient en premier
                if trip1.trip_date != nil {
                    return true
                }
                // Si seulement trip2 a trip_date, il vient en premier
                if trip2.trip_date != nil {
                    return false
                }
                // Sinon, comparer par created_at
                if let created1 = trip1.created_at, let created2 = trip2.created_at {
                    return created1 > created2
                }
                return false
            }
            
            print("[CO2] Trips loaded: \(trips.count)")
            
            // Log détaillé pour debug
            var totalCO2: Double = 0.0
            for trip in trips {
                if let co2 = trip.co2_emissions_kg {
                    totalCO2 += co2
                    print("[CO2] Trip \(trip.id) → \(String(format: "%.2f", co2)) kg CO₂")
                    if let vehicle = trip.vehicles {
                        print("[CO2]   Vehicle: \(vehicle.brand ?? "") \(vehicle.model ?? "") (\(vehicle.registration ?? "N/A"))")
                    }
                }
            }
            print("[CO2] Total CO₂: \(String(format: "%.2f", totalCO2)) kg")
            print("[CO2] ✅ Successfully fetched \(trips.count) personal trips")
            
            return trips
        } catch {
            print("[CO2] ❌ Error fetching personal trips: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchTrips(limit: Int = 50) async throws -> [Trip] {
        print("[TRIPS] fetchTrips start")
        
        // Vérifier la session
        do {
            let session = try await client.auth.session
            print("[TRIPS] User ID: \(session.user.id)")
        } catch {
            print("[TRIPS] ⚠️ No session found: \(error.localizedDescription)")
            throw error
        }
        
        // Requête Supabase - sélection explicite des colonnes nécessaires
        do {
            let trips: [Trip] = try await client
                .from("trips")
                .select("id, trip_date, type_trajet, distance_km, co2_emissions_kg, user_id, vehicle_id, origin, destination, created_at")
                .order("trip_date", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            print("[TRIPS] ✅ Successfully fetched \(trips.count) trips")
            
            // Log détaillé des 3 premiers trips
            let sampleCount = min(3, trips.count)
            if sampleCount > 0 {
                print("[TRIPS] 📋 Sample trips (first \(sampleCount)):")
                for i in 0..<sampleCount {
                    let trip = trips[i]
                    print("[TRIPS]   [\(i+1)] id=\(trip.id)")
                    print("[TRIPS]        trip_date=\(trip.trip_date ?? "nil")")
                    print("[TRIPS]        type_trajet=\(trip.type_trajet ?? "nil")")
                    print("[TRIPS]        distance_km=\(trip.distance_km ?? 0)")
                    if let co2 = trip.co2_emissions_kg {
                        print("[TRIPS]        co2_emissions_kg=\(co2)")
                    } else {
                        print("[TRIPS]        co2_emissions_kg=nil ⚠️")
                    }
                }
            }
            
            return trips
        } catch let error as DecodingError {
            print("[TRIPS] ❌ Decoding error: \(error)")
            if case .keyNotFound(let key, let context) = error {
                print("[TRIPS] Missing key: \(key.stringValue) in \(context.debugDescription)")
            }
            throw error
        } catch {
            print("[TRIPS] ❌ Error: \(error.localizedDescription)")
            
            // Diagnostic supplémentaire pour erreurs d'authentification
            if error.localizedDescription.contains("401") || error.localizedDescription.contains("unauthorized") {
                print("[TRIPS] ⚠️ Authentication error - check session token")
            } else if error.localizedDescription.contains("403") || error.localizedDescription.contains("forbidden") {
                print("[TRIPS] ⚠️ Permission error - check RLS policies")
            } else if error.localizedDescription.contains("does not exist") || error.localizedDescription.contains("relation") {
                print("[TRIPS] ⚠️ Table 'trips' may not exist - check table name in Supabase")
            }
            
            // Diagnostic supplémentaire
            if let urlError = error as? URLError {
                print("[TRIPS] URL Error code: \(urlError.code.rawValue)")
            }
            
            throw error
        }
    }
}

// MARK: - JSONDecoder Extension
extension JSONDecoder {
    static var withISO8601: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Essayer avec fractional seconds
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Essayer sans fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Essayer avec un format plus simple
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = simpleFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateString)"
            )
        }
        
        return decoder
    }
}
