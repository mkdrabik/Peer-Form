//
//  Profile.swift
//  TWI
//
//  Created by Mason Drabik on 9/25/25.
//
import SwiftUI

struct Profile: Decodable, Encodable, Identifiable {
    let id: UUID
    let username: String
    let first_name: String
    let last_name: String
    var avatar_url: String?
    
    
    static let preview: Profile = {
            let profile = Profile(id: .init(), username: "deez nuts",first_name: "Mason", last_name: "Drabik", avatar_url: "https://via.placeholder.com/150")
            return profile
    }()
}
struct WorkoutStats: Decodable {
    let yearly_count: Int
    let monthly_count: Int
    let weekly_count: Int
}
