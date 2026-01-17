//
//  MonthYearPickerSheet.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct MonthYearPickerSheet: View {
    @Binding var month: Int
    @Binding var year: Int
    @Environment(\.dismiss) private var dismiss
    
    var onValidate: () -> Void
    
    private let months: [(Int, String)] = [
        (1, "Janvier"), (2, "Février"), (3, "Mars"),
        (4, "Avril"), (5, "Mai"), (6, "Juin"),
        (7, "Juillet"), (8, "Août"), (9, "Septembre"),
        (10, "Octobre"), (11, "Novembre"), (12, "Décembre")
    ]
    
    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...(currentYear + 1))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mois")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Picker("Mois", selection: $month) {
                            ForEach(months, id: \.0) { monthData in
                                Text(monthData.1).tag(monthData.0)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Année")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Picker("Année", selection: $year) {
                            ForEach(years, id: \.self) { yearValue in
                                Text("\(yearValue)").tag(yearValue)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Choisir une période")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Valider") {
                        onValidate()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    MonthYearPickerSheet(
        month: .constant(1),
        year: .constant(2026),
        onValidate: {}
    )
}
