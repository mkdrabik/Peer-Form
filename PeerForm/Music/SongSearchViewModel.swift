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
    
    func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isLoading = true
        
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
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
    
    func addSongToDatabase(_ track: DeezerTrack, supabaseManager: SupabaseManager) async throws {
        guard let user = supabaseManager.client.auth.currentUser else { return }
        
        let song = SongInsert(
               user_id: user.id,
               title: track.title,
               artist: track.artist.name,
               cover_url: track.album.coverBig
           )
        
        try await supabaseManager.client
            .from("songs")
            .insert(song)
            .execute()
        
        showAddedAlert = true

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
}
