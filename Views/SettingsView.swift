import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authState: AuthState
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }
                
                Section(header: Text("Account")) {
                    Button(action: {
                        authState.logout()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                    
                    if let email = authState.userEmail {
                        Text("Logged in as \(email)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("About")) {
                    NavigationLink(destination: AboutView()) {
                        Text("About MirrorMind")
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "face.dashed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                
                Text("About MirrorMind")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity)
                
                Text("MirrorMind uses advanced facial analysis to help you understand your unique facial features and proportions. Our technology is based on scientific research in facial aesthetics and golden ratios.")
                    .font(.body)
                
                Text("All processing happens on your device - we never store or transmit your facial data.")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .background(Color.darkBackground.ignoresSafeArea())
        .navigationTitle("About")
    }
}