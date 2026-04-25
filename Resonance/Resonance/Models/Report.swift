//  Report.swift
//  Resonance

import Foundation

// MARK: - Report

/// A user-submitted report of objectionable content or abusive behavior.
/// Reports are written to the `reports` Firestore collection and are
/// read-only from the client (only Cloud Functions / admin SDK can read them).
struct Report: Identifiable, Codable, Sendable {
    var id: String?
    var reporterId: String
    var reportedUserId: String
    var contextType: ContextType
    var contextId: String?
    var reason: Reason
    var details: String?
    var createdAt: Date
    var status: Status

    // MARK: - Memberwise Init

    init(
        id: String? = nil,
        reporterId: String,
        reportedUserId: String,
        contextType: ContextType,
        contextId: String? = nil,
        reason: Reason,
        details: String? = nil,
        createdAt: Date,
        status: Status
    ) {
        self.id = id
        self.reporterId = reporterId
        self.reportedUserId = reportedUserId
        self.contextType = contextType
        self.contextId = contextId
        self.reason = reason
        self.details = details
        self.createdAt = createdAt
        self.status = status
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, reporterId, reportedUserId, contextType, contextId
        case reason, details, createdAt, status
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        reporterId = try container.decode(String.self, forKey: .reporterId)
        reportedUserId = try container.decode(String.self, forKey: .reportedUserId)
        contextType = try container.decode(ContextType.self, forKey: .contextType)
        contextId = try container.decodeIfPresent(String.self, forKey: .contextId)
        reason = try container.decode(Reason.self, forKey: .reason)
        details = try container.decodeIfPresent(String.self, forKey: .details)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        status = try container.decode(Status.self, forKey: .status)
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(reporterId, forKey: .reporterId)
        try container.encode(reportedUserId, forKey: .reportedUserId)
        try container.encode(contextType, forKey: .contextType)
        try container.encodeIfPresent(contextId, forKey: .contextId)
        try container.encode(reason, forKey: .reason)
        try container.encodeIfPresent(details, forKey: .details)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(status, forKey: .status)
    }

    // MARK: - ContextType

    enum ContextType: String, Codable, Sendable {
        case profile
        case chatMessage
        case match
    }

    // MARK: - Reason

    enum Reason: String, Codable, Sendable, CaseIterable, Identifiable {
        case spam
        case harassment
        case inappropriateContent
        case impersonation
        case underage
        case other

        var id: String { rawValue }

        var localizedTitle: String {
            switch self {
            case .spam: String(localized: "Spam or scam")
            case .harassment: String(localized: "Harassment or bullying")
            case .inappropriateContent: String(localized: "Inappropriate content")
            case .impersonation: String(localized: "Impersonation")
            case .underage: String(localized: "User appears underage")
            case .other: String(localized: "Other")
            }
        }
    }

    // MARK: - Status

    enum Status: String, Codable, Sendable {
        case open
        case reviewed
        case actioned
        case dismissed
    }
}
