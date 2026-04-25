//  MatchDetailView.swift
//  Resonance

import SwiftUI
import OSLog

// MARK: - MatchDetailView

struct MatchDetailView: View {

    // MARK: - Properties

    let match: Match
    let currentUserId: String
    var onBlockUser: ((String) -> Void)?

    @Environment(\.services) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var otherUser: ResonanceUser?
    @State private var didLoadUser = false
    @State private var chatViewModel: ChatViewModel?
    @State private var showReportSheet = false
    @State private var showBlockConfirmation = false
    @State private var showMessageReportSheet = false
    @State private var reportMessageId: String?
    @State private var errorMessage: String?

    private var otherUserId: String? {
        match.userIds.first { $0 != currentUserId }
    }

    private var otherUserName: String {
        otherUser?.displayName ?? (didLoadUser ? String(localized: "Resonance User") : String(localized: "Match"))
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let chatViewModel {
                detailContent(chatViewModel: chatViewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showReportSheet = true
                    } label: {
                        Label(String(localized: "Report User"), systemImage: "exclamationmark.triangle")
                    }

                    Button(role: .destructive) {
                        showBlockConfirmation = true
                    } label: {
                        Label(String(localized: "Block User"), systemImage: "hand.raised")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel(String(localized: "More options"))
                }
            }
        }
        .sheet(isPresented: $showReportSheet) {
            if let otherUserId {
                ReportSheet(
                    reportedUserId: otherUserId,
                    contextType: .profile,
                    currentUserId: currentUserId
                )
            }
        }
        .sheet(isPresented: $showMessageReportSheet) {
            if let otherUserId, let reportMessageId {
                ReportSheet(
                    reportedUserId: otherUserId,
                    contextType: .chatMessage,
                    contextId: reportMessageId,
                    currentUserId: currentUserId
                )
            }
        }
        .confirmationDialog(
            String(localized: "Block \(otherUserName)?"),
            isPresented: $showBlockConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Block"), role: .destructive) {
                Task {
                    guard let otherUserId else { return }
                    do {
                        try await services.moderationService.blockUser(
                            currentUserId: currentUserId,
                            blockedUserId: otherUserId
                        )
                        onBlockUser?(otherUserId)
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        } message: {
            Text(String(localized: "You won't see their messages or profile again."))
        }
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
        .task {
            if chatViewModel == nil {
                chatViewModel = ChatViewModel(chatService: services.chatService)
            }

            guard let otherUserId = match.userIds.first(where: { $0 != currentUserId }) else {
                didLoadUser = true
                return
            }
            do {
                otherUser = try await services.userService.fetchUser(userId: otherUserId)
            } catch {
                Log.ui.error("Failed to load other user: \(error.localizedDescription)")
            }
            didLoadUser = true

            if let matchId = match.id {
                await chatViewModel?.listenForMessages(matchId: matchId)
            }
        }
    }

    // MARK: - Detail Content

    @ViewBuilder
    private func detailContent(chatViewModel: ChatViewModel) -> some View {
        VStack(spacing: 0) {
            matchInfoHeader

            Divider()

            chatSection(chatViewModel: chatViewModel)
        }
    }

    // MARK: - Match Info Header

    private var matchInfoHeader: some View {
        VStack(spacing: 12) {
            ProfilePhotoView(
                photoURL: otherUser?.photoURL,
                size: 80
            )

            Text(otherUser?.displayName ?? "")
                .font(.title3)
                .fontWeight(.semibold)

            if let song = match.triggerSong {
                Label(song.name, systemImage: "music.note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let score = match.similarityScore {
                MatchScoreBadge(score: score)
            }
        }
        .padding()
    }

    // MARK: - Chat Section

    @ViewBuilder
    private func chatSection(chatViewModel: ChatViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(chatViewModel.messages) { message in
                        let isOwn = message.senderId == currentUserId
                        ChatBubble(
                            message: message,
                            isFromCurrentUser: isOwn,
                            onDelete: isOwn ? {
                                guard let messageId = message.id else { return }
                                Task {
                                    await chatViewModel.deleteMessage(
                                        matchId: match.id ?? "",
                                        messageId: messageId
                                    )
                                }
                            } : nil,
                            onReport: !isOwn ? {
                                reportMessageId = message.id
                                showMessageReportSheet = true
                            } : nil
                        )
                    }
                }
                .padding()
            }
            .defaultScrollAnchor(.bottom)

            Divider()

            chatInputBar(chatViewModel: chatViewModel)
        }
    }

    // MARK: - Chat Input

    @ViewBuilder
    private func chatInputBar(chatViewModel: ChatViewModel) -> some View {
        @Bindable var vm = chatViewModel
        HStack(spacing: 12) {
            TextField(String(localized: "Message..."), text: $vm.messageText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

            Button {
                guard let matchId = match.id else { return }
                Task {
                    await chatViewModel.sendMessage(matchId: matchId, senderId: currentUserId)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.musicRed)
            }
            .accessibilityLabel(String(localized: "Send message"))
            .disabled(chatViewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
}

// MARK: - ChatBubble

struct ChatBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    var onDelete: (() -> Void)?
    var onReport: (() -> Void)?

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }

            bubbleContent
                .contextMenu {
                    if let onDelete {
                        Button(role: .destructive, action: onDelete) {
                            Label(String(localized: "Delete"), systemImage: "trash")
                        }
                    }
                    if !isFromCurrentUser, let onReport {
                        Button(action: onReport) {
                            Label(String(localized: "Report Message"), systemImage: "exclamationmark.bubble")
                        }
                    }
                }

            if !isFromCurrentUser { Spacer() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            isFromCurrentUser
                ? String(localized: "You: \(message.text)")
                : String(localized: "Them: \(message.text)")
        )
    }

    private var bubbleContent: some View {
        Text(message.text)
            .font(.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isFromCurrentUser ? .musicRed : Color(.systemGray5))
            .foregroundStyle(isFromCurrentUser ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
