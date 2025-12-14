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
        VStack(spacing: 0) {

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
                .swipeActions(edge: .trailing) {
                    if comment.user_id == supabaseManager.client.auth.currentUser?.id ||
                        post.user_id == supabaseManager.client.auth.currentUser?.id {

                        Button(role: .destructive) {
                            Task { await vm.deleteComment(comment.id, supabase: supabaseManager.client) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }

            CommentInputView(
                text: $vm.newComment,
                mentionResults: vm.mentionResults,
                isMentioning: vm.isMentioning,
                onMentionSelected: { user in
                    vm.insertMention(user.username)
                },
                onSend: {
                    Task {
                        if let user = supabaseManager.client.auth.currentUser {
                            await vm.addComment(
                                for: post.id,
                                userId: user.id,
                                supabase: supabaseManager.client
                            )
                        }
                    }
                }
            )

            .padding()
        }
        .navigationTitle("Comments")
        .task {
            await vm.fetchComments(for: post.id, supabase: supabaseManager.client)
            await vm.loadUsersForMentions(supabaseManager: supabaseManager)
        }
        .onChange(of: vm.newComment) { _ in
            vm.checkForMentionTrigger()
        }
    }
}

struct CommentInputView: View {
    @Binding var text: String
    let mentionResults: [Profile]
    let isMentioning: Bool
    var onMentionSelected: (Profile) -> Void = { _ in }
    let onSend: () -> Void

    @FocusState private var isFocused: Bool
    
    private let rowHeight: CGFloat = 44
    private let maxListHeight: CGFloat = 200

    var body: some View {
        VStack(spacing: 8) {

            if isMentioning && !mentionResults.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(mentionResults) { user in
                            Button {
                                onMentionSelected(user)
                            } label: {
                                HStack(spacing: 12) {
                                    if let url = URL(string: user.avatar_url ?? "") {
                                        KFImage(url)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                    }

                                    Text("@\(user.username)")
                                        .foregroundColor(.primary)

                                    Spacer()
                                }
                                .frame(height: rowHeight)
                                .padding(.horizontal)
                            }

                            Divider()
                        }
                    }
                }
                .frame(
                    height: min(
                        CGFloat(mentionResults.count) * rowHeight,
                        maxListHeight
                    )
                )
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 3)
                .animation(.easeInOut, value: mentionResults.count)
            }


            HStack(spacing: 8) {
                TextField("Add a comment…", text: $text, axis: .horizontal)
                    .focused($isFocused)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .lineLimit(1)
                    .onTapGesture { isFocused = true }

                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .padding(10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
}

struct GrowingTextEditor: View {
    @Binding var text: String
    @Binding var height: CGFloat
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .frame(height: height)
                .background(GeometryReader { geo in
                    Color.clear
                        .onAppear { height = geo.size.height }
                })
            
            if text.isEmpty {
                Text("Add a comment…")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
            }
        }
        .onChange(of: text) { _ in
            recalcHeight()
        }
    }
    
    private func recalcHeight() {
        let defaultHeight: CGFloat = 20
        let maxHeight: CGFloat = 120
        
        let fittingSize = CGSize(width: UIScreen.main.bounds.width - 80, height: .greatestFiniteMagnitude)
        
        let size = text.boundingRect(
            with: fittingSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.systemFont(ofSize: 16)],
            context: nil
        )
        
        height = min(max(defaultHeight, size.height + 20), maxHeight)
    }
}

struct MentionListView: View {
    let users: [Profile]
    let onSelect: (Profile) -> Void

    private let rowHeight: CGFloat = 44
    private let maxHeight: CGFloat = 200

    var body: some View {
        VStack(spacing: 0) {
            if !users.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(users) { user in
                            Button(action: { onSelect(user) }) {
                                HStack {
                                    Text(user.username)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .frame(height: rowHeight)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .frame(height: min(CGFloat(users.count) * rowHeight, maxHeight))
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
                .animation(.easeInOut, value: users.count)
            }
        }
    }
}
