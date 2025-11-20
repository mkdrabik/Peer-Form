//
//  LoginViewModel.swift
//  TWI
//
//  Created by Mason Drabik on 9/28/25.
//

import SwiftUI
import Foundation
import Supabase
import Combine

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var message: String? = nil
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var showSignUp: Bool = false

    
    func login(supabaseManager: SupabaseManager) {
        Task {
            isLoading = true
            do {
                try await supabaseManager.client.auth.signIn(email: email, password: password)
                try await supabaseManager.fetchProfile()
            } catch {
                message = nil
                errorMessage = " \(error.localizedDescription)"
                print(error)
            }
            isLoading = false
        }
    }
}
