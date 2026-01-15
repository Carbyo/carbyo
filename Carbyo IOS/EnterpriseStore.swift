//
//  EnterpriseStore.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import Foundation
import Combine

enum EnterpriseStatus {
    case none
    case invited
    case member
}

@MainActor
final class EnterpriseStore: ObservableObject {
    @Published var status: EnterpriseStatus = .invited
    
    func accept() {
        status = .member
    }
    
    func refuse() {
        status = .none
    }
}
