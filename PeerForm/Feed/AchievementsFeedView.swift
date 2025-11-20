//
//  AchievementView.swift
//  PeerForm
//
//  Created by Mason Drabik on 11/3/25.
//


import SwiftUI
import Kingfisher
import Supabase

struct AchievementsFeedView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject private var vm = AchievementsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                if vm.isLoading {
                    ProgressView("Loading Achievements...")
                        .padding()
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(vm.achievements) { achievement in
                            PostCardView(post: achievement)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Achievements")
            .task {
                await vm.fetchPosts(supabaseManager: supabaseManager)
            }
        }
    }
}



#Preview{
    AchievementsFeedView()
        .environmentObject(SupabaseManager.previewInstance)
}
