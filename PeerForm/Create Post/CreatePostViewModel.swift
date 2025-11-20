//
//  CreatePostViewModel.swift
//  TWEE
//
//  Created by Mason Drabik on 10/10/25.
//

import Foundation
import Supabase
import SwiftUI
import Combine

@MainActor
final class CreatePostViewModel: ObservableObject {
    @Published var caption: String = "Leg Day! 🏋️‍♂️💪🏼"
    @Published var isPosting = false
    @Published var errorMessage: String?
    @Published var isUploading: Bool = false
    @Published var showAlert = false
    @Published var selectedImage: UIImage?
    @Published var alertMessage: String? = nil
    @Published var postType = "Post"

    func createPost(supabaseManager: SupabaseManager, imagePath: String, type: String) async {
        guard let userId = supabaseManager.profile?.id else { return }
       
        isPosting = true
        defer { isPosting = false }

        do {
            let newPost: PostInsert = .init(
                user_id: userId,
                image_path: imagePath,
                caption: caption,
                type: type
            )

            try await supabaseManager.client
                .from("posts")
                .insert(newPost)
                .execute()

            caption = ""
        } catch {
            errorMessage = "Failed to upload post: \(error.localizedDescription)"
            print("❌ Error creating post:", error)
        }
    }
    
    
    
    func uploadAndCreatePost(supabaseManager: SupabaseManager) async {
        guard let image = selectedImage else { return }
        guard let _ = supabaseManager.profile else {
            print("User is not logged in!")
            return
        }

        do {
            isUploading = true
            let data = image.jpegData(compressionQuality: 0.8)!
            let path = "post-images/\(UUID().uuidString).jpg"
            try await supabaseManager.client.storage
                .from("post-images")
                .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
            var type = ""
            if postType == "Achievement"{
                type = "achievement"
                supabaseManager.didPreloadAchievements = false
            } else {
                type = "post"
                supabaseManager.didPreloadPosts = false
            }
            await createPost(supabaseManager: supabaseManager, imagePath: path, type: type)

            isUploading = false
            selectedImage = nil
            caption = ""
            showAlert = true
            await supabaseManager.refreshWorkoutStats()
        } catch {
            isUploading = false
            print("❌ Upload error:", error)
        }
    }
}
struct PostInsert: Encodable {
    let user_id: UUID
    let image_path: String
    let caption: String
    let type: String
}
