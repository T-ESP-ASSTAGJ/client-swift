import SwiftUI

struct PrivacyLockedView: View {
    let message: String
    var expandVertically: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            if !expandVertically { Spacer().frame(height: 60) }
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if !expandVertically { Spacer() }
        }
        .frame(maxWidth: .infinity, maxHeight: expandVertically ? .infinity : nil)
    }
}
