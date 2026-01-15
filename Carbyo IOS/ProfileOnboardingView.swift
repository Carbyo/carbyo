//
//  ProfileOnboardingView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct ProfileOnboardingView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var onboardingStore: OnboardingStore
    @Environment(\.dismiss) var dismiss
    
    @State private var pseudo: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Pseudo *", text: $pseudo)
                        .textInputAutocapitalization(.never)
                    
                    TextField("Prénom", text: $firstName)
                    
                    TextField("Nom", text: $lastName)
                } header: {
                    Text("Informations personnelles")
                } footer: {
                    Text("* Champ obligatoire")
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        saveProfile()
                    }
                    .disabled(pseudo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let existingProfile = session.profile {
                    pseudo = existingProfile.pseudo
                    firstName = existingProfile.firstName ?? ""
                    lastName = existingProfile.lastName ?? ""
                }
            }
        }
    }
    
    private func saveProfile() {
        let trimmedPseudo = pseudo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPseudo.isEmpty else { return }
        
        session.profile = UserProfile(
            pseudo: trimmedPseudo,
            firstName: firstName.isEmpty ? nil : firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.isEmpty ? nil : lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        onboardingStore.completeProfile()
        dismiss()
    }
}

#Preview {
    ProfileOnboardingView()
        .environmentObject(SessionStore())
        .environmentObject(OnboardingStore())
}
