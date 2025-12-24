//
//  GroupViewModel.swift
//  PeerForm
//
//  Created by Mason Drabik on 12/23/25.
//

import Combine
import SwiftUI
import Supabase


struct PGroup: Identifiable, Decodable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let goal: String
    let is_private: Bool
    let owner_id: UUID
    let created_at: Date
}


struct GroupMembership: Decodable {
    let group: PGroup
}


@MainActor
final class GroupsHomeViewModel: ObservableObject {
    @Published var myGroups: [PGroup] = []
    @Published var discoverGroups: [PGroup] = []
    @Published var searchText = ""
    @Published var isLoading = false

    private let supabase = SupabaseManager.shared.client
}

extension GroupsHomeViewModel {
    func loadMyGroups(userId: UUID) async {
        isLoading = true

        do {
            let memberships: [GroupMembership] = try await supabase
                .from("group_members")
                .select("group:groups(*)")
                .eq("user_id", value: userId)
                .execute()
                .value

            myGroups = memberships.map { $0.group }
        } catch {
            print("❌ Failed to load my groups:", error)
        }

        isLoading = false
    }
}


extension GroupsHomeViewModel {
    func searchGroups() async {
        guard !searchText.isEmpty else {
            discoverGroups = []
            return
        }

        do {
            let results: [PGroup] = try await supabase
                .from("groups")
                .select()
                .ilike("name", pattern: "%\(searchText)%")
                .eq("is_private", value: false)
                .limit(20)
                .execute()
                .value

            discoverGroups = results
        } catch {
            print("❌ Failed to search groups:", error)
        }
    }
}

