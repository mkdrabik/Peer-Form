//
//  FriendView.swift
//  TWEE
//
//  Created by Mason Drabik on 10/2/25.
//
import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject private var viewModel = FriendsViewModel()

    var body: some View {
        VStack {
            TextField("Search users...", text: $viewModel.searchQuery)
                .textFieldStyle(.roundedBorder)
                .padding()

            if viewModel.isLoading {
                ProgressView()
            } else {
                List(viewModel.filteredResults, id: \.id) { user in
                    UserRowView(
                        user: user,
                        isFollowing: viewModel.followStatus[user.id] ?? false,
                        avatarURL: viewModel.avatarURLs[user.id]
                    )
                }
            }
        }
        .navigationTitle("Friends")
        .task {
            await viewModel.loadIfNeeded(supabaseManager: supabaseManager)
        }
    }
}

