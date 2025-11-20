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
    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject var vm = UserRowViewModel()

    
    var body: some View {
            HStack {
                if let urlString = vm.avatarURL{
                    KFImage(urlString)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                }
                    VStack(alignment: .leading){
                        Text(user.username)
                            .font(.body)
                            .bold()
                        Text("\(user.first_name) \( user.last_name)")
                            .font(.footnote)
                    }
                    .padding(.leading, 8)
                    .background(
                        NavigationLink("", destination: FriendProfileView(user: user, avatarURL: vm.avatarURL))
                                    .opacity(0)
                            )
                Spacer()
                
                Button(action: {
                    Task {
                        await vm.toggleFollow(supabaseManager: supabaseManager, currentUserId: supabaseManager.profile!.id, targetUserId: user.id)
                    }
                }) {
                    Text(vm.isFollowing ? "Following" : "Follow")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(vm.isFollowing ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }        }
            .buttonStyle(.plain)
            .task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        await vm.checkFollowStatus(
                            supabaseManager: supabaseManager,
                            currentUserId: supabaseManager.profile!.id,
                            targetUserId: user.id
                        )
                    }
                    group.addTask {
                        do {
                            try await vm.fetchOtherAvatarURL(
                                supabaseManager: supabaseManager,
                                avatarURL: user.avatar_url ?? ""
                            )
                        } catch {
                            print("❌ Failed to fetch avatar: \(error)")
                        }
                    }
                }
            }
        }
}
#Preview {
    UserRowView(user: Profile(id: UUID(), username: "mkdrabik", first_name: "Mason", last_name: "Drabik"))
        .environmentObject(SupabaseManager.previewInstance)
}
