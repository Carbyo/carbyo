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
    
    @State private var selectedContext: ContextType = .perso
    @State private var personalCO2Month: Double = 0.0
    @State private var personalTripsCount: Int = 0
    @State private var personalDistanceMonth: Double = 0.0
    @State private var prevPersonalCO2Month: Double = 0.0
    @State private var prevPersonalTripsCount: Int = 0
    @State private var prevPersonalDistanceMonth: Double = 0.0
    @State private var professionalCO2Month: Double = 0.0
    @State private var professionalTripsCount: Int = 0
    @State private var professionalDistanceMonth: Double = 0.0
    @State private var prevProfessionalCO2Month: Double = 0.0
    @State private var prevProfessionalTripsCount: Int = 0
    @State private var prevProfessionalDistanceMonth: Double = 0.0
    @State private var isLoadingCO2: Bool = false
    // États pour les données totales
    @State private var personalCO2Total: Double = 0.0
    @State private var personalTripsCountTotal: Int = 0
    @State private var personalDistanceTotal: Double = 0.0
    @State private var professionalCO2Total: Double = 0.0
    @State private var professionalTripsCountTotal: Int = 0
    @State private var professionalDistanceTotal: Double = 0.0
    @State private var showMonthTripsModal: Bool = false
    
    private let tripService = TripService(client: SupabaseManager.shared.client)
    
    enum ContextType: CaseIterable {
        case perso, pro
        
        var label: String {
            switch self {
            case .perso: return "Perso"
            case .pro: return "Pro"
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
    
    private func formatDistanceValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    private func formatCO2PerKm(_ co2: Double, _ km: Double) -> String {
        guard km > 0 else { return "—" }
        let ratio = co2 / km
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: ratio)) ?? "0,00"
    }
    
    private var currentKPIItem: KPIItem? {
        switch selectedContext {
        case .perso:
            // Calculer les deltas pour Perso
            let deltaTrips = personalTripsCount - prevPersonalTripsCount
            let deltaKm = personalDistanceMonth - prevPersonalDistanceMonth
            let deltaCO2 = personalCO2Month - prevPersonalCO2Month
            
            // Calculer le ratio CO2/km
            let co2PerKmValue = personalDistanceMonth > 0 ? formatCO2PerKm(personalCO2Month, personalDistanceMonth) : nil
            let co2PerKmFormatted = co2PerKmValue != nil ? "\(co2PerKmValue!) kg CO₂ / km" : nil
            
            return KPIItem(icon: "leaf.fill", title: "Perso", value: formatCO2Value(personalCO2Month), unit: "kg CO₂", subtitle: "Ce mois", kpiType: .co2Perso, tripsCount: personalTripsCount, distanceKm: personalDistanceMonth, deltaTrips: deltaTrips, deltaKm: deltaKm, deltaCO2: deltaCO2, prevTripsCount: prevPersonalTripsCount, prevDistanceKm: prevPersonalDistanceMonth, prevCO2Month: prevPersonalCO2Month, co2PerKm: co2PerKmFormatted)
            
        case .pro:
            // Calculer les deltas pour Pro
            let deltaTrips = professionalTripsCount - prevProfessionalTripsCount
            let deltaKm = professionalDistanceMonth - prevProfessionalDistanceMonth
            let deltaCO2 = professionalCO2Month - prevProfessionalCO2Month
            
            // Calculer le ratio CO2/km
            let co2PerKmValue = professionalDistanceMonth > 0 ? formatCO2PerKm(professionalCO2Month, professionalDistanceMonth) : nil
            let co2PerKmFormatted = co2PerKmValue != nil ? "\(co2PerKmValue!) kg CO₂ / km" : nil
            
            return KPIItem(icon: "briefcase.fill", title: "Pro", value: formatCO2Value(professionalCO2Month), unit: "kg CO₂", subtitle: "Ce mois", kpiType: .co2Pro, tripsCount: professionalTripsCount, distanceKm: professionalDistanceMonth, deltaTrips: deltaTrips, deltaKm: deltaKm, deltaCO2: deltaCO2, prevTripsCount: prevProfessionalTripsCount, prevDistanceKm: prevProfessionalDistanceMonth, prevCO2Month: prevProfessionalCO2Month, co2PerKm: co2PerKmFormatted)
        }
    }
    
    private var currentTotalKPIItem: KPIItem? {
        switch selectedContext {
        case .perso:
            // Calculer le ratio CO2/km pour le total
            let co2PerKmValue = personalDistanceTotal > 0 ? formatCO2PerKm(personalCO2Total, personalDistanceTotal) : nil
            let co2PerKmFormatted = co2PerKmValue != nil ? "\(co2PerKmValue!) kg CO₂ / km" : nil
            
            return KPIItem(icon: "leaf.fill", title: "Perso", value: formatCO2Value(personalCO2Total), unit: "kg CO₂", subtitle: "Total", kpiType: .co2Perso, tripsCount: personalTripsCountTotal, distanceKm: personalDistanceTotal, deltaTrips: nil, deltaKm: nil, deltaCO2: nil, prevTripsCount: nil, prevDistanceKm: nil, prevCO2Month: nil, co2PerKm: co2PerKmFormatted)
            
        case .pro:
            // Calculer le ratio CO2/km pour le total
            let co2PerKmValue = professionalDistanceTotal > 0 ? formatCO2PerKm(professionalCO2Total, professionalDistanceTotal) : nil
            let co2PerKmFormatted = co2PerKmValue != nil ? "\(co2PerKmValue!) kg CO₂ / km" : nil
            
            return KPIItem(icon: "briefcase.fill", title: "Pro", value: formatCO2Value(professionalCO2Total), unit: "kg CO₂", subtitle: "Total", kpiType: .co2Pro, tripsCount: professionalTripsCountTotal, distanceKm: professionalDistanceTotal, deltaTrips: nil, deltaKm: nil, deltaCO2: nil, prevTripsCount: nil, prevDistanceKm: nil, prevCO2Month: nil, co2PerKm: co2PerKmFormatted)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond plein écran
                CarbyoColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center) {
                            HStack(spacing: 8) {
                                Image(systemName: "leaf.fill")
                                    .font(.title3)
                                    .foregroundColor(CarbyoColors.primary)
                                
                                Text("Carbyo")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(CarbyoColors.muted)
                            }
                            
                            Spacer()
                            
                            Text("Cockpit")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(CarbyoColors.text)
                        }
                        
                        // Greeting (mocked)
                        HStack(spacing: 0) {
                            Text("Salut ")
                                .font(.subheadline)
                                .foregroundColor(CarbyoColors.muted)
                            Text("Cédric")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(CarbyoColors.muted)
                        }
                        .padding(.bottom, 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, -20)
                    
                    // Sélecteur de contexte Perso/Pro - placé juste sous le header
                    Picker("", selection: $selectedContext) {
                        ForEach(ContextType.allCases, id: \.self) { context in
                            Text(context.label).tag(context)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    
                    // Bloc KPI principal en pleine largeur (Ce mois)
                    if let item = currentKPIItem {
                        Button {
                            showMonthTripsModal = true
                        } label: {
                            KPITile(item: item)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .animation(.easeInOut(duration: 0.2), value: selectedContext)
                    }
                    
                    // Bloc Total en pleine largeur
                    if let totalItem = currentTotalKPIItem {
                        KPITile(item: totalItem)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .animation(.easeInOut(duration: 0.2), value: selectedContext)
                    }
                    
                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationDestination(for: KPIType.self) { kpiType in
                if kpiType == .co2Perso {
                    CO2TripsListView()
                } else {
                    KPIDetailView(kpiType: kpiType)
                }
            }
            .sheet(isPresented: $showMonthTripsModal) {
                MonthTripsModalView(contextType: selectedContext)
                    .environmentObject(session)
            }
            .task {
                await loadCO2Data()
                await loadTotalData()
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
            // Charger les données du mois courant et du mois précédent en parallèle
            async let currentResult = tripService.fetchPersonalCO2ThisMonth()
            async let previousResult = tripService.fetchPersonalCO2PreviousMonth()
            
            let (current, previous) = try await (currentResult, previousResult)
            
            await MainActor.run {
                personalCO2Month = current.total
                personalTripsCount = current.tripCount
                personalDistanceMonth = current.distanceKm
                prevPersonalCO2Month = previous.total
                prevPersonalTripsCount = previous.tripCount
                prevPersonalDistanceMonth = previous.distanceKm
                isLoadingCO2 = false
            }
        } catch {
            print("[COCKPIT] ❌ Error loading CO₂ data: \(error.localizedDescription)")
            await MainActor.run {
                // En cas d'erreur, mettre les valeurs précédentes à 0
                prevPersonalCO2Month = 0.0
                prevPersonalTripsCount = 0
                prevPersonalDistanceMonth = 0.0
                isLoadingCO2 = false
            }
        }
    }
    
    private func loadTotalData() async {
        guard session.isLoggedIn else {
            return
        }
        
        do {
            // Charger tous les trajets personnels (sans filtre de date)
            let personalTrips = try await tripService.fetchPersonalTrips(startDate: nil, endDate: nil)
            
            // Calculer les totaux pour Perso
            let totalPersonalCO2 = personalTrips.reduce(0.0) { sum, trip in
                sum + (trip.co2_emissions_kg ?? 0.0)
            }
            let totalPersonalDistance = personalTrips.reduce(0.0) { sum, trip in
                sum + (trip.distance_km ?? 0.0)
            }
            
            await MainActor.run {
                personalCO2Total = totalPersonalCO2
                personalTripsCountTotal = personalTrips.count
                personalDistanceTotal = totalPersonalDistance
            }
            
            print("[COCKPIT] ✅ Total data loaded: \(personalTrips.count) trips, \(String(format: "%.2f", totalPersonalCO2)) kg CO₂, \(String(format: "%.1f", totalPersonalDistance)) km")
            
            // TODO: Charger les données professionnelles quand elles seront disponibles
            // Pour l'instant, on met les valeurs pro à 0
            await MainActor.run {
                professionalCO2Total = 0.0
                professionalTripsCountTotal = 0
                professionalDistanceTotal = 0.0
            }
        } catch {
            print("[COCKPIT] ❌ Error loading total data: \(error.localizedDescription)")
            await MainActor.run {
                // En cas d'erreur, mettre les valeurs à 0
                personalCO2Total = 0.0
                personalTripsCountTotal = 0
                personalDistanceTotal = 0.0
                professionalCO2Total = 0.0
                professionalTripsCountTotal = 0
                professionalDistanceTotal = 0.0
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
    let tripsCount: Int? // Pour le bloc Perso CO2 uniquement
    let distanceKm: Double? // Distance en km pour le bloc Perso CO2
    let deltaTrips: Int? // Delta trajets vs mois précédent
    let deltaKm: Double? // Delta km vs mois précédent
    let deltaCO2: Double? // Delta CO2 vs mois précédent
    let prevTripsCount: Int? // Valeur précédente pour calcul du pourcentage
    let prevDistanceKm: Double? // Valeur précédente pour calcul du pourcentage
    let prevCO2Month: Double? // Valeur précédente pour calcul du pourcentage
    let co2PerKm: String? // Ratio CO2/km formaté (ex: "0,12 kg CO₂ / km")
}

struct KPIDashboard {
    let personal: [KPIItem]
    let professional: [KPIItem]?
}

// MARK: - Delta Text Component

struct DeltaText: View {
    let delta: Double
    let previousValue: Double
    let isCO2OrKm: Bool // true pour CO2 et km (vert si baisse = meilleur), false pour trajets (neutre)
    
    init(delta: Double, previousValue: Double, isCO2OrKm: Bool = false) {
        self.delta = delta
        self.previousValue = previousValue
        self.isCO2OrKm = isCO2OrKm
    }
    
    private var canCalculatePercentage: Bool {
        previousValue > 0
    }
    
    private var percentage: Double {
        guard canCalculatePercentage else { return 0 }
        let epsilon = 0.0001
        return (delta / max(previousValue, epsilon)) * 100
    }
    
    private var deltaColor: Color {
        guard canCalculatePercentage else {
            return Color.secondary
        }
        
        if isCO2OrKm {
            // Pour CO2 et km : vert si baisse (meilleur), rouge si hausse
            if delta < 0 {
                return Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759 (vert)
            } else if delta > 0 {
                return Color(red: 1.0, green: 0.23, blue: 0.19) // #FF3B30 (rouge)
            } else {
                return Color.secondary
            }
        } else {
            // Pour trajets : neutre (gris) ou même logique que km
            return Color.secondary
        }
    }
    
    private var formattedValue: String {
        guard canCalculatePercentage else {
            return "—"
        }
        
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0 // Arrondi à l'entier
        
        let absPercentage = abs(percentage)
        let sign = delta > 0 ? "+" : (delta < 0 ? "-" : "")
        let formatted = formatter.string(from: NSNumber(value: absPercentage)) ?? "0"
        
        return "\(sign)\(formatted)%"
    }
    
    var body: some View {
        Text(formattedValue)
            .font(.system(size: 11, weight: .regular))
            .fontWeight(.regular)
            .foregroundColor(deltaColor)
            .frame(width: 52, alignment: .trailing)
    }
}

// MARK: - KPI Tile Component

struct KPITile: View {
    let item: KPIItem
    
    // Layout spécial pour le bloc Perso/Pro CO2
    private var isPersoCO2: Bool {
        (item.kpiType == .co2Perso || item.kpiType == .co2Pro) && item.tripsCount != nil
    }
    
    // Vérifier si c'est un bloc "Total" (sans variations)
    private var isTotalBlock: Bool {
        item.subtitle == "Total"
    }
    
    private func formatTripsText(_ count: Int?) -> String {
        guard let count = count else { return "—" }
        if count == 0 { return "0 trajet" }
        return count == 1 ? "1 trajet" : "\(count) trajets"
    }
    
    private func formatDistanceKm(_ distance: Double?) -> String {
        guard let distance = distance else { return "—" }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: distance)) ?? "0"
    }
    
    var body: some View {
        VStack(spacing: 6) {
            if isPersoCO2 {
                // Layout spécial pour Perso/Pro CO2 (Carbyo Fresh palette)
                VStack(alignment: .leading, spacing: 4) {
                    // Header: Titre "Perso · Ce mois" ou "Pro · Ce mois"
                    HStack(spacing: 6) {
                        Text("\(item.title) · \(item.subtitle ?? "Ce mois")")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(CarbyoColors.freshOrange)
                            .fixedSize(horizontal: true, vertical: false)
                        
                        Spacer()
                    }
                    
                    // Valeurs avec typographie harmonisée et comparatif aligné à droite
                    VStack(alignment: .leading, spacing: 4) {
                        // Nombre de trajets
                        HStack {
                            Text(formatTripsText(item.tripsCount))
                                .font(.caption2)
                                .fontWeight(.regular)
                                .foregroundColor(CarbyoColors.carbyoGreen)
                                .lineLimit(1)
                            
                            if !isTotalBlock {
                                Spacer()
                                
                                if let deltaTrips = item.deltaTrips, let prevTrips = item.prevTripsCount {
                                    DeltaText(delta: Double(deltaTrips), previousValue: Double(prevTrips), isCO2OrKm: false)
                                } else {
                                    Text("—")
                                        .font(.caption2)
                                        .fontWeight(.regular)
                                        .foregroundColor(Color.secondary)
                                        .frame(width: 52, alignment: .trailing)
                                }
                            }
                        }
                        
                        // Distance en km
                        HStack {
                            Text("\(formatDistanceKm(item.distanceKm)) km")
                                .font(.caption2)
                                .fontWeight(.regular)
                                .foregroundColor(CarbyoColors.carbyoGreen)
                                .lineLimit(1)
                            
                            if !isTotalBlock {
                                Spacer()
                                
                                if let deltaKm = item.deltaKm, let prevKm = item.prevDistanceKm {
                                    DeltaText(delta: deltaKm, previousValue: prevKm, isCO2OrKm: true)
                                } else {
                                    Text("—")
                                        .font(.caption2)
                                        .fontWeight(.regular)
                                        .foregroundColor(Color.secondary)
                                        .frame(width: 52, alignment: .trailing)
                                }
                            }
                        }
                        
                        // CO2
                        if let unit = item.unit {
                            HStack {
                                Text("\(item.value) \(unit)")
                                    .font(.caption2)
                                    .fontWeight(.regular)
                                    .foregroundColor(CarbyoColors.carbyoGreen)
                                    .lineLimit(1)
                                    .monospacedDigit()
                                
                                if !isTotalBlock {
                                    Spacer()
                                    
                                    if let deltaCO2 = item.deltaCO2, let prevCO2 = item.prevCO2Month {
                                        DeltaText(delta: deltaCO2, previousValue: prevCO2, isCO2OrKm: true)
                                    } else {
                                        Text("—")
                                            .font(.caption2)
                                            .fontWeight(.regular)
                                            .foregroundColor(Color.secondary)
                                            .frame(width: 52, alignment: .trailing)
                                    }
                                }
                            }
                        }
                        
                        // Ratio CO2/km (4ème ligne - sans variation, centrée, en noir)
                        if let co2PerKm = item.co2PerKm {
                            HStack {
                                Spacer()
                                Text(co2PerKm)
                                    .font(.caption2)
                                    .fontWeight(.regular)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.top, 1)
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
                .padding(.bottom, 2)
            } else {
                // Layout standard pour les autres KPIs
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
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 110)
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

// MARK: - Month Trips Modal View

struct MonthTripsModalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: SessionStore
    let contextType: CockpitView.ContextType
    
    @State private var trips: [Trip] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let tripService = TripService(client: SupabaseManager.shared.client)
    
    private var tripType: String {
        contextType == .perso ? "perso" : "pro"
    }
    
    private var modalTitle: String {
        return contextType == .perso ? "Trajets perso" : "Trajets pro"
    }
    
    private var monthYearSubtitle: String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: now).capitalized
    }
    
    private func getCurrentMonthStart() -> String {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter.string(from: now)
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: startOfMonth)
    }
    
    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "—" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "fr_FR")
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
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
    
    private func transportIcon(for mode: String?) -> String {
        guard let mode = mode?.lowercased() else { return "car.fill" }
        switch mode {
        case "voiture", "car", "automobile":
            return "car.fill"
        case "avion", "plane", "airplane":
            return "airplane"
        case "train":
            return "tram.fill"
        case "vélo", "bike", "bicycle":
            return "bicycle"
        case "moto", "motorcycle":
            return "motorcycle"
        case "bus":
            return "bus.fill"
        case "métro", "metro", "subway":
            return "tram.fill"
        default:
            return "car.fill"
        }
    }
    
    private func transportLabel(for trip: Trip) -> String {
        guard let mode = trip.transport_mode?.lowercased() else {
            return "Véhicule"
        }
        
        switch mode {
        case "voiture", "car", "automobile":
            return "Voiture"
        case "avion", "plane", "airplane":
            return "Avion"
        case "train":
            return "Train"
        case "vélo", "bike", "bicycle":
            return "Vélo"
        case "moto", "motorcycle":
            return "Moto"
        case "bus":
            return "Bus"
        case "métro", "metro", "subway":
            return "Métro"
        default:
            return "Véhicule"
        }
    }
    
    private func formatShortDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "—" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "fr_FR")
        displayFormatter.dateFormat = "dd/MM/yy"
        return displayFormatter.string(from: date)
    }
    
    private func calculateIntensity(co2Kg: Double?, distanceKm: Double?) -> Double? {
        guard let co2 = co2Kg, let distance = distanceKm, distance > 0 else {
            return nil
        }
        return (co2 * 1000) / distance
    }
    
    private func formatIntensity(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    private func intensityColor(for intensity: Double) -> Color {
        let clampedIntensity = min(max(intensity, 0), 300)
        let progress = clampedIntensity / 300.0
        
        // Interpolation de couleur : vert (0) → orange (0.5) → rouge (0.75) → noir (1.0)
        if progress <= 0.5 {
            // Vert → Orange
            let t = progress * 2.0
            return Color(
                red: 0.2 + (t * 0.8),
                green: 0.78 - (t * 0.28),
                blue: 0.35 - (t * 0.35)
            )
        } else if progress <= 0.75 {
            // Orange → Rouge
            let t = (progress - 0.5) * 4.0
            return Color(
                red: 1.0,
                green: 0.5 - (t * 0.27),
                blue: 0.0
            )
        } else {
            // Rouge → Noir
            let t = (progress - 0.75) * 4.0
            return Color(
                red: 1.0 - (t * 1.0),
                green: 0.23 - (t * 0.23),
                blue: 0.19 - (t * 0.19)
            )
        }
    }
    
    private func intensityProgress(for intensity: Double) -> Double {
        let clampedIntensity = min(max(intensity, 0), 300)
        return clampedIntensity / 300.0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                CarbyoColors.background
                    .ignoresSafeArea()
                
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
                        Text("Aucun trajet enregistré pour ce mois.")
                            .font(.body)
                            .foregroundColor(CarbyoColors.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(trips) { trip in
                            NavigationLink {
                                TripDetailView(trip: trip)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    // Ligne 1 : Date · Icône + Libellé transport · Distance · CO₂ · Chevron
                                    HStack(alignment: .center, spacing: 3) {
                                        // Date (format numérique court JJ/MM/AA)
                                        Text(formatShortDate(trip.trip_date))
                                            .font(.system(size: 11))
                                            .foregroundColor(Color.secondary)
                                            .monospacedDigit()
                                        
                                        Text("·")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color.secondary.opacity(0.3))
                                        
                                        // Icône transport
                                        Image(systemName: transportIcon(for: trip.transport_mode))
                                            .font(.system(size: 10))
                                            .foregroundColor(CarbyoColors.primary)
                                        
                                        // Libellé transport
                                        Text(transportLabel(for: trip))
                                            .font(.system(size: 11))
                                            .foregroundColor(CarbyoColors.text)
                                        
                                        Spacer(minLength: 2)
                                        
                                        // Distance
                                        if let distance = trip.distance_km {
                                            Text("·")
                                                .font(.system(size: 10))
                                                .foregroundColor(Color.secondary.opacity(0.3))
                                            
                                            Text("\(formatDistance(distance)) km")
                                                .font(.system(size: 11))
                                                .foregroundColor(CarbyoColors.text)
                                                .monospacedDigit()
                                        }
                                        
                                        // CO₂
                                        if let co2 = trip.co2_emissions_kg {
                                            Text("·")
                                                .font(.system(size: 10))
                                                .foregroundColor(Color.secondary.opacity(0.3))
                                            
                                            Text("\(formatCO2(co2)) kg CO₂")
                                                .font(.system(size: 11))
                                                .foregroundColor(CarbyoColors.primary)
                                                .monospacedDigit()
                                        }
                                        
                                        // Chevron (ajouté automatiquement par NavigationLink, mais on peut le masquer si nécessaire)
                                    }
                                    
                                    // Ligne 2 : Intensité CO₂ + Jauge
                                    if let intensity = calculateIntensity(co2Kg: trip.co2_emissions_kg, distanceKm: trip.distance_km) {
                                        HStack(alignment: .center, spacing: 8) {
                                            // Texte intensité
                                            Text("Intensité: \(formatIntensity(intensity)) g CO₂/km")
                                                .font(.system(size: 10))
                                                .foregroundColor(CarbyoColors.muted)
                                            
                                            Spacer()
                                            
                                            // Jauge
                                            GeometryReader { geometry in
                                                let progress = intensityProgress(for: intensity)
                                                let width = geometry.size.width * progress
                                                let barColor = intensityColor(for: intensity)
                                                
                                                ZStack(alignment: .leading) {
                                                    // Fond gris clair
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.gray.opacity(0.2))
                                                        .frame(height: 7)
                                                    
                                                    // Barre de progression
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(barColor)
                                                        .frame(width: width, height: 7)
                                                }
                                            }
                                            .frame(width: 80, height: 7)
                                        }
                                    } else {
                                        // Si pas d'intensité calculable
                                        Text("Intensité: —")
                                            .font(.system(size: 10))
                                            .foregroundColor(CarbyoColors.muted)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(minHeight: 68)
                            }
                            .buttonStyle(.plain)
                            .background(CarbyoColors.surface)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(CarbyoColors.border.opacity(0.3), lineWidth: 0.5)
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await loadTrips()
                    }
                }
            }
            .navigationTitle(modalTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 4) {
                        Text(modalTitle)
                            .font(.headline)
                        Text(monthYearSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloseActionButton {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadTrips()
        }
    }
    
    private func loadTrips() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let monthStart = getCurrentMonthStart()
            let fetchedTrips = try await tripService.fetchTripsByType(type: tripType, startDate: monthStart, endDate: nil)
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

// MARK: - Close Action Button Component

struct CloseActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text("Fermer")
                .font(.caption)
                .foregroundColor(CarbyoColors.primary)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trip Detail View

struct TripDetailView: View {
    let trip: Trip
    @Environment(\.dismiss) var dismiss
    @State private var showEditView = false
    
    // Formatters centralisés
    private func formatDateShort(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "—" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "fr_FR")
        displayFormatter.dateFormat = "dd/MM/yy"
        return displayFormatter.string(from: date)
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
    
    private func calculateIntensity(co2Kg: Double?, distanceKm: Double?) -> Double? {
        guard let co2 = co2Kg, let distance = distanceKm, distance > 0 else {
            return nil
        }
        return (co2 * 1000) / distance
    }
    
    private func formatIntensity(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    private func transportIcon(for mode: String?) -> String {
        guard let mode = mode?.lowercased() else { return "car.fill" }
        switch mode {
        case "voiture", "car", "automobile": return "car.fill"
        case "avion", "plane", "airplane": return "airplane"
        case "train": return "tram.fill"
        case "vélo", "bike", "bicycle": return "bicycle"
        case "moto", "motorcycle": return "motorcycle"
        case "bus": return "bus.fill"
        case "métro", "metro", "subway": return "tram.fill"
        default: return "car.fill"
        }
    }
    
    private func transportLabel(for mode: String?) -> String {
        guard let mode = mode?.lowercased() else { return "Véhicule" }
        switch mode {
        case "voiture", "car", "automobile": return "Voiture"
        case "avion", "plane", "airplane": return "Avion"
        case "train": return "Train"
        case "vélo", "bike", "bicycle": return "Vélo"
        case "moto", "motorcycle": return "Moto"
        case "bus": return "Bus"
        case "métro", "metro", "subway": return "Métro"
        default: return "Véhicule"
        }
    }
    
    private func intensityColor(for intensity: Double) -> Color {
        let clampedIntensity = min(max(intensity, 0), 300)
        let progress = clampedIntensity / 300.0
        
        if progress <= 0.27 { // 0-80g
            let t = progress / 0.27
            return Color(red: 0.2 + (t * 0.8), green: 0.78 - (t * 0.28), blue: 0.35 - (t * 0.35))
        } else if progress <= 0.5 { // 80-150g
            let t = (progress - 0.27) / 0.23
            return Color(red: 1.0, green: 0.5 + (t * 0.3), blue: 0.0)
        } else if progress <= 0.73 { // 150-220g
            let t = (progress - 0.5) / 0.23
            return Color(red: 1.0, green: 0.8 - (t * 0.57), blue: 0.0)
        } else if progress <= 1.0 { // 220-300g
            let t = (progress - 0.73) / 0.27
            return Color(red: 1.0 - (t * 1.0), green: 0.23 - (t * 0.23), blue: 0.19 - (t * 0.19))
        }
        return Color.black
    }
    
    private func formatDateLong(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "—" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "fr_FR")
        displayFormatter.dateFormat = "dd/MM/yyyy"
        return displayFormatter.string(from: date)
    }
    
    private func tripTypeLabel(for type: String?) -> String {
        guard let type = type?.lowercased() else { return "PERSO" }
        switch type {
        case "pro": return "PRO"
        case "domicile-travail", "domicile_travail": return "DOMICILE-TRAVAIL"
        default: return "PERSO"
        }
    }
    
    private func tripTypeColor(for type: String?) -> Color {
        guard let type = type?.lowercased() else { return CarbyoColors.primary }
        switch type {
        case "pro": return Color.purple
        case "domicile-travail", "domicile_travail": return Color.blue
        default: return CarbyoColors.primary
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Badge type de trajet (juste sous le titre)
                TripTypeBadge(
                    type: trip.type_trajet,
                    label: tripTypeLabel(for: trip.type_trajet),
                    color: tripTypeColor(for: trip.type_trajet)
                )
                
                // Première ligne : Date — Mode — Intensité
                TripContextRow(
                    date: formatDateLong(trip.trip_date),
                    transportLabel: transportLabel(for: trip.transport_mode),
                    intensity: calculateIntensity(co2Kg: trip.co2_emissions_kg, distanceKm: trip.distance_km),
                    formatIntensity: formatIntensity
                )
                
                // Ligne véhicule : Immatriculation — Carburant
                if let vehicle = trip.vehicles {
                    TripVehicleRow(
                        registration: vehicle.registration,
                        energy: vehicle.energy
                    )
                }
                
                // Bloc itinéraire vertical : Départ → Arrivée
                TripVerticalRouteRow(
                    originAddress: trip.origin_address,
                    destinationAddress: trip.destination_address
                )
                
                // Ligne récapitulative : Distance • Émissions • Intensité
                TripSummaryRow(
                    distance: trip.distance_km,
                    co2: trip.co2_emissions_kg,
                    intensity: calculateIntensity(co2Kg: trip.co2_emissions_kg, distanceKm: trip.distance_km),
                    formatDistance: formatDistance,
                    formatCO2: formatCO2,
                    formatIntensity: formatIntensity
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(CarbyoColors.background)
        .navigationTitle("Détail du trajet")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showEditView = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                        Text("Modifier")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.plain)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                CloseActionButton {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showEditView) {
            NavigationStack {
                TripEditView(trip: trip)
            }
        }
    }
}

// MARK: - Trip Type Badge

struct TripTypeBadge: View {
    let type: String?
    let label: String
    let color: Color
    
    var body: some View {
        HStack {
            Spacer()
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(color)
                )
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
}

// MARK: - Trip Vertical Route Row

struct TripVerticalRouteRow: View {
    let originAddress: String?
    let destinationAddress: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Départ
            VStack(alignment: .leading, spacing: 4) {
                Text("Départ")
                    .font(.caption2)
                    .foregroundColor(CarbyoColors.muted)
                
                if let origin = originAddress, !origin.isEmpty {
                    Text(origin)
                        .font(.system(size: 12))
                        .foregroundColor(CarbyoColors.text)
                        .lineLimit(2)
                } else {
                    Text("Départ non renseigné")
                        .font(.system(size: 12))
                        .foregroundColor(CarbyoColors.muted)
                }
            }
            
            // Flèche verticale
            HStack {
                Image(systemName: "arrow.down")
                    .font(.system(size: 14))
                    .foregroundColor(CarbyoColors.primary.opacity(0.6))
                    .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity)
            
            // Arrivée
            VStack(alignment: .leading, spacing: 4) {
                Text("Arrivée")
                    .font(.caption2)
                    .foregroundColor(CarbyoColors.muted)
                
                if let destination = destinationAddress, !destination.isEmpty {
                    Text(destination)
                        .font(.system(size: 12))
                        .foregroundColor(CarbyoColors.text)
                        .lineLimit(2)
                } else {
                    Text("Arrivée non renseignée")
                        .font(.system(size: 12))
                        .foregroundColor(CarbyoColors.muted)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CarbyoColors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CarbyoColors.border.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Trip Vehicle Row

struct TripVehicleRow: View {
    let registration: String?
    let energy: String?
    
    var body: some View {
        HStack(spacing: 6) {
            Spacer()
            
            if let registration = registration, !registration.isEmpty {
                Text(registration)
                    .font(.system(size: 12))
                    .foregroundColor(CarbyoColors.muted)
                    .lineLimit(1)
                
                if let energy = energy, !energy.isEmpty {
                    // Séparateur
                    Text("—")
                        .font(.system(size: 12))
                        .foregroundColor(CarbyoColors.muted)
                    
                    // Carburant
                    Text(energy.capitalized)
                        .font(.system(size: 12))
                        .foregroundColor(CarbyoColors.muted)
                        .lineLimit(1)
                }
            } else if let energy = energy, !energy.isEmpty {
                Text(energy.capitalized)
                    .font(.system(size: 12))
                    .foregroundColor(CarbyoColors.muted)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
        .lineLimit(1)
    }
}

// MARK: - Trip Context Row

struct TripContextRow: View {
    let date: String
    let transportLabel: String
    let intensity: Double?
    let formatIntensity: (Double) -> String
    
    var body: some View {
        HStack(spacing: 6) {
            // Date
            Text(date)
                .font(.system(size: 13))
                .foregroundColor(CarbyoColors.text)
                .monospacedDigit()
                .lineLimit(1)
            
            // Séparateur
            Text("—")
                .font(.system(size: 13))
                .foregroundColor(CarbyoColors.muted)
            
            // Mode de transport
            Text(transportLabel)
                .font(.system(size: 13))
                .foregroundColor(CarbyoColors.text)
                .lineLimit(1)
            
            // Séparateur
            Text("—")
                .font(.system(size: 13))
                .foregroundColor(CarbyoColors.muted)
            
            // Intensité carbone
            if let intensity = intensity {
                Text("\(formatIntensity(intensity)) g CO₂/km")
                    .font(.system(size: 13))
                    .foregroundColor(CarbyoColors.primary)
                    .monospacedDigit()
                    .lineLimit(1)
            } else {
                Text("— g CO₂/km")
                    .font(.system(size: 13))
                    .foregroundColor(CarbyoColors.muted)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(CarbyoColors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CarbyoColors.border.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Trip Summary Row

struct TripSummaryRow: View {
    let distance: Double?
    let co2: Double?
    let intensity: Double?
    let formatDistance: (Double?) -> String
    let formatCO2: (Double?) -> String
    let formatIntensity: (Double) -> String
    
    var body: some View {
        HStack(spacing: 8) {
            Spacer()
            
            // Distance
            Text("\(formatDistance(distance)) km")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(CarbyoColors.text)
                .monospacedDigit()
            
            // Séparateur
            Text("•")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(CarbyoColors.muted)
            
            // Émissions CO₂
            Text("\(formatCO2(co2)) kg CO₂")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(CarbyoColors.primary)
                .monospacedDigit()
            
            // Séparateur
            Text("•")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(CarbyoColors.muted)
            
            // Intensité
            if let intensity = intensity {
                Text("\(formatIntensity(intensity)) g CO₂/km")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(CarbyoColors.text)
                    .monospacedDigit()
            } else {
                Text("— g CO₂/km")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(CarbyoColors.muted)
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
        .lineLimit(1)
    }
}

// MARK: - Trip KPI Row (deprecated - kept for reference)

struct TripKpiRow: View {
    let distance: Double?
    let co2: Double?
    let intensity: Double?
    let formatDistance: (Double?) -> String
    let formatCO2: (Double?) -> String
    let formatIntensity: (Double) -> String
    let intensityColor: (Double) -> Color
    
    var body: some View {
        HStack(spacing: 8) {
            // Distance
            VStack(alignment: .leading, spacing: 4) {
                Text("Distance")
                    .font(.caption2)
                    .foregroundColor(CarbyoColors.muted)
                Text("\(formatDistance(distance)) km")
                    .font(.headline)
                    .foregroundColor(CarbyoColors.text)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(CarbyoColors.surface)
            .cornerRadius(10)
            
            // CO₂
            VStack(alignment: .leading, spacing: 4) {
                Text("Émissions")
                    .font(.caption2)
                    .foregroundColor(CarbyoColors.muted)
                Text("\(formatCO2(co2)) kg CO₂")
                    .font(.headline)
                    .foregroundColor(CarbyoColors.primary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(CarbyoColors.surface)
            .cornerRadius(10)
            
            // Intensité
            if let intensity = intensity {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Intensité")
                        .font(.caption2)
                        .foregroundColor(CarbyoColors.muted)
                    Text("\(formatIntensity(intensity)) g CO₂/km")
                        .font(.headline)
                        .foregroundColor(CarbyoColors.text)
                        .monospacedDigit()
                    
                    // Jauge
                    let progress = min(max(intensity, 0), 300) / 300.0
                    let barColor = intensityColor(intensity)
                    
                    GeometryReader { geometry in
                        let width = geometry.size.width * progress
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 5)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(barColor)
                                .frame(width: width, height: 5)
                        }
                    }
                    .frame(height: 5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(CarbyoColors.surface)
                .cornerRadius(10)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Intensité")
                        .font(.caption2)
                        .foregroundColor(CarbyoColors.muted)
                    Text("—")
                        .font(.headline)
                        .foregroundColor(CarbyoColors.text)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(CarbyoColors.surface)
                .cornerRadius(10)
            }
        }
    }
}

// MARK: - Trip Route Card

struct TripRouteCard: View {
    let origin: String?
    let destination: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Itinéraire")
                .font(.caption)
                .foregroundColor(CarbyoColors.muted)
            
            if let origin = origin, let destination = destination {
                // Départ et arrivée
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Départ")
                            .font(.caption2)
                            .foregroundColor(CarbyoColors.muted)
                        Text(origin)
                            .font(.body)
                            .foregroundColor(CarbyoColors.text)
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Arrivée")
                            .font(.caption2)
                            .foregroundColor(CarbyoColors.muted)
                        Text(destination)
                            .font(.body)
                            .foregroundColor(CarbyoColors.text)
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                }
            } else if let origin = origin {
                // Seulement départ
                Text(origin)
                    .font(.body)
                    .foregroundColor(CarbyoColors.text)
                    .lineLimit(2)
                    .truncationMode(.tail)
            } else if let destination = destination {
                // Seulement arrivée
                Text(destination)
                    .font(.body)
                    .foregroundColor(CarbyoColors.text)
                    .lineLimit(2)
                    .truncationMode(.tail)
            } else {
                // Aucune adresse
                Text("Itinéraire non renseigné")
                    .font(.body)
                    .foregroundColor(CarbyoColors.muted)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CarbyoColors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CarbyoColors.border.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Trip Vehicle Card

struct TripVehicleCard: View {
    let vehicle: VehicleDB
    
    var body: some View {
        // Afficher le bloc uniquement s'il y a des infos supplémentaires (marque/modèle ou V7)
        let hasBrandModel = vehicle.brand != nil && vehicle.model != nil
        let hasV7Emissions = vehicle.v7_emissions != nil
        
        if hasBrandModel || hasV7Emissions {
            VStack(alignment: .leading, spacing: 12) {
                Text("Véhicule")
                    .font(.caption)
                    .foregroundColor(CarbyoColors.muted)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Marque et modèle (si présents)
                    if let brand = vehicle.brand, let model = vehicle.model {
                        Text("\(brand) \(model)")
                            .font(.body)
                            .foregroundColor(CarbyoColors.text)
                    }
                    
                    // Émissions V7 (si présentes)
                    if let v7Emissions = vehicle.v7_emissions {
                        HStack(spacing: 4) {
                            Text("V7:")
                                .font(.caption)
                                .foregroundColor(CarbyoColors.muted)
                            Text("\(String(format: "%.1f", v7Emissions)) g/km")
                                .font(.caption)
                                .foregroundColor(CarbyoColors.text)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CarbyoColors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CarbyoColors.border.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Trip Edit View

struct TripEditView: View {
    let trip: Trip
    @Environment(\.dismiss) var dismiss
    
    // États pour les champs éditables
    @State private var tripDate: String
    @State private var tripType: String
    @State private var transportMode: String
    @State private var co2Intensity: String
    @State private var originAddress: String
    @State private var destinationAddress: String
    @State private var vehicleRegistration: String
    @State private var vehicleEnergy: String
    
    init(trip: Trip) {
        self.trip = trip
        _tripDate = State(initialValue: trip.trip_date ?? "")
        _tripType = State(initialValue: trip.type_trajet ?? "perso")
        _transportMode = State(initialValue: trip.transport_mode ?? "")
        _co2Intensity = State(initialValue: trip.co2_emissions_kg != nil ? String(format: "%.2f", trip.co2_emissions_kg!) : "")
        _originAddress = State(initialValue: trip.origin_address ?? "")
        _destinationAddress = State(initialValue: trip.destination_address ?? "")
        _vehicleRegistration = State(initialValue: trip.vehicles?.registration ?? "")
        _vehicleEnergy = State(initialValue: trip.vehicles?.energy ?? "")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.caption)
                        .foregroundColor(CarbyoColors.muted)
                    TextField("Date du trajet", text: $tripDate)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Type de trajet
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type de trajet")
                        .font(.caption)
                        .foregroundColor(CarbyoColors.muted)
                    Picker("Type", selection: $tripType) {
                        Text("Perso").tag("perso")
                        Text("Pro").tag("pro")
                    }
                    .pickerStyle(.segmented)
                }
                
                // Mode de transport
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mode de transport")
                        .font(.caption)
                        .foregroundColor(CarbyoColors.muted)
                    TextField("Voiture, Train, Avion...", text: $transportMode)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Intensité CO₂
                VStack(alignment: .leading, spacing: 8) {
                    Text("Intensité CO₂ (kg)")
                        .font(.caption)
                        .foregroundColor(CarbyoColors.muted)
                    TextField("0.00", text: $co2Intensity)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }
                
                // Adresse de départ
                VStack(alignment: .leading, spacing: 8) {
                    Text("Adresse de départ")
                        .font(.caption)
                        .foregroundColor(CarbyoColors.muted)
                    TextField("Adresse de départ", text: $originAddress, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...5)
                }
                
                // Adresse d'arrivée
                VStack(alignment: .leading, spacing: 8) {
                    Text("Adresse d'arrivée")
                        .font(.caption)
                        .foregroundColor(CarbyoColors.muted)
                    TextField("Adresse d'arrivée", text: $destinationAddress, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...5)
                }
                
                // Plaque d'immatriculation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Plaque d'immatriculation")
                        .font(.caption)
                        .foregroundColor(CarbyoColors.muted)
                    TextField("AA-123-BB", text: $vehicleRegistration)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Carburant
                VStack(alignment: .leading, spacing: 8) {
                    Text("Carburant")
                        .font(.caption)
                        .foregroundColor(CarbyoColors.muted)
                    TextField("Essence, Diesel, Électrique...", text: $vehicleEnergy)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding()
        }
        .background(CarbyoColors.background)
        .navigationTitle("Modifier le trajet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") {
                    dismiss()
                }
                .foregroundColor(CarbyoColors.text)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Enregistrer") {
                    // TODO: Sauvegarder les modifications
                    // Pour l'instant, juste fermer le modal
                    dismiss()
                }
                .foregroundColor(CarbyoColors.primary)
                .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Trip Tech Disclosure

struct TripTechDisclosure: View {
    @Binding var isExpanded: Bool
    let calculationMethod: String?
    let transportMode: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Voir les détails techniques")
                        .font(.subheadline)
                        .foregroundColor(CarbyoColors.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(CarbyoColors.primary)
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if let method = calculationMethod {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Méthode de calcul")
                                .font(.caption2)
                                .foregroundColor(CarbyoColors.muted)
                            Text(method)
                                .font(.caption)
                                .foregroundColor(CarbyoColors.text)
                        }
                    }
                    
                    if let mode = transportMode {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mode de transport")
                                .font(.caption2)
                                .foregroundColor(CarbyoColors.muted)
                            Text(mode.capitalized)
                                .font(.caption)
                                .foregroundColor(CarbyoColors.text)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(CarbyoColors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CarbyoColors.border.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        CockpitView()
            .environmentObject(SessionStore())
    }
}
