class RatioDatabase {
    static var shared = RatioDatabase()
    private(set) var allRatios: [FacialRatio] = []
    private(set) var improvementMethods: [ImprovementMethod] = []
    
    init() {
        loadRatios()
        loadImprovementMethods()
    }
    
    private func loadRatios() {
        guard let url = Bundle.main.url(forResource: "facial_ratios", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load facial ratios data")
        }
        
        do {
            let decoder = JSONDecoder()
            let wrapper = try decoder.decode(RatioWrapper.self, from: data)
            allRatios = wrapper.ratios
        } catch {
            print("Error decoding ratios: \(error)")
        }
    }
    
    private func loadImprovementMethods() {
        guard let url = Bundle.main.url(forResource: "improvement_methods", withExtension: "csv"),
              let content = try? String(contentsOf: url) else {
            fatalError("Failed to load improvement methods")
        }
        
        let rows = content.components(separatedBy: "\n").dropFirst()
        improvementMethods = rows.compactMap { row in
            let columns = row.components(separatedBy: ",")
            return ImprovementMethod(csvRow: columns)
        }
    }
    
    func getImprovements(for feature: String) -> ImprovementMethod? {
        return improvementMethods.first { $0.feature.lowercased() == feature.lowercased() }
    }
    
    private struct RatioWrapper: Codable {
        let ratios: [FacialRatio]
    }
}