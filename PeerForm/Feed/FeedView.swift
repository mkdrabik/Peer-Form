//
//  FeedView.swift
//  TWEE
//
//  Created by Mason Drabik on 10/2/25.
//


import SwiftUI
import Kingfisher
import Supabase

struct FeedView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject private var vm = FeedViewModel()
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if vm.isLoading {
                    ProgressView("Loading Feed...")
                        .padding()
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(vm.posts) { post in
                            PostCardView(post: post)
                        }
                    }
                    .padding()
                }
            }
            .task {
                await vm.fetchPosts(supabaseManager: supabaseManager)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ZStack {
                        NavigationLink(destination: NotificationsView()) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 24))
                                .foregroundColor(vm.unreadCount > 0 ? .red : .primary)
                        }
                        if vm.unreadCount > 0 {
                            Text("\(vm.unreadCount)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 10, y: -10)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    ZStack{
                        NavigationLink(destination: AchievementsFeedView()) {
                            Image(systemName: "flag.checkered")
                                .font(.system(size: 28))
                                .foregroundColor(.primary)
                        }
                    }
                  }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: FriendLeaderboardView()) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                    }
                }
            }

            .task {
                await vm.fetchUnreadCount(supabaseManager: supabaseManager)
            }
            .onReceive(NotificationCenter.default.publisher(for: .notificationsRead)) { _ in
                vm.unreadCount = 0
            }
        }
    }
}

#Preview{
    FeedView()
        .environmentObject(SupabaseManager.previewInstance)
}
