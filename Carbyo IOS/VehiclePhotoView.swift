//
//  VehiclePhotoView.swift
//  Carbyo IOS
//
//  Created for vehicle photo display from Supabase Storage
//

import SwiftUI

struct VehiclePhotoView: View {
    let photoUrl: String?
    let vehiclesService: VehiclesService
    @State private var resolvedURL: URL?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let url = resolvedURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "car")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    @unknown default:
                        Image(systemName: "car")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    }
                }
            } else {
                Image(systemName: "car")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
            }
        }
        .task {
            if let photoUrl = photoUrl {
                isLoading = true
                resolvedURL = await vehiclesService.resolvePhotoURL(photoUrl)
                isLoading = false
            }
        }
    }
}
