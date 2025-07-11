import Foundation
import CryptoKit  // Added for encryption

class UserProfile: ObservableObject {
    @Published var scanHistory: [ScanResult] = []
    @Published var favoriteTips: [DailyTip] = []
    
    // New: Encryption key for privacy protection
    private let encryptionKey: SymmetricKey = {
        // In production, store this in Keychain
        return SymmetricKey(size: .bits256)
    }()
    
    struct ScanResult: Identifiable, Codable {
        let id: UUID
        let date: Date
        let ratios: [FacialRatio]
        let imageData: Data?  // Consider encrypting this too in production
        
        // Added accessibility support
        var accessibilitySummary: String {
            let topFeatures = ratios.prefix(3).map { $0.name }.joined(separator: ", ")
            return "Scan from \(formattedDate). Top features: \(topFeatures)"
        }
        
        // Existing preserved exactly
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    // Existing preserved exactly
    func addScanResult(_ result: ScanResult) {
        scanHistory.append(result)
        saveToDisk()
    }
    
    // Modified to add encryption
    private func saveToDisk() {
        do {
            let encoded = try JSONEncoder().encode(scanHistory)
            let sealedBox = try AES.GCM.seal(encoded, using: encryptionKey)
            UserDefaults.standard.set(sealedBox.combined, forKey: "encryptedScanHistory")
        } catch {
            print("Encryption failed: \(error)")
        }
    }
    
    // Modified to add decryption
    func loadFromDisk() {
        guard let combined = UserDefaults.standard.data(forKey: "encryptedScanHistory"),
              let sealedBox = try? AES.GCM.SealedBox(combined: combined),
              let decrypted = try? AES.GCM.open(sealedBox, using: encryptionKey),
              let decoded = try? JSONDecoder().decode([ScanResult].self, from: decrypted) else {
            return
        }
        scanHistory = decoded
    }
}