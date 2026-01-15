//
//  CockpitView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct CockpitView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var selectedTab: CockpitTab = .co2
    @State private var personalCO2Month: Double = 0.0
    @State private var personalTripsCount: Int = 0
    @State private var isLoadingCO2: Bool = false
    
    private let tripService = TripService(client: SupabaseManager.shared.client)
    
    enum CockpitTab: CaseIterable {
        case co2, mode, km
        
        var label: String {
            switch self {
            case .co2: return "Co2"
            case .mode: return "Mode"
            case .km: return "Km"
            }
        }
    }
    
    private func formatCO2Value(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "0,0"
    }
    
    private var mockDashboard: KPIDashboard {
        switch selectedTab {
        case .co2:
            return KPIDashboard(
                personal: [
                    KPIItem(icon: "leaf.fill", title: "Perso", value: formatCO2Value(personalCO2Month), unit: "kg CO₂", subtitle: "Ce mois", kpiType: .co2Perso),
                    KPIItem(icon: "bolt.car.fill", title: "Trajets", value: "\(personalTripsCount)", unit: nil, subtitle: "Ce mois", kpiType: .trips)
                ],
                professional: nil
            )
        case .mode:
            return KPIDashboard(
                personal: [
                    KPIItem(icon: "car.fill", title: "Voiture", value: "62", unit: "%", subtitle: nil, kpiType: .mode),
                    KPIItem(icon: "figure.walk", title: "Marche", value: "18", unit: "%", subtitle: nil, kpiType: .mode)
                ],
                professional: [
                    KPIItem(icon: "tram.fill", title: "TC", value: "40", unit: "%", subtitle: nil, kpiType: .mode),
                    KPIItem(icon: "car.2.fill", title: "Covoit.", value: "25", unit: "%", subtitle: nil, kpiType: .mode)
                ]
            )
        case .km:
            return KPIDashboard(
                personal: [
                    KPIItem(icon: "road.lanes", title: "Perso", value: "124", unit: "km", subtitle: "Ce mois", kpiType: .km),
                    KPIItem(icon: "clock.fill", title: "Jours", value: "14", unit: nil, subtitle: "Actifs", kpiType: .trips)
                ],
                professional: [
                    KPIItem(icon: "briefcase.fill", title: "Pro", value: "88", unit: "km", subtitle: "Ce mois", kpiType: .km),
                    KPIItem(icon: "calendar", title: "Jours", value: "9", unit: nil, subtitle: "Actifs", kpiType: .trips)
                ]
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond plein écran
                CarbyoColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 10) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center) {
                            Text("Cockpit")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(CarbyoColors.text)
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Image(systemName: "leaf.fill")
                                    .font(.caption)
                                    .foregroundColor(CarbyoColors.primary)
                                
                                Text("Carbyo")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(CarbyoColors.muted)
                            }
                        }
                        
                        // Greeting (mocked)
                        Text("Salut Cédric")
                            .font(.subheadline)
                            .foregroundColor(CarbyoColors.muted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    
                    // Bouton: Enregistrer rapidement un trajet
                    Button {
                        // TODO: Navigation vers déclaration de trajet
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Enregistrer rapidement un trajet")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(CarbyoColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, 16)
                    
                    // Sélecteur d'onglet
                    Picker("", selection: $selectedTab) {
                        ForEach(CockpitTab.allCases, id: \.self) { tab in
                            Text(tab.label).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    
                    // Grille KPI
                    VStack(spacing: 10) {
                        // Ligne Perso (toujours visible)
                        HStack(spacing: 12) {
                            ForEach(mockDashboard.personal) { item in
                                NavigationLink(value: item.kpiType) {
                                    KPITile(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Ligne Pro (seulement si données pro)
                        if let proItems = mockDashboard.professional {
                            HStack(spacing: 12) {
                                ForEach(proItems) { item in
                                    NavigationLink(value: item.kpiType) {
                                        KPITile(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    .navigationDestination(for: KPIType.self) { kpiType in
                        if kpiType == .co2Perso {
                            CO2TripsListView()
                        } else {
                            KPIDetailView(kpiType: kpiType)
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.bottom, 56)
            }
            .task {
                await loadCO2Data()
            }
            .onAppear {
                // Style du segmented control
                UISegmentedControl.appearance().backgroundColor = UIColor(CarbyoColors.border.opacity(0.1))
                UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(CarbyoColors.primary)
                UISegmentedControl.appearance().setTitleTextAttributes([
                    .foregroundColor: UIColor(CarbyoColors.text),
                    .font: UIFont.systemFont(ofSize: 13, weight: .medium)
                ], for: .normal)
                UISegmentedControl.appearance().setTitleTextAttributes([
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
                ], for: .selected)
            }
        }
    }
    
    private func loadCO2Data() async {
        guard session.isLoggedIn else {
            return
        }
        
        isLoadingCO2 = true
        
        do {
            let result = try await tripService.fetchPersonalCO2ThisMonth()
            await MainActor.run {
                personalCO2Month = result.total
                personalTripsCount = result.tripCount
                isLoadingCO2 = false
            }
        } catch {
            print("[COCKPIT] ❌ Error loading CO₂ data: \(error.localizedDescription)")
            await MainActor.run {
                isLoadingCO2 = false
            }
        }
    }
}

// MARK: - Data Models

enum KPIType: String, CaseIterable, Hashable {
    case co2Perso
    case co2Pro
    case km
    case mode
    case trips
    case vehicles
    
    var title: String {
        switch self {
        case .co2Perso: return "CO₂ Personnel"
        case .co2Pro: return "CO₂ Professionnel"
        case .km: return "Distance"
        case .mode: return "Mode de transport"
        case .trips: return "Trajets"
        case .vehicles: return "Véhicules"
        }
    }
    
    var subtitle: String {
        switch self {
        case .co2Perso: return "Émissions de carbone de vos trajets personnels"
        case .co2Pro: return "Émissions de carbone de vos trajets professionnels"
        case .km: return "Distance totale parcourue"
        case .mode: return "Répartition des modes de transport"
        case .trips: return "Nombre total de trajets enregistrés"
        case .vehicles: return "Véhicules enregistrés dans votre profil"
        }
    }
    
    var unit: String {
        switch self {
        case .co2Perso, .co2Pro: return "kg CO₂"
        case .km: return "km"
        case .mode: return "%"
        case .trips: return ""
        case .vehicles: return ""
        }
    }
    
    var mockValue: String {
        switch self {
        case .co2Perso: return "12,4"
        case .co2Pro: return "8,2"
        case .km: return "124"
        case .mode: return "62"
        case .trips: return "8"
        case .vehicles: return "2"
        }
    }
}

struct KPIItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
    let unit: String?
    let subtitle: String?
    let kpiType: KPIType
}

struct KPIDashboard {
    let personal: [KPIItem]
    let professional: [KPIItem]?
}

// MARK: - KPI Tile Component

struct KPITile: View {
    let item: KPIItem
    
    var body: some View {
        VStack(spacing: 6) {
            // Header: Icône + Titre
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(CarbyoColors.primary)
                    .frame(width: 18)
                
                Text(item.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(CarbyoColors.muted)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
            }
            
            Spacer(minLength: 0)
            
            // Valeur centrée
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text(item.value)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(CarbyoColors.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .monospacedDigit()
                    
                    if let unit = item.unit {
                        Text(unit)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(CarbyoColors.muted)
                    }
                }
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(CarbyoColors.muted)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 88)
        .background(CarbyoColors.surface)
        .overlay(
            Rectangle()
                .stroke(CarbyoColors.border.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 2)
    }
}

// MARK: - CO2 Trips List View

struct CO2TripsListView: View {
    @State private var trips: [Trip] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let tripService = TripService(client: SupabaseManager.shared.client)
    
    var body: some View {
        ZStack {
            CarbyoColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Subtitle
                HStack {
                    Text("Trajets récents")
                        .font(.subheadline)
                        .foregroundColor(CarbyoColors.muted)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                // Content
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Text("Erreur")
                            .font(.headline)
                            .foregroundColor(CarbyoColors.text)
                        Text(error)
                            .font(.body)
                            .foregroundColor(CarbyoColors.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else if trips.isEmpty {
                    VStack(spacing: 12) {
                        Text("Aucun trajet enregistré pour le moment.")
                            .font(.body)
                            .foregroundColor(CarbyoColors.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(trips) { trip in
                            TripRowView(trip: trip)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await loadTrips()
                    }
                }
            }
        }
        .navigationTitle("CO₂ – Personnel")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTrips()
        }
    }
    
    private func loadTrips() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedTrips = try await tripService.fetchPersonalTrips()
            await MainActor.run {
                trips = fetchedTrips
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Trip Row View

struct TripRowView: View {
    let trip: Trip
    
    private func parseTripDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatDistance(_ value: Double?) -> String {
        guard let value = value else { return "—" }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }
    
    private func formatCO2(_ value: Double?) -> String {
        guard let value = value else { return "—" }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }
    
    private func formatVehicleEmissions(_ value: Double?) -> String {
        guard let value = value else { return "—" }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }
    
    private var originDestinationText: String {
        if let origin = trip.origin_address, let destination = trip.destination_address {
            return "\(origin) → \(destination)"
        } else if let origin = trip.origin_address {
            return origin
        } else if let destination = trip.destination_address {
            return destination
        } else {
            return "Trajet"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Ligne principale: Date + Origine/Destination
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if let tripDate = parseTripDate(trip.trip_date) {
                        Text(formatDate(tripDate))
                            .font(.caption)
                            .foregroundColor(CarbyoColors.muted)
                    } else if let createdAtString = trip.created_at {
                        // Fallback sur created_at si trip_date n'est pas disponible
                        if let createdAt = parseISODate(createdAtString) {
                            Text(formatDate(createdAt))
                                .font(.caption)
                                .foregroundColor(CarbyoColors.muted)
                        }
                    }
                    
                    Text(originDestinationText)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(CarbyoColors.text)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Distance et CO2 à droite
                VStack(alignment: .trailing, spacing: 4) {
                    if let distance = trip.distance_km {
                        HStack(spacing: 4) {
                            Text(formatDistance(distance))
                                .font(.body)
                                .foregroundColor(CarbyoColors.text)
                            Text("km")
                                .font(.caption)
                                .foregroundColor(CarbyoColors.muted)
                        }
                    }
                    
                    if let co2 = trip.co2_emissions_kg {
                        HStack(spacing: 4) {
                            Text(formatCO2(co2))
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(CarbyoColors.text)
                                .monospacedDigit()
                            Text("kg CO₂")
                                .font(.caption)
                                .foregroundColor(CarbyoColors.muted)
                        }
                    }
                }
            }
            
            // Détails véhicule (si présent)
            if let vehicle = trip.vehicles {
                VStack(alignment: .leading, spacing: 2) {
                    if let brand = vehicle.brand, let model = vehicle.model {
                        HStack(spacing: 4) {
                            Text(brand)
                                .font(.caption)
                                .foregroundColor(CarbyoColors.muted)
                            Text(model)
                                .font(.caption)
                                .foregroundColor(CarbyoColors.muted)
                            if let registration = vehicle.registration {
                                Text("(\(registration))")
                                    .font(.caption)
                                    .foregroundColor(CarbyoColors.muted)
                            }
                        }
                    }
                    
                    if let v7Emissions = vehicle.v7_emissions {
                        HStack(spacing: 4) {
                            Text("Émissions:")
                                .font(.caption2)
                                .foregroundColor(CarbyoColors.muted)
                            Text(formatVehicleEmissions(v7Emissions))
                                .font(.caption2)
                                .foregroundColor(CarbyoColors.muted)
                            Text("g/km")
                                .font(.caption2)
                                .foregroundColor(CarbyoColors.muted)
                        }
                    }
                }
                .padding(.top, 4)
                .padding(.leading, 4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func parseISODate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
}

// MARK: - KPI Detail View

struct KPIDetailView: View {
    let kpiType: KPIType
    
    var body: some View {
        ZStack {
            CarbyoColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Valeur principale centrée
                VStack(spacing: 12) {
                    Text(kpiType.mockValue)
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(CarbyoColors.text)
                        .monospacedDigit()
                    
                    Text(kpiType.unit)
                        .font(.title3)
                        .foregroundColor(CarbyoColors.muted)
                }
                
                // Texte explicatif
                Text(kpiType.subtitle)
                    .font(.body)
                    .foregroundColor(CarbyoColors.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(kpiType.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CockpitView()
            .environmentObject(SessionStore())
    }
}
