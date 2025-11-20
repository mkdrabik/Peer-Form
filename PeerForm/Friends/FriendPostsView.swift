//  FriendPostsView.swift
//  PeerForm
//
//  Created by Mason Drabik on 10/18/25.
//

import SwiftUI
import Kingfisher
import Supabase

struct FriendPostsView: View {
    @StateObject private var vm = ProfileViewModel()
    @EnvironmentObject var supabaseManager: SupabaseManager
    let userId: UUID
    let avatarURL: URL
    let username: String
    let type: String
    
    @State private var showDeleteAlert = false
    @State private var postToDelete: Post?
    @State private var hasLoaded = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if vm.isLoading {
                    ProgressView("Loading posts...")
                        .padding(.top, 40)
                } else if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.top, 40)
                } else if (vm.posts.isEmpty && type == "post") || (vm.achievements.isEmpty && type == "achievement") {
                    Text("No posts yet.")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 20) {
                        if type == "post"{
                            ForEach(vm.posts) { post in
                                FriendsPostCardView(post: post, vm: vm, isLiked: post.isLikedByCurrentUser ?? false, likeCount: post.likeCount ?? 0, avatarURL: avatarURL, username: username)
                            }
                            .padding(.top, 20)
                        } else {
                                ForEach(vm.achievements) { post in
                                    FriendsPostCardView(post: post, vm: vm, isLiked: post.isLikedByCurrentUser ?? false, likeCount: post.likeCount ?? 0, avatarURL: avatarURL, username: username)
                                }
                                .padding(.top, 20)
                            }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            if !hasLoaded {
                hasLoaded = true
                Task {
                    await vm.fetchUserPosts(client: supabaseManager.client, supabaseManager: supabaseManager, userId: userId, type: type)
                }
            }
        }
        .refreshable {
            await vm.fetchUserPosts(client: supabaseManager.client, supabaseManager: supabaseManager, userId: userId, type: type)
        }
    }
}
