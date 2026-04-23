import SwiftUI

// MARK: - Search Bar

struct MusicPickerSearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

// MARK: - Sharing Overlay

struct SharingOverlay: View {
    let label: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().tint(.white).scaleEffect(1.5)
                Text(label).foregroundColor(.white).font(.caption)
            }
        }
    }
}

// MARK: - Row Selection Background

private struct PickerRowBackground: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.white.opacity(0.15) : Color.gray.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2))
        )
    }
}

extension View {
    func pickerRowBackground(isSelected: Bool) -> some View {
        modifier(PickerRowBackground(isSelected: isSelected))
    }
}

// MARK: - Share Error Alert

private struct ShareErrorAlert: ViewModifier {
    @Binding var shareError: String?

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(shareError != nil)) {
                Button("OK") { shareError = nil }
            } message: {
                if let error = shareError { Text(error) }
            }
    }
}

extension View {
    func shareErrorAlert(_ error: Binding<String?>) -> some View {
        modifier(ShareErrorAlert(shareError: error))
    }
}
