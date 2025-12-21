//
//  FollowerRowView.swift
//  PeerForm
//
//  Created by Mason Drabik on 12/20/25.
//
import SwiftUI
import Kingfisher
import Supabase

struct FollowerRowView: View {
    let user: Profile
    let avatarURL: URL?
    let onRemoved: () -> Void
    
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var showConfirmation = false
    @State private var isRemoving = false
    
    var body: some View {
        HStack {
            if let avatarURL = avatarURL {
                KFImage(avatarURL)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text(user.username).bold()
                Text("\(user.first_name) \(user.last_name)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 8)
            
            Spacer()
            Button {
                showConfirmation = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.red)
            }
            .disabled(isRemoving)
            .alert("Remove Follower?", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    Task {
                        await removeFollower()
                    }
                }
            } message: {
                Text("Are you sure you want to remove this follower?")
            }
        }
        .padding(.vertical, 4)
    }

    private func removeFollower() async {
        guard
            let currentUserId = supabaseManager.profile?.id,
            !isRemoving
        else { return }
        isRemoving = true

        do {
            try await supabaseManager.client
                .from("follows")
                .delete()
                .eq("follower_id", value: user.id)
                .eq("following_id", value: currentUserId)
                .execute()
            onRemoved()
        } catch {
            print("❌ Failed to remove follower:", error)
        }

        isRemoving = false
    }
}
