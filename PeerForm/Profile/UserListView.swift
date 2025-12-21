//
//  FollowersListView.swift
//  TWEE
//
//  Created by Mason Drabik on 10/11/25.
//
import Kingfisher
import SwiftUI

struct UserListView: View {
    let users: [Profile]
    let title: String
    @State var isFollowing: Bool = false

    var body: some View {
        NavigationView {
            List(users, id: \.id) { user in
                UserRowView(user: user, avatarURL: URL(string: user.avatar_url ?? ""))
            }
            .listStyle(PlainListStyle())
            .navigationTitle(title)
        }
    }
}

