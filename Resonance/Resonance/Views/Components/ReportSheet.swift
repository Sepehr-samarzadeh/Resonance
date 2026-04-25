//  ReportSheet.swift
//  Resonance

import SwiftUI

// MARK: - ReportSheet

/// A sheet that allows users to report objectionable content or abusive users.
/// Presented from chat, user profiles, and discovery feeds.
struct ReportSheet: View {

    // MARK: - Properties

    let reportedUserId: String
    let contextType: Report.ContextType
    let contextId: String?

    @Environment(\.services) private var services
    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason: Report.Reason = .spam
    @State private var details = ""
    @State private var isSubmitting = false
    @State private var didSubmit = false
    @State private var errorMessage: String?

    private let currentUserId: String

    init(
        reportedUserId: String,
        contextType: Report.ContextType,
        contextId: String? = nil,
        currentUserId: String
    ) {
        self.reportedUserId = reportedUserId
        self.contextType = contextType
        self.contextId = contextId
        self.currentUserId = currentUserId
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(String(localized: "Reason"), selection: $selectedReason) {
                        ForEach(Report.Reason.allCases) { reason in
                            Text(reason.localizedTitle).tag(reason)
                        }
                    }
                } header: {
                    Text(String(localized: "Why are you reporting this user?"))
                }

                Section {
                    TextField(
                        String(localized: "Additional details (optional)"),
                        text: $details,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                } header: {
                    Text(String(localized: "Details"))
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(String(localized: "Report User"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Submit")) {
                        Task { await submitReport() }
                    }
                    .disabled(isSubmitting)
                }
            }
            .overlay {
                if didSubmit {
                    reportSubmittedOverlay
                }
            }
            .interactiveDismissDisabled(isSubmitting)
        }
    }

    // MARK: - Submit

    private func submitReport() async {
        isSubmitting = true
        errorMessage = nil

        let report = Report(
            reporterId: currentUserId,
            reportedUserId: reportedUserId,
            contextType: contextType,
            contextId: contextId,
            reason: selectedReason,
            details: details.isEmpty ? nil : details,
            createdAt: Date(),
            status: .open
        )

        do {
            try await services.moderationService.submitReport(report)
            didSubmit = true
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    // MARK: - Confirmation Overlay

    private var reportSubmittedOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text(String(localized: "Report submitted"))
                .font(.headline)
            Text(String(localized: "We'll review this within 24 hours."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
