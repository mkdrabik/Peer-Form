//
//  SignUpViewModel.swift
//  TWI
//
//  Created by Mason Drabik on 9/28/25.
//

import Foundation
import Supabase
import Combine
import SwiftUI

class SignUpViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var errorMessage: String?
    @Published var isLoading = false

    func signUp(supabaseManager: SupabaseManager, showSignUp: Binding<Bool>, message: Binding<String?>) {
        Task {
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match"
                return
            }

            isLoading = true
            errorMessage = nil

            do {
                struct Profile: Decodable { let id: UUID }
                
                let emailExisiting: [Profile] = try await supabaseManager.client
                    .from("profiles")
                    .select("id")
                    .eq("email", value: email)
                    .execute()
                    .value

                if !emailExisiting.isEmpty {
                    errorMessage = "Email is already in use please log in."
                    isLoading = false
                    return
                }


                try await supabaseManager.client.auth.signUp(
                    email: email,
                    password: password,
                    redirectTo: URL(string: "twee://verify")!
                )
                message.wrappedValue  = "Check your inbox to confirm your email before logging in."
                showSignUp.wrappedValue = false
            } catch {
                errorMessage = error.localizedDescription
                print("ERROR: \(error)")
            }
            isLoading = false
        }
    }
}
