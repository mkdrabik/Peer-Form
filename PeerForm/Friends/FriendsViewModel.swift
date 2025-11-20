//
//  FriendsViewModel.swift
//  TWEE
//
//  Created by Mason Drabik on 10/2/25.
//
import Foundation
import Combine
import Supabase

//@MainActor
//class FriendsViewModel: ObservableObject {
//    @Published var searchQuery: String = ""
//    @Published var searchResults: [Profile] = []
//    @Published var isLoading = false
//    
//    
//    func searchUsers(supabaseManager: SupabaseManager) async {
//        guard !searchQuery.isEmpty else { return }
//        isLoading = true
//        do {
//            let response = try await supabaseManager.client
//                .from("profiles")
//                .select()
//                .ilike("username", pattern: "%\(searchQuery)%")
//                .neq("username", value: supabaseManager.profile?.username ?? "")
//                .execute()
//            
//            let data = response.data
//            let profiles = try JSONDecoder().decode([Profile].self, from: data)
//            self.searchResults = profiles
//            
//        } catch {
//            print("Error searching users: \(error)")
//        }
//        isLoading = false
//    }
//}

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var allUsers: [Profile] = []
    @Published var searchQuery: String = "" {
        didSet { filterUsers() }
    }
    @Published var filteredResults: [Profile] = []
    @Published var isLoading = false

    func loadAllUsers(supabaseManager: SupabaseManager) async {
        isLoading = true
        do {
            let response = try await supabaseManager.client
                .from("profiles")
                .select()
                .neq("username", value: supabaseManager.profile?.username ?? "")
                .execute()
            
            let data = response.data
            let profiles = try JSONDecoder().decode([Profile].self, from: data)
            self.allUsers = profiles
            self.filteredResults = profiles
        } catch {
            print("❌ Error loading all users:", error)
        }
        isLoading = false
    }

    private func filterUsers() {
        let query = searchQuery.lowercased()
        if query.isEmpty {
            filteredResults = allUsers
        } else {
            filteredResults = allUsers.filter { user in
                user.username.lowercased().contains(query)
            }
        }
    }
}

