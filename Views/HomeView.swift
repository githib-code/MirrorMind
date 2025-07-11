import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var profile: UserProfile
    @EnvironmentObject var tipsService: DailyTipsService
    @State private var showOnboarding = false
    @State private var showCelebration = false
    @State private var activeSheet: ActiveSheet?
    
    enum ActiveSheet: Identifiable {
        case scan, history, tips, settings
        var id: Int { hashValue }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 30) {
                        // Welcome Header
                        WelcomeHeader()
                        
                        // Daily Tip
                        DailyTipView(tip: tipsService.getTodaysTip())
                        
                        // Quick Actions Grid
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                            ActionCard(
                                title: "New Scan",
                                icon: "camera.fill",
                                color: .blue
                            ) {
                                activeSheet = .scan
                            }
                            
                            ActionCard(
                                title: "History",
                                icon: "clock.fill",
                                color: .purple
                            ) {
                                activeSheet = .history
                            }
                            
                            ActionCard(
                                title: "Beauty Tips",
                                icon: "lightbulb.fill",
                                color: .yellow
                            ) {
                                activeSheet = .tips
                            }
                            
                            ActionCard(
                                title: "Settings",
                                icon: "gearshape.fill",
                                color: .gray
                            ) {
                                activeSheet = .settings
                            }
                        }
                        .padding(.horizontal)
                        
                        // Progress Section
                        ProgressSection()
                        
                        // Recent Scans
                        RecentScansSection()
                    }
                    .padding(.vertical)
                }
                .background(Color.darkBackground.ignoresSafeArea())
                .navigationTitle("Home")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { authState.logout() }) {
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                if showCelebration {
                    CelebrationView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .scan:
                FaceScanView()
            case .history:
                HistoryView()
            case .tips:
                TipsView()
            case .settings:
                SettingsView()
            }
        }
        .onAppear {
            profile.loadFromDisk()
            showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            
            // Show celebration if user just subscribed
            if UserDefaults.standard.bool(forKey: "shouldCelebrate") {
                showCelebration = true
                UserDefaults.standard.set(false, forKey: "shouldCelebrate")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showCelebration = false
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isOnboardingComplete: $showOnboarding)
                .onDisappear {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }
        }
    }
    
    @ViewBuilder
    private func WelcomeHeader() -> some View {
        VStack(alignment: .leading) {
            Text("Hello,")
                .font(.largeTitle.bold())
            Text(authState.userEmail ?? "Beautiful")
                .font(.title)
                .foregroundColor(.purple)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top)
    }
    
    @ViewBuilder
    private func ProgressSection() -> some View {
        let completionRate = profile.scanHistory.count > 0 ? 
            Double(profile.scanHistory.count) / 7.0 : 0
        
        return VStack(alignment: .leading) {
            Text("Weekly Progress")
                .font(.headline)
            
            Gauge(value: completionRate, in: 0...1) {
                Text("Scans")
            } currentValueLabel: {
                Text("\(profile.scanHistory.count)/7")
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                Text("7")
            }
            .gaugeStyle(.linearCapacity)
            .tint(completionRate >= 1 ? .green : .blue)
            
            Text(completionRate >= 1 ? 
                 "🎉 Perfect week completed!" :
                 "Complete \(7 - profile.scanHistory.count) more scans this week")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func RecentScansSection() -> some View {
        if !profile.scanHistory.isEmpty {
            VStack(alignment: .leading) {
                Text("Recent Scans")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(profile.scanHistory.prefix(5)) { scan in
                            ScanThumbnail(scan: scan)
                        }
                    }
                    .padding(.horizontal, 5)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ScanThumbnail: View {
    let scan: UserProfile.ScanResult
    
    var body: some View {
        VStack {
            if let imageData = scan.imageData,
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: 1)
                    )
            } else {
                Image(systemName: "face.smiling")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .padding(20)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Text(scan.formattedDate)
                .font(.caption2)
        }
    }
}