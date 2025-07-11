import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var profile: UserProfile
    
    var body: some View {
        NavigationView {
            ScrollView {
                if profile.scanHistory.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No scan history yet")
                            .font(.title2)
                        Text("Complete your first scan to see results here")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(profile.scanHistory) { scan in
                            HistoryCard(scan: scan)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Scan History")
            .background(Color.darkBackground.ignoresSafeArea())
        }
    }
}

struct HistoryCard: View {
    let scan: UserProfile.ScanResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(scan.formattedDate)
                    .font(.headline)
                Spacer()
                Text("\(scan.ratios.count) features analyzed")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if let imageData = scan.imageData,
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text("Top features:")
                .font(.subheadline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(scan.ratios.prefix(5)) { ratio in
                        FeaturePill(ratio: ratio)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(15)
    }
}

struct FeaturePill: View {
    let ratio: FacialRatio
    
    var body: some View {
        Text(ratio.name)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(ratio.priorityColor.opacity(0.2))
            .foregroundColor(ratio.priorityColor)
            .cornerRadius(20)
    }
}