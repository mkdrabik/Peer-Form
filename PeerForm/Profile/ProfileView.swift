//
//  ProfileView.swift
//  TWEE
//
//  Created by Mason Drabik on 10/2/25.
//

import SwiftUI
import Kingfisher
import Supabase

private enum ProfileTab: String {
    case calendar = "Calendar"
    case posts = "Posts"
    case achievements = "Achievements"
}

struct ProfileView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var selectedTab: ProfileTab = .calendar
    @State private var selectedDate = Date()
    @StateObject private var vm = ProfileViewModel()
    @StateObject private var followersVM = FollowersViewModel()
    @StateObject private var postsVM = ProfileViewModel()
    @StateObject private var achievementsVM = ProfileViewModel()

    @State private var showFullScreen = false
    @State private var showingFollowersList = false
    @State private var showingFollowingList = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {

                if let avatarURL = supabaseManager.avatarURL {
                    KFImage(avatarURL)
                        .placeholder {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .foregroundColor(.gray)
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 160)
                        .clipShape(Circle())
                        .shadow(radius: 6)
                        .onTapGesture { withAnimation(.spring()) { showFullScreen = true } }
                        .fullScreenCover(isPresented: $showFullScreen) {
                            ZStack {
                                Color.black.ignoresSafeArea()
                                    .onTapGesture { withAnimation(.spring()) { showFullScreen = false } }

                                KFImage(avatarURL)
                                    .resizable()
                                    .scaledToFit()
                                    .padding()
                                    .transition(.scale)
                                    .onTapGesture { withAnimation(.spring()) { showFullScreen = false } }
                            }
                        }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                        .shadow(radius: 6)
                }

                HStack {
                    Text(supabaseManager.profile?.first_name ?? "")
                        .font(.title).fontWeight(.semibold)
                    Text(supabaseManager.profile?.last_name ?? "")
                        .font(.title).fontWeight(.semibold)
                }

                HStack(spacing: 40) {
                    VStack {
                        Text("\(supabaseManager.followersCount)")
                            .font(.title2.bold())
                        Text("Followers").font(.caption)
                    }
                    .onTapGesture {
                        Task {
                            try await followersVM.fetchFollowers(
                                for: supabaseManager.profile!.id,
                                supabaseManager: supabaseManager
                            )
                            showingFollowersList = true
                        }
                    }

                    VStack {
                        Text("\(supabaseManager.followingCount)")
                            .font(.title2.bold())
                        Text("Following").font(.caption)
                    }
                    .onTapGesture {
                        Task {
                            try await followersVM.fetchFollowing(
                                for: supabaseManager.profile!.id,
                                supabaseManager: supabaseManager
                            )
                            showingFollowingList = true
                        }
                    }
                }

                NavigationLink(
                    destination: FollowersView(users: $followersVM.followers, title: "Followers"),
                    isActive: $showingFollowersList
                ) { EmptyView() }

                NavigationLink(
                    destination: FollowersListView(users: followersVM.following, title: "Following"),
                    isActive: $showingFollowingList
                ) { EmptyView() }

                Picker("View", selection: $selectedTab) {
                    Text("Calendar").tag(ProfileTab.calendar)
                    Text("Posts").tag(ProfileTab.posts)
                    Text("Achievements").tag(ProfileTab.achievements)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 8)

                Group {
                    switch selectedTab {
                    case .calendar:
                        ProfileCalendarView(vm: vm, selectedDate: $selectedDate)
                            .transition(.opacity)

                    case .posts:
                        if let user = supabaseManager.client.auth.currentUser {
                            UserPostsView(vm: postsVM, userId: user.id)
                                .environmentObject(supabaseManager)
                        } else {
                            Text("Please log in to view your posts.")
                                .foregroundColor(.gray)
                                .padding()
                        }

                    case .achievements:
                        if let user = supabaseManager.client.auth.currentUser {
                            UserAchievementsView(vm: achievementsVM, userId: user.id)
                                .environmentObject(supabaseManager)
                        } else {
                            Text("Please log in to view your achievements.")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
            }
            .padding(.vertical)
        }
        .toolbar {
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape.fill")
                    .imageScale(.large)
            }
        }
        .onAppear {
            vm.daysInCurrentMonth() }
    }
}

private struct ProfileCalendarView: View {
    @ObservedObject var vm: ProfileViewModel
    @EnvironmentObject var supabaseManager: SupabaseManager
    @Binding var selectedDate: Date

    var body: some View {
        VStack {
            HStack {
                Text("Week: \(supabaseManager.stats?.weekly_count ?? 0)/7")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .padding(.leading)
                Spacer()
                WorkoutProgressBar(completed: supabaseManager.stats?.weekly_count ?? 0, total: 7)
            }
            .padding(.bottom)

            HStack {
                Text("Month: \(supabaseManager.stats?.monthly_count ?? 0)/\(vm.days)")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .padding(.leading)
                Spacer()
                WorkoutProgressBar(completed: supabaseManager.stats?.monthly_count ?? 0, total: vm.days)
            }
            .padding(.bottom)

            HStack {
                Text("Year: \(supabaseManager.stats?.yearly_count ?? 0)/365")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .padding(.leading)
                Spacer()
                WorkoutProgressBar(completed: supabaseManager.stats?.yearly_count ?? 0, total: 365)
            }

            DatePicker(
                "Select a Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .frame(maxHeight: 350)
            .padding(.bottom, 40)
        }
    }
}
