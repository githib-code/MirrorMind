struct ResultsDashboard: View {
    let ratios: [FacialRatio]
    @State private var selectedRatio: FacialRatio?
    @State private var showCelebration = false
    @State private var motivationalMessage = ""
    
    var idealFeaturesCount: Int {
        ratios.filter { $0.priority == .ideal }.count
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        // Hero Section
                        VStack(spacing: 20) {
                            Text("Your Beauty Analysis")
                                .font(.largeTitle.bold())
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            if idealFeaturesCount > ratios.count / 3 {
                                Text("🌟 You're naturally beautiful!")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                            } else {
                                Text("✨ You have unique features!")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                            }
                            
                            Gauge(value: Double(idealFeaturesCount), in: 0...Double(ratios.count)) {
                                Text("Ideal Features")
                            } currentValueLabel: {
                                Text("\(idealFeaturesCount)/\(ratios.count)")
                            } minimumValueLabel: {
                                Text("0")
                            } maximumValueLabel: {
                                Text("\(ratios.count)")
                            }
                            .gaugeStyle(.accessoryCircularCapacity)
                            .tint(.green)
                            .scaleEffect(1.5)
                            .padding()
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                        // Features Sections
                        FeatureSection(
                            title: "Your Strengths",
                            ratios: ratios.filter { $0.priority == .ideal },
                            color: .green,
                            icon: "checkmark.seal.fill"
                        )
                        
                        FeatureSection(
                            title: "Enhancement Opportunities",
                            ratios: ratios.filter { $0.priority == .couldBeBetter },
                            color: .blue,
                            icon: "sparkles"
                        )
                        
                        FeatureSection(
                            title: "Focus Areas",
                            ratios: ratios.filter { $0.priority == .needsImprovement },
                            color: .orange,
                            icon: "target"
                        )
                    }
                    .padding()
                }
                .background(Color.darkBackground.ignoresSafeArea())
                .navigationTitle("Your Results")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(item: $selectedRatio) { ratio in
                    RatioDetailView(ratio: ratio)
                }
            }
            
            if showCelebration {
                CelebrationView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showCelebration = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showCelebration = false
                    }
                }
            }
        }
    }
}

struct FeatureSection: View {
    let title: String
    let ratios: [FacialRatio]
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.title2.bold())
            }
            
            if ratios.isEmpty {
                Text("No features in this category")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170))], spacing: 15) {
                    ForEach(ratios) { ratio in
                        RatioCard(ratio: ratio, color: color)
                            .onTapGesture {
                                selectedRatio = ratio
                            }
                            .bounceOnAppear()
                            .hapticOnTap()
                    }
                }
            }
        }
    }
}