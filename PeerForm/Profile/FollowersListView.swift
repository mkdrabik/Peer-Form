//
//  FollowersListView.swift
//  TWEE
//
//  Created by Mason Drabik on 10/11/25.
//
import Kingfisher
import SwiftUI

struct FollowersListView: View {
    let users: [Profile]
    let title: String

    var body: some View {
        NavigationView {
            List(users, id: \.id) { user in
                HStack {
                    KFImage(URL(string: user.avatar_url ?? ""))
                        .placeholder {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    Text(user.username)
                        .font(.body)
                }
                .background(
                    NavigationLink("", destination: FriendProfileView(user: user, avatarURL: URL(string:user.avatar_url ?? "")))
                                .opacity(0)
                        )
            }
            .navigationTitle(title)
        }
    }
}

