//
//  PostcardView.swift
//  Nomad
//

import SwiftUI
import UIKit

struct PostcardView: View {
    let postcard: Postcard

    private var image: UIImage? {
        postcard.cachedImage
    }

    var body: some View {
        ZStack {
            Color.white
            VStack(spacing: 0) {
                photoArea
            }
            .padding(8)
        }
        .aspectRatio(4.0/3.0, contentMode: .fit)
        .background(Color.white)
        .adaptiveShadow(radius: 8, y: 4)
    }

    private var photoArea: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { proxy in
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else {
                    Color.gray.opacity(0.2)
                }

                if let message = postcard.message, !message.isEmpty {
                    VStack {
                        Spacer()
                        Text(message)
                            .font(postcard.fontStyle == .classic
                                  ? .system(.body, design: .serif).weight(.medium)
                                  : .system(.body, design: .rounded).weight(.medium))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [.black.opacity(0.0), .black.opacity(0.55)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
                
                // Weather indicator
                if let weatherIcon = postcard.weatherIcon, let temp = postcard.temperature {
                    VStack {
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: weatherIcon)
                                    .font(.caption2)
                                Text(String(format: "%.0f°C", temp))
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Capsule())
                            .padding(8)
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                }
            }

            StampView(
                locationName: postcard.locationName,
                date: postcard.timestamp,
                themeRaw: postcard.stampTheme,
                stateName: postcard.stateName,
                countryCode: postcard.countryCode
            )
            .padding(10)
        }
    }
}

#Preview {
    let sample = Postcard(
        rawImageData: UIImage(systemName: "photo")?.pngData() ?? Data(),
        locationName: "Austin, USA",
        latitude: 30.27,
        longitude: -97.74,
        message: "Wish you were here ✨",
        stampTheme: "city"
    )
    return PostcardView(postcard: sample)
        .padding()
}
