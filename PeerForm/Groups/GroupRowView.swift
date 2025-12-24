//
//  GroupRowView.swift
//  PeerForm
//
//  Created by Mason Drabik on 12/23/25.
//

import SwiftUI
import Supabase

struct GroupRowView: View {
    let group: PGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(group.name)
                .font(.headline)

            Text(group.goal)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}
struct GroupDiscoverRowView: View {
    let group: PGroup
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var isJoining = false

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(group.name).bold()
                Text(group.goal)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button("Join") {
                Task { await joinGroup() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isJoining)
        }
    }

    private func joinGroup() async {
        guard let userId = supabaseManager.profile?.id else { return }
        isJoining = true

        do {
            try await supabaseManager.client
                .from("group_members")
                .insert([
                    "group_id": group.id,
                    "user_id": userId
                ])
                .execute()
        } catch {
            print("❌ Failed to join group:", error)
        }

        isJoining = false
    }
}

