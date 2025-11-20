//
//  FriendsPostsCardView.swift
//  PeerForm
//
//  Created by Mason Drabik on 10/28/25.
//

import SwiftUI
import Kingfisher
import Supabase


struct FriendsPostCardView: View {
    let post: Post
    let vm: ProfileViewModel
    let avatarURL: URL
    let username: String
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var isLiked: Bool
    @State private var likeCount: Int
   
    
    init(post: Post, vm: ProfileViewModel, isLiked: Bool, likeCount: Int, avatarURL: URL, username: String) {
        self.post = post
        self.vm = vm
        _isLiked = State(initialValue: isLiked)
        _likeCount = State(initialValue: likeCount)
        self.avatarURL = avatarURL
        self.username = username
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                KFImage(avatarURL)
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
                    .allowsHitTesting(false)

                Text(username)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical)
            
            KFImage(URL(string: post.image_path))
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 350)
                .clipped()
                .allowsHitTesting(false)
            
            HStack {
                Button {
                    Task {
                        await toggleLike()
                    }
                } label: {
                    Label("\(likeCount)", systemImage: isLiked ? "dumbbell.fill" : "dumbbell")
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(isLiked ? .green : .primary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 15)
                NavigationLink(destination: CommentsView(post: post)) {
                    Label("\(post.commentCount ?? 0)", systemImage: "text.bubble")
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 4)
            

            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(.body)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
            }
            
            Text(post.createdAtEST)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
    func toggleLike() async {
        guard let userId = supabaseManager.profile?.id else { return }
        let client = supabaseManager.client

        if isLiked {
            do {
                try await client
                    .from("likes")
                    .delete()
                    .eq("user_id", value: userId)
                    .eq("post_id", value: post.id)
                    .execute()
                withAnimation {
                    isLiked = false
                    likeCount -= 1
                }
            } catch {
                print("❌ Error unliking:", error)
            }
        } else {
            do {
                try await client
                    .from("likes")
                    .insert(["user_id": userId, "post_id": post.id])
                    .execute()
                withAnimation {
                    isLiked = true
                    likeCount += 1
                }
            } catch {
                print("❌ Error liking:", error)
            }
        }
    }
}
