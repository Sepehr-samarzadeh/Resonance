//  ToastModifier.swift
//  Resonance

import SwiftUI

// MARK: - ToastStyle

/// The visual style of a toast notification.
enum ToastStyle: Sendable {
    case success
    case error
    case info

    var iconName: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .error: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .success: .green
        case .error: .red
        case .info: .blue
        }
    }
}

// MARK: - ToastItem

/// Represents a single toast notification.
struct ToastItem: Equatable, Sendable {
    let id = UUID()
    let message: String
    let style: ToastStyle

    static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - ToastView

/// A small banner notification that appears at the top of the screen.
struct ToastView: View {

    let toast: ToastItem
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.style.iconName)
                .font(.body)
                .foregroundStyle(toast.style.tintColor)

            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            Button("Dismiss", systemImage: "xmark", action: onDismiss)
                .font(.caption)
                .foregroundStyle(.secondary)
                .labelStyle(.iconOnly)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - ToastModifier

/// A view modifier that presents a toast notification at the top of the screen.
struct ToastModifier: ViewModifier {

    @Binding var toast: ToastItem?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let currentToast = toast {
                    ToastView(toast: currentToast) {
                        toast = nil
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                    .padding(.top, 8)
                    .task {
                        try? await Task.sleep(for: .seconds(3))
                        toast = nil
                    }
                }
            }
            .animation(.spring(duration: 0.4), value: toast)
    }
}

// MARK: - View Extension

extension View {

    /// Presents a toast notification at the top of the screen.
    func toast(_ toast: Binding<ToastItem?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
