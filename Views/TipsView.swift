import SwiftUI

struct TipsView: View {
    @EnvironmentObject var tipsService: DailyTipsService
    @State private var savedTips: [DailyTip] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(savedTips.isEmpty ? [tipsService.getTodaysTip()] : savedTips, id: \.title) { tip in
                        TipCard(tip: tip, isSaved: savedTips.contains { $0.title == tip.title }) {
                            if savedTips.contains(where: { $0.title == tip.title }) {
                                savedTips.removeAll { $0.title == tip.title }
                            } else {
                                savedTips.append(tip)
                            }
                        }
                    }
                    
                    if !savedTips.isEmpty {
                        Text("Saved Tips")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                        
                        ForEach(savedTips) { tip in
                            TipCard(tip: tip, isSaved: true) {
                                savedTips.removeAll { $0.title == tip.title }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Beauty Tips")
            .background(Color.darkBackground.ignoresSafeArea())
            .onAppear {
                // Load saved tips from UserDefaults
                if let data = UserDefaults.standard.data(forKey: "savedTips"),
                   let decoded = try? JSONDecoder().decode([DailyTip].self, from: data) {
                    savedTips = decoded
                }
            }
            .onChange(of: savedTips) { newValue in
                // Save to UserDefaults
                if let encoded = try? JSONEncoder().encode(newValue) {
                    UserDefaults.standard.set(encoded, forKey: "savedTips")
                }
            }
        }
    }
}

struct TipCard: View {
    let tip: DailyTip
    let isSaved: Bool
    let onSaveToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: tip.icon)
                    .foregroundColor(tip.color)
                    .imageScale(.large)
                
                Text(tip.title)
                    .font(.headline)
                
                Spacer()
                
                Button(action: onSaveToggle) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isSaved ? tip.color : .gray)
                }
            }
            
            Text(tip.message)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(15)
    }
}