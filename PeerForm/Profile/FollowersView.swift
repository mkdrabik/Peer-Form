//
//  FollowerView.swift
//  PeerForm
//
//  Created by Mason Drabik on 12/20/25.
//

import Kingfisher
import SwiftUI

struct FollowersView: View {
    @Binding var users: [Profile]
    let title: String
    @State var isFollowing: Bool = false

    var body: some View {
        NavigationView {
            List(users, id: \.id) { user in
                FollowerRowView(
                        user: user,
                        avatarURL: URL(string: user.avatar_url ?? "")
                    ) {
                        withAnimation {
                            users.removeAll { $0.id == user.id }
                        }
                    }
            }
            .listStyle(PlainListStyle())
            .navigationTitle(title)
        }
    }
}
