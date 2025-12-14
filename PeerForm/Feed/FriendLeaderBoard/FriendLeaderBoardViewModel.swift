//
//  LeaderBoardViewModel.swift
//  PeerForm
//
//  Created by Mason Drabik on 10/31/25.
//


import Supabase
import SwiftUI
import Combine
import Foundation

@MainActor
final class FriendLeaderboardViewModel: ObservableObject {
    @Published var leaderboard: [FriendLeaderboardEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchLeaderboard(
        supabaseManager: SupabaseManager,
        followers: [Profile]
    ) async {
        guard let currentUser = supabaseManager.profile else { return }
        isLoading = true
        defer { isLoading = false }

        var entries: [FriendLeaderboardEntry] = []

        var allUsers = followers

        var currentUserCopy = currentUser
        if let avatarPath = currentUserCopy.avatar_url,
           !avatarPath.starts(with: "http"),
           let publicURL = try? supabaseManager.client.storage.from("avatars").getPublicURL(path: avatarPath) {
            currentUserCopy.avatar_url = publicURL.absoluteString
        }
        allUsers.append(currentUserCopy)


        await withTaskGroup(of: FriendLeaderboardEntry?.self) { group in
            for user in allUsers {
                group.addTask {
                    do {
                        let response = try await supabaseManager.client
                            .rpc("fetch_workout_stats", params: ["uid": user.id.uuidString])
                            .execute()

                        struct WorkoutStats: Decodable {
                            let yearly_count: Int
                            let monthly_count: Int
                            let weekly_count: Int
                        }

                        let decoded = try JSONDecoder().decode([WorkoutStats].self, from: response.data)
                        let stats = decoded.first ?? .init(yearly_count: 0, monthly_count: 0, weekly_count: 0)

                        return FriendLeaderboardEntry(
                            id: user.id,
                            username: user.username,
                            avatar_url: user.avatar_url,
                            yearly_count: stats.yearly_count,
                            monthly_count: stats.monthly_count,
                            weekly_count: stats.weekly_count
                        )
                    } catch {
                        print("❌ Error fetching stats for \(user.username):", error)
                        return nil
                    }
                }
            }

            for await result in group {
                if let entry = result { entries.append(entry) }
            }
        }

        leaderboard = entries.sorted { $0.weekly_count > $1.weekly_count }
    }
}

struct FriendLeaderboardEntry: Identifiable {
    let id: UUID
    let username: String
    let avatar_url: String?
    let yearly_count: Int
    let monthly_count: Int
    let weekly_count: Int
}
