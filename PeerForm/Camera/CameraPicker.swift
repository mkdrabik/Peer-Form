//
//  CameraPicker.swift
//  TWI
//
//  Created by Mason Drabik on 9/25/25.
//

import UIKit
import SwiftUI

struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var onImagePicked: (UIImage) -> Void

    final class PortraitImagePickerController: UIImagePickerController {
        override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
        override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .portrait }
        override var shouldAutorotate: Bool { false }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if UIDevice.current.orientation.isLandscape {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            guard let image = info[.originalImage] as? UIImage else {
                           parent.presentationMode.wrappedValue.dismiss()
                           return
                       }
            if image.size.width > image.size.height {
                        let alert = UIAlertController(
                            title: "Error",
                            message: "Please take a vertical (portrait) photo.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            picker.dismiss(animated: true) {
                                // reopen camera automatically if you want:
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let root = windowScene.windows.first?.rootViewController {
                                    root.present(PortraitImagePickerController(), animated: true)
                                }
                            }
                        })
                        picker.present(alert, animated: true)
                        return
                    }

            parent.onImagePicked(image.fixedOrientation())
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> PortraitImagePickerController {
        let picker = PortraitImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen
        return picker
    }

    func updateUIViewController(_ uiViewController: PortraitImagePickerController, context: Context) {}
}

private extension UIImage {
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized ?? self
    }
}
