//
//  TripsView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct TripsView: View {
    @State private var isLoading = true
    @State private var trips: [Trip] = []
    @State private var errorMessage: String? = nil
    @State private var selectedTrip: Trip? = nil
    @State private var showMonthPicker = false
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    
    private let tripService = TripService(client: SupabaseManager.shared.client)
    
    init() {
        let calendar = Calendar.current
        let now = Date()
        _selectedMonth = State(initialValue: calendar.component(.month, from: now))
        _selectedYear = State(initialValue: calendar.component(.year, from: now))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tripsTopHeader
                tableHeader
                
                Group {
                    if isLoading {
                        ProgressView("Chargement…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage {
                        errorView(errorMessage)
                    } else if trips.isEmpty {
                        ContentUnavailableView(
                            "Aucun trajet",
                            systemImage: "car",
                            description: Text("Ajoutez un trajet avec le +")
                        )
                    } else {
                        List(trips) { trip in
                            TripRowCompact(trip: trip)
                                .onTapGesture {
                                    selectedTrip = trip
                                }
                                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        }
                        .listStyle(.plain)
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: 72) // prevents the floating + from hiding rows
                        }
                        .refreshable {
                            await load()
                        }
                    }
                }
            }
            .navigationTitle("Mes trajets")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await load()
            }
            .sheet(item: $selectedTrip) { trip in
                TripDetailModal(trip: trip)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showMonthPicker) {
                MonthYearPickerSheet(
                    month: $selectedMonth,
                    year: $selectedYear,
                    onValidate: {
                        Task {
                            await loadTripsForSelectedMonth()
                        }
                    }
                )
            }
        }
    }
    
    private var monthYearTitle: String {
        formatMonthYearFR(month: selectedMonth, year: selectedYear)
    }
    
    // MARK: - Helpers pour les dates
    
    private func formatMonthYearFR(month: Int, year: Int) -> String {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let date = calendar.date(from: components) else {
            return "\(month)/\(year)"
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "LLLL yyyy" // ex: "janvier 2026"
        let raw = formatter.string(from: date)
        return raw.prefix(1).uppercased() + raw.dropFirst() // "Janvier 2026"
    }
    
    private func monthStartISO(month: Int, year: Int) -> String {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let date = calendar.date(from: components) else {
            return String(format: "%04d-%02d-01", year, month)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
    
    private func monthEndISO(month: Int, year: Int) -> String {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let firstDayOfMonth = calendar.date(from: components) else {
            // Fallback: calculer le dernier jour du mois
            let daysInMonth = calendar.range(of: .day, in: .month, for: Date())!.count
            return String(format: "%04d-%02d-%02d", year, month, daysInMonth)
        }
        
        // Obtenir le dernier jour du mois en ajoutant un mois et en retirant un jour
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth),
              let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth) else {
            // Fallback: calculer le dernier jour du mois
            let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!.count
            return String(format: "%04d-%02d-%02d", year, month, daysInMonth)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: lastDayOfMonth)
    }
    
    private var tripsTopHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Button {
                    showMonthPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(monthYearTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Changer de mois")
                
                Text("Mes trajets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            carbyoLogo
                .frame(width: 28, height: 28)
                .padding(.trailing, 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
    }
    
    @ViewBuilder
    private var carbyoLogo: some View {
        if UIImage(named: "CarbyoLeaf") != nil {
            Image("CarbyoLeaf")
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "leaf.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.green)
        }
    }
    
    private var tableHeader: some View {
        HStack(spacing: 10) {
            Text("Date")
                .frame(width: 86, alignment: .leading)
            Text("Type")
                .frame(width: 52, alignment: .leading)
            Spacer(minLength: 6)
            Text("Km")
                .frame(width: 62, alignment: .trailing)
            Text("CO₂")
                .frame(width: 70, alignment: .trailing)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
    }
    
    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text("Erreur")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button("Réessayer") {
                Task {
                    await load()
                }
            }
        }
        .padding()
    }
    
    @MainActor
    private func load() async {
        await loadTripsForSelectedMonth()
    }
    
    @MainActor
    private func loadTripsForSelectedMonth() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let startDate = monthStartISO(month: selectedMonth, year: selectedYear)
            
            // Si c'est le mois courant, ne pas mettre de endDate
            let calendar = Calendar.current
            let now = Date()
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)
            let isCurrentMonth = (selectedMonth == currentMonth && selectedYear == currentYear)
            
            let endDate: String? = isCurrentMonth ? nil : monthEndISO(month: selectedMonth, year: selectedYear)
            
            let result = try await tripService.fetchAllTrips(startDate: startDate, endDate: endDate)
            trips = result
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}

private struct TripRowCompact: View {
    let trip: Trip
    
    var body: some View {
        HStack(spacing: 10) {
            Text(trip.shortDateFR)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 86, alignment: .leading)
            
            Text(trip.typeShort)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
                .frame(width: 52, alignment: .leading)
            
            Spacer(minLength: 6)
            
            Text(trip.kmShort)
                .font(.caption)
                .monospacedDigit()
                .frame(width: 62, alignment: .trailing)
            
            Text(trip.co2Short)
                .font(.caption)
                .monospacedDigit()
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

private struct TripDetailModal: View {
    let trip: Trip
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Résumé") {
                    row("Date", trip.shortDateFR)
                    row("Type", (trip.type_trajet ?? "-").uppercased())
                    row("Distance", String(format: "%.1f km", trip.distance_km ?? 0))
                    row("CO₂", String(format: "%.2f kg", trip.co2_emissions_kg ?? 0))
                }
                
                Section("Adresses") {
                    row("Départ", trip.origin_address ?? "-")
                    row("Arrivée", trip.destination_address ?? "-")
                }
                
                Section("Infos") {
                    row("Mode", trip.transport_mode ?? "-")
                    row("Méthode", trip.calculation_method ?? "-")
                    if let vehicleId = trip.vehicle_id {
                        row("Véhicule", vehicleId.uuidString)
                    }
                }
            }
            .navigationTitle("Détail trajet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder private func row(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    TripsView()
}
