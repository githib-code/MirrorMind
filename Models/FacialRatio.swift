struct FacialRatio: Identifiable, Codable {
    let id: Int
    let name: String
    let ideal: Double
    let tolerance: Double
    let landmarks: [String]
    let calculation: String
    let reference: String
    
    var score: Double = 0
    var deviation: Double = 0
    var priority: PriorityLevel = .couldBeBetter
    
    enum PriorityLevel: Int, Codable {
        case ideal = 3
        case needsImprovement = 1
        case couldBeBetter = 2
    }
    
    func calculateDeviation(_ value: Double) -> Double {
        return abs(value - ideal) / tolerance
    }
    
    mutating func evaluate(value: Double) {
        self.score = value
        self.deviation = calculateDeviation(value)
        
        if deviation <= 1.0 {
            priority = .ideal
        } else if deviation >= 2.0 {
            priority = .needsImprovement
        } else {
            priority = .couldBeBetter
        }
    }
}