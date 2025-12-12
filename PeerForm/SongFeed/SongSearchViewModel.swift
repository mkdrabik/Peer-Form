//
//  MusicViewModel.swift
//  PeerForm
//
//  Created by Mason Drabik on 12/12/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class SongSearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [DeezerTrack] = []
    @Published var isLoading: Bool = false
    @Published var showAddedAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    private var cancellables = Set<AnyCancellable>()

    
    init() {
         $query
             .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
             .removeDuplicates()
             .sink { [weak self] newQuery in
                 Task {
                     await self?.search()
                 }
             }
             .store(in: &cancellables)
     }
    
    func search() async {
            let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
            guard !trimmedQuery.isEmpty else {
                results = []
                return
            }
            
            isLoading = true
            let encoded = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "https://api.deezer.com/search?q=\(encoded)"
            
            guard let url = URL(string: urlString) else {
                isLoading = false
                return
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(DeezerSearchResponse.self, from: data)
                self.results = response.data
            } catch {
                print("Search error:", error)
            }
            isLoading = false
        }
    
    func addSongToDatabase(
        _ track: DeezerTrack,
        supabaseManager: SupabaseManager
    ) async {
        guard let user = supabaseManager.client.auth.currentUser else { return }

        let spotifyURL = "spotify://search/\(track.title.urlEncoded)%20\(track.artist.name.urlEncoded)"
        let appleMusicURL = "music://search?term=\(track.title.urlEncoded)%20\(track.artist.name.urlEncoded)"

        let song = SongInsert(
            user_id: user.id,
            title: track.title,
            artist: track.artist.name,
            cover_url: track.album.coverBig,
            apple_music_url: appleMusicURL,
            spotify_url: spotifyURL
        )
        do{
            try await supabaseManager.client
                .from("songs")
                .insert(song)
                .execute()
            
            // Show alert
            await MainActor.run {
                self.showAddedAlert = true
            }
        } catch {
            errorMessage = "Failed to add song: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}

struct DeezerSearchResponse: Codable {
    let data: [DeezerTrack]
}

struct DeezerTrack: Codable, Identifiable {
    let id: Int
    let title: String
    let artist: DeezerArtist
    var album: DeezerAlbum
}

struct DeezerArtist: Codable {
    let name: String
}

struct DeezerAlbum: Codable {
    let title: String
    let cover: String
    var coverBig: String
    let coverXl: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case cover
        case coverBig = "cover_big"
        case coverXl = "cover_xl"
    }
}

struct SongInsert: Encodable {
    let user_id: UUID
    let title: String
    let artist: String
    let cover_url: String
    let apple_music_url: String
    let spotify_url: String
}
