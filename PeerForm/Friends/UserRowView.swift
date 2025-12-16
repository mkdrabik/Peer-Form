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
                    .foregroundColor(.gray)
            }
            .padding(.leading, 8)
            .background(
                NavigationLink("", destination: FriendProfileView( user: user, avatarURL: avatarURL))
                    .opacity(0)
            )
            
            Spacer()
        }
    }
}
