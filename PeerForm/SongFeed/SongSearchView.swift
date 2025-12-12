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
                                await vm.addSongToDatabase(track, supabaseManager: supabaseManager)
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Search Songs")
            .alert(" Song Added!", isPresented: $vm.showAddedAlert) {
                            Button("OK", role: .cancel) {}
            }
            .alert("Error", isPresented: $vm.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Song already uploaded (I will fix this later, right now it's just one universal unique list)")
            }
        }
    }
}
