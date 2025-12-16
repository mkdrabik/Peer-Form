//
//  LeaderBoardView.swift
//  PeerForm
//
//  Created by Mason Drabik on 10/31/25.
//

import SwiftUI
import Kingfisher
import Combine
import Supabase

struct FriendLeaderboardView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject private var followersVM = FollowersViewModel()
    @StateObject private var leaderboardVM = FriendLeaderboardViewModel()
    @State private var selectedPeriod = "Week"

    var body: some View {
        VStack {
            Picker("Period", selection: $selectedPeriod) {
                Text("Week").tag("Week")
                Text("Month").tag("Month")
                Text("Year").tag("Year")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top)

            if leaderboardVM.isLoading {
                ProgressView("Loading Leaderboard...")
                    .padding()
            } else if let error = leaderboardVM.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                let sortedEntries = leaderboardVM.leaderboard.sorted {
                    switch selectedPeriod {
                    case "Month": return $0.monthly_count > $1.monthly_count
                    case "Year":  return $0.yearly_count > $1.yearly_count
                    default:      return $0.weekly_count > $1.weekly_count
                    }
                }

                // Pre-compute tied ranks before List
                let rankedEntries = calculateRanks(for: sortedEntries, period: selectedPeriod)

                List {
                    Section(header: Text("🏆 \(selectedPeriod) Leaderboard").font(.headline)) {
                        ForEach(rankedEntries, id: \.entry.id) { item in
                            LeaderboardRowView(
                                entry: item.entry,
                                rank: item.rank,
                                isCurrentUser: item.entry.id == supabaseManager.profile?.id,
                                selectedPeriod: selectedPeriod
                            )
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Leaderboard")
        .task {
            guard let currentUser = supabaseManager.profile else { return }
            try? await followersVM.fetchFollowers(for: currentUser.id, supabaseManager: supabaseManager)
            await leaderboardVM.fetchLeaderboard(
                supabaseManager: supabaseManager,
                followers: followersVM.followers
            )
        }
    }

    /// Calculates tied ranks
    private func calculateRanks(for entries: [FriendLeaderboardEntry], period: String)
        -> [(entry: FriendLeaderboardEntry, rank: Int)] {
        var result: [(FriendLeaderboardEntry, Int)] = []
        var prevCount: Int? = nil
        var currentRank = 0

        for (index, entry) in entries.enumerated() {
            let count: Int
            switch period {
            case "Month": count = entry.monthly_count
            case "Year":  count = entry.yearly_count
            default:      count = entry.weekly_count
            }

            if prevCount == nil || prevCount! != count {
                currentRank = index + 1
                prevCount = count
            }
            result.append((entry, currentRank))
        }
        return result
    }
}
private struct LeaderboardRowView: View {
    let entry: FriendLeaderboardEntry
    let rank: Int
    let isCurrentUser: Bool
    let selectedPeriod: String

    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var showFriendProfile = false
    @State private var selectedUser: Profile?
    @State private var isFetchingProfile = false

    var body: some View {
        HStack(spacing: 12) {
            if let avatarURL = entry.avatar_url, let url = URL(string: avatarURL) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .onTapGesture { Task { await fetchProfileAndShow() } }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                    .onTapGesture { Task { await fetchProfileAndShow() } }
            }

            Group {
                switch rank {
                case 1: Text("🥇").font(.system(size: 20))
                case 2: Text("🥈").font(.system(size: 20))
                case 3: Text("🥉").font(.system(size: 20))
                default:
                    Text("\(rank).")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }

            Text(entry.username)
                .fontWeight(isCurrentUser ? .bold : .regular)
                .foregroundColor(isCurrentUser ? .blue : .primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .onTapGesture { Task { await fetchProfileAndShow() } }

            Spacer()

            Text("\(count) workouts")
                .foregroundColor(.primary)
        }
        .padding(.vertical, 6)
        .overlay {
            if isFetchingProfile {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.gray)
            }
        }
        .background(
            NavigationLink(
                destination: Group {
                    if let user = selectedUser,
                       let avatarString = user.avatar_url,
                       let avatarURL = URL(string: avatarString) {
                        FriendProfileView( user: user, avatarURL: avatarURL)
                    } else {
                        EmptyView()
                    }
                },
                isActive: $showFriendProfile
            ) {
                EmptyView()
            }
            .hidden()
        )
    }

    private var count: Int {
        switch selectedPeriod {
        case "Month": return entry.monthly_count
        case "Year":  return entry.yearly_count
        default:      return entry.weekly_count
        }
    }

    private func fetchProfileAndShow() async {
        guard !isFetchingProfile else { return }
        isFetchingProfile = true

        do {
            let client = supabaseManager.client
            let response = try await client
                .from("profiles")
                .select("id, username, avatar_url, first_name, last_name")
                .eq("id", value: entry.id)
                .single()
                .execute()

            var user = try JSONDecoder().decode(Profile.self, from: response.data)

            if let avatarPath = user.avatar_url,
               !avatarPath.starts(with: "http") {
                let url = try client.storage.from("avatars").getPublicURL(path: avatarPath)
                user.avatar_url = url.absoluteString
            }

            await MainActor.run {
                selectedUser = user
                showFriendProfile = true
            }
        } catch {
            print("❌ Error fetching user profile:", error)
        }

        isFetchingProfile = false
    }
}
