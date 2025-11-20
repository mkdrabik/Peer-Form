//
//  UserAchievementView.swift
//  PeerForm
//
//  Created by Mason Drabik on 11/3/25.
//

import SwiftUI
import Kingfisher
import Supabase

struct UserAchievementsView: View {
    @ObservedObject var vm: ProfileViewModel 
    @EnvironmentObject var supabaseManager: SupabaseManager
    let userId: UUID
    @State private var hasLoaded = false
    @State private var showRefreshToast = false
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                LazyVStack(spacing: 24) {
                    if vm.isLoading {
                        ProgressView("Loading posts...")
                            .padding(.top, 40)
                    } else if let error = vm.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.top, 40)
                    } else if vm.achievements.isEmpty {
                        Text("No posts yet.")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                    } else {
                        ForEach(vm.achievements) { post in
                            UserPostCardView(post: post, vm: vm, isLiked: post.isLikedByCurrentUser ?? false, likeCount: post.likeCount ?? 0)
                        }
                    }
                }
                .padding(.vertical, 24)
            }
            .onAppear {
                if !hasLoaded {
                    hasLoaded = true
                    Task {
                        await vm.fetchUserPosts(client: supabaseManager.client, supabaseManager: supabaseManager, userId: userId, type: "achievement")
                    }
                }
            }
            
            if showRefreshToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                    Text("Feed updated")
                        .foregroundColor(.white)
                        .font(.callout.weight(.semibold))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(Color.black.opacity(0.8))
                .clipShape(Capsule())
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 8)
                .zIndex(1)
            }
        }
        .alert("Delete Post?", isPresented: $vm.showDeleteAlert, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let post = vm.postToDelete {
                    Task {
                        await vm.deletePost(supabaseManager: supabaseManager, postId: post.id)
                        await vm.fetchUserPosts(client: supabaseManager.client, supabaseManager: supabaseManager, userId: userId, type: "achievement")
                    }
                }
            }
        }, message: {
            Text("This action cannot be undone.")
        })
    }
}
