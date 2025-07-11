import FirebaseAuth
import Combine

class AuthState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userEmail: String?
    @Published var authError: AuthError?
    private var cancellables = Set<AnyCancellable>()
    
    // New: Offline support
    private let networkMonitor = NetworkMonitor.shared
    
    // Existing enum preserved exactly
    enum AuthError: Error, Identifiable {
        case loginFailed(String)
        case signupFailed(String)
        case offlineModeUnavailable  // New case
        case unknownError
        
        var id: String { localizedDescription }
        var localizedDescription: String {
            switch self {
            case .loginFailed(let msg): return "Login failed: \(msg)"
            case .signupFailed(let msg): return "Signup failed: \(msg)"
            case .offlineModeUnavailable: return "Offline mode not available"
            case .unknownError: return "Unknown error occurred"
            }
        }
    }
    
    // Modified init for offline support
    init() {
        // Check for cached credentials
        if let cachedEmail = UserDefaults.standard.string(forKey: "cachedUserEmail") {
            self.isLoggedIn = true
            self.userEmail = cachedEmail
        }
        
        // Existing preserved
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            if let user = user {
                self.isLoggedIn = true
                self.userEmail = user.email
                UserDefaults.standard.set(user.email, forKey: "cachedUserEmail")
            } else if !self.networkMonitor.isConnected {
                // Maintain offline state
                self.isLoggedIn = true
            } else {
                self.isLoggedIn = false
                self.userEmail = nil
                UserDefaults.standard.removeObject(forKey: "cachedUserEmail")
            }
        }
    }
    
    // Modified for offline support
    func login(email: String, password: String) async {
        do {
            if networkMonitor.isConnected {
                try await Auth.auth().signIn(withEmail: email, password: password)
            } else {
                // Offline mode: Check cached credentials
                if email == UserDefaults.standard.string(forKey: "cachedUserEmail") {
                    isLoggedIn = true
                    userEmail = email
                } else {
                    throw AuthError.offlineModeUnavailable
                }
            }
        } catch {
            handleAuthError(error)
        }
    }
    
    // Modified for offline support
    func signup(email: String, password: String) async {
        guard networkMonitor.isConnected else {
            authError = .offlineModeUnavailable
            return
        }
        
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            handleAuthError(error)
        }
    }
    
    // Existing preserved exactly
    private func handleAuthError(_ error: Error) {
        if let authError = error as? AuthErrorCode {
            switch authError.code {
            case .wrongPassword, .invalidEmail, .userDisabled:
                authError = .loginFailed(authError.localizedDescription)
            case .emailAlreadyInUse, .weakPassword:
                authError = .signupFailed(authError.localizedDescription)
            default:
                authError = .unknownError
            }
        } else {
            authError = .unknownError
        }
    }
    
    // Existing preserved exactly
    func logout() {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "cachedUserEmail")  // Added
        } catch {
            authError = .unknownError
        }
    }
}