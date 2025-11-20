//
//  SignUpView.swift
//  TWI
//
//  Created by Mason Drabik on 9/25/25.
//

 import SwiftUI
 import PhotosUI
 import Supabase

 struct SignUpView: View {
     @Binding var showSignUp: Bool
     @Binding var message: String?
     @StateObject var vm = SignUpViewModel()
     @EnvironmentObject var supabaseManager: SupabaseManager


     var body: some View {
         ScrollView {
             VStack(spacing: 20) {
                 Text("Create Account")
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

                 SecureField("Confirm Password", text: $vm.confirmPassword)
                     .padding()
                     .background(Color(.secondarySystemBackground))
                     .cornerRadius(8)

                 if let errorMessage = vm.errorMessage {
                     Text(errorMessage)
                         .foregroundColor(.red)
                         .multilineTextAlignment(.center)
                 }
                 Button(action: {vm.signUp(supabaseManager: supabaseManager, showSignUp: $showSignUp, message: $message)}) {
                     if vm.isLoading {
                         ProgressView()
                     } else {
                         Text("Sign Up")
                             .frame(maxWidth: .infinity)
                             .padding()
                             .background(Color.green)
                             .foregroundColor(.white)
                             .cornerRadius(8)
                     }
                 }
             }
             .padding()
         }
     }

     
 }
