import SwiftUI

struct ErrorView: View {
    let error: Error
    var retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text("Oops!")
                .font(.largeTitle.bold())
            
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            if let retry = retryAction {
                Button(action: retry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 20)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.darkBackground)
    }
}

// Extension for better error display
extension Error {
    var localizedDescription: String {
        if let localizedError = self as? LocalizedError {
            return localizedError.errorDescription ?? String(describing: self)
        }
        return String(describing: self)
    }
}