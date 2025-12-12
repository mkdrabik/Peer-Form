//
//  MusicView.swift
//  PeerForm
//
//  Created by Mason Drabik on 12/12/25.
//

import SwiftUI

struct SongSearchView: View {
    @StateObject private var vm = SongSearchViewModel()
    @EnvironmentObject var supabaseManager: SupabaseManager

    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search for songs...", text: $vm.query)
                    .padding()
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task { await vm.search() }
                    }
                
                if vm.isLoading {
                    ProgressView().padding()
                }
                
                List(vm.results, id: \.id) { track in
                    HStack {
                        let cover = track.album.coverBig
                        AsyncImage(url: URL(string: cover)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)

                        VStack(alignment: .leading) {
                            Text(track.title)
                                .font(.headline)

                            Text(track.artist.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button {
                            Task {
                                do {
                                    try await vm.addSongToDatabase(track, supabaseManager: supabaseManager)
                                } catch {
                                    print("Error adding song:", error)
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                    
                    .onTapGesture {
                        // Add your open Spotify/Apple Music here if you want
                        print("Tapped:", track.title)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Search Songs")
            .alert("Added!", isPresented: $vm.showAddedAlert) {
                            Button("OK", role: .cancel) {}
            }
        }
    }
}
