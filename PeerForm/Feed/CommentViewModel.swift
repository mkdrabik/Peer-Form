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
}

