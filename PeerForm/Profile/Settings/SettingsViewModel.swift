//
//  SettingsViewModel.swift
//  TWEE
//
//  Created by Mason Drabik on 10/2/25.
//

import SwiftUI
import Foundation
import Supabase
import Combine
import PhotosUI

class SettingsViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem? = nil
    @Published var selectedImage: UIImage? = nil
    @Published var isUploading: Bool = false
    
    func updateAvatar(image: UIImage, supabaseManager: SupabaseManager) async throws {
        do {
            isUploading = true
            let user = try await supabaseManager.client.auth.session.user
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
            
            let newPath = "avatars/\(UUID().uuidString).jpg"
            
            guard let cleanPath = supabaseManager.profile?.avatar_url?
                .replacingOccurrences(of: "avatars/", with: "") else { return }

            try await supabaseManager.client.storage
                .from("avatars")
                .remove(paths: [cleanPath])


                        try await supabaseManager.client.storage
                .from("avatars")
                .upload(newPath, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))
            
            try await supabaseManager.client
                .from("profiles")
                .update(["avatar_url": newPath])
                .eq("id", value: user.id.uuidString)
                .execute()
            
            supabaseManager.profile?.avatar_url = newPath
            try await supabaseManager.fetchAvatarURL()
            isUploading = false
        }catch{
            print("Error \(error)")
        }
        }
    
    func logOut(supabaseManager: SupabaseManager) async throws {
        let id = supabaseManager.profile!.id
        await supabaseManager.deleteFcmToken(id: id)
        try await supabaseManager.client.auth.signOut()
        supabaseManager.profile = nil
    }
}

