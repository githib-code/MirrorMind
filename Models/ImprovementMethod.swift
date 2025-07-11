struct ImprovementMethod: Identifiable {
    let id: Int
    let feature: String
    let naturalMethod: String
    let cosmeticMethod: String
    let lifestyleMethod: String
    
    init?(csvRow: [String]) {
        guard csvRow.count >= 4 else { return nil }
        self.id = csvRow[0].hashValue
        self.feature = csvRow[0]
        self.naturalMethod = csvRow[1]
        self.cosmeticMethod = csvRow[2]
        self.lifestyleMethod = csvRow[3]
    }
}