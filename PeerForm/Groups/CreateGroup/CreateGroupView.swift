//
//  CreateGroupView.swift
//  PeerForm
//
//  Created by Mason Drabik on 12/23/25.
//
import SwiftUI
import Supabase

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var supabaseManager: SupabaseManager

    @StateObject private var vm = CreateGroupViewModel()
    @State private var createdGroup: PGroup?

    var body: some View {
        Form {
            Section(header: Text("Group Info")) {
                TextField("Group name", text: $vm.name)

                TextField("Goal (e.g. Run 100 miles)", text: $vm.goal)

                TextEditor(text: $vm.description)
                    .frame(height: 80)
            }

            if let error = vm.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Create Group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Create") {
                    Task {
                        await submit()
                    }
                }
                .disabled(!vm.canSubmit() || vm.isLoading)
            }
        }
        .overlay {
            if vm.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
        .navigationDestination(item: $createdGroup) { group in
            GroupFeedView(group: group)
        }
    }

    private func submit() async {
        guard let userId = supabaseManager.profile?.id else { return }

        if let group = await vm.createGroup(
            supabase: supabaseManager.client,
            currentUserId: userId
        ) {
            createdGroup = group
        }
    }
}
