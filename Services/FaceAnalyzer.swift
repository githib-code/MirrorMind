import Vision
import UIKit
import CryptoKit

class FaceAnalyzer {
    private let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
    private let faceDetectionRequest = VNDetectFaceRectanglesRequest()
    private let logger = Logger(subsystem: "com.you.MirrorMind", category: "faceAnalysis")
    
    private let encryptionKey = SymmetricKey(size: .bits256)
    
    enum AnalysisError: Error {
        case noFaceDetected
        case landmarksUnavailable
        case imageConversionFailed
        case ratioCalculationFailed
    }
    
    func analyze(image: UIImage, completion: @escaping (Result<[FacialRatio], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(AnalysisError.imageConversionFailed))
            return
        }
        
        // Performance optimization: Downsample large images
        let processedImage: UIImage
        if image.size.width * image.size.height > 8_000_000 {
            processedImage = downsample(image: image, to: CGSize(width: 2000, height: 2000))
        } else {
            processedImage = image
        }
        
        guard let processedCGImage = processedImage.cgImage else {
            completion(.failure(AnalysisError.imageConversionFailed))
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: processedCGImage, orientation: .up, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([self.faceDetectionRequest, self.faceLandmarksRequest])
                
                guard let face = self.faceDetectionRequest.results?.first,
                      let landmarks = self.faceLandmarksRequest.results?.first?.landmarks else {
                    throw AnalysisError.noFaceDetected
                }
                
                let landmarkPoints = self.extractLandmarkPoints(from: landmarks, in: face.boundingBox)
                var ratios = self.analyzeRatios(with: landmarkPoints)
                
                // Privacy: Encrypt sensitive landmark data
                for index in ratios.indices {
                    ratios[index].encryptedLandmarks = try self.encryptLandmarks(landmarkPoints)
                }
                
                // Sort by deviation (most deviated first)
                ratios.sort { $0.deviation > $1.deviation }
                
                DispatchQueue.main.async {
                    completion(.success(ratios))
                }
                
            } catch {
                self.logger.error("Face analysis failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func downsample(image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private func encryptLandmarks(_ landmarks: [String: CGPoint]) throws -> Data {
        let data = try JSONEncoder().encode(landmarks)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        return sealedBox.combined!
    }
    
    private func extractLandmarkPoints(from landmarks: VNFaceLandmarks2D, in boundingBox: CGRect) -> [String: CGPoint] {
        var points = [String: CGPoint]()
        
        // Extract all landmarks as in your original implementation
        // Jawline (17 points)
        if let jawPoints = landmarks.jawLine?.normalizedPoints {
            for (index, point) in jawPoints.enumerated() {
                points["j\(index+1)"] = denormalize(point, for: boundingBox)
            }
        }
        
        // Left eyebrow (5 points)
        if let leftEyebrowPoints = landmarks.leftEyebrow?.normalizedPoints {
            for (index, point) in leftEyebrowPoints.enumerated() {
                points["eb_l\(index+1)"] = denormalize(point, for: boundingBox)
            }
        }
        
        // Right eyebrow (5 points)
        if let rightEyebrowPoints = landmarks.rightEyebrow?.normalizedPoints {
            for (index, point) in rightEyebrowPoints.enumerated() {
                points["eb_r\(index+1)"] = denormalize(point, for: boundingBox)
            }
        }
        
        // Nose (9 points)
        if let nosePoints = landmarks.nose?.normalizedPoints {
            for (index, point) in nosePoints.enumerated() {
                points["n\(index+1)"] = denormalize(point, for: boundingBox)
            }
        }
        
        // Nose crest (6 points)
        if let noseCrestPoints = landmarks.noseCrest?.normalizedPoints {
            for (index, point) in noseCrestPoints.enumerated() {
                points["nc\(index+1)"] = denormalize(point, for: boundingBox)
            }
        }
        
        // Median line (11 points)
        if let medianLinePoints = landmarks.medianLine?.normalizedPoints {
            for (index, point) in medianLinePoints.enumerated() {
                points["ml\(index+1)"] = denormalize(point, for: boundingBox)
            }
        }
        
        // Left eye (12 points)
        if let leftEyePoints = landmarks.leftEye?.normalizedPoints {
            for (index, point) in leftEyePoints.enumerated() {
                points["le_l\(index+1)"] = denormalize(point, for: boundingBox)
            }
        }
        
        // Right eye (12 points)
        if let rightEyePoints = landmarks.rightEye?.normalizedPoints {
            for (index, point) in rightEyePoints.enumerated() {
                points["le_r\(index+1)"] = denormalize(point, for: boundingBox)
            }
        }
        
        // Outer lips (12 points)
        if let outerLipsPoints = landmarks.outerLips?.normalizedPoints {
            for (index, point) in outerLipsPoints.enumerated() {
                points["ol\(index+1)"] = denormalize(point, for: boundingBox)
            }
        }
        
        // Inner lips (8 points)
        if let innerLipsPoints = landmarks.innerLips?.normalizedPoints {
            for (index, point) in innerLipsPoints.enumerated() {
                points["il\(index+1)"] = denormalize(point, for: boundingBox)
            }
        }
        
        // Add standard facial landmarks
        if let allPoints = landmarks.allPoints?.normalizedPoints {
            for (index, point) in allPoints.enumerated() {
                points["p\(index)"] = denormalize(point, for: boundingBox)
            }
        }
        
        return points
    }
    
    private func denormalize(_ point: CGPoint, for boundingBox: CGRect) -> CGPoint {
        return CGPoint(
            x: point.x * boundingBox.width + boundingBox.origin.x,
            y: (1 - point.y) * boundingBox.height + boundingBox.origin.y
        )
    }
    
    private func analyzeRatios(with landmarks: [String: CGPoint]) -> [FacialRatio] {
        var results = RatioDatabase.shared.allRatios
        
        for index in results.indices {
            guard let value = calculateRatio(results[index], landmarks: landmarks) else { continue }
            results[index].evaluate(value: value)
        }
        
        return results
    }
    
    private func calculateRatio(_ ratio: FacialRatio, landmarks: [String: CGPoint]) -> Double? {
        // Get all required landmarks
        let requiredLandmarks = ratio.landmarks
        var points = [String: CGPoint]()
        
        for landmark in requiredLandmarks {
            guard let point = landmarks[landmark] else {
                return nil
            }
            points[landmark] = point
        }
        
        // Calculate based on ratio ID
        switch ratio.id {
        // Critical facial ratios (1-50)
        case 1: // Jawline Definition Index
            guard let j1 = points["j1"], let j9 = points["j9"], let j17 = points["j17"] else { return nil }
            let d1 = distance(from: j1, to: j9)
            let d2 = distance(from: j17, to: j9)
            let d3 = distance(from: j1, to: j17)
            return (d1 + d2) / (2 * d3)
            
        case 2: // Chin Projection Ratio
            guard let li = points["li"], let pg = points["pg"], let n = points["n"] else { return nil }
            return distance(li, pg) / distance(pg, n)
            
        case 3: // Mandibular Angle
            guard let j1 = points["j1"], let j9 = points["j9"], let j17 = points["j17"] else { return nil }
            return angle(j1, j9, j17)
            
        case 4: // Facial Width-to-Height Ratio
            guard let zy_r = points["zy_r"], let zy_l = points["zy_l"], let n = points["n"], let gn = points["gn"] else { return nil }
            return distance(zy_r, zy_l) / distance(n, gn)
            
        case 5: // Cheekbone Prominence Index
            guard let zy_r = points["zy_r"], let n = points["n"], let zy_l = points["zy_l"] else { return nil }
            return (distance(zy_r, n) + distance(zy_l, n)) / distance(zy_r, zy_l)
            
        case 6: // Midface Ratio
            guard let n = points["n"], let sn = points["sn"], let gn = points["gn"] else { return nil }
            return distance(n, sn) / distance(sn, gn)
            
        case 7: // Lower Face Proportion
            guard let sn = points["sn"], let gn = points["gn"], let tr = points["tr"], let n = points["n"] else { return nil }
            return distance(sn, gn) / distance(tr, n)
            
        case 8: // Jaw Width-to-Face Ratio
            guard let j1 = points["j1"], let j17 = points["j17"], let zy_r = points["zy_r"], let zy_l = points["zy_l"] else { return nil }
            return distance(j1, j17) / distance(zy_r, zy_l)
            
        case 9: // Chin Width Ratio
            guard let ch_r = points["ch_r"], let ch_l = points["ch_l"], let j1 = points["j1"], let j17 = points["j17"] else { return nil }
            return distance(ch_r, ch_l) / distance(j1, j17)
            
        case 10: // Gonial Angle Width
            guard let j1 = points["j1"], let j9 = points["j9"], let j17 = points["j17"] else { return nil }
            return distance(j1, j9) / distance(j9, j17)
            
        case 11: // Facial Symmetry Index
            guard let j1 = points["j1"], let j17 = points["j17"], let n = points["n"], let gn = points["gn"] else { return nil }
            return 1 - (abs(distance(j1, n) - distance(j17, n)) / distance(j1, j17)
            
        case 12: // Zygomatic Arch Prominence
            guard let zy_r = points["zy_r"], let t_r = points["t_r"], let zy_l = points["zy_l"], let t_l = points["t_l"] else { return nil }
            return (distance(zy_r, t_r) + distance(zy_l, t_l)) / (2 * distance(zy_r, zy_l))
            
        case 13: // Temporal Hollowing Ratio
            guard let t_r = points["t_r"], let t_l = points["t_l"], let zy_r = points["zy_r"], let zy_l = points["zy_l"] else { return nil }
            return distance(t_r, t_l) / distance(zy_r, zy_l)
            
        case 14: // Frontal Bossing Index
            guard let n = points["n"], let g = points["g"], let tr = points["tr"] else { return nil }
            return distance(n, g) / distance(g, tr)
            
        case 15: // Nasofrontal Angle
            guard let g = points["g"], let n = points["n"], let prn = points["prn"] else { return nil }
            return angle(g, n, prn)
            
        case 16: // Nasal Tip Projection
            guard let n = points["n"], let prn = points["prn"], let sn = points["sn"] else { return nil }
            return distance(prn, sn) / distance(n, prn)
            
        case 17: // Nasal Width-to-Length Ratio
            guard let al_r = points["al_r"], let al_l = points["al_l"], let n = points["n"], let sn = points["sn"] else { return nil }
            return distance(al_r, al_l) / distance(n, sn)
            
        case 18: // Nasolabial Angle
            guard let cph = points["cph"], let sn = points["sn"], let ls = points["ls"] else { return nil }
            return angle(cph, sn, ls)
            
        case 19: // Alar Base Width
            guard let al_r = points["al_r"], let al_l = points["al_l"], let en_r = points["en_r"], let en_l = points["en_l"] else { return nil }
            return distance(al_r, al_l) / distance(en_r, en_l)
            
        case 20: // Columella Show Index
            guard let sn = points["sn"], let c = points["c"], let ls = points["ls"] else { return nil }
            return distance(sn, c) / distance(c, ls)
            
        case 21: // Philtrum Length Ratio
            guard let sn = points["sn"], let ls = points["ls"], let n = points["n"], let gn = points["gn"] else { return nil }
            return distance(sn, ls) / distance(n, gn)
            
        case 22: // Upper Lip Protrusion
            guard let sn = points["sn"], let ls = points["ls"], let prn = points["prn"] else { return nil }
            return distance(sn, ls) / distance(prn, sn)
            
        case 23: // Lower Lip Protrusion
            guard let li = points["li"], let pg = points["pg"], let sn = points["sn"] else { return nil }
            return distance(li, pg) / distance(pg, sn)
            
        case 24: // Lip Fullness Index
            guard let ls = points["ls"], let li = points["li"], let sto = points["sto"] else { return nil }
            return distance(ls, sto) / distance(sto, li)
            
        case 25: // Vermilion Height Ratio
            guard let ls = points["ls"], let li = points["li"], let sto = points["sto"] else { return nil }
            return distance(ls, sto) / distance(sto, li)
            
        case 26: // Mentolabial Fold Depth
            guard let li = points["li"], let sl = points["sl"], let pg = points["pg"] else { return nil }
            return distance(li, pg) / distance(sl, pg)
            
        case 27: // Chin Height Ratio
            guard let sl = points["sl"], let gn = points["gn"], let n = points["n"] else { return nil }
            return distance(sl, gn) / distance(n, gn)
            
        case 28: // Chin Projection Index
            guard let li = points["li"], let pg = points["pg"], let n = points["n"] else { return nil }
            return distance(li, pg) / distance(pg, n)
            
        case 29: // Chin Width-to-Jaw Ratio
            guard let ch_r = points["ch_r"], let ch_l = points["ch_l"], let j1 = points["j1"], let j17 = points["j17"] else { return nil }
            return distance(ch_r, ch_l) / distance(j1, j17)
            
        case 30: // Chin-Neck Angle
            guard let pg = points["pg"], let gn = points["gn"], let me = points["me"] else { return nil }
            return angle(pg, gn, me)
            
        case 31: // Intercanthal Width
            guard let en_r = points["en_r"], let en_l = points["en_l"], let ex_r = points["ex_r"], let ex_l = points["ex_l"] else { return nil }
            return distance(en_r, en_l) / distance(ex_r, ex_l)
            
        case 32: // Palpebral Fissure Height
            guard let ps_up = points["ps_up"], let ps_dn = points["ps_dn"], let n = points["n"], let gn = points["gn"] else { return nil }
            return distance(ps_up, ps_dn) / distance(n, gn)
            
        case 33: // Eye Spacing Index
            guard let en_r = points["en_r"], let en_l = points["en_l"], let eye_r = points["eye_r"], let eye_l = points["eye_l"] else { return nil }
            return distance(en_r, en_l) / (distance(eye_r, eye_l) - distance(en_r, en_l))
            
        case 34: // Canthal Tilt Angle
            guard let ex_r = points["ex_r"], let en_r = points["en_r"], let ex_l = points["ex_l"], let en_l = points["en_l"] else { return nil }
            return (angle(ex_r, en_r) + angle(ex_l, en_l)) / 2
            
        case 35: // Eyebrow Position Index
            guard let eb_up = points["eb_up"], let ps_up = points["ps_up"], let n = points["n"], let gn = points["gn"] else { return nil }
            return distance(eb_up, ps_up) / distance(n, gn)
            
        case 36: // Eyebrow Arch Peak Position
            guard let eb_med = points["eb_med"], let eb_peak = points["eb_peak"], let eb_lat = points["eb_lat"] else { return nil }
            return distance(eb_med, eb_peak) / distance(eb_peak, eb_lat)
            
        case 37: // Eyebrow Thickness Index
            guard let eb_up = points["eb_up"], let eb_dn = points["eb_dn"], let n = points["n"], let gn = points["gn"] else { return nil }
            return distance(eb_up, eb_dn) / distance(n, gn)
            
        case 38: // Orbital Width-to-Height
            guard let ex_r = points["ex_r"], let en_r = points["en_r"], let ps_up = points["ps_up"], let ps_dn = points["ps_dn"] else { return nil }
            return distance(ex_r, en_r) / distance(ps_up, ps_dn)
            
        case 39: // Upper Eyelid Show
            guard let mr_up = points["mr_up"], let ps_up = points["ps_up"], let n = points["n"], let gn = points["gn"] else { return nil }
            return distance(mr_up, ps_up) / distance(n, gn)
            
        case 40: // Lower Eyelid Position
            guard let ir_dn = points["ir_dn"], let ps_dn = points["ps_dn"], let n = points["n"], let gn = points["gn"] else { return nil }
            return distance(ir_dn, ps_dn) / distance(n, gn)
            
        case 41: // Nasal Tip Angle
            guard let n = points["n"], let prn = points["prn"], let sn = points["sn"] else { return nil }
            return angle(n, prn, sn)
            
        case 42: // Nasal Tip Rotation
            guard let cph = points["cph"], let sn = points["sn"], let prn = points["prn"] else { return nil }
            return angle(cph, sn, prn)
            
        case 43: // Nasal Base Width
            guard let al_r = points["al_r"], let al_l = points["al_l"], let n = points["n"], let sn = points["sn"] else { return nil }
            return distance(al_r, al_l) / distance(n, sn)
            
        case 44: // Nasal Length-to-Face Ratio
            guard let n = points["n"], let sn = points["sn"], let tr = points["tr"], let gn = points["gn"] else { return nil }
            return distance(n, sn) / distance(tr, gn)
            
        case 45: // Nasal Dorsum Angle
            guard let n = points["n"], let r = points["r"], let prn = points["prn"] else { return nil }
            return angle(n, r, prn)
            
        case 46: // Nasal Tip Definition
            guard let prn = points["prn"], let c = points["c"], let sn = points["sn"] else { return nil }
            return distance(prn, c) / distance(c, sn)
            
        case 47: // Alar-Columellar Relationship
            guard let al_r = points["al_r"], let ac_r = points["ac_r"], let al_l = points["al_l"], let ac_l = points["ac_l"] else { return nil }
            return (distance(al_r, ac_r) + distance(al_l, ac_l)) / (2 * distance(al_r, al_l))
            
        case 48: // Nasal Sidewall Angle
            guard let n = points["n"], let r = points["r"], let al_r = points["al_r"], let al_l = points["al_l"] else { return nil }
            return (angle(n, r, al_r) + angle(n, r, al_l)) / 2
            
        case 49: // Nasal Tip Projection Index
            guard let n = points["n"], let prn = points["prn"], let sn = points["sn"] else { return nil }
            return distance(prn, sn) / distance(n, prn)
            
        case 50: // Nasal Tip Width Ratio
            guard let prn = points["prn"], let d_r = points["d_r"], let d_l = points["d_l"], let sn = points["sn"] else { return nil }
            return distance(d_r, d_l) / distance(prn, sn)
            
        // Continued in next part...
                // Facial ratios (51-100)
        case 51: // Upper Lip Height
            guard let sn = points["sn"], let ls = points["ls"], let n = points["n"], let gn = points["gn"] else { return nil }
            return distance(sn, ls) / distance(n, gn)
            
        case 52: // Lower Lip Height
            guard let li = points["li"], let sl = points["sl"], let n = points["n"], let gn = points["gn"] else { return nil }
            return distance(li, sl) / distance(n, gn)
            
        case 53: // Lip Chin Balance
            guard let sn = points["sn"], let ls = points["ls"], let li = points["li"], let sl = points["sl"] else { return nil }
            return distance(sn, ls) / distance(li, sl)
            
        case 54: // Vermilion Border Fullness
            guard let ls = points["ls"], let cph = points["cph"], let li = points["li"], let sl = points["sl"] else { return nil }
            return (distance(ls, cph) + distance(li, sl)) / (2 * distance(cph, sl))
            
        case 55: // Lip Projection Index
            guard let sn = points["sn"], let ls = points["ls"], let prn = points["prn"] else { return nil }
            return distance(sn, ls) / distance(prn, sn)
            
        case 56: // Mouth Width Ratio
            guard let ch_r = points["ch_r"], let ch_l = points["ch_l"], let zy_r = points["zy_r"], let zy_l = points["zy_l"] else { return nil }
            return distance(ch_r, ch_l) / distance(zy_r, zy_l)
            
        case 57: // Smile Index
            guard let ch_r = points["ch_r"], let ch_l = points["ch_l"], let ls = points["ls"], let li = points["li"] else { return nil }
            return distance(ch_r, ch_l) / distance(ls, li)
            
        case 58: // Dental Show Ratio
            guard let ls = points["ls"], let sto = points["sto"], let li = points["li"] else { return nil }
            return distance(ls, sto) / distance(sto, li)
            
        case 59: // Lip Incompetence Index
            guard let ls = points["ls"], let li = points["li"], let sto = points["sto"] else { return nil }
            return distance(ls, li) / distance(sto, li)
            
        case 60: // Mentolabial Angle
            guard let li = points["li"], let sl = points["sl"], let pg = points["pg"] else { return nil }
            return angle(li, sl, pg)
            
        case 61: // Chin Projection Balance
            guard let li = points["li"], let pg = points["pg"], let n = points["n"] else { return nil }
            return distance(li, pg) / distance(pg, n)
            
        case 62: // Chin-Neck Length Ratio
            guard let gn = points["gn"], let me = points["me"], let n = points["n"] else { return nil }
            return distance(gn, me) / distance(n, gn)
            
        case 63: // Submental Length
            guard let gn = points["gn"], let me = points["me"], let n = points["n"] else { return nil }
            return distance(gn, me) / distance(n, gn)
            
        case 64: // Cervicomental Angle
            guard let pg = points["pg"], let gn = points["gn"], let me = points["me"] else { return nil }
            return angle(pg, gn, me)
            
        case 65: // Thyroid Angle
            guard let gn = points["gn"], let me = points["me"], let hy = points["hy"] else { return nil }
            return angle(gn, me, hy)
            
        case 66: // Facial Harmony Index
            guard let tr = points["tr"], let n = points["n"], let gn = points["gn"] else { return nil }
            return distance(tr, n) / distance(n, gn)
            
        case 67: // Facial Thirds Balance
            guard let tr = points["tr"], let n = points["n"], let sn = points["sn"], let gn = points["gn"] else { return nil }
            let d1 = distance(tr, n)
            let d2 = distance(n, sn)
            let d3 = distance(sn, gn)
            return min(d1, d2, d3) / max(d1, d2, d3)
            
        case 68: // Midface Harmony Ratio
            guard let n = points["n"], let sn = points["sn"], let gn = points["gn"] else { return nil }
            return distance(n, sn) / distance(sn, gn)
            
        case 69: // Lower Face Harmony Ratio
            guard let sn = points["sn"], let gn = points["gn"], let me = points["me"] else { return nil }
            return distance(sn, gn) / distance(gn, me)
            
        case 70: // Facial Profile Angle
            guard let tr = points["tr"], let n = points["n"], let pg = points["pg"] else { return nil }
            return angle(tr, n, pg)
            
        case 71: // Nasofacial Angle
            guard let n = points["n"], let prn = points["prn"], let pg = points["pg"] else { return nil }
            return angle(n, prn, pg)
            
        case 72: // Nasomental Angle
            guard let n = points["n"], let prn = points["prn"], let pg = points["pg"] else { return nil }
            return angle(n, prn, pg)
            
        case 73: // Mentocervical Angle
            guard let pg = points["pg"], let gn = points["gn"], let me = points["me"] else { return nil }
            return angle(pg, gn, me)
            
        case 74: // Total Facial Convexity
            guard let tr = points["tr"], let n = points["n"], let pg = points["pg"] else { return nil }
            return angle(tr, n, pg)
            
        case 75: // Mandibular Plane Angle
            guard let j1 = points["j1"], let j17 = points["j17"], let gn = points["gn"] else { return nil }
            return angle(j1, gn, j17)
            
        case 76: // Facial Taper Index
            guard let zy_r = points["zy_r"], let zy_l = points["zy_l"], let j1 = points["j1"], let j17 = points["j17"] else { return nil }
            return distance(j1, j17) / distance(zy_r, zy_l)
            
        case 77: // Cheekbone Fullness Index
            guard let zy_r = points["zy_r"], let n = points["n"], let zy_l = points["zy_l"] else { return nil }
            return (distance(zy_r, n) + distance(zy_l, n)) / distance(zy_r, zy_l)
            
        case 78: // Orbital Vector Index
            guard let ex_r = points["ex_r"], let en_r = points["en_r"], let ps_up = points["ps_up"], let ps_dn = points["ps_dn"] else { return nil }
            return distance(ex_r, en_r) / distance(ps_up, ps_dn)
            
        case 79: // Eyebrow Tail Position
            guard let eb_med = points["eb_med"], let eb_peak = points["eb_peak"], let eb_lat = points["eb_lat"] else { return nil }
            return distance(eb_med, eb_peak) / distance(eb_peak, eb_lat)
            
        case 80: // Nasal Sidewall Curvature
            guard let n = points["n"], let r = points["r"], let al_r = points["al_r"], let al_l = points["al_l"] else { return nil }
            return (distance(n, r) + distance(r, al_r) + distance(r, al_l)) / (2 * distance(al_r, al_l))
            
        case 81: // Lip Chin Height Ratio
            guard let sn = points["sn"], let ls = points["ls"], let li = points["li"], let sl = points["sl"] else { return nil }
            return distance(sn, ls) / distance(li, sl)
            
        case 82: // Upper Lip Curvature
            guard let sn = points["sn"], let ls = points["ls"], let sto = points["sto"] else { return nil }
            return distance(sn, sto) / distance(sto, ls)
            
        case 83: // Lower Lip Curvature
            guard let sto = points["sto"], let li = points["li"], let sl = points["sl"] else { return nil }
            return distance(sto, sl) / distance(sl, li)
            
        case 84: // Chin Projection Symmetry
            guard let ch_r = points["ch_r"], let pg = points["pg"], let ch_l = points["ch_l"] else { return nil }
            return distance(ch_r, pg) / distance(pg, ch_l)
            
        case 85: // Jawline Symmetry Index
            guard let j1 = points["j1"], let j9 = points["j9"], let j17 = points["j17"] else { return nil }
            return distance(j1, j9) / distance(j9, j17)
            
        case 86: // Cheekbone Symmetry Index
            guard let zy_r = points["zy_r"], let n = points["n"], let zy_l = points["zy_l"] else { return nil }
            return distance(zy_r, n) / distance(zy_l, n)
            
        case 87: // Eye Symmetry Index
            guard let en_r = points["en_r"], let ex_r = points["ex_r"], let en_l = points["en_l"], let ex_l = points["ex_l"] else { return nil }
            return distance(en_r, ex_r) / distance(en_l, ex_l)
            
        case 88: // Eyebrow Symmetry Index
            guard let eb_med_r = points["eb_med_r"], let eb_peak_r = points["eb_peak_r"], let eb_med_l = points["eb_med_l"], let eb_peak_l = points["eb_peak_l"] else { return nil }
            return distance(eb_med_r, eb_peak_r) / distance(eb_med_l, eb_peak_l)
            
        case 89: // Nasal Symmetry Index
            guard let n = points["n"], let prn = points["prn"], let al_r = points["al_r"], let al_l = points["al_l"] else { return nil }
            return distance(prn, al_r) / distance(prn, al_l)
            
        case 90: // Lip Symmetry Index
            guard let cph = points["cph"], let ch_r = points["ch_r"], let ch_l = points["ch_l"] else { return nil }
            return distance(cph, ch_r) / distance(cph, ch_l)
            
        case 91: // Facial Golden Ratio (Vertical)
            guard let tr = points["tr"], let n = points["n"], let gn = points["gn"] else { return nil }
            return distance(tr, n) / distance(n, gn)
            
        case 92: // Facial Golden Ratio (Horizontal)
            guard let zy_r = points["zy_r"], let n = points["n"], let zy_l = points["zy_l"] else { return nil }
            return distance(zy_r, n) / distance(n, zy_l)
            
        case 93: // Eye Golden Ratio
            guard let en_r = points["en_r"], let ps_up = points["ps_up"], let ex_r = points["ex_r"] else { return nil }
            return distance(en_r, ps_up) / distance(ps_up, ex_r)
            
        case 94: // Nasal Golden Ratio
            guard let n = points["n"], let r = points["r"], let prn = points["prn"] else { return nil }
            return distance(n, r) / distance(r, prn)
            
        case 95: // Lip Golden Ratio
            guard let cph = points["cph"], let ls = points["ls"], let sto = points["sto"] else { return nil }
            return distance(cph, ls) / distance(ls, sto)
            
        case 96: // Facial Harmony Score
            guard let tr = points["tr"], let n = points["n"], let sn = points["sn"], let gn = points["gn"] else { return nil }
            return (distance(tr, n)/distance(n, sn) + distance(n, sn)/distance(sn, gn)) / 2
            
        case 97: // Profile Harmony Index
            guard let tr = points["tr"], let n = points["n"], let pg = points["pg"], let gn = points["gn"] else { return nil }
            return (distance(tr, n)/distance(n, pg) + distance(n, pg)/distance(pg, gn)) / 2
            
        case 98: // Frontal Symmetry Score
            guard let j1 = points["j1"], let j17 = points["j17"], let zy_r = points["zy_r"], let zy_l = points["zy_l"], 
                  let en_r = points["en_r"], let en_l = points["en_l"] else { return nil }
            return (distance(j1, zy_r)/distance(j17, zy_l) + distance(zy_r, en_r)/distance(zy_l, en_l)) / 2
            
        case 99: // Dynamic Balance Index
            guard let tr = points["tr"], let n = points["n"], let sn = points["sn"], 
                  let j1 = points["j1"], let j17 = points["j17"], let zy_r = points["zy_r"], let zy_l = points["zy_l"] else { return nil }
            return (distance(tr, n)/distance(n, sn) + distance(j1, j17)/distance(zy_r, zy_l)) / 2
            
        case 100: // Overall Facial Proportion Index
            guard let tr = points["tr"], let n = points["n"], let sn = points["sn"], let gn = points["gn"],
                  let zy_r = points["zy_r"], let zy_l = points["zy_l"], let j1 = points["j1"], let j17 = points["j17"] else { return nil }
            return (distance(tr, gn)/distance(zy_r, zy_l) + distance(n, sn)/distance(sn, gn)) / 2
            
        default:
            return nil
        }
    }
    
    // Geometry helper functions
    private func distance(from p1: CGPoint, to p2: CGPoint) -> Double {
        return sqrt(pow(Double(p1.x - p2.x), 2) + pow(Double(p1.y - p2.y), 2))
    }
    
    private func angle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let ab = distance(from: a, to: b)
        let bc = distance(from: b, to: c)
        let ac = distance(from: a, to: c)
        return acos((ab*ab + bc*bc - ac*ac) / (2 * ab * bc)) * 180 / .pi
    }
}