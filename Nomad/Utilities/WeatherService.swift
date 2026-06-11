//
//  WeatherService.swift
//  Nomad
//

import Foundation
import CoreLocation
import WeatherKit

@available(iOS 16.0, *)
enum WeatherService {
    /// Fetches current weather for a location
    static func fetchWeather(for coordinate: CLLocationCoordinate2D) async throws -> (condition: String, temperature: Double, icon: String) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let weather = try await WeatherKit.WeatherService.shared.weather(for: location)
            let current = weather.currentWeather
            
            let condition = current.condition.description
            let temperature = current.temperature.value // Celsius
            let icon = symbolName(for: current.condition)
            
            return (condition, temperature, icon)
        } catch {
            // Fallback to basic weather info
            return ("Unknown", 20.0, "cloud")
        }
    }
    
    /// Maps WeatherCondition to SF Symbol name
    private static func symbolName(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .mostlyClear:
            return "cloud.sun.fill"
        case .mostlyCloudy:
            return "cloud.sun.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .rain:
            return "cloud.rain.fill"
        case .drizzle:
            return "cloud.drizzle.fill"
        case .heavyRain:
            return "cloud.heavyrain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .sleet:
            return "cloud.sleet.fill"
        case .hail:
            return "cloud.hail.fill"
        case .freezingDrizzle, .freezingRain:
            return "cloud.sleet.fill"
        case .flurries:
            return "cloud.snow.fill"
        case .windy, .breezy:
            return "wind"
        case .foggy, .haze, .smoky:
            return "cloud.fog.fill"
        case .blowingDust:
            return "sun.dust.fill"
        case .hot:
            return "sun.max.fill"
        case .frigid:
            return "snowflake"
        case .hurricane, .tropicalStorm:
            return "hurricane"
        case .blizzard:
            return "wind.snow"
        case .blowingSnow:
            return "wind.snow"
        case .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms, .thunderstorms:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud"
        }
    }
}
