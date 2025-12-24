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

    @Published var caption: String = "Workout! 💪"
    @Published var isPosting = false
    @Published var isUploading = false
    @Published var showAlert = false
    @Published var selectedImage: UIImage?
    @Published var alertMessage: String?
    @Published var postType = "Post"
    @Published var isMentioning = false
    @Published var mentionQuery = ""
    @Published var mentionResults: [Profile] = []
    @Published var mentionedUsernames: Set<String> = []

    var allUsers: [Profile] = []

    func loadUsersForMentions(supabaseManager: SupabaseManager) async {
        do {
            let res = try await supabaseManager.client
                .from("profiles")
                .select()
                .execute()

            self.allUsers = try JSONDecoder().decode([Profile].self, from: res.data)
                var temp = [Profile]()
                for a in allUsers{
                    let avatar_url = try? supabaseManager.client.storage.from("avatars").getPublicURL(path: a.avatar_url ?? "").absoluteString
                    let newProfile = Profile(id: a.id, username: a.username, first_name: a.first_name, last_name: a.last_name, avatar_url: avatar_url)
                    temp.append(newProfile)
                }
                allUsers = temp
        } catch {
            print("❌ Failed loading mention users:", error)
        }
    }

    func attributedCaption() -> AttributedString {
        var attributed = AttributedString(caption)
        let mentionRegex = try! NSRegularExpression(pattern: "@[a-zA-Z0-9_]+")
        let nsString = NSString(string: caption)
        
        let matches = mentionRegex.matches(in: caption, range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            if let range = Range(match.range, in: caption) {
                let mentionRange = attributed.range(of: String(caption[range]))!
                attributed[mentionRange].foregroundColor = .blue
                attributed[mentionRange].font = .body.bold()
            }
        }
        
        return attributed
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
    func insertMention(_ username: String) {
        isMentioning = false
        var words = caption.split(separator: " ")
        if words.isEmpty { return }

        words.removeLast()
        words.append(Substring("@\(username)"))
        caption = words.joined(separator: " ") + " "

        mentionedUsernames.insert(username)
        mentionResults = []
    }


    func filterMentionResults() {
        let q = mentionQuery.lowercased()
        guard !q.isEmpty else { mentionResults = []; return }

        mentionResults = allUsers.filter {
            $0.username.lowercased().contains(q)
        }
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

