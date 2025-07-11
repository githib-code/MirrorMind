import SwiftUI

struct RatioDetailView: View {
    let ratio: FacialRatio
    @State private var showAppStorePreview = false  // Added for ASO
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Existing preserved
                VStack(alignment: .leading, spacing: 10) {
                    Text(ratio.name)
                        .font(.title.bold())
                    
                    HStack {
                        Text(ratio.priorityDescription)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(ratio.priorityColor.opacity(0.2))
                            .foregroundColor(ratio.priorityColor)
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.2f", ratio.score))")
                            .font(.title.bold())
                        +
                        Text(" vs ideal \(String(format: "%.2f", ratio.ideal)) ±\(String(format: "%.2f", ratio.tolerance))")
                            .font(.subheadline)
                    }
                }
                
                // Existing preserved
                Divider()
                
                // Existing preserved
                VStack(alignment: .leading, spacing: 15) {
                    Text("Ratio Calculation")
                        .font(.headline)
                    
                    Text(ratio.calculation)
                        .font(.body.monospaced())
                    
                    Text("Landmarks: \(ratio.landmarks.joined(separator: ", "))")
                        .font(.caption)
                }
                
                // Existing preserved
                if let improvements = improvements {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Improvement Methods")
                            .font(.headline)
                        
                        ImprovementCard(
                            title: "Natural Methods",
                            description: improvements.naturalMethod,
                            icon: "leaf"
                        )
                        
                        ImprovementCard(
                            title: "Cosmetic Solutions",
                            description: improvements.cosmeticMethod,
                            icon: "wand.and.stars"
                        )
                        
                        ImprovementCard(
                            title: "Lifestyle Adjustments",
                            description: improvements.lifestyleMethod,
                            icon: "figure.walk"
                        )
                    }
                }
                
                // Existing preserved
                Divider()
                
                // Existing preserved
                Text("Reference: \(ratio.reference)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Added for App Store compliance
                Text("Results are aesthetic approximations only")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.top)
                
                Spacer()
            }
            .padding()
            
            // Added for premium preview
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAppStorePreview = true }) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                    }
                    .accessibilityLabel("Preview premium feature")
                }
            }
        }
        .sheet(isPresented: $showAppStorePreview) {
            PremiumFeaturePreview()
        }
    }
    
    // Existing preserved
    private var improvements: ImprovementMethod? {
        RatioDatabase.shared.getImprovements(for: ratio.name)
    }
    
    // Added for ASO
    struct PremiumFeaturePreview: View {
        var body: some View {
            VStack(spacing: 20) {
                Text("3D Face Morphing")
                    .font(.title.bold())
                
                Text("See how small changes would enhance your facial harmony")
                    .multilineTextAlignment(.center)
                
                // Placeholder for premium visualization
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 200)
                
                Text("Subscribe to unlock this premium feature")
                    .font(.headline)
                
                Button("View Subscription Options") {
                    // Would open subscription view
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}