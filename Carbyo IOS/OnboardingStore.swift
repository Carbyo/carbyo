//
//  OnboardingStore.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import Foundation
import Combine

@MainActor
final class OnboardingStore: ObservableObject {
    @Published var hasProfile: Bool = false
    @Published var hasHomeAddress: Bool = false
    @Published var homeAddress: Address? {
        didSet {
            hasHomeAddress = homeAddress != nil
            saveAddresses()
        }
    }
    @Published var hasWorkAddress: Bool = false
    @Published var workAddress: Address? {
        didSet {
            hasWorkAddress = workAddress != nil
            saveAddresses()
        }
    }
    @Published var hasVehicle: Bool = false
    @Published var vehicle: Vehicle? {
        didSet {
            hasVehicle = vehicle != nil
            saveVehicle()
        }
    }
    
    private let homeAddressKey = "homeAddress"
    private let workAddressKey = "workAddress"
    private let vehicleKey = "vehicle"
    
    var isComplete: Bool {
        hasProfile && hasHomeAddress && hasWorkAddress && hasVehicle
    }
    
    init() {
        loadAddresses()
        loadVehicle()
    }
    
    func completeProfile() {
        hasProfile = true
    }
    
    func setHomeAddress(_ address: Address) {
        homeAddress = address
    }
    
    func setWorkAddress(_ address: Address) {
        workAddress = address
    }
    
    func setVehicle(_ vehicle: Vehicle) {
        self.vehicle = vehicle
    }
    
    private func saveAddresses() {
        if let homeAddress = homeAddress,
           let encoded = try? JSONEncoder().encode(homeAddress) {
            UserDefaults.standard.set(encoded, forKey: homeAddressKey)
        }
        
        if let workAddress = workAddress,
           let encoded = try? JSONEncoder().encode(workAddress) {
            UserDefaults.standard.set(encoded, forKey: workAddressKey)
        }
    }
    
    private func loadAddresses() {
        if let data = UserDefaults.standard.data(forKey: homeAddressKey),
           let decoded = try? JSONDecoder().decode(Address.self, from: data) {
            homeAddress = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: workAddressKey),
           let decoded = try? JSONDecoder().decode(Address.self, from: data) {
            workAddress = decoded
        }
    }
    
    private func saveVehicle() {
        if let vehicle = vehicle,
           let encoded = try? JSONEncoder().encode(vehicle) {
            UserDefaults.standard.set(encoded, forKey: vehicleKey)
        }
    }
    
    private func loadVehicle() {
        if let data = UserDefaults.standard.data(forKey: vehicleKey),
           let decoded = try? JSONDecoder().decode(Vehicle.self, from: data) {
            vehicle = decoded
        }
    }
}
