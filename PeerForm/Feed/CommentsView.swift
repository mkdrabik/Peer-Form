//
//  CommentsView.swift
//  PeerForm
//
//  Created by Mason Drabik on 10/22/25.
//

import SwiftUI
import Supabase
import Kingfisher

struct CommentsView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject private var vm = CommentsViewModel()
    let post: Post

    var body: some View {
        VStack {
            List(vm.comments) { comment in
                HStack(alignment: .top) {
                    if let avatarURL = URL(string: comment.profiles?.avatar_url ?? "") {
                        KFImage(avatarURL)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(comment.profiles?.username ?? "Unknown")
                            .font(.subheadline.bold())
                        Text(comment.content)
                            .font(.body)
                    }
                }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if (comment.user_id == supabaseManager.client.auth.currentUser?.id || post.user_id == supabaseManager.client.auth.currentUser?.id){
                                                Button(role: .destructive) {
                                                    Task {
                                                        await vm.deleteComment(comment.id, supabase: supabaseManager.client)
                                                    }
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
            }

            HStack {
                TextField("Add a comment...", text: $vm.newComment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Send") {
                    Task {
                        if let user = supabaseManager.client.auth.currentUser {
                            await vm.addComment(for: post.id, userId: user.id, supabase: supabaseManager.client)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .task {
            await vm.fetchComments(for: post.id, supabase: supabaseManager.client)
        }
        .navigationTitle("Comments")
    }
}
