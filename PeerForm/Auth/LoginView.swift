//
//  LoginView.swift
//  TWI
//
//  Created by Mason Drabik on 9/25/25.
//
import SwiftUI
import Supabase

struct LoginView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject private var vm = LoginViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome Back")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $vm.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            SecureField("Password", text: $vm.password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            if let errorMessage = vm.errorMessage {
                if vm.message == nil {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            if let message = vm.message {
                Text(message)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            }

            Button(action: { vm.login(supabaseManager: supabaseManager) }) {
                if vm.isLoading {
                    ProgressView()
                } else {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            Button("Don't have an account? Sign Up") {
                vm.showSignUp = true
            }
            .padding(.top)

        }
        .padding()
        .sheet(isPresented: $vm.showSignUp) {
            SignUpView(showSignUp: $vm.showSignUp, message: $vm.message)
        }
        .onOpenURL { url in
                            if url.scheme == "twee", url.host == "verify" {
                                vm.message = "Email verified, please login!"
            }
        }
    }
}

#Preview {
    LoginView()
}
