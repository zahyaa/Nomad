//
//  CameraManager.swift
//  Nomad
//

import AVFoundation
import SwiftUI
import UIKit

@Observable
@MainActor
final class CameraManager: NSObject {
    enum Status {
        case unknown, authorized, denied, restricted
    }

    var status: Status = .unknown
    var isUsingFrontCamera: Bool = false
    var lastError: String?

    nonisolated let session = AVCaptureSession()
    nonisolated let photoOutput = AVCapturePhotoOutput()
    nonisolated let sessionQueue = DispatchQueue(label: "nomad.camera.session")

    // MUST only be accessed on sessionQueue
    private var videoInput: AVCaptureDeviceInput?
    private var didConfigure = false
    
    // Keyed by photo settings uniqueID to support concurrent captures
    private var captureCompletions: [Int64: (UIImage?) -> Void] = [:]

    override init() {
        super.init()
        Task { await refreshAuthorizationStatus() }
    }

    func refreshAuthorizationStatus() async {
        // iOS aborts the process if we call `requestAccess` without the
        // `NSCameraUsageDescription` key in Info.plist. Guard so we degrade
        // gracefully instead of crashing in dev builds.
        guard Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil else {
            status = .denied
            lastError = "Add NSCameraUsageDescription to Info.plist."
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            status = .authorized
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            status = granted ? .authorized : .denied
        case .denied:
            status = .denied
        case .restricted:
            status = .restricted
        @unknown default:
            status = .denied
        }
    }

    func start() {
        guard status == .authorized else { return }
        let session = self.session
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !session.isRunning {
                self.configureSessionIfNeeded()
                session.startRunning()
            }
        }
    }

    func stop() {
        let session = self.session
        sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    func toggleCamera() {
        let wasFront = isUsingFrontCamera
        let session = self.session
        sessionQueue.async { [weak self] in
            guard let self else { return }
            session.beginConfiguration()
            defer { session.commitConfiguration() }

            // videoInput is accessed only on sessionQueue
            if let current = self.videoInput {
                session.removeInput(current)
            }

            let position: AVCaptureDevice.Position = wasFront ? .back : .front
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return }

            session.addInput(input)
            self.videoInput = input
            Task { @MainActor [weak self] in
                self?.isUsingFrontCamera.toggle()
            }
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard status == .authorized else {
            completion(nil)
            return
        }
        let photoOutput = self.photoOutput
        sessionQueue.async { [weak self] in
            guard let self else {
                Task { @MainActor in completion(nil) }
                return
            }
            self.configureSessionIfNeeded()
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto
            
            Task { @MainActor [weak self] in
                self?.captureCompletions[settings.uniqueID] = completion
            }
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MUST be called on sessionQueue only
    private func configureSessionIfNeeded() {
        // didConfigure and videoInput are accessed only on sessionQueue
        guard !didConfigure else { return }
        let session = self.session
        let photoOutput = self.photoOutput
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            Task { @MainActor [weak self] in
                self?.lastError = "Unable to access camera."
            }
            return
        }
        if session.canAddInput(input) {
            session.addInput(input)
            videoInput = input
        }
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        didConfigure = true
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        let data = photo.fileDataRepresentation()
        let image = data.flatMap { UIImage(data: $0) }
        let uniqueID = photo.resolvedSettings.uniqueID
        
        Task { @MainActor [weak self] in
            guard let completion = self?.captureCompletions.removeValue(forKey: uniqueID) else { return }
            completion(image)
        }
    }
}
