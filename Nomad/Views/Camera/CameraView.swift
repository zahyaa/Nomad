//
//  CameraView.swift
//  Nomad
//

import SwiftUI
import PhotosUI
import UIKit

struct CameraView: View {
    @State private var manager = CameraManager()
    @State private var pickerItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    var onCapture: (UIImage) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let image = capturedImage {
                photoPreview(image)
            } else {
                cameraInterface
            }
        }
        .task {
            await manager.refreshAuthorizationStatus()
            manager.start()
        }
        .onDisappear { manager.stop() }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    capturedImage = image
                }
                pickerItem = nil
            }
        }
    }
    
    private var cameraInterface: some View {
        Group {
            switch manager.status {
            case .authorized:
                cameraLive
            case .denied, .restricted:
                permissionDenied
            case .unknown:
                ProgressView().tint(.white)
            }
        }
    }
    
    private func photoPreview(_ image: UIImage) -> some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                HStack(spacing: 20) {
                    Button {
                        capturedImage = nil
                    } label: {
                        Label("Retake", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.glass)
                    
                    Button {
                        onCapture(image)
                        capturedImage = nil
                    } label: {
                        Label("Use Photo", systemImage: "checkmark")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.glassProminent)
                }
                .padding(.bottom, 40)
            }
        }
    }

    private var cameraLive: some View {
        ZStack {
            CameraPreviewView(session: manager.session)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button {
                        manager.toggleCamera()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.glass)
                    .padding(.trailing)
                }
                Spacer()
                HStack(alignment: .center) {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .glassEffect(.clear.interactive(), in: Circle())
                    }
                    Spacer()
                    captureButton
                    Spacer()
                    Color.clear.frame(width: 50, height: 50)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
    }

    private var captureButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            manager.capturePhoto { image in
                if let image {
                    capturedImage = image
                }
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 72, height: 72)
                Circle()
                    .fill(Color.white)
                    .frame(width: 58, height: 58)
            }
        }
        .accessibilityLabel("Capture photo")
    }

    private var permissionDenied: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.7))
            Text("Camera access needed")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Enable camera access in Settings to capture your moments.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 32)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)

            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Pick from Library", systemImage: "photo.on.rectangle")
            }
            .foregroundStyle(.white)
            .padding(.top, 8)
        }
        .padding()
    }
}
