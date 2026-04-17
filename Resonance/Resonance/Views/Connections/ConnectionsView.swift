//  ConnectionsView.swift
//  Resonance

import SwiftUI

// MARK: - ConnectionsSection

enum ConnectionsSection: String, CaseIterable, Identifiable {
    case matches
    case messages

    var id: String { rawValue }

    var title: String {
        switch self {
        case .matches: String(localized: "Matches")
        case .messages: String(localized: "Messages")
        }
    }
}

// MARK: - ConnectionsView

struct ConnectionsView: View {

    // MARK: - Properties

    @State var viewModel: MatchViewModel
    let currentUserId: String
    @State private var selectedSection: ConnectionsSection = .messages

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Picker(String(localized: "Section"), selection: $selectedSection) {
                ForEach(ConnectionsSection.allCases) { section in
                    Text(section.title).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch selectedSection {
            case .matches:
                MatchFeedContent(viewModel: viewModel, currentUserId: currentUserId)
            case .messages:
                ChatListContent(viewModel: viewModel, currentUserId: currentUserId)
            }
        }
        .navigationTitle(String(localized: "Connections"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.listenForMatches(userId: currentUserId)
        }
        .refreshable {
            await viewModel.loadMatches(userId: currentUserId)
        }
        .alert(
            String(localized: "Error"),
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

    // MARK: - Switch to Messages

    /// Programmatically switch to the Messages section (used by deep links).
    func showMessages() {
        selectedSection = .messages
    }
}
