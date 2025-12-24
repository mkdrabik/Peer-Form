//
//  GroupView.swift
//  PeerForm
//
//  Created by Mason Drabik on 12/23/25.
//
import SwiftUI
import Supabase

struct GroupsView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    //    @StateObject private var viewModel = GroupsViewModel()
    
    var body: some View {
        Text("Hello")
    }
    
}


struct GroupsHomeView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject private var vm = GroupsHomeViewModel()

    var body: some View {
        NavigationStack {
            List {
                if !vm.myGroups.isEmpty {
                    Section("Your Groups") {
                        ForEach(vm.myGroups) { group in
                            NavigationLink {
                                GroupFeedView(group: group)
                            } label: {
                                GroupRowView(group: group)
                            }
                        }
                    }
                }

                if !vm.discoverGroups.isEmpty {
                    Section("Discover") {
                        ForEach(vm.discoverGroups) { group in
                            GroupDiscoverRowView(group: group)
                        }
                    }
                }
            }
            .searchable(text: $vm.searchText, prompt: "Search groups")
            .onChange(of: vm.searchText) {
                Task { await vm.searchGroups() }
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        CreateGroupView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                if let userId = supabaseManager.profile?.id {
                    await vm.loadMyGroups(userId: userId)
                }
            }
        }
    }
}
