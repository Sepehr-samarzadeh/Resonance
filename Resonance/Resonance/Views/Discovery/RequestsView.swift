//  RequestsView.swift
//  Resonance

import SwiftUI

// MARK: - RequestsView

/// Shows incoming and outgoing friend requests.
struct RequestsView: View {

    // MARK: - Properties

    @State var viewModel: DiscoveryViewModel
    let currentUserId: String

    // MARK: - Body

    var body: some View {
        List {
            if !viewModel.incomingRequests.isEmpty {
                Section {
                    ForEach(viewModel.incomingRequests) { request in
                        IncomingRequestRow(
                            request: request,
                            senderProfile: viewModel.requestUserProfiles[request.senderId],
                            onAccept: {
                                Task { await viewModel.acceptRequest(request) }
                            },
                            onDecline: {
                                Task { await viewModel.declineRequest(request) }
                            }
                        )
                    }
                } header: {
                    Text(String(localized: "Incoming"))
                }
            }

            if !viewModel.outgoingRequests.isEmpty {
                Section {
                    ForEach(viewModel.outgoingRequests) { request in
                        OutgoingRequestRow(
                            request: request,
                            onCancel: {
                                Task { await viewModel.cancelRequest(request) }
                            }
                        )
                    }
                } header: {
                    Text(String(localized: "Sent"))
                }
            }

            if viewModel.incomingRequests.isEmpty && viewModel.outgoingRequests.isEmpty {
                ContentUnavailableView(
                    String(localized: "No Requests"),
                    systemImage: "person.2.slash",
                    description: Text(String(localized: "Friend requests you send or receive will appear here."))
                )
            }
        }
        .navigationTitle(String(localized: "Requests"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadRequests(userId: currentUserId)
        }
    }
}

// MARK: - IncomingRequestRow

struct IncomingRequestRow: View {
    let request: FriendRequest
    let senderProfile: ResonanceUser?
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ProfilePhotoView(
                photoURL: senderProfile?.photoURL,
                size: 44
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(senderProfile?.displayName ?? String(localized: "Someone"))
                    .font(.subheadline.weight(.medium))

                Text(String(localized: "Wants to connect"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(String(localized: "Accept"), action: onAccept)
                    .buttonStyle(.borderedProminent)
                    .tint(.musicRed)
                    .controlSize(.small)

                Button(String(localized: "Decline"), action: onDecline)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - OutgoingRequestRow

struct OutgoingRequestRow: View {
    let request: FriendRequest
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "paperplane.fill")
                .font(.title3)
                .foregroundStyle(.musicRed)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Request sent"))
                    .font(.subheadline.weight(.medium))

                Text(request.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(String(localized: "Cancel"), action: onCancel)
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)
        }
        .accessibilityElement(children: .combine)
    }
}
