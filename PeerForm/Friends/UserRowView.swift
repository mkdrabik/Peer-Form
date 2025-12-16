//
//  UserRowView.swift
//  TWEE
//
//  Created by Mason Drabik on 10/2/25.
//

import SwiftUI
import Kingfisher

struct UserRowView: View {
    let user: Profile
    let avatarURL: URL?

    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject private var vm: UserRowViewModel

    init(user: Profile, isFollowing: Bool, avatarURL: URL?) {
        self.user = user
        self.avatarURL = avatarURL
        _vm = StateObject(wrappedValue: UserRowViewModel(isFollowing: isFollowing))
    }

    var body: some View {
        HStack {
            if let avatarURL {
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
            }
            .padding(.leading, 8)
            .background(
                NavigationLink("", destination: FriendProfileView( user: user, avatarURL: avatarURL))
                    .opacity(0)
            )

            Spacer()

            Button {
                Task {
                    await vm.toggleFollow(
                        supabaseManager: supabaseManager,
                        currentUserId: supabaseManager.profile!.id,
                        targetUserId: user.id
                    )
                }
            } label: {
                Text(vm.isFollowing ? "Following" : "Follow")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(vm.isFollowing ? .gray : .blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .buttonStyle(.plain)
    }
}

