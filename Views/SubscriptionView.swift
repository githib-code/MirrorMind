import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showFeaturePreview = false  // Added for ASO
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Existing preserved
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.yellow)
                
                Text("Unlock MirrorMind Pro")
                    .font(.title.bold())
                
                Text("Get personalized facial ratio analysis and improvement plans")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            
            // Added for ASO
            Button("See Premium Feature Preview") {
                showFeaturePreview = true
            }
            .padding(.top, 10)
            
            // Existing preserved
            VStack(spacing: 16) {
                if let product = subscriptionManager.products.first {
                    SubscriptionCard(product: product)
                } else {
                    ProgressView()
                }
                
                Text("Cancel anytime. Payment will be charged to your Apple ID account.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Existing preserved
            Button("Restore Purchases") {
                subscriptionManager.restorePurchases()
            }
            .foregroundColor(.blue)
            .padding(.bottom)
        }
        .padding()
        .background(Color.darkBackground.ignoresSafeArea())
        .sheet(isPresented: $showFeaturePreview) {
            PremiumFeaturePreview()
        }
        .onChange(of: subscriptionManager.isSubscribed) {
            if $0 { dismiss() }
        }
    }
    
    // Existing preserved
    struct SubscriptionCard: View {
        let product: SKProduct
        @EnvironmentObject var subscriptionManager: SubscriptionManager
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(product.localizedTitle)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(product.localizedPrice ?? "")
                        .font(.title2.bold())
                }
                
                Text("Full feature access")
                    .foregroundColor(.gray)
                
                Button("Subscribe with Apple Pay") {
                    subscriptionManager.purchase(product: product)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
        }
    }
    
    // Added for ASO
    struct PremiumFeaturePreview: View {
        var body: some View {
            VStack(spacing: 20) {
                Text("3D Face Morphing")
                    .font(.title.bold())
                
                Text("Visualize how small changes would enhance your facial harmony")
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
                    // Would close this and show subscription options
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

// Existing preserved
extension SKProduct {
    var localizedPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)
    }
}