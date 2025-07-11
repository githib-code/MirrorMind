import Foundation

struct AnalyticsService {
    static func track(event: String, properties: [String: String] = [:]) {
        #if !DEBUG
        // In production, integrate with your analytics SDK
        print("Tracked event: \(event), Properties: \(properties)")
        #endif
    }
    
    static func trackAnalysis(duration: TimeInterval, ratiosCount: Int) {
        let durationSec = String(format: "%.1f", duration)
        track(event: "face_analysis_completed", properties: [
            "duration_sec": durationSec,
            "ratios_count": "\(ratiosCount)",
            "device_model": UIDevice.current.model
        ])
    }
}