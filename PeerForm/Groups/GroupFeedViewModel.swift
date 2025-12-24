//
//  GroupFeedViewModel.swift
//  PeerForm
//
//  Created by Mason Drabik on 12/23/25.
//

import Supabase
import Combine
import SwiftUI

@MainActor
final class GroupFeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var hasLoaded = false

    let group: PGroup
    private let supabase = SupabaseManager.shared.client

    init(group: PGroup) {
        self.group = group
    }
}

extension GroupFeedViewModel {
    func loadPosts() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        isLoading = true

        do {
            let response: [Post] = try await supabase
                .from("posts")
                .select("""
                    *,
                    profiles(*),
                    likes(count),
                    comments(count)
                """)
                .eq("group_id", value: group.id)
                .order("created_at", ascending: false)
                .execute()
                .value

            posts = response
        } catch {
            print("❌ Failed to load group posts:", error)
        }

        isLoading = false
    }
}
