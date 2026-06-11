//
//  Models.swift
//  Nomad
//

import Foundation
import SwiftData

enum PostcardStatus: String, Codable {
    case draft, sent, received
}

@Model
final class User {
    var id: String
    var username: String
    var avatarData: Data?
    var createdAt: Date

    init(id: String, username: String, avatarData: Data? = nil, createdAt: Date = .now) {
        self.id = id
        self.username = username
        self.avatarData = avatarData
        self.createdAt = createdAt
    }
}

@Model
final class PostcardCollection {
    var id: UUID
    var name: String
    var desc: String?
    var createdAt: Date
    var coverImageData: Data?
    
    @Relationship(deleteRule: .nullify, inverse: \Postcard.collections)
    var postcards: [Postcard]?
    
    init(id: UUID = UUID(), name: String, desc: String? = nil, createdAt: Date = .now, coverImageData: Data? = nil) {
        self.id = id
        self.name = name
        self.desc = desc
        self.createdAt = createdAt
        self.coverImageData = coverImageData
    }
}

@Model
final class Postcard {
    var id: UUID
    var rawImageData: Data
    var renderedImageData: Data?
    var thumbnailData: Data?
    var locationName: String
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var message: String?
    var stampTheme: String
    var statusRaw: String
    var recipientUsername: String?
    var senderUsername: String?
    var fontStyleRaw: String
    var stateName: String?
    var countryName: String?
    var countryCode: String?
    var isFavorite: Bool
    
    // Weather data
    var weatherCondition: String?  // "Sunny", "Cloudy", "Rainy", etc.
    var temperature: Double?       // in Celsius
    var weatherIcon: String?       // SF Symbol name
    
    @Relationship(deleteRule: .nullify)
    var collections: [PostcardCollection]?

    var status: PostcardStatus {
        get { PostcardStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var fontStyle: PostcardFontStyle {
        get { PostcardFontStyle(rawValue: fontStyleRaw) ?? .casual }
        set { fontStyleRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        rawImageData: Data,
        renderedImageData: Data? = nil,
        locationName: String,
        latitude: Double,
        longitude: Double,
        timestamp: Date = .now,
        message: String? = nil,
        stampTheme: String = "city",
        status: PostcardStatus = .draft,
        recipientUsername: String? = nil,
        senderUsername: String? = nil,
        fontStyle: PostcardFontStyle = .casual,
        stateName: String? = nil,
        countryName: String? = nil,
        countryCode: String? = nil,
        isFavorite: Bool = false,
        weatherCondition: String? = nil,
        temperature: Double? = nil,
        weatherIcon: String? = nil
    ) {
        self.id = id
        self.rawImageData = rawImageData
        self.renderedImageData = renderedImageData
        self.thumbnailData = ImageCompressor.generateThumbnail(from: rawImageData, size: 150)
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.message = message
        self.stampTheme = stampTheme
        self.statusRaw = status.rawValue
        self.recipientUsername = recipientUsername
        self.senderUsername = senderUsername
        self.fontStyleRaw = fontStyle.rawValue
        self.stateName = stateName
        self.countryName = countryName
        self.countryCode = countryCode
        self.isFavorite = isFavorite
        self.weatherCondition = weatherCondition
        self.temperature = temperature
        self.weatherIcon = weatherIcon
    }
}

enum PostcardFontStyle: String, Codable, CaseIterable, Identifiable {
    case casual, classic
    var id: String { rawValue }
    var label: String {
        switch self {
        case .casual: return "Casual"
        case .classic: return "Classic"
        }
    }
}
