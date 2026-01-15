//
//  AccountView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Mon compte")
                    .padding()
                
                Button(action: {
                    Task {
                        await session.signOut()
                    }
                }) {
                    Text("Se déconnecter")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Mon compte")
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(SessionStore())
}
