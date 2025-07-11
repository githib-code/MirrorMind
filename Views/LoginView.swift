import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var authState: AuthState
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "face.dashed")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            Text("MirrorMind")
                .font(.largeTitle.bold())
                .padding(.bottom, 40)
            
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: isSignUp ? signUp : login) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isLoading)
            }
            .padding(.horizontal, 30)
            
            Button(action: toggleAuthMode) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.darkBackground.ignoresSafeArea())
    }
    
    private func login() {
        isLoading = true
        errorMessage = ""
        
        authState.login(email: email, password: password) { result in
            isLoading = false
            switch result {
            case .success: break
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func signUp() {
        isLoading = true
        errorMessage = ""
        
        authState.signup(email: email, password: password) { result in
            isLoading = false
            switch result {
            case .success: break
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func toggleAuthMode() {
        isSignUp.toggle()
        errorMessage = ""
    }
}