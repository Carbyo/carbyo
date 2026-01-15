//
//  PendingEnterpriseView.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

struct PendingEnterpriseView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var enterpriseStore: EnterpriseStore
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)
                    
                    // Logo placeholder
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(CarbyoColors.primarySoft)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 36))
                                .foregroundColor(CarbyoColors.primary)
                        }
                    }
                    .padding(.bottom, 12)
                    
                    // Header
                    VStack(spacing: 8) {
                        Text("Invitation")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(CarbyoColors.text)
                        
                        Text("Vous avez été invité par une entreprise")
                            .font(.subheadline)
                            .foregroundColor(CarbyoColors.muted)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 16)
                    
                    // Carte centrale avec boutons
                    CarbyoCard {
                        VStack(spacing: 16) {
                            Button(action: {
                                session.invitationStatus = .accepted
                                enterpriseStore.accept()
                            }) {
                                Text("Accepter")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(CarbyoColors.primary)
                                    .cornerRadius(14)
                            }
                            
                            Button(action: {
                                session.invitationStatus = .refused
                                enterpriseStore.refuse()
                            }) {
                                Text("Refuser")
                                    .font(.headline)
                                    .foregroundColor(CarbyoColors.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(CarbyoColors.primary, lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical, 12)
            }
            .carbyoScreen()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PendingEnterpriseView()
        .environmentObject(SessionStore())
        .environmentObject(EnterpriseStore())
}
