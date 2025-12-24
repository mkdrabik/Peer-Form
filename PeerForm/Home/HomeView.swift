//
//  HomeView.swift
//  TWEE
//
//  Created by Mason Drabik on 10/2/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            
            NavigationStack {
                FeedView()
            }
            .tabItem {
                Label("Feed", systemImage: "house.fill")
            }
            .tag(HomeTab.feed)
            
            NavigationStack {
                FriendsView()
            }
            .tabItem {
                Label("Friends", systemImage: "person.2.fill")
            }
            .tag(HomeTab.friends)
            
            NavigationStack {
                GroupsHomeView()
            }
            .tabItem {
                Label("Groups", systemImage: "person.3.fill")
            }
            .tag(HomeTab.groups)
            
            NavigationStack {
                CreatePostView()
            }
            .tabItem {
                Label("Post", systemImage: "camera.fill")
            }
            .tag(HomeTab.camera)
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(HomeTab.profile)
        }
        .task {
            await supabaseManager.fetchFollowersCount()
            await supabaseManager.fetchFollowingCount()
        }
    }
}
#Preview{
    HomeView()
        .environmentObject(SupabaseManager.previewInstance)
}
