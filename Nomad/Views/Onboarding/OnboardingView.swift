//
//  OnboardingView.swift
//  Nomad
//

import SwiftUI
import AVFoundation
import CoreLocation
import Photos
import SwiftData

struct OnboardingView: View {
    @AppStorage("nomad.onboardingComplete") private var onboardingComplete = false
    @State private var page: Int = 0
    @State private var locationManager = LocationManager()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.indigo.opacity(0.6), .pink.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TabView(selection: $page) {
                welcomePage.tag(0)
                permissionsPage.tag(1)
                AuthView(onComplete: { onboardingComplete = true })
                    .background(Color(uiColor: .systemBackground))
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "envelope.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white)
            Text("Pocket Postcard")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
            Text("Capture a moment. Send a postcard.")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button {
                withAnimation { page = 1 }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glassProminent)
            .tint(.white)
            .foregroundStyle(.indigo)
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }

    private var permissionsPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "camera.metering.matrix")
                .font(.system(size: 64))
                .foregroundStyle(.white)
            Text("Camera & Location")
                .font(.title.bold())
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 16) {
                permissionRow(
                    icon: "camera.fill",
                    title: "Camera Access",
                    description: "Capture beautiful moments to turn into postcards"
                )
                permissionRow(
                    icon: "location.fill",
                    title: "Location",
                    description: "Automatically stamp postcards with where you are"
                )
                permissionRow(
                    icon: "photo.on.rectangle",
                    title: "Photos",
                    description: "Pick library photos and save finished postcards"
                )
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 12)

            Text("You can change these permissions anytime in Settings.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                Task {
                    // Pre-flight all three prompts up front. Asking inside the
                    // onboarding flow (with context above) lifts grant rates
                    // vs. asking at the moment of use, and avoids a permission
                    // popup interrupting the capture flow later.
                    _ = await AVCaptureDevice.requestAccess(for: .video)
                    locationManager.requestUpdate()
                    _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                    withAnimation { page = 2 }
                }
            } label: {
                Text("Allow Access")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glassProminent)
            .tint(.white)
            .foregroundStyle(.indigo)
            .padding(.horizontal, 40)

            Button {
                withAnimation { page = 2 }
            } label: {
                Text("Not now")
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.bottom, 60)
        }
    }
    
    private func permissionRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}
