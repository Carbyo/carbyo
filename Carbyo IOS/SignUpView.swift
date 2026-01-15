//
//  SignUpView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) var dismiss

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false

    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword &&
        !isLoading
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                Spacer(minLength: 16)

                // Logo
                ZStack {
                    Circle()
                        .fill(CarbyoColors.primarySoft)
                        .frame(width: 72, height: 72)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 32))
                        .foregroundColor(CarbyoColors.primary)
                }
                .padding(.bottom, 4)

                // Header
                VStack(spacing: 6) {
                    Text("Créer un compte")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(CarbyoColors.text)

                    Text("Rejoignez Mon Carbyo en 30 secondes")
                        .font(.subheadline)
                        .foregroundColor(CarbyoColors.muted)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)

                // Carte formulaire
                CarbyoCard {
                    VStack(spacing: 12) {

                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(CarbyoColors.background)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(CarbyoColors.border, lineWidth: 1)
                            )

                        SecureField("Mot de passe", text: $password)
                            .textContentType(.newPassword)
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(CarbyoColors.background)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(CarbyoColors.border, lineWidth: 1)
                            )

                        SecureField("Confirmer le mot de passe", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(CarbyoColors.background)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(CarbyoColors.border, lineWidth: 1)
                            )

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 2)
                        }

                        Button(action: { handleSignUp() }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(
                                            CircularProgressViewStyle(tint: .white)
                                        )
                                } else {
                                    Text("Créer mon compte")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(
                                isFormValid
                                ? CarbyoColors.primary
                                : CarbyoColors.muted.opacity(0.5)
                            )
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || isLoading)
                    }
                    .padding(.vertical, 2)
                }
                .padding(.horizontal, 16)

                // Lien retour
                Button(action: { dismiss() }) {
                    Text("J'ai déjà un compte")
                        .font(.subheadline)
                        .foregroundColor(CarbyoColors.primary)
                }
                .padding(.top, 4)

                Spacer(minLength: 16)
            }
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .carbyoScreen()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handleSignUp() {
        errorMessage = ""

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "L'email est requis"
            return
        }

        guard trimmedEmail.contains("@") else {
            errorMessage = "Veuillez entrer une adresse email valide"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Le mot de passe doit contenir au moins 6 caractères"
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Les mots de passe ne correspondent pas"
            return
        }

        isLoading = true

        Task {
            do {
                try await session.signUp(
                    email: trimmedEmail,
                    password: password
                )
            } catch let authError as AuthError {
                await MainActor.run {
                    errorMessage = authError.errorDescription
                        ?? "Une erreur est survenue"
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
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(SessionStore())
    }
}
