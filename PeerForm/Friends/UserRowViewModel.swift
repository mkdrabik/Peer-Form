//
//  UserRowViewModel.swift
//  TWEE
//
//  Created by Mason Drabik on 10/2/25.
//
import Foundation
import Combine
import Supabase

@MainActor
class UserRowViewModel: ObservableObject {
    @Published var isFollowing: Bool = false
    @Published var avatarURL: URL?
    
    
    func toggleFollow(supabaseManager: SupabaseManager, currentUserId: UUID, targetUserId: UUID) async {
           if isFollowing {
               await unfollowUser(supabaseManager: supabaseManager, currentUserId: currentUserId, targetUserId: targetUserId)
           } else {
               await followUser(supabaseManager: supabaseManager, currentUserId: currentUserId, targetUserId: targetUserId)
           }
        await supabaseManager.fetchFollowingCount()
       }
    
    func checkFollowStatus(supabaseManager: SupabaseManager, currentUserId: UUID, targetUserId: UUID) async {
        do {
            let response: [Follow] = try await supabaseManager.client
                .from("follows")
                .select()
                .eq("follower_id", value: currentUserId.uuidString)
                .eq("following_id", value: targetUserId.uuidString)
                .execute()
                .value
            
            isFollowing = !response.isEmpty
        } catch {
            print("Error checking follow status: \(error)")
        }
    }
    
    func followUser(supabaseManager: SupabaseManager, currentUserId: UUID, targetUserId: UUID) async {
        do {
            try await supabaseManager.client.from("follows").insert([
                "follower_id": currentUserId,
                "following_id": targetUserId
            ]).execute()
            isFollowing = true
        } catch {
            print("Error following: \(error)")
        }
    }

    func unfollowUser(supabaseManager: SupabaseManager, currentUserId: UUID, targetUserId: UUID) async {
        do {
            try await supabaseManager.client.from("follows")
                .delete()
                .eq("follower_id", value: currentUserId)
                .eq("following_id", value: targetUserId)
                .execute()
            isFollowing = false
        } catch {
            print("Error unfollowing: \(error)")
        }
    }
    func fetchOtherAvatarURL(supabaseManager: SupabaseManager, avatarURL: String) async throws {
//        let signedUrlResponse = try await supabaseManager.client.storage
//            .from("avatars")
//            .createSignedURL(path: avatarURL, expiresIn: 60 * 60)
        let signedUrlResponse = try supabaseManager.client.storage.from("avatars").getPublicURL(path: avatarURL)
        self.avatarURL = signedUrlResponse
    }
}
struct Follow: Codable {
    let follower_id: UUID
    let following_id: UUID
}
