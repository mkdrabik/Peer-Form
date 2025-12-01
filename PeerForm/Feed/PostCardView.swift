//
//  PostCardView.swift
//  PeerForm
//
//  Created by Mason Drabik on 10/22/25.
//
import SwiftUI
import Kingfisher
import Supabase

struct PostCardView: View {
    let post: Post
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var showFriendProfile = false
    @State private var selectedUser: Profile?
    @State private var isLiked: Bool
    @State private var likeCount: Int
    @State private var showHeart = false
    @State private var heartScale: CGFloat = 0.5

    
    init(post: Post) {
        self.post = post
        _isLiked = State(initialValue: post.isLikedByCurrentUser ?? false)
        _likeCount = State(initialValue: post.likeCount ?? 0)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
                HStack {
                    KFImage(post.signedAvatarURL)
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

                    Text(post.profiles?.username ?? "Error")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical)
                .onTapGesture {
                       selectedUser = post.profiles
                       showFriendProfile = true
                   }
            NavigationLink(
                   destination: Group {
                       if let user = selectedUser {
                           FriendProfileView(
                               user: user,
                               avatarURL: post.signedAvatarURL
                           )
                       } else {
                           EmptyView()
                       }
                   },
                   isActive: $showFriendProfile
               ) {
                   EmptyView()
               }
               .hidden()
            ZStack{
                KFImage(URL(string: post.signedImageURL?.absoluteString ?? ""))
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 350)
                    .clipped()
                    .allowsHitTesting(false)
                if showHeart {
                        Image(systemName: "dumbbell.fill")
                            .resizable()
                            .foregroundColor(.green)
                            .scaledToFit()
                            .frame(width: 120)
                            .scaleEffect(heartScale)
                            .shadow(radius: 10)
                            .transition(.opacity)
                    }
            }
            .frame(height: 350)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                Task {
                    await handleDoubleTapLike()
                }
            }
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
    func handleDoubleTapLike() async {
        if !isLiked {
            await toggleLike()
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showHeart = true
            heartScale = 1.2
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3)) {
                heartScale = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                showHeart = false
            }
        }
    }


}

