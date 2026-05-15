# Conventions API

Ce document décrit comment la couche réseau du client Jamly est structurée
et comment **ajouter un nouvel endpoint** en respectant les patterns du projet.

Lecture recommandée après le [README](../README.md) et le document
[architecture](./architecture.md).

## Le client HTTP : `APIClient`

[`APIClient`](../jamly/Networking/APIClient.swift) est un singleton qui
centralise **tous** les appels HTTP. Aucun autre fichier ne doit instancier
de `URLSession` ou construire de `URLRequest` à la main.

### Signature de `request<T>`

```swift
@discardableResult
func request<T: Decodable>(
    _ path: String,
    method: HTTPMethod = .get,
    query: [String: String?] = [:],
    body: Encodable? = nil,
    additionalHeaders: [String: String] = [:],
    responseType: T.Type = T.self
) async throws -> APIResponse<T>
```

Le client se charge de :

1. **Construire l'URL** à partir de `Config.baseURL` + `/api` + `path`.
2. **Sérialiser** `body` en JSON via `JSONEncoder`.
3. **Injecter le token** `Authorization: Bearer <jwt>` si présent dans le Keychain.
4. **Forcer le Content-Type** à `application/merge-patch+json` pour les `PATCH`
   (exigence API Platform).
5. **Décoder** la réponse en `T`, ou lever une [`APIError`](../jamly/Networking/APIError.swift) typée.
6. **Déconnecter automatiquement** sur `401` (suppression du token + notification).

### Exemple d'appel

```swift
let response = try await APIClient.shared.request(
    "/users/42",
    method: .get,
    responseType: User.self
)
let user = response.value          // User décodé
let status = response.statusCode   // ex. 200
```

## La couche Actions

Les **Actions** sont des `enum` namespace contenant des `static func`. Un
fichier par domaine métier dans [`jamly/Actions/`](../jamly/Actions/).

Exemple basé sur [`UserActions.fetchMe()`](../jamly/Actions/Users/UserAction.swift) :

```swift
enum UserActions {
    static func fetchMe() async throws -> APIResponse<User> {
        return try await APIClient.shared.request(
            UserEndpoints.me,
            method: .get,
            responseType: User.self
        )
    }
}
```

**Pourquoi des `enum` sans cas ?** Garantir qu'on ne peut pas instancier
la « classe » : ce ne sont que des fonctions regroupées par domaine.

### Centralisation des chemins

Les chemins relatifs sont regroupés dans des structs `*Endpoints` au début
du fichier d'action. Cela évite les chaînes magiques dispersées :

```swift
struct UserEndpoints {
    static let me = "/users/me"
    static let users = "/users"

    static func user(_ id: Int) -> String { "/users/\(id)" }
    static func follow(_ id: Int) -> String { "/users/\(id)/follow" }
}
```

## Ajouter un nouvel endpoint : exemple pas à pas

Imaginons qu'on veuille ajouter une fonctionnalité de **blocage d'utilisateur** :
`POST /users/{id}/block` avec un body `{ "reason": "..." }`.

### Étape 1 — Ajouter le chemin dans `UserEndpoints`

Dans [`Actions/Users/UserAction.swift`](../jamly/Actions/Users/UserAction.swift) :

```swift
struct UserEndpoints {
    // ... chemins existants
    static func block(_ id: Int) -> String { "/users/\(id)/block" }
}
```

### Étape 2 — Créer la struct de body

Toujours dans le même fichier, avant l'enum `UserActions` :

```swift
struct BlockUserRequest: Encodable {
    let reason: String
}
```

**Convention de nommage** : `XxxRequest` pour les bodies, `XxxResponse`
pour les réponses si elles ne correspondent pas à un modèle existant.

### Étape 3 — Ajouter la fonction static dans `UserActions`

```swift
enum UserActions {
    // ... fonctions existantes

    /// Bloque un utilisateur pour le compte de l'utilisateur connecté.
    ///
    /// - Parameters:
    ///   - userId: Identifiant de l'utilisateur à bloquer.
    ///   - reason: Motif libre du blocage.
    /// - Throws: ``APIError`` en cas d'échec.
    static func blockUser(userId: Int, reason: String) async throws -> APIResponse<EmptyResponse> {
        return try await APIClient.shared.request(
            UserEndpoints.block(userId),
            method: .post,
            body: BlockUserRequest(reason: reason),
            responseType: EmptyResponse.self
        )
    }
}
```

**Remarques** :
- Documente toute fonction publique avec un commentaire `///` (rendu dans
  Xcode au survol et exploitable par DocC).
- Utilise `EmptyResponse` quand le serveur ne renvoie pas de body.

### Étape 4 — Consommer depuis un ViewModel

Dans le ViewModel qui pilote la vue concernée :

```swift
@MainActor
final class ProfileActionsViewModel: ObservableObject {
    @Published var error: AppError?
    @Published var isBlocking = false

    func block(userId: Int, reason: String) async -> Bool {
        defer { isBlocking = false }
        isBlocking = true
        error = nil

        do {
            _ = try await UserActions.blockUser(userId: userId, reason: reason)
            return true
        } catch let apiError as APIError {
            handleAPIError(apiError)
            return false
        } catch {
            error = .unknown
            return false
        }
    }

    private func handleAPIError(_ apiError: APIError) {
        switch apiError {
        case .unauthorized: error = .unauthorized
        case .networkError: error = .networkError
        case .serverError:  error = .serverError
        default:            error = .unknown
        }
    }
}
```

### Étape 5 — Appeler depuis la View

```swift
struct BlockButton: View {
    let userId: Int
    @StateObject private var viewModel = ProfileActionsViewModel()

    var body: some View {
        Button("Bloquer") {
            Task {
                let ok = await viewModel.block(userId: userId, reason: "Spam")
                // ... gérer le résultat
            }
        }
        .disabled(viewModel.isBlocking)
        .alert("Erreur", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        }
    }
}
```

## Convention de pagination

Toutes les listes paginées de l'app suivent les **mêmes règles** :

- **20 éléments par page** côté serveur (constante).
- **Paramètre `page`** dans la query string, démarrant à `1`.
- **Une page partielle (< 20)** ou **vide** signifie la fin du flux.
- **Déduplication par `id`** côté client pour les cas où la pagination
  chevauche (un nouvel élément inséré entre deux requêtes).

Exemple type tiré de [`SearchViewModel`](../jamly/ViewModels/Search/SearchViewModel.swift) :

```swift
func loadMoreResults() async {
    guard !isLoadingMore, !isLoading, hasMorePages else { return }

    let nextPage = currentPage + 1
    let response = try await SearchAction.searchUsers(
        username: currentSearchQuery,
        page: nextPage
    )

    if !response.value.isEmpty {
        searchResults.append(contentsOf: response.value)
        currentPage = nextPage
        hasMorePages = response.value.count >= itemsPerPage
    } else {
        hasMorePages = false
    }
}
```

**Prefetch automatique** : la convention est de déclencher `loadMore` quand
l'utilisateur atteint **l'une des 3 dernières cellules** de la liste, via
une fonction `shouldLoadMore(for:)`.

## Conventions de nommage

| Type | Convention | Exemple |
|---|---|---|
| Body de requête | `XxxRequest` | `CreateCommentRequest`, `BlockUserRequest` |
| Réponse ad hoc | `XxxResponse` | `AuthVerifyResponse`, `SendCommentResponse` |
| Namespace d'actions | `XxxAction` ou `XxxActions` | `FeedAction`, `UserActions` |
| ViewModel d'une vue | `XxxViewModel` | `ChatsViewModel`, `ProfileViewModel` |
| Endpoints centralisés | `XxxEndpoints` ou `XxxEndpoint` | `UserEndpoints`, `MessageEndpoint` |
| Modèles complets | Singulier | `Post`, `Conversation`, `User` |
| Modèles allégés | `LightXxx` ou `CommonXxx` | `LightMessage`, `CommonUser` |

## `@MainActor` : où l'appliquer

**Règle simple** : tout ce qui mute un `@Published` doit être main-actor.

| Type | Annotation | Pourquoi |
|---|---|---|
| `ObservableObject` ViewModel | `@MainActor` sur la classe | Les `@Published` ne peuvent être mutés qu'en main thread |
| `Store` global | `@MainActor` sur la classe | Idem, plus la cohérence d'état entre toutes les vues observatrices |
| Service HTTP (`APIClient`) | _aucune_ | L'appel réseau s'exécute sur un thread de pool ; l'appelant garantit le retour main |
| Délégué `URLSession` (`MercureService`) | `nonisolated` sur les callbacks | Les callbacks viennent d'un thread arbitraire ; on **bascule** sur main via `Task { @MainActor in ... }` |
| Modèle Codable | _aucune_ | Les structs sont thread-safe par construction |

## Cas particuliers à connaître

### `EmptyResponse` pour les endpoints sans body

Quand un endpoint renvoie `204 No Content`, on utilise `EmptyResponse`
comme `responseType` :

```swift
return try await APIClient.shared.request(
    UserEndpoints.unfollow(userId),
    method: .delete,
    responseType: EmptyResponse.self
)
```

### `merge-patch+json` automatique pour les PATCH

API Platform exige le Content-Type `application/merge-patch+json` sur les
requêtes `PATCH`. `APIClient` l'applique automatiquement quand `method == .patch` —
**rien à faire** côté action.

### Encodage générique d'`Encodable`

Le paramètre `body: Encodable?` accepte n'importe quel type conforme,
**même existentiel**, grâce au wrapper privé `AnyEncodable` dans `APIClient`.
On peut donc passer un body sans avoir à le typer explicitement à
l'appelant.
