//
//  FriendsViewModel.swift
//  TWEE
//
//  Created by Mason Drabik on 10/2/25.
//
import Foundation
import Combine
import Supabase


@MainActor
class FriendsViewModel: ObservableObject {
    @Published var allUsers: [Profile] = []
    @Published var filteredResults: [Profile] = []
    @Published var searchQuery: String = "" {
        didSet { filterUsers() }
    }
    @Published var isLoading = false

    @Published var followStatus: [UUID: Bool] = [:]
    @Published var avatarURLs: [UUID: URL] = [:]

    private var hasLoaded = false

    func loadIfNeeded(supabaseManager: SupabaseManager) async {
        guard !hasLoaded else { return }
        hasLoaded = true

        await loadAllUsers(supabaseManager: supabaseManager)
        await preloadRowData(supabaseManager: supabaseManager)
    }

    private func loadAllUsers(supabaseManager: SupabaseManager) async {
        isLoading = true
        do {
            let response = try await supabaseManager.client
                .from("profiles")
                .select()
                .neq("username", value: supabaseManager.profile?.username ?? "")
                .execute()

            let profiles = try JSONDecoder().decode([Profile].self, from: response.data)
            allUsers = profiles
            filteredResults = profiles
        } catch {
            print("❌ Error loading users:", error)
        }
        isLoading = false
    }

    private func preloadRowData(supabaseManager: SupabaseManager) async {
        guard let currentUserId = supabaseManager.profile?.id else { return }

        await withTaskGroup(of: Void.self) { group in
            for user in allUsers {
                group.addTask {
                    await self.loadRowData(
                        supabaseManager: supabaseManager,
                        currentUserId: currentUserId,
                        user: user
                    )
                }
            }
        }
    }

    private func loadRowData(
        supabaseManager: SupabaseManager,
        currentUserId: UUID,
        user: Profile
    ) async {
        async let follow = fetchFollowStatus(
            supabaseManager: supabaseManager,
            currentUserId: currentUserId,
            targetUserId: user.id
        )

        async let avatar = fetchAvatarURL(
            supabaseManager: supabaseManager,
            avatarPath: user.avatar_url
        )

        let (isFollowing, avatarURL) = await (follow, avatar)

        followStatus[user.id] = isFollowing
        avatarURLs[user.id] = avatarURL
    }

    private func fetchFollowStatus(
        supabaseManager: SupabaseManager,
        currentUserId: UUID,
        targetUserId: UUID
    ) async -> Bool {
        do {
            let response: [Follow] = try await supabaseManager.client
                .from("follows")
                .select()
                .eq("follower_id", value: currentUserId.uuidString)
                .eq("following_id", value: targetUserId.uuidString)
                .execute()
                .value
            return !response.isEmpty
        } catch {
            return false
        }
    }

    private func fetchAvatarURL(
        supabaseManager: SupabaseManager,
        avatarPath: String?
    ) async -> URL? {
        guard let path = avatarPath else { return nil }
        return try? supabaseManager.client.storage
            .from("avatars")
            .getPublicURL(path: path)
    }

    private func filterUsers() {
        let query = searchQuery.lowercased()
        filteredResults = query.isEmpty
            ? allUsers
            : allUsers.filter { $0.username.lowercased().contains(query) }
    }
}
