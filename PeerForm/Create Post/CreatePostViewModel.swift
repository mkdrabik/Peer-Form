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

    @Published var caption: String = ""
    @Published var isPosting = false
    @Published var isUploading = false
    @Published var showAlert = false
    @Published var selectedImage: UIImage?
    @Published var alertMessage: String?
    @Published var postType = "Post"

    // ----- Mentions -----
    @Published var isMentioning = false
    @Published var mentionQuery = ""
    @Published var mentionResults: [Profile] = []

    var allUsers: [Profile] = []

    func loadUsersForMentions(supabaseManager: SupabaseManager) async {
        do {
            let res = try await supabaseManager.client
                .from("profiles")
                .select()
                .execute()

            self.allUsers = try JSONDecoder().decode([Profile].self, from: res.data)
        } catch {
            print("❌ Failed loading mention users:", error)
        }
    }

    func checkForMentionTrigger() {
        let words = caption.split(separator: " ")
        guard let last = words.last else { return }

        if last.hasPrefix("@") {
            isMentioning = true
            mentionQuery = String(last.dropFirst())
            filterMentionResults()
        } else {
            isMentioning = false
        }
    }

    func filterMentionResults() {
        let q = mentionQuery.lowercased()
        guard !q.isEmpty else { mentionResults = []; return }

        mentionResults = allUsers.filter {
            $0.username.lowercased().contains(q)
        }
    }

    func insertMention(_ username: String) {
        var words = caption.split(separator: " ")
        if words.isEmpty { return }

        words.removeLast()
        words.append(Substring("@\(username)"))

        caption = words.joined(separator: " ") + " "
        isMentioning = false
    }


    func createPost(supabaseManager: SupabaseManager, imagePath: String, type: String) async {
        guard let userId = supabaseManager.profile?.id else { return }

        isPosting = true
        defer { isPosting = false }

        do {
            let newPost = PostInsert(
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
            print("❌ Error creating post:", error)
        }
    }

    func uploadAndCreatePost(supabaseManager: SupabaseManager) async {
        guard let image = selectedImage else { return }

        do {
            isUploading = true

            let data = image.jpegData(compressionQuality: 0.8)!
            let path = "post-images/\(UUID().uuidString).jpg"

            try await supabaseManager.client.storage
                .from("post-images")
                .upload(
                    path,
                    data: data,
                    options: FileOptions(contentType: "image/jpeg", upsert: true)
                )

            let type = (postType == "Achievement") ? "achievement" : "post"

            await createPost(
                supabaseManager: supabaseManager,
                imagePath: path,
                type: type
            )

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


