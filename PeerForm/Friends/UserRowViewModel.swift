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
    @Published var isFollowing: Bool

    init(isFollowing: Bool) {
        self.isFollowing = isFollowing
    }

    func toggleFollow(
        supabaseManager: SupabaseManager,
        currentUserId: UUID,
        targetUserId: UUID
    ) async {
        if isFollowing {
            await unfollow(supabaseManager, currentUserId, targetUserId)
        } else {
            await follow(supabaseManager, currentUserId, targetUserId)
        }
    }

    private func follow(
        _ supabaseManager: SupabaseManager,
        _ currentUserId: UUID,
        _ targetUserId: UUID
    ) async {
        try? await supabaseManager.client
            .from("follows")
            .insert([
                "follower_id": currentUserId,
                "following_id": targetUserId
            ])
            .execute()
        isFollowing = true
    }

    private func unfollow(
        _ supabaseManager: SupabaseManager,
        _ currentUserId: UUID,
        _ targetUserId: UUID
    ) async {
        try? await supabaseManager.client
            .from("follows")
            .delete()
            .eq("follower_id", value: currentUserId)
            .eq("following_id", value: targetUserId)
            .execute()
        isFollowing = false
    }
}

struct Follow: Codable {
    let follower_id: UUID
    let following_id: UUID
}
