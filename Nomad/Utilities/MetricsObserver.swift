//
//  MetricsObserver.swift
//  Nomad
//
//  Subscribes to MetricKit for crash, hang, and diagnostic payloads.
//  The system delivers daily metrics and same-day diagnostics for the
//  previous app launches. We log them through `Log.metrics`, which
//  shows up in Console.app filtered by subsystem during beta triage.
//  Zero third-party dependencies.
//

import Foundation
import MetricKit
import os

final class MetricsObserver: NSObject, MXMetricManagerSubscriber {
    static let shared = MetricsObserver()

    private override init() {
        super.init()
    }

    func start() {
        MXMetricManager.shared.add(self)
        Log.metrics.info("MetricKit subscriber attached")
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            Log.metrics.info("Daily metrics — \(payload.timeStampBegin.formatted(), privacy: .public) to \(payload.timeStampEnd.formatted(), privacy: .public)")
            if let app = payload.applicationLaunchMetrics {
                Log.metrics.info("Launch p50: \(app.histogrammedTimeToFirstDraw.bucketEnumerator.allObjects.count, privacy: .public) buckets")
            }
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            for crash in payload.crashDiagnostics ?? [] {
                Log.metrics.fault("Crash — exception \(crash.exceptionType?.intValue ?? -1, privacy: .public) signal \(crash.signal?.intValue ?? -1, privacy: .public) \(crash.terminationReason ?? "", privacy: .public)")
            }
            for hang in payload.hangDiagnostics ?? [] {
                Log.metrics.fault("Hang — duration \(hang.hangDuration.value, privacy: .public) \(hang.hangDuration.unit.symbol, privacy: .public)")
            }
            for cpu in payload.cpuExceptionDiagnostics ?? [] {
                Log.metrics.error("CPU exception — total \(cpu.totalCPUTime.value, privacy: .public) \(cpu.totalCPUTime.unit.symbol, privacy: .public)")
            }
            for memory in payload.diskWriteExceptionDiagnostics ?? [] {
                Log.metrics.error("Disk write exception — \(memory.totalWritesCaused.value, privacy: .public) writes")
            }
        }
    }
}
