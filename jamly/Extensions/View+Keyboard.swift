import SwiftUI

extension View {
    /// Dismiss le clavier quand l'utilisateur tape sur une zone non interactive
    /// (en dehors des TextField/Button). Les gestures enfants gardent la priorité,
    /// donc les boutons et champs continuent de fonctionner normalement.
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}
