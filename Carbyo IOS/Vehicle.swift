//
//  Vehicle.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import Foundation

struct Vehicle: Identifiable, Codable, Hashable {
    var id: UUID
    var label: String
    var energy: String
    var v7Co2Gkm: Double?
    var photoData: Data?
    
    init(id: UUID = UUID(), label: String, energy: String, v7Co2Gkm: Double? = nil, photoData: Data? = nil) {
        self.id = id
        self.label = label
        self.energy = energy
        self.v7Co2Gkm = v7Co2Gkm
        self.photoData = photoData
    }
    
    var displayTitle: String {
        "\(label) - \(energy)"
    }
}
