//  BlockedUsersView.swift
//  Resonance

import SwiftUI

// MARK: - BlockedUsersView

/// Displays the list of users the current user has blocked,
/// with the ability to unblock each one.
struct BlockedUsersView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State private var blockedUsers: [ResonanceUser] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    let currentUserId: String

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if blockedUsers.isEmpty {
                ContentUnavailableView(
                    String(localized: "No Blocked Users"),
                    systemImage: "hand.raised.slash",
                    description: Text(String(localized: "Users you block will appear here."))
                )
            } else {
                List {
                    ForEach(blockedUsers) { user in
                        blockedUserRow(user)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Blocked Users"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadBlockedUsers() }
        .alert(
            String(localized: "Error"),
            isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Row

    private func blockedUserRow(_ user: ResonanceUser) -> some View {
        HStack(spacing: 12) {
            ProfilePhotoView(photoURL: user.photoURL, size: 44)

            Text(user.displayName)
                .font(.subheadline.weight(.medium))

            Spacer()

            Button(String(localized: "Unblock")) {
                Task { await unblockUser(user) }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.red)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Data Loading

    private func loadBlockedUsers() async {
        isLoading = true
        do {
            let ids = try await services.moderationService.fetchBlockedUserIds(for: currentUserId)
            blockedUsers = try await services.moderationService.fetchUsers(ids: ids)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func unblockUser(_ user: ResonanceUser) async {
        guard let userId = user.id else { return }
        do {
            try await services.moderationService.unblockUser(
                currentUserId: currentUserId,
                blockedUserId: userId
            )
            withAnimation {
                blockedUsers.removeAll { $0.id == userId }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
