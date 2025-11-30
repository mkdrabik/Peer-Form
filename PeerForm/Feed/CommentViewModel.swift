//
//  Comment.swift
//  PeerForm
//
//  Created by Mason Drabik on 10/22/25.
//
import SwiftUI
import Combine
import Supabase

struct Comment: Decodable, Identifiable {
    let id: UUID
    let post_id: UUID
    let user_id: UUID
    let content: String
    let created_at: String
    var profiles: Profile?
}

@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var newComment: String = ""
    @Published var isMentioning = false
    @Published var mentionQuery = ""
    @Published var mentionResults: [Profile] = []
    var allUsers: [Profile] = []

    func fetchComments(for postId: UUID, supabase: SupabaseClient) async {
        do {
            let response = try await supabase
                .from("comments")
                .select("*, profiles(id, username, avatar_url, first_name, last_name)")
                .eq("post_id", value: postId)
                .order("created_at", ascending: true)
                .execute()
            
            let data = response.data
            let decoded = try JSONDecoder().decode([Comment].self, from: data)
            self.comments = decoded
            var updatedComments = [Comment]()
            for c in comments{
                var comment = c
                comment.profiles?.avatar_url = try? supabase.storage.from("avatars").getPublicURL(path: c.profiles?.avatar_url ?? "").absoluteString
                updatedComments.append(comment)
            }
            self.comments = updatedComments

        } catch {
            print("❌ Error fetching comments:", error)
        }
    }

    func addComment(for postId: UUID, userId: UUID, supabase: SupabaseClient) async {
        guard !newComment.isEmpty else { return }
        do {
            try await supabase
                .from("comments")
                .insert([
                    "post_id": postId.uuidString,
                    "user_id": userId.uuidString,
                    "content": newComment
                ])
                .execute()
            newComment = ""
            await fetchComments(for: postId, supabase: supabase)
        } catch {
            print("❌ Error adding comment:", error)
        }
    }
    
    func deleteComment(_ commentId: UUID, supabase: SupabaseClient) async {
            do {
                try await supabase
                    .from("comments")
                    .delete()
                    .eq("id", value: commentId)
                    .execute()
                comments.removeAll { $0.id == commentId }
            } catch {
                print("❌ Error deleting comment:", error)
            }
    }
    
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
                print("❌ Failed to load users:", error)
            }
        }

        func checkForMentionTrigger() {
            let words = newComment.split(separator: " ")
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

            mentionResults = allUsers.filter { profile in
                profile.username.lowercased().contains(q)
            }
        }

        func insertMention(_ username: String) {
            isMentioning = false

            var words = newComment.split(separator: " ")
            if !words.isEmpty {
                words.removeLast()
            }

            words.append(Substring("@\(username)"))
            newComment = words.joined(separator: " ") + " "
        }

}

