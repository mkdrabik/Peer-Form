//
//  AchievementViewModel.swift
//  PeerForm
//
//  Created by Mason Drabik on 11/3/25.
//

import SwiftUI
import Supabase
import Combine

@MainActor
final class AchievementsViewModel: ObservableObject {
    @Published var achievements: [Post] = []
    @Published var isLoading = false

    func fetchPosts(supabaseManager: SupabaseManager) async {
        let client = supabaseManager.client

        do {
            let response = try await client
                .from("posts")
                .select("""
                    id,
                    user_id,
                    image_path,
                    caption,
                    created_at,
                    profiles ( id, username, avatar_url, first_name, last_name )
                """)
                .eq("type", value: "achievement")
                .order("created_at", ascending: false)
                .execute()

            var fetchedPosts = try JSONDecoder().decode([Post].self, from: response.data)

            
            await withTaskGroup(of: Void.self) { group in
                for index in fetchedPosts.indices {
                    group.addTask {
                        let post = fetchedPosts[index]
                        
                        do {
                            let commentCountResponse = try await client
                                .from("comments")
                                .select("*", count: .exact)
                                .eq("post_id", value: post.id)
                                .execute()
                            fetchedPosts[index].commentCount = commentCountResponse.count ?? 0
                        } catch {
                            print("❌ Error fetching comment count:", error)
                            fetchedPosts[index].commentCount = 0
                        }
                        do {
                                            let likeCountResponse = try await client
                                                .from("likes")
                                                .select("*", count: .exact)
                                                .eq("post_id", value: post.id)
                                                .execute()
                                            fetchedPosts[index].likeCount = likeCountResponse.count ?? 0
                                        } catch {
                                            fetchedPosts[index].likeCount = 0
                                        }
                        
                        if let currentUser = await supabaseManager.profile?.id {
                            do {
                                let likedResponse = try await client
                                    .from("likes")
                                    .select("id")
                                    .eq("post_id", value: post.id)
                                    .eq("user_id", value: currentUser)
                                    .limit(1)
                                    .execute()
                                let likedRows = try JSONDecoder().decode([LikeRow].self, from: likedResponse.data)
                                fetchedPosts[index].isLikedByCurrentUser = !likedRows.isEmpty
                            } catch {
                                print("⚠️ Error checking like status:", error)
                                fetchedPosts[index].isLikedByCurrentUser = false

                            }
                        }

                        
                        if !post.image_path.isEmpty {
                            fetchedPosts[index].signedImageURL = try? supabaseManager.client.storage.from("post-images").getPublicURL(path: post.image_path)
//                            fetchedPosts[index].signedImageURL = try? await client.storage
//                                .from("post-images")
//                                .createSignedURL(path: post.image_path, expiresIn: 3600)
                        }
                        if let avatarPath = post.profiles?.avatar_url {
                            fetchedPosts[index].signedAvatarURL = try? supabaseManager.client.storage.from("avatars").getPublicURL(path: avatarPath)
//                            fetchedPosts[index].signedAvatarURL = try? await client.storage
//                                .from("avatars")
//                                .createSignedURL(path: avatarPath, expiresIn: 3600)
                        }
                    }
                }
            }
            
            self.achievements = fetchedPosts

        } catch {
            print("❌ Error fetching posts:", error)
        }
    }
}

