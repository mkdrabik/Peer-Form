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
    @EnvironmentObject var supabaseManager: SupabaseManager

    let user: Profile
    let avatarURL: URL?
    let onRemoved: () -> Void

    @State private var isRemoving = false
    @State private var showProfile = false

        var body: some View {
            HStack {
                HStack {
                    if let avatarURL {
                        KFImage(avatarURL)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .allowsHitTesting(false)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                            .allowsHitTesting(false)
                    }

                    VStack(alignment: .leading) {
                        Text(user.username).bold()
                        Text("\(user.first_name) \(user.last_name)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showProfile = true
                }

                Spacer()

                Button(role: .destructive) {
                    Task {
                        await removeFollower()
                    }
                } label: {
                    Text("Remove")
                        .font(.subheadline)
                }
                .buttonStyle(.borderless)
            }
            .background(
                NavigationLink(
                    destination: FriendProfileView(
                        user: user,
                        avatarURL: avatarURL
                    ),
                    isActive: $showProfile
                ) {
                    EmptyView()
                }
                .hidden()
            )
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
