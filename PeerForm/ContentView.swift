//
//  ContentView.swift
//  TWI
//
//  Created by Mason Drabik on 9/25/25.
//


import SwiftUI
import UIKit
import Supabase
import Foundation

struct ContentView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    var body: some View {
        if  supabaseManager.profile == nil {
            ProfileSetupView()
        } else {
            HomeView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SupabaseManager.previewInstance)
}
