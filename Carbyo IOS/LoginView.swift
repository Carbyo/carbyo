//
//  LoginView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showCGU = false
    @State private var showPrivacy = false
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var showLoginOverlay: Bool = false
    @State private var overlayPhase: LoginLoadingOverlay.Phase = .loading(step: 0)
    @State private var overlayIndex: Int = 0
    
    private let overlaySteps: [String] = [
        "Connexion sécurisée à votre espace…",
        "Récupération de vos émissions…",
        "Compilation des informations…",
        "Finalisation de l'accès…"
    ]

    private var isCompact: Bool { verticalSizeClass == .compact }
    private var isAccessibilityText: Bool { dynamicTypeSize.isAccessibilitySize }

    private var tight: Bool {
        isCompact || isAccessibilityText
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Fond plein écran pour éviter les bandes noires
                CarbyoColors.background
                    .ignoresSafeArea()
                
                // Overlay de chargement
                if showLoginOverlay {
                    LoginLoadingOverlay(steps: overlaySteps, phase: $overlayPhase, currentIndex: $overlayIndex)
                        .transition(.opacity)
                        .zIndex(999)
                }
                
                GeometryReader { geo in
                    ScrollView {
                        VStack(alignment: .center, spacing: 10) {
                    // ===== HEADER =====
                    VStack(spacing: tight ? 5 : 7) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: tight ? 24 : 25, weight: .medium))
                            .foregroundColor(CarbyoColors.primary)
                            .padding(.bottom, 4)

                        VStack(spacing: tight ? 2 : 3) {
                            Text("Carbyo")
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(CarbyoColors.text)

                            Text("Connexion")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(CarbyoColors.text)

                            Text("Accéder à mon Carbyo")
                                .font(.caption)
                                .foregroundColor(CarbyoColors.muted)
                                .opacity(0.75)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, tight ? 3 : 6)

                    // ===== CARD (Formulaire) =====
                    CarbyoCard {
                        VStack(spacing: tight ? 8 : 10) {

                            TextField("Email", text: $email)
                                .font(.subheadline)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .padding(.horizontal, 12)
                                .frame(height: 40)
                                .background(CarbyoColors.background)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(CarbyoColors.border, lineWidth: 1)
                                )

                            SecureField("Mot de passe", text: $password)
                                .font(.subheadline)
                                .textContentType(.password)
                                .padding(.horizontal, 12)
                                .frame(height: 40)
                                .background(CarbyoColors.background)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(CarbyoColors.border, lineWidth: 1)
                                )

                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.9)
                                    .padding(.top, 2)
                            }

                            Button {
                                Task { await handleLogin() }
                            } label: {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .tint(.white)
                                            .scaleEffect(0.9)
                                    }
                                    Text(isLoading ? "Connexion..." : "Se connecter")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(isLoginFormValid ? CarbyoColors.primary : CarbyoColors.muted.opacity(0.5))
                                .cornerRadius(10)
                            }
                            .disabled(!isLoginFormValid || isLoading)

                            NavigationLink {
                                SignUpView()
                                    .environmentObject(session)
                            } label: {
                                Text("Créer un compte")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(CarbyoColors.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(CarbyoColors.primary, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, tight ? 10 : 12)
                        .padding(.horizontal, 16)
                    }
                    .padding(.horizontal, 16)

                    // ===== FOOTER =====
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Text("En continuant, vous acceptez les")
                                .foregroundColor(CarbyoColors.muted)
                            Button("CGU") { showCGU = true }
                                .font(.caption2)
                                .foregroundColor(CarbyoColors.primary)
                                .underline()
                            Text("et la")
                                .foregroundColor(CarbyoColors.muted)
                            Button("politique de confidentialité") { showPrivacy = true }
                                .font(.caption2)
                                .foregroundColor(CarbyoColors.primary)
                                .underline()
                            Text(".")
                                .foregroundColor(CarbyoColors.muted)
                        }
                        .font(.caption2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .padding(.horizontal, 20)
                        .opacity(0.65)

                        Text("© Carbyo")
                            .font(.caption2)
                            .foregroundColor(CarbyoColors.muted.opacity(0.6))
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                        }
                        .padding(.top, tight ? 6 : 10)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height, alignment: .top)
                        .contentShape(Rectangle())
                        .onTapGesture { hideKeyboard() }
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .carbyoScreen()
            .alert("CGU", isPresented: $showCGU) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Bientôt disponible")
            }
            .alert("Politique de confidentialité", isPresented: $showPrivacy) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Bientôt disponible")
            }
        }
    }

    private var isLoginFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") &&
        !password.isEmpty &&
        !isLoading
    }

    private func handleLogin() async {
        errorMessage = ""
        isLoading = true
        showLoginOverlay = true
        overlayIndex = 0
        overlayPhase = .loading(step: 0)

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await session.login(email: trimmedEmail, password: password)
            
            // Succès : fast-forward jusqu'à la dernière étape si nécessaire
            if overlayIndex < overlaySteps.count - 1 {
                for i in (overlayIndex + 1)...(overlaySteps.count - 1) {
                    await MainActor.run {
                        overlayIndex = i
                        overlayPhase = .loading(step: i)
                    }
                    try? await Task.sleep(nanoseconds: 280_000_000) // 0.28s
                }
            }
            
            // Afficher le checkmark
            await MainActor.run {
                overlayPhase = .success
            }
            
            // Attendre 0.55s avant le fade-out
            try? await Task.sleep(nanoseconds: 550_000_000)
            
            // Lancer le fade-out
            await MainActor.run {
                overlayPhase = .fadeOut
            }
            
            // Attendre la fin de l'animation (0.35s)
            try? await Task.sleep(nanoseconds: 350_000_000)
            
            // Fermer l'overlay
            await MainActor.run {
                showLoginOverlay = false
            }
        } catch let authError as AuthError {
            // Erreur : fermer l'overlay immédiatement
            await MainActor.run {
                showLoginOverlay = false
                errorMessage = authError.errorDescription ?? "Une erreur est survenue"
            }
        } catch {
            // Erreur : fermer l'overlay immédiatement
            await MainActor.run {
                showLoginOverlay = false
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    private func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionStore())
}
