//
//  ContentView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var session = SessionStore()
    @StateObject private var enterpriseStore = EnterpriseStore()
    @StateObject private var onboardingStore = OnboardingStore()
    
    var body: some View {
        Group {
            if !session.isLoggedIn {
                LoginView()
                    .environmentObject(session)
                    .environmentObject(enterpriseStore)
                    .environmentObject(onboardingStore)
            } else if session.shouldShowInvitation {
                PendingEnterpriseView()
                    .environmentObject(session)
                    .environmentObject(enterpriseStore)
                    .environmentObject(onboardingStore)
            } else if !session.isOnboardingComplete {
                OnboardingView()
                    .environmentObject(session)
                    .environmentObject(enterpriseStore)
                    .environmentObject(onboardingStore)
            } else {
                MainTabView()
                    .environmentObject(session)
                    .environmentObject(enterpriseStore)
                    .environmentObject(onboardingStore)
            }
        }
        .task {
            // Restaurer la session Supabase au démarrage
            await session.restoreSession()
        }
    }
}

#Preview {
    ContentView()
}
