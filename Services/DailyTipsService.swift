import Foundation

class DailyTipsService {
    static let shared = DailyTipsService()
    private let tips: [DailyTip]
    
    init() {
        self.tips = [
            DailyTip(
                title: "Hydration Boost",
                message: "Drink an extra glass of water today for plumper skin",
                icon: "drop.fill",
                color: .blue
            ),
            DailyTip(
                title: "Posture Check",
                message: "Keep your chin parallel to the floor for better jaw definition",
                icon: "figure.stand",
                color: .green
            ),
            DailyTip(
                title: "Facial Massage",
                message: "Gently massage your cheeks upward for better circulation",
                icon: "hand.draw.fill",
                color: .pink
            )
        ]
    }
    
    func getTodaysTip() -> DailyTip {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return tips[day % tips.count]
    }
}

struct DailyTip {
    let title: String
    let message: String
    let icon: String
    let color: Color
}