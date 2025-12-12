//
//  SongFeedViewModel.swift
//  PeerForm
//
//  Created by Mason Drabik on 12/12/25.
//
import SwiftUI
import Foundation
import Combine
import Supabase

@MainActor
class SongFeedViewModel: ObservableObject {
    @Published var songs: [SongRow] = []

    struct SongRow: Identifiable, Decodable {
        let id: Int
        let user_id: String
        let title: String
        let artist: String
        let cover_url: String
        let created_at: String
    }

    func loadFeed(supabaseManager: SupabaseManager) async {
        do {
            let response = try await supabaseManager.client
                .from("songs")
                .select("""
                    id,
                    user_id,
                    title,
                    artist,
                    cover_url,
                    created_at
                """)
                .order("created_at", ascending: false)
                .execute()

            let fetchedSongs = try JSONDecoder().decode([SongRow].self, from: response.data)

            DispatchQueue.main.async {
                self.songs = fetchedSongs
            }

        } catch {
            print("Feed load error:", error)
        }
    }
}
