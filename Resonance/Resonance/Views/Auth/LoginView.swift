//  LoginView.swift
//  Resonance

import SwiftUI
import AuthenticationServices

// MARK: - LoginView

struct LoginView: View {

    // MARK: - Properties

    @State private var viewModel = AuthViewModel()

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
                colors: [.purple.opacity(0.3), .blue.opacity(0.2), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .alert(
            String(localized: "Sign In Error"),
            isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.purple)
                .symbolEffect(.pulse, isActive: true)

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
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding()
            } else {
                SignInWithAppleButton(.signIn) { request in
                    Task {
                        await viewModel.prepareAppleSignInRequest(request)
                    }
                } onCompletion: { result in
                    Task {
                        await viewModel.handleAppleSignIn(result: result)
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    Task {
                        await viewModel.signInWithGoogle()
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
