//
//  LoginLoadingOverlay.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct LoginLoadingOverlay: View {
    enum Phase: Equatable {
        case loading(step: Int)
        case success
        case fadeOut
    }

    let steps: [String]
    @Binding var phase: Phase
    @Binding var currentIndex: Int

    @State private var timer: Timer?
    @State private var opacity: Double = 1.0
    @State private var isTimerActive: Bool = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 14) {
                if case .success = phase {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(CarbyoColors.primary)
                        .transition(.scale.combined(with: .opacity))

                    Text("Accès confirmé")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(CarbyoColors.text)
                        .transition(.opacity)
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.15)
                        .tint(CarbyoColors.primary)
                        .transition(.opacity)
                }

                Text(stepText)
                    .font(.footnote)
                    .foregroundColor(CarbyoColors.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .padding(.horizontal, 28)
                    .id(currentIndex)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .opacity(opacity)
        .onAppear {
            opacity = 1.0
            startRotatingSteps()
        }
        .onChange(of: phase) { oldPhase, newPhase in
            switch newPhase {
            case .loading(let step):
                opacity = 1.0
                // Si le step correspond à currentIndex ET que le timer est actif, c'est le timer qui a changé
                // Sinon, c'est un changement externe (fast-forward), on arrête le timer
                if step == currentIndex && isTimerActive {
                    // Le timer a fait son travail, on continue
                } else {
                    // Changement externe : arrêter le timer et mettre à jour currentIndex
                    stopRotatingSteps()
                    currentIndex = step
                }
            case .success:
                stopRotatingSteps()
                // garder le dernier texte, ou un texte fixe, au choix
            case .fadeOut:
                stopRotatingSteps()
                withAnimation(.easeInOut(duration: 0.35)) {
                    opacity = 0.0
                }
            }
        }
        .onDisappear {
            stopRotatingSteps()
        }
        // bloque les interactions dessous
        .allowsHitTesting(true)
    }

    private var stepText: String {
        let total = max(steps.count, 1)
        let current = min(currentIndex, total - 1)
        let label = steps.isEmpty ? "Connexion…" : steps[current]
        let stepNumber = min(current + 1, total)
        return "\(stepNumber)/\(total)  \(label)"
    }

    private func startRotatingSteps() {
        stopRotatingSteps()
        guard steps.count > 1 else { return }

        isTimerActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.25, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                currentIndex = (currentIndex + 1) % steps.count
                phase = .loading(step: currentIndex)
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopRotatingSteps() {
        timer?.invalidate()
        timer = nil
        isTimerActive = false
    }
}
