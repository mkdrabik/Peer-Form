//
//  CreatePostView.swift
//  TWEE
//
//  Created by Mason Drabik on 10/10/25.
//

import SwiftUI
import PhotosUI
import Kingfisher
import Storage
import Supabase

struct CreatePostView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @StateObject private var viewModel = CreatePostViewModel()
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var uploadedImageURL: String?

    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                        Picker("Type", selection: $viewModel.postType) {
                            Text("Post").tag("Post")
                            Text("Achievement").tag("Achievement")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                    
                    if let image = viewModel.selectedImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 300)
                                .cornerRadius(16)
                                .clipped()
                                .shadow(radius: 4)
                            
                            Button {
                                withAnimation { viewModel.selectedImage = nil }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .shadow(radius: 3)
                                    .padding(8)
                            }
                        }
                        .transition(.scale)
                    } else {
                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                Text("Tap to select a photo")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 220)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    
                    CameraView(cpvm: viewModel)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $viewModel.caption)
                            .frame(minHeight: 80, maxHeight: 160)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    Button {
                        Task {
                            await viewModel.uploadAndCreatePost(supabaseManager: supabaseManager)
                            dismissKeyboard()
                        }
                    } label: {
                        HStack {
                            if viewModel.isUploading || viewModel.isPosting {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Post")
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isUploading || viewModel.isPosting ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                    }
                    .disabled(viewModel.isUploading || viewModel.isPosting)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding()
                .onTapGesture {
                    dismissKeyboard()
                }
            }
            .navigationTitle("Share")
            .onChange(of: photoPickerItem) { _, newItem in
                Task { await loadImage(from: newItem) }
            }
            .alert(
                viewModel.alertMessage ?? "Post Created!",
                isPresented: $viewModel.showAlert
            ) {
                Button("OK", role: .cancel) {
                    viewModel.alertMessage = nil
                }
            } message: {
                if let _ = viewModel.alertMessage {
                    Text("Please upload a vertical photo.")
                }
            }

        }
    }
    
    func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            if image.size.width > image.size.height {
                        await MainActor.run {
                            viewModel.selectedImage = nil
                            viewModel.showAlert = true
                            viewModel.alertMessage = "Error: Vertical pictures only."
                            viewModel.caption = ""
                        }
                        return
                    }
            await MainActor.run { viewModel.selectedImage = image }
        }
    }
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

#Preview {
    CreatePostView()
        .environmentObject(SupabaseManager.previewInstance)
}
