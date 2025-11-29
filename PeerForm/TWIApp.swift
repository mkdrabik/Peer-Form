////
////  TWIApp.swift
////  TWI
////
////  Created by Mason Drabik on 9/24/25.
////
//
//import SwiftUI
//import Supabase
//
//@main
//struct TWIApp: App {
//    @StateObject private var supabaseManager = SupabaseManager()
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate  
//
//    var body: some Scene {
//        WindowGroup {
//            Group {
//                if supabaseManager.isLoadingProfile {
//                    LoadingView()
//                } else if supabaseManager.profile != nil {
//                    HomeView()
//                } else if supabaseManager.client.auth.currentUser != nil && !supabaseManager.isLoadingProfile{
//                    ContentView()
//                } else {
//                    LoginView()
//                }
//            }
//            .animation(.easeInOut(duration: 0.3), value: supabaseManager.isLoadingProfile)
//            .task {
//                supabaseManager.isLoadingProfile = true
//                do {
//                    let _ = try await supabaseManager.client.auth.session
//                    try await supabaseManager.fetchProfile()
//                    supabaseManager.isLoadingProfile = false
//                } catch {
//                    print("Fail")
//                    supabaseManager.isLoadingProfile = false
//                }
//            }
//            .environmentObject(supabaseManager)
//        }
//    }
//}


//
//  TWIApp.swift
//  TWI
//
//  Created by Mason Drabik on 9/24/25.
//

import SwiftUI
import Supabase

@main
struct TWIApp: App {
    @StateObject private var supabaseManager = SupabaseManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var showLoadingView = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showLoadingView || supabaseManager.isLoadingProfile {
                    LoadingView()
                } else if supabaseManager.profile != nil {
                    HomeView()
                } else if supabaseManager.client.auth.currentUser != nil && !supabaseManager.isLoadingProfile {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: supabaseManager.isLoadingProfile)
            .task {
                supabaseManager.isLoadingProfile = true

                let minimumDisplayTime: TimeInterval = 1.5
                let startTime = Date()

                do {
                    let _ = try await supabaseManager.client.auth.session
                    try await supabaseManager.fetchProfile()
                } catch {
                    print("❌ Failed to load session or profile:", error)
                }

                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed < minimumDisplayTime {
                    try? await Task.sleep(nanoseconds: UInt64((minimumDisplayTime - elapsed) * 1_000_000_000))
                }

                supabaseManager.isLoadingProfile = false

                withAnimation(.easeInOut(duration: 0.3)) {
                    showLoadingView = false
                }
            }
            .environmentObject(supabaseManager)
        }
    }
}

