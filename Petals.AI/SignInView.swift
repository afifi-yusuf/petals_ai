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
    var body: some View {
        GoogleSignInButton(action: handleSignIn)
            .frame(width: 220, height: 50)
            .padding()
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
        }
    }
}

#Preview {
    LoginView()
}
