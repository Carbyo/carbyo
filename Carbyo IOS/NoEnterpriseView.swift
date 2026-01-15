//
//  NoEnterpriseView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct NoEnterpriseView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Vous n'êtes rattaché à aucune entreprise")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Entreprise")
        }
    }
}

#Preview {
    NoEnterpriseView()
}
