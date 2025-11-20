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
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onSubmit {
                        Task { await viewModel.loadAllUsers(supabaseManager: supabaseManager) }
                    }
                
                if viewModel.isLoading {
                    ProgressView("Searching...")
                } else {
                    List(viewModel.filteredResults, id: \.id) { user in
                        UserRowView(user: user)
                    }
                }
            }
            .navigationTitle("Friends")
        .task{
            do{
                await viewModel.loadAllUsers(supabaseManager: supabaseManager)
            }
        }
    }
}
