//
//  FollowersViewModel.swift
//  TWEE
//
//  Created by Mason Drabik on 10/11/25.
//

import Foundation
import Supabase
import Combine

@MainActor
final class FriendProfileViewModel: ObservableObject {
    @Published var followers: [Profile] = []
    @Published var following: [Profile] = []
    @Published var followersCount = 0
    @Published var followingCount = 0
    @Published var stats: WorkoutStats?
    @Published var days = 30
    
    func fetchFollowers(for userId: UUID, supabaseManager: SupabaseManager) async throws {
        do {
            let response = try await supabaseManager.client
                .from("follows")
                .select("follower_id, profiles!follower_id(id, username, avatar_url, first_name, last_name)")
                .eq("following_id", value: userId.uuidString)
                .execute()
            
            let decoder = JSONDecoder()
            let rows = try decoder.decode([FollowRow].self, from: response.data)
            var updatedProfiles: [Profile] = []
            for var profile in rows.map({ $0.profiles }) {
                        if let avatarPath = profile.avatar_url {
                        let url = try supabaseManager.client.storage.from("avatars").getPublicURL(path: avatarPath)
//                        let url = try await supabaseManager.client.storage
//                                .from("avatars")
//                                .createSignedURL(path: avatarPath, expiresIn: 3600)
                            profile.avatar_url = url.absoluteString
                        }
                updatedProfiles.append(profile)
            }
            self.followers = updatedProfiles
            self.followersCount = self.followers.count
        } catch {
            print("Error finding followers", error)
        }
    }
    
    func fetchFollowersCount(supabaseManager: SupabaseManager, userId: UUID) async {
            do {
                let response = try await supabaseManager.client
                    .from("follows")
                    .select("follower_id", count: .exact)
                    .eq("following_id", value: userId.uuidString)
                    .execute()
                
                if let count = response.count {
                    self.followersCount = count
                } else {
                    self.followersCount = 0
                }
            } catch {
                print("❌ Error fetching followers count:", error)
                self.followersCount = 0
            }
        }
    
    
    func fetchFollowingCount(supabaseManager: SupabaseManager, userId: UUID) async {
            do {
                let response = try await supabaseManager.client
                    .from("follows")
                    .select("following_id", count: .exact)
                    .eq("follower_id", value: userId.uuidString)
                    .execute()
                
                if let count = response.count {
                    self.followingCount = count
                } else {
                    self.followingCount = 0
                }
            } catch {
                print("❌ Error fetching following count:", error)
                self.followersCount = 0
            }
        }

    func fetchFollowing(for userId: UUID, supabaseManager: SupabaseManager) async throws {
        do {
            let response = try await supabaseManager.client
                .from("follows")
                .select("profiles!following_id(id, username, avatar_url, first_name, last_name)")
                .eq("follower_id", value: userId.uuidString)
                .execute()
            let decoder = JSONDecoder()
            let rows = try decoder.decode([FollowRow].self, from: response.data)
            var updatedProfiles: [Profile] = []
            for var profile in rows.map({ $0.profiles }) {
                        if let avatarPath = profile.avatar_url {
                        let url = try supabaseManager.client.storage.from("avatars").getPublicURL(path: avatarPath)
//                        let url = try await supabaseManager.client.storage
//                                .from("avatars")
//                                .createSignedURL(path: avatarPath, expiresIn: 3600)
                            profile.avatar_url = url.absoluteString
                        }
                updatedProfiles.append(profile)
            }
            self.following = updatedProfiles
            self.followingCount = self.following.count
        } catch{
            print("Error finding following ", error)
        }
    }
    func daysInCurrentMonth() {
        let calendar = Calendar.current
        let date = Date()
        guard let range = calendar.range(of: .day, in: .month, for: date) else {
            days = 30
            return
        }
        days = range.count
    }

}
