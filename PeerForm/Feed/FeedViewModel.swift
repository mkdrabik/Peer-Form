//
//  FeedViewModel.swift
//  TWEE
//
//  Created by Mason Drabik on 10/10/25.
//

import Foundation
import Supabase
import SwiftUI
import Combine

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var unreadCount = 0

    func fetchUnreadCount(supabaseManager: SupabaseManager) async {
        guard let userId = supabaseManager.profile?.id else { return }
        do {
            let response = try await supabaseManager.client
                .from("notifications")
                .select("id", count: .exact)
                .eq("user_id", value: userId)
                .eq("is_read", value: false)
                .execute()
            let count = response.count ?? 0
            await MainActor.run {
                self.unreadCount = count
                UIApplication.shared.applicationIconBadgeNumber = count
            }
        } catch {
            print("❌ Error loading unread count:", error)
            await MainActor.run { self.unreadCount = 0 }
        }
    }

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
                .eq("type", value: "post")
                .order("created_at", ascending: false)
                .limit(20)
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
            
            self.posts = fetchedPosts

        } catch {
            print("❌ Error fetching posts:", error)
        }
    }
}

struct Post: Decodable, Identifiable {
    let id: UUID
    let user_id: UUID
    let image_path: String
    let caption: String?
    let created_at: String
    let type: String?
    var signedImageURL: URL?
    var signedAvatarURL: URL?
    var profiles: Profile?
    var commentCount: Int?
    var likeCount: Int?
    var isLikedByCurrentUser: Bool?
}
extension Post {
    var createdAtDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: created_at)
    }
}
extension Post {
    var createdAtEST: String {
        guard let date = createdAtDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

struct LikeRow: Decodable { let id: UUID }
