////
////  CameraView.swift
////  TWI
////
////  Created by Mason Drabik on 9/25/25.
////
//
//import SwiftUI
//import UIKit
//import Supabase
//import Foundation
//import Kingfisher
//
//struct CameraView: View {
//    @EnvironmentObject var supabaseManager: SupabaseManager
//    var cpvm: CreatePostViewModel
//    @State var showCamera: Bool = false
//
//    var body: some View {
//        VStack(spacing: 20) {
//            Button(action: { showCamera = true }) {
//                Label("Open Camera", systemImage: "camera")
//                    .padding()
//                    .background(Color.blue.opacity(0.8))
//                    .foregroundColor(.white)
//                    .cornerRadius(12)
//            }
//        }
//        .padding()
//        .sheet(isPresented: $showCamera) {
//            CameraPicker { image in
//                cpvm.selectedImage = image
//            }
//        }
//    }
//}
import SwiftUI
import UIKit
import Supabase
import Kingfisher

struct CameraView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    var cpvm: CreatePostViewModel
    @State private var showCamera = false
    
    var body: some View {
        Button {
            showCamera = true
        } label: {
            Label("Open Camera", systemImage: "camera")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 3)
        }
        .padding(.horizontal)
//        .sheet(isPresented: $showCamera) {
//            CameraPicker { image in
//                cpvm.selectedImage = image
//            }
//        }
        .fullScreenCover(isPresented: $showCamera) {
                    CameraPicker { image in
                        cpvm.selectedImage = image
                    }
                    .ignoresSafeArea()
                }
    }
}
