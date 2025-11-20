//
//  ProfileSetupViewModel.swift
//  TWI
//
//  Created by Mason Drabik on 9/28/25.
//

import SwiftUI
import Foundation
import Supabase
import Combine
import PhotosUI

class ProfileSetupViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var selectedItem: PhotosPickerItem? = nil
    @Published var selectedImage: UIImage? = nil
    @Published var isUploading: Bool = false
    @Published var profileSaved: Bool = false
    @Published var message: String? = nil
    
    func logOut(supabaseManager: SupabaseManager) async throws {
        try await supabaseManager.client.auth.signOut()
        supabaseManager.profile = nil
    }
    
    
    func saveProfile(supabaseManager: SupabaseManager) {
        guard let selectedImage = selectedImage else { return }
        isUploading = true
        
        Task {
            do {
                guard let imageData = selectedImage.jpegData(compressionQuality: 0.8) else { return }
                
                let user = try await supabaseManager.client.auth.session.user
                
                let checkResponse = try await supabaseManager.client
                    .from("profiles")
                    .select("id")
                    .eq("username", value: username)
                    .execute()
                
                let data = checkResponse.data
                if let results = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   !results.isEmpty {
                    message = "Username is already taken"
                    isUploading = false
                    return
                }
                let path = "avatars/\(user.id).jpg"
              
                try await supabaseManager.client.storage.from("avatars").upload(
                    path,
                    data: imageData,
                    options: FileOptions(contentType: "image/jpeg", upsert: true)
                )
                
                let userEmail = try await supabaseManager.client.auth.session.user.email!
                
                let profileRow = ProfileInsert(
                     id: user.id.uuidString,
                     username: username,
                     first_name: firstName,
                     last_name: lastName,
                     avatar_url: path,
                     email: userEmail,
                 )
                 
                try await supabaseManager.client
                     .from("profiles")
                     .insert(profileRow)
                     .execute()

                try await supabaseManager.fetchProfile()
                print("✅ Profile saved successfully")
                isUploading = false
                profileSaved = true
            } catch {
                print("❌ Upload failed: \(error)")
                isUploading = false
            }
        }
    }

}

struct ProfileInsert: Encodable {
    let id: String
    let username: String
    let first_name: String
    let last_name: String
    let avatar_url: String?
    let email: String
}


