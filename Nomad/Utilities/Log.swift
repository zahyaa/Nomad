//
//  Log.swift
//  Nomad
//
//  Centralized `os.Logger` access. Categories let Console.app + the
//  MetricKit diagnostics surface filter by subsystem during beta
//  triage. Subsystem follows the app's bundle identifier so it shows
//  up under our own process in Console.
//

import Foundation
import os

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "co.winglet.Nomad"

    static let app       = Logger(subsystem: subsystem, category: "app")
    static let camera    = Logger(subsystem: subsystem, category: "camera")
    static let location  = Logger(subsystem: subsystem, category: "location")
    static let cloudKit  = Logger(subsystem: subsystem, category: "cloudkit")
    static let composer  = Logger(subsystem: subsystem, category: "composer")
    static let weather   = Logger(subsystem: subsystem, category: "weather")
    static let storage   = Logger(subsystem: subsystem, category: "storage")
    static let metrics   = Logger(subsystem: subsystem, category: "metrics")
    static let social    = Logger(subsystem: subsystem, category: "social")
}
