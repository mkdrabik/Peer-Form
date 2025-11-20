//
//  SupabaseManager.swift
//  TWI
//
//  Created by Mason Drabik on 9/28/25.
//
import Supabase
import SwiftUI
import Combine
import Firebase

final class SupabaseManager: ObservableObject {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    static let shared = SupabaseManager()
    let client: SupabaseClient
    @Published var profile: Profile? = nil
    @Published var avatarURL: URL? = nil
    @Published var isLoadingProfile = false
    @Published var followingCount: Int = 0
    @Published var followersCount: Int = 0
    @Published var stats: WorkoutStats?
    @Published var didPreloadPosts = false
    @Published var didPreloadAchievements = false
    
    init() {
            guard let url = Bundle.main.url(forResource: "SupabaseKeys", withExtension: "plist"),
                  let data = try? Data(contentsOf: url),
                  let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
                  let supabaseURL = plist["url"] as? String,
                  let supabaseAnonKey = plist["key"] as? String
            else {
                fatalError("❌ Missing or invalid SupabaseKeys.plist file")
            }
            
            self.client = SupabaseClient(
                supabaseURL: URL(string: supabaseURL)!,
                supabaseKey: supabaseAnonKey
            )
        }
    func deleteFcmToken(id: UUID) async {
            await appDelegate.deleteFcmToken(id: id)
    }
    func fetchProfile() async throws {
        isLoadingProfile = true
        defer { isLoadingProfile = false }
        do {
            let response = try await client
                .from("profiles")
                .select("*")
                .eq("email", value: self.client.auth.currentUser?.email)
                .single()
                .execute()
            
            let data = response.data
            
            let decoder = JSONDecoder()
            let profile = try decoder.decode(Profile.self, from: data)
            self.profile = profile
            try await self.fetchAvatarURL()
            if let token = Messaging.messaging().fcmToken{
                await appDelegate.upsertFcmToken(token)
            }
            isLoadingProfile = false
            await refreshWorkoutStats()
        } catch {
            self.profile = nil
            isLoadingProfile = false
        }
        isLoadingProfile = false
    }
    
    func refreshWorkoutStats() async {
          guard let profile = profile else { return }
          do {
              let s = try await fetchWorkoutStats(for: profile.id)
              stats = WorkoutStats(
                  yearly_count: s.year,
                  monthly_count: s.month,
                  weekly_count: s.week
              )
          } catch {
              print("❌ Failed to refresh workout stats: \(error)")
          }
      }
    
    func fetchAvatarURL() async throws {
        if self.profile == nil {
            _ = try? await fetchProfile()
        }
        guard let path = self.profile?.avatar_url else { return }
        
//        let signedUrlResponse = try await client.storage
//            .from("avatars")
//            .createSignedURL(path: path, expiresIn: 60 * 60)
        let url = try self.client.storage.from("avatars").getPublicURL(path: path)
        self.avatarURL = url
    }
    
    func fetchFollowersCount() async {
            do {
                let response = try await client
                    .from("follows")
                    .select("follower_id", count: .exact)
                    .eq("following_id", value: profile?.id)
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
    
    func fetchFollowingCount() async {
            do {
                let response = try await client
                    .from("follows")
                    .select("following_id", count: .exact)
                    .eq("follower_id", value: profile?.id)
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
    
    func fetchWorkoutStats(for userId: UUID) async throws -> (year: Int, month: Int, week: Int) {
        let response = try await client
            .rpc("fetch_workout_stats", params: ["uid": userId.uuidString])
            .execute()

        let decoded = try JSONDecoder().decode([WorkoutStats].self, from: response.data)

        let stats = decoded.first ?? WorkoutStats(yearly_count: 0, monthly_count: 0, weekly_count: 0)
        return (stats.yearly_count, stats.monthly_count, stats.weekly_count)
    }
    
    static let previewInstance: SupabaseManager = {
            let manager = SupabaseManager()
            manager.profile = Profile.preview
            return manager
        }()
}


