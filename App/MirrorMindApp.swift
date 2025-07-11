import SwiftUI
import FirebaseCore
import os.log

@main
struct MirrorMindApp: App {
    @StateObject private var authState = AuthState()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var profile = UserProfile()
    @StateObject private var tipsService = DailyTipsService()
    @State private var appError: AppError?
    
    private let logger = Logger(subsystem: "com.you.MirrorMind", category: "app")
    
    enum AppError: Error, Identifiable {
        case firebaseInitFailed
        case configurationError
        
        var id: String { localizedDescription }
        var localizedDescription: String {
            switch self {
            case .firebaseInitFailed: return "Failed to initialize Firebase services"
            case .configurationError: return "App configuration error"
            }
        }
    }
    
    init() {
        do {
            try configureFirebase()
            setupAppearance()
        } catch {
            appError = .firebaseInitFailed
            logger.error("Initialization failed: \(error.localizedDescription)")
        }
    }
    
    private func configureFirebase() throws {
        guard FirebaseApp.app() == nil else { return }
        
        #if DEBUG
        let configFile = "GoogleService-Info-Debug"
        #else
        let configFile = "GoogleService-Info"
        #endif
        
        guard let path = Bundle.main.path(forResource: configFile, ofType: "plist"),
              FirebaseApp.app() == nil else {
            throw AppError.firebaseInitFailed
        }
        
        FirebaseApp.configure()
    }
    
    private func setupAppearance() {
        UITableView.appearance().backgroundColor = .clear
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
    }
    
    var body: some Scene {
        WindowGroup {
            if let error = appError {
                ErrorView(error: error) {
                    // Retry initialization
                    do {
                        try configureFirebase()
                        appError = nil
                    } catch {
                        appError = .firebaseInitFailed
                    }
                }
            } else {
                ContentView()
                    .environmentObject(authState)
                    .environmentObject(subscriptionManager)
                    .environmentObject(profile)
                    .environmentObject(tipsService)
                    .preferredColorScheme(.dark)
            }
        }
    }
}