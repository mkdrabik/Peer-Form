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
    @State private var showSearch = false 

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
                        Text(song.title)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading) 
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    HStack(spacing: 20) {
                        if let appleURL = song.apple_music_url,
                           let url = URL(string: appleURL) {
                            Button {
                                UIApplication.shared.open(url)
                            } label: {
                                Image(systemName: "apple.logo")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 10)
                            .padding(.bottom, 4)
                        }
                               if let spotifyURL = song.spotify_url,
                                  let url = URL(string: spotifyURL) {
                                   Button {
                                       UIApplication.shared.open(url)
                                   } label: {
                                       Image(systemName:"s.circle.fill")
                                           .resizable()
                                           .frame(width: 32, height: 32)
                                           .foregroundColor(.green)
                                   }
                                   .buttonStyle(.plain)
                                   
                               }
                           }
                       }
    }
            .listStyle(.plain)
            .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                NavigationLink(destination: SongSearchView()) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 28))
                                        .foregroundColor(.red)
                                }
                            }
                        }
            .task {
                await vm.loadFeed(supabaseManager: supabaseManager)
            }
        }
    }
}

