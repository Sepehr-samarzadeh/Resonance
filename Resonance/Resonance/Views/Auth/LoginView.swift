//  LoginView.swift
//  Resonance

import SwiftUI
import AuthenticationServices

// MARK: - LoginView

struct LoginView: View {

    // MARK: - Properties

    @State var authViewModel: AuthViewModel
    @ScaledMetric(relativeTo: .largeTitle) private var appIconSize: CGFloat = 80

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            headerSection

            Spacer()

            signInSection

            Spacer()
                .frame(height: 60)
        }
        .padding(.horizontal, 32)
        .background(
            LinearGradient(
                colors: [.musicRed.opacity(0.3), .blue.opacity(0.2), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .alert(
            String(localized: "Sign In Error"),
            isPresented: .init(
                get: { authViewModel.errorMessage != nil },
                set: { if !$0 { authViewModel.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            await authViewModel.prepareCachedNonce()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: appIconSize))
                .foregroundStyle(.musicRed)
                .symbolEffect(.pulse, isActive: true)
                .accessibilityHidden(true)

            Text("Resonance")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(String(localized: "Connect through music"))
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Sign In Section

    private var signInSection: some View {
        VStack(spacing: 16) {
            if authViewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding()
            } else {
                SignInWithAppleButton(.signIn) { request in
                    authViewModel.prepareAppleSignInRequest(request)
                } onCompletion: { result in
                    Task {
                        await authViewModel.handleAppleSignIn(result: result)
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    Task {
                        await authViewModel.signInWithGoogle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "g.circle.fill")
                            .font(.title3)
                        Text(String(localized: "Sign in with Google"))
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
