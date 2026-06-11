//
//  UserSettings.swift
//  Nomad
//

import SwiftUI

@Observable
final class UserSettings {
    static let shared = UserSettings()
    
    var photoQuality: PhotoQuality {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: "photoQuality"),
                  let quality = PhotoQuality(rawValue: rawValue) else {
                return .medium
            }
            return quality
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "photoQuality")
        }
    }
    
    private init() {}
}
