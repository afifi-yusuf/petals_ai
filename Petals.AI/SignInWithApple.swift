//
//  SignInWithApple.swift
//  Petals.AI
//
//  Created by Rishi Hundia on 19/06/2025.
//

import SwiftUI
import AuthenticationServices

struct SignInWithAppleView: View {
    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: configureRequest,
            onCompletion: handleAuthorization
        )
        .signInWithAppleButtonStyle(.black)
        .frame(width: 280, height: 45)
    }

    func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                print("✅ User ID: \(credential.user)")
                print("📧 Email: \(credential.email ?? "No email")")
                print("👤 Name: \(credential.fullName?.givenName ?? "")")
                // Save user ID securely (e.g., to Keychain)
            }
        case .failure(let error):
            print("❌ Authorization failed: \(error.localizedDescription)")
        }
    }
}
