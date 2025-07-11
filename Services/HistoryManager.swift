import UIKit

class HistoryManager {
    static let shared = HistoryManager()
    
    func saveScanImage(_ image: UIImage) -> Data? {
        return image.jpegData(compressionQuality: 0.8)
    }
    
    func loadScanImage(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    func generateComparisonGIF(before: UIImage, after: UIImage, completion: @escaping (URL?) -> Void) {
        // Implementation for creating before/after GIF
        // Would use CGImageDestination and UIImage frames in real implementation
        completion(nil)
    }
}