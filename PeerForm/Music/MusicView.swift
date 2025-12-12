//
//  MusicView.swift
//  PeerForm
//
//  Created by Mason Drabik on 12/12/25.
//

import SwiftUI

struct SongFeedView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject private var vm = SongFeedViewModel()

    var body: some View {
        NavigationStack {
            List(vm.songs) { song in
                HStack {
                    AsyncImage(url: URL(string: song.cover_url)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)

                    VStack(alignment: .leading) {
                        Text(song.title).font(.headline)
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Following Feed")
            .task {
                await vm.loadFeed(supabaseManager: supabaseManager)
            }
        }
    }
}

