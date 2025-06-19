//
//  SignInView.swift
//  Petals.AI
//
//  Created by Rishi Hundia on 14/06/2025.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.05),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Logo and Welcome Text
                VStack(spacing: 16) {
                    Image("icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Text("Welcome to Petals AI")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Your wellness journey starts here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Sign In Button
                VStack(spacing: 16) {
                    Text("Sign in with Google to get started")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    GoogleSignInButton(action: handleSignIn)
                        .frame(width: 280, height: 50)
                        .cornerRadius(25)
                        .shadow(color: .purple.opacity(0.2), radius: 8, x: 0, y: 4)
                    SignInWithAppleView()
                }
            }
            .padding()
        }
    }

    func handleSignIn() {
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("❌ Could not get root VC")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("❌ Sign-in failed: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user else {
                print("❌ No user object returned")
                return
            }

            print("✅ Signed in as: \(user.profile?.email ?? "Unknown email")")

            appState.isSignedIn = true
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
