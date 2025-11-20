//
//  SettingsView.swift
//  TWEE
//
//  Created by Mason Drabik on 10/2/25.
//

import SwiftUI
import Supabase
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject var vm: SettingsViewModel = SettingsViewModel()
    @State private var showNotificationsAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Profile Settings")) {
                PhotosPicker("Change Profile Picture", selection: $vm.selectedItem, matching: .images)
                    .onChange(of: vm.selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                vm.selectedImage = uiImage
                                try await vm.updateAvatar(image: vm.selectedImage!, supabaseManager: supabaseManager)
                            }
                        }
                    }
            }
            Section(header: Text("Notifications")) {
                Button("Toggle Notifications") {
                    showNotificationsAlert = true
                }
                .alert("Go to your settings and turn them off. If you are lazy just say it.", isPresented: $showNotificationsAlert) {
                    Button("OK", role: .cancel) {}
                }
            }
            Section(header: Text("Log Out")) {
                Button("Log Out", role: .destructive) {
                    Task {
                        do {
                            try await vm.logOut(supabaseManager: supabaseManager)
                        } catch {
                            print("Logout failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        VStack{
            if vm.isUploading {
                ProgressView()
                Text("Uploading")
            }
        }
        .padding(.bottom, 100)
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
        .environmentObject(SupabaseManager.previewInstance)
}
