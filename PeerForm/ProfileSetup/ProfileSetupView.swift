//
//  UsernameView.swift
//  TWI
//
//  Created by Mason Drabik on 9/28/25.
//

import SwiftUI
import PhotosUI
import Supabase

struct ProfileSetupView: View {
    @StateObject var vm = ProfileSetupViewModel()
    @EnvironmentObject var supabaseManager: SupabaseManager
    
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 20) {
                
                ZStack {
                    if let selectedImage = vm.selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            )
                    }
                }
                PhotosPicker("Choose Photo", selection: $vm.selectedItem, matching: .images)
                    .onChange(of: vm.selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                vm.selectedImage = uiImage
                            }
                        }
                    }
                
                TextField("Enter username", text: $vm.username)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                
                TextField("Enter First Name", text: $vm.firstName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                
                TextField("Enter Last Name", text: $vm.lastName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                
                if let message = vm.message {
                    Text(message)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                
                Button(action: {vm.saveProfile(supabaseManager: supabaseManager)}) {
                    if vm.isUploading {
                        ProgressView()
                    } else {
                        Text("Save Profile")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(vm.username.isEmpty || vm.selectedImage == nil ? Color.gray : Color.blue)
                            .cornerRadius(10)
                    }
                }
                .disabled(vm.username.isEmpty || vm.selectedImage == nil)
                .padding(.horizontal)
                Button("Log Out", role: .destructive) {
                    Task {
                        do {
                            try await vm.logOut(supabaseManager: supabaseManager)
                        } catch {
                            print("Logout failed: \(error.localizedDescription)")
                        }
                    }
                }
                Spacer()
            }
            .navigationDestination(isPresented: $vm.profileSaved) {
                HomeView()
            }
            .padding()
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(SupabaseManager.previewInstance)
}


