//
//  GroupFeedView.swift
//  PeerForm
//
//  Created by Mason Drabik on 12/23/25.
//
import SwiftUI
import Combine
import Supabase

struct GroupFeedView: View {
    let group: PGroup

    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject private var vm: GroupFeedViewModel

    init(group: PGroup) {
        self.group = group
        _vm = StateObject(wrappedValue: GroupFeedViewModel(group: group))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {

                GroupHeaderView(group: group)

                if vm.posts.isEmpty && !vm.isLoading {
                    emptyState
                }

                ForEach(vm.posts) { post in
                    PostCardView(post: post)
                        .padding(.horizontal)
                }

                if vm.isLoading {
                    ProgressView()
                        .padding()
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CreateGroupPostView(group: group)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await vm.loadPosts()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No posts yet")
                .font(.headline)

            Text("Be the first to post in this group")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
}

struct GroupHeaderView: View {
    let group: PGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(group.goal)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let description = group.description {
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}


struct CreateGroupPostView: View {
    let group: PGroup

    var body: some View {
        Text("Create post for \(group.name)")
            .navigationTitle("New Post")
    }
}
