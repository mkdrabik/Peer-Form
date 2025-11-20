//
//  ProfileViewModel.swift
//  PeerForm
//
//  Created by Mason Drabik on 10/18/25.
//

import Supabase
import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var achievements: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var days = 30
    @Published var postToDelete: Post?
    @Published var showDeleteAlert = false
    
    private var hasLoadedPosts = false
    private var hasLoadedAchievements = false

    func fetchUserPosts(
        client: SupabaseClient,
        supabaseManager: SupabaseManager,
        userId: UUID,
        type: String
    ) async {
        if ((type == "post" && hasLoadedPosts && supabaseManager.didPreloadPosts) || (type == "achievement" && hasLoadedAchievements && supabaseManager.didPreloadAchievements)) {
            print("⚙️ Skipping \(type) fetch — already loaded")
            return
        }

        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await client
                .from("posts")
                .select()
                .eq("user_id", value: userId)
                .eq("type", value: type)
                .order("created_at", ascending: false)
                .execute()

            let data = response.data
            var fetched = try JSONDecoder().decode([Post].self, from: data)
            var updatedPosts: [Post] = []
            for index in fetched.indices {
                let p = fetched[index]
                let url = try client.storage.from("post-images").getPublicURL(path: p.image_path)

                var commentCount = 0
                var likeCount = 0
                var isLiked = false

                do {
                    let commentCountResponse = try await client
                        .from("comments")
                        .select("*", count: .exact)
                        .eq("post_id", value: p.id)
                        .execute()
                    commentCount = commentCountResponse.count ?? 0

                    let likeCountResponse = try await client
                        .from("likes")
                        .select("*", count: .exact)
                        .eq("post_id", value: p.id)
                        .execute()
                    likeCount = likeCountResponse.count ?? 0

                    if let currentUser = supabaseManager.profile?.id {
                        let likedResponse = try await client
                            .from("likes")
                            .select("id")
                            .eq("post_id", value: p.id)
                            .eq("user_id", value: currentUser)
                            .limit(1)
                            .execute()
                        let likedRows = try JSONDecoder().decode([LikeRow].self, from: likedResponse.data)
                        isLiked = !likedRows.isEmpty
                    }
                } catch {
                    print("⚠️ Error loading metadata for post \(p.id):", error)
                }

                let post = Post(
                    id: p.id,
                    user_id: p.user_id,
                    image_path: url.absoluteString,
                    caption: p.caption,
                    created_at: p.created_at,
                    type: p.type,
                    commentCount: commentCount,
                    likeCount: likeCount,
                    isLikedByCurrentUser: isLiked
                )
                updatedPosts.append(post)
            }

            if type == "achievement" {
                self.achievements = updatedPosts
                hasLoadedAchievements = true
                supabaseManager.didPreloadAchievements = true
    
            } else {
                self.posts = updatedPosts
                hasLoadedPosts = true
                supabaseManager.didPreloadPosts = true
            }

            print("✅ Loaded \(updatedPosts.count) \(type)s successfully")
        } catch {
            errorMessage = "Failed to fetch \(type)s: \(error.localizedDescription)"
            print("❌ \(errorMessage ?? "")")
        }
    }

    func deletePost(supabaseManager: SupabaseManager, postId: UUID) async {
        do {
            try await supabaseManager.client
                .from("posts")
                .delete()
                .eq("id", value: postId)
                .execute()

            posts.removeAll { $0.id == postId }
            achievements.removeAll { $0.id == postId }

            hasLoadedPosts = false
            hasLoadedAchievements = false

            print("✅ Post deleted — cache cleared")
            await supabaseManager.refreshWorkoutStats()
        } catch {
            print("❌ Failed to delete post:", error)
        }
    }

    func daysInCurrentMonth() {
        let calendar = Calendar.current
        let date = Date()
        guard let range = calendar.range(of: .day, in: .month, for: date) else {
            days = 30
            return
        }
        days = range.count
    }
}
