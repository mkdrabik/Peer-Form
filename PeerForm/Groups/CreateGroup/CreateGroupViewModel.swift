//
//  CreateGroupViewModel.swift
//  PeerForm
//
//  Created by Mason Drabik on 12/23/25.
//

import SwiftUI
import Combine
import Supabase

@MainActor
final class CreateGroupViewModel: ObservableObject {
    @Published var name = ""
    @Published var goal = ""
    @Published var description = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func canSubmit() -> Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !goal.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func createGroup(
        supabase: SupabaseClient,
        currentUserId: UUID
    ) async -> PGroup? {
        guard canSubmit() else { return nil }
        isLoading = true
        errorMessage = nil

        do {
            // 1️⃣ Create group
            let group: PGroup = try await supabase
                .from("groups")
                .insert([
                    "name": name,
                    "goal": goal,
                    "description": description,
                    "created_by": currentUserId.uuidString
                ])
                .select()
                .single()
                .execute()
                .value

            // 2️⃣ Add creator as admin
            try await supabase
                .from("group_members")
                .insert([
                    "group_id": group.id.uuidString,
                    "user_id": currentUserId.uuidString,
                    "role": "admin"
                ])
                .execute()

            isLoading = false
            return group

        } catch {
            errorMessage = "Failed to create group"
            print("❌ Create group error:", error)
            isLoading = false
            return nil
        }
    }
}

