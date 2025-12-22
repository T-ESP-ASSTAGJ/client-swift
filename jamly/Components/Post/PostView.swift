import SwiftUI

/// Exemple d'utilisation de la modale de commentaires
struct PostView: View {
    // État pour afficher/masquer la modale de commentaires
    @State private var showComments = false
    
    // Nombre de commentaires (à remplacer par vos données réelles)
    @State private var commentCount = 12
    
    var body: some View {
        VStack(spacing: 20) {
            // Votre contenu de post ici
            VStack(alignment: .leading, spacing: 12) {
                Text("Mon Post")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Ceci est le contenu de mon post. Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Boutons d'actions (like, commentaire, partage)
            HStack(spacing: 20) {
                // Bouton Like
                Button {
                    // Action like
                } label: {
                    Label("Like", systemImage: "heart")
                }
                .buttonStyle(.bordered)
                
                // Bouton Commentaire
                Button {
                    showComments = true
                } label: {
                    HStack {
                        Image(systemName: "bubble.left")
                        Text("Commentaires")
                        if commentCount > 0 {
                            Text("(\(commentCount))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.bordered)
                
                // Bouton Partage
                Button {
                    // Action partage
                } label: {
                    Label("Partager", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    PostView()
}
