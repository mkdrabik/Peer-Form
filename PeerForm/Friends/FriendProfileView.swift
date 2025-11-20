//
//  FriendProfileView.swift
//  PeerForm
//
//  Created by Mason Drabik on 10/16/25.
import SwiftUI
import Kingfisher
import Supabase

struct FriendProfileView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var selectedTab = "Calendar"
    @State private var selectedDate = Date()
    @StateObject private var vm = FriendProfileViewModel()
    @State private var showingFollowersList = false
    @State private var showingFollowingList = false
    @State private var showFullScreen = false
    
    let user: Profile
    let avatarURL: URL?
    
    
    var body: some View {
            ScrollView {
                VStack(spacing: 10) {
                    if let avatarURL = avatarURL {
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
                            .onTapGesture {
                                withAnimation(.spring()) { showFullScreen = true }
                            }
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
                        Text(user.first_name)
                            .font(.title)
                            .fontWeight(.semibold)
                        Text(user.last_name)
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 40) {
                        VStack {
                            Text("\(vm.followersCount)")
                                .font(.title2.bold())
                            Text("Followers")
                                .font(.caption)
                        }
                        .onTapGesture {
                            Task {
                                try await vm.fetchFollowers(for: user.id, supabaseManager: supabaseManager)
                                showingFollowersList = true
                            }
                        }
                        
                        VStack {
                            Text("\(vm.followingCount)")
                                .font(.title2.bold())
                            Text("Following")
                                .font(.caption)
                        }
                        .onTapGesture {
                            Task {
                                try await vm.fetchFollowing(for: user.id, supabaseManager: supabaseManager)
                                showingFollowingList = true
                            }
                        }
                    }
                    
                    NavigationLink(
                        destination: FollowersListView(users: vm.followers, title: "Followers"),
                        isActive: $showingFollowersList
                    ) { EmptyView() }
                    
                    NavigationLink(
                        destination: FollowersListView(users: vm.following, title: "Following"),
                        isActive: $showingFollowingList
                    ) { EmptyView() }
                    
                    Picker("View", selection: $selectedTab) {
                        Text("Calendar").tag("Calendar")
                        Text("Posts").tag("Posts")
                        Text("Achievements").tag("Achievements")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    if selectedTab == "Calendar" {
                        VStack{
                            HStack{
                                Text("Week: \(vm.stats?.weekly_count ?? 0)/7")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .padding(.leading)
                                Spacer()
                                WorkoutProgressBar(completed: vm.stats?.weekly_count ?? 0, total: 7)
                                
                            }
                            .padding(.bottom)
                            HStack{
                                Text("Month: \(vm.stats?.monthly_count ?? 0)/\(vm.days)")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .padding(.leading)
                                Spacer()
                                WorkoutProgressBar(completed: vm.stats?.monthly_count ?? 0, total: vm.days)
                            }
                            .padding(.bottom)
                            HStack{
                                Text("Month: \(vm.stats?.yearly_count ?? 0)/365")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .padding(.leading)
                                Spacer()
                                WorkoutProgressBar(completed: vm.stats?.monthly_count ?? 0, total: 365)
                                
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
                    } else if selectedTab  == "Achievements"{
                        FriendPostsView(userId: user.id, avatarURL: avatarURL ?? URL(fileURLWithPath: ""), username: user.username, type: "achievement")
                            .environmentObject(supabaseManager)
                    } else {
                        FriendPostsView(userId: user.id, avatarURL: avatarURL ?? URL(fileURLWithPath: ""), username: user.username, type: "post")
                            .environmentObject(supabaseManager)
                    }
                    
                    Spacer()
                }
                .padding(.top, 10)
                .task {
                    await vm.fetchFollowersCount(supabaseManager: supabaseManager, userId: user.id)
                    await vm.fetchFollowingCount(supabaseManager: supabaseManager, userId: user.id)
                    vm.daysInCurrentMonth()
                    do{
                        let s = try await supabaseManager.fetchWorkoutStats(for: user.id)
                        vm.stats = WorkoutStats(yearly_count: s.year, monthly_count: s.month, weekly_count: s.week)
                    } catch {
                        print("Error fetching friends stats")
                    }
                    
                }
            }
        }
    }

#Preview {
    FriendProfileView(
        user: Profile(
            id: UUID(),
            username: "mason",
            first_name: "Mason",
            last_name: "Drabik",
            avatar_url: nil
        ),
        avatarURL: nil
    )
    .environmentObject(SupabaseManager.previewInstance)
}
