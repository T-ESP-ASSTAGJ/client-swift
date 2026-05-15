# Jamly — client iOS

Application iOS du projet **T-ESP** (Epitech) : un réseau social musical qui
permet de publier des photos avant/arrière accompagnées d'un morceau, de suivre
des utilisateurs, de discuter en temps réel et de partager du contenu Apple Music.

> Ce dépôt contient uniquement le client iOS (SwiftUI). Le backend (Symfony /
> API Platform) est versionné dans un dépôt séparé.

## Stack

- **Langage** : Swift 5.9+ / SwiftUI
- **Cible** : iOS 17+
- **Architecture** : MVVM + Stores (`@EnvironmentObject`)
- **Concurrence** : `async`/`await`, acteurs `@MainActor`
- **Audio / musique** : [MusicKit](https://developer.apple.com/musickit/) + AVPlayer (previews 30 s)
- **Temps réel** : [Mercure](https://mercure.rocks/) (Server-Sent Events)
- **Notifications push** : APNs via `NotificationServiceExtension`
- **Stockage sécurisé** : Keychain Services
- **Outils CI** : GitHub Actions (auto-PR, intégration Jira)

## Fonctionnalités principales

- Authentification par email + code OTP (JWT)
- Onboarding et gestion de la connexion Apple Music
- Feed Discovery (public) et feed Friends (utilisateurs suivis), paginés
- Publication de posts (photo avant/arrière + morceau)
- Likes, vues, commentaires, signalements
- Profil utilisateur avec statistiques d'écoute (top morceaux, artistes, albums, genres)
- Système de followers / followings avec pagination
- Recherche d'utilisateurs avec historique local
- Messagerie temps réel (conversations directes + groupes) via Mercure
- Partage de morceaux et playlists Apple Music dans les chats
- Notifications push (messages, nouveaux followers, likes, commentaires)

## Arborescence

```
jamly/
├── jamlyApp.swift           — Point d'entrée @main, racine SwiftUI
├── AppDelegate.swift        — Initialisation UIKit (push notifications)
├── Config.swift             — URL de base et constantes globales
│
├── App/                     — Vues SwiftUI organisées par feature
│   ├── Auth/                — Onboarding + login OTP
│   ├── Home/                — Feed principal + détail d'un post
│   ├── Discover/            — Feed public
│   ├── Chats/               — Inbox et détails de conversation
│   ├── Comments/            — Commentaires d'un post
│   ├── Notifications/       — Centre de notifications
│   ├── Post/                — Création de post
│   ├── Profile/             — Profil utilisateur + paramètres
│   ├── Search/              — Recherche d'utilisateurs
│   ├── Tabs/                — TabBar racine
│   └── Branding/            — Splash, logos
│
├── ViewModels/              — ObservableObject par feature (un dossier par feature)
│
├── Models/                  — DTOs Codable (User, Post, Comment, Message…)
│
├── Networking/
│   ├── APIClient.swift      — Client HTTP générique (auth, JSON, gestion 401)
│   └── APIError.swift       — Erreurs typées exposées à l'app
│
├── Actions/                 — Couche d'appels API, un dossier par domaine
│   ├── Auth/   Chat/   Comment/   Feed/   Follower/   Following/
│   ├── Post/   Search/   Users/
│
├── Stores/
│   ├── UserStore.swift      — État global (user connecté, feeds, pagination)
│   └── SecureStore.swift    — Wrapper Keychain
│
├── Core/
│   ├── Music/               — MusicKit (autorisation, playlists, previews, stats)
│   └── Search/              — Historique de recherche local
│
├── Services/
│   └── Mercure/             — Souscription SSE pour la messagerie temps réel
│
├── Components/              — Vues SwiftUI réutilisables (PostView, headers…)
├── Extensions/              — Extensions Swift (Color+…)
├── Utils/                   — AuthManager, schémas de validation, pickers musique
└── Ressources/              — Polices, assets non-image

NotificationServiceExtension/ — Extension iOS pour les push notifications
```

## Architecture en bref

```
        ┌─────────────────┐
        │   SwiftUI View  │
        └────────┬────────┘
                 │  observe
                 ▼
        ┌─────────────────┐         ┌──────────────────┐
        │   ViewModel /   │────────▶│   Action layer   │
        │      Store      │  call   │ (one per domain) │
        └────────┬────────┘         └────────┬─────────┘
                 │                           │
                 ▼                           ▼
        ┌─────────────────┐         ┌──────────────────┐
        │  SecureStore /  │         │    APIClient     │
        │   MusicKit /    │         │    (HTTP/JSON)   │
        │    Mercure      │         └────────┬─────────┘
        └─────────────────┘                  │
                                             ▼
                                        Backend Jamly
                                       (Symfony / API Platform)
```

- **`UserStore`** est l'unique source de vérité pour l'utilisateur connecté et
  les feeds. Il est injecté dans toute l'app via `@EnvironmentObject`.
- **`APIClient`** centralise tous les appels HTTP (auth automatique, gestion
  des `401`, encodage JSON, retry de `PATCH` en `merge-patch+json`).
- Les **`*Action`** sont de simples namespaces de fonctions statiques par
  domaine (`UserActions.fetchMe()`, `FeedAction.getPublicFeed(...)`).
- Les **`*ViewModel`** orchestrent les actions et exposent l'état à la vue.

## Configuration

L'application lit son URL de base dans `jamly/Config.swift` :

```swift
#if DEBUG
    static let baseURL = "http://<ip-locale>:80"   // serveur dev local
#else
    static let baseURL = "https://api.jamly.app"   // production
#endif
```

Pour pointer vers un autre backend en développement, modifier la valeur
`DEBUG` puis relancer le build.

### Apple Music & Push

- La capability **MusicKit** doit être activée dans le projet et le compte
  Apple Developer (déjà configurée dans `jamly.entitlements`).
- Les notifications push nécessitent un certificat APNs côté backend ainsi
  que la capability **Push Notifications** dans Xcode.
- Le fichier `GoogleService-Info.plist` est utilisé pour l'envoi via Firebase
  (s'il s'applique au projet).

## Démarrage

### Prérequis

- macOS Sonoma (14+)
- Xcode 15+
- Un compte Apple Developer (pour MusicKit et Push en device physique)
- Un backend Jamly accessible (local ou production)

### Installation

```bash
git clone <repo-url>
cd client-swift
open jamly.xcodeproj
```

1. Sélectionner la target **jamly** et un simulateur iOS 17+.
2. Vérifier l'URL dans `jamly/Config.swift`.
3. Build & Run (⌘R).

### Tester sur un device physique

MusicKit ne fonctionne pas dans le simulateur. Pour tester la lecture des
previews et les statistiques d'écoute :

1. **Activer le mode développeur sur l'iPhone** :
   `Réglages → Confidentialité et sécurité → Mode développeur → Activer`,
   puis redémarrer le téléphone et confirmer à l'écran de déverrouillage.
2. **Rejoindre l'organisation Apple Developer de Gaël** : lui demander une
   invitation depuis App Store Connect afin que ton identifiant Apple soit
   ajouté à l'équipe. Sans cela, Xcode ne pourra pas signer le build avec
   les capabilities MusicKit + Push Notifications.
3. Dans Xcode, sélectionner la **Team** de l'organisation dans
   `Signing & Capabilities` pour la target `jamly`.
4. Brancher un iPhone, le sélectionner comme destination Xcode.
5. S'assurer que le compte Apple connecté sur l'iPhone a un abonnement
   Apple Music actif (pour la bibliothèque) — les previews fonctionnent
   sans abonnement.
6. Accepter le prompt MusicKit au premier lancement.

## Tests

```bash
# Lancer les tests depuis Xcode
⌘U
```

Les targets de tests sont :

- `jamlyTests` — tests unitaires
- `jamlyUITests` — tests UI

## Documentation in-code

La majorité des composants techniques (Networking, Models, Stores, Actions,
ViewModels, Services) est documentée au format DocC. Pour générer le site
documentation :

```
Xcode → Product → Build Documentation (⇧⌃⌘D)
```

La documentation s'ouvre ensuite dans Xcode et peut être exportée.

## Conventions

- **MVVM strict** : aucune logique réseau dans les vues, tout passe par un
  ViewModel ou un Store.
- **`@MainActor`** sur tout ce qui mute des `@Published`.
- **Pagination** : 20 éléments par page, déduplication par `id` côté client.
- **Erreurs** : `APIClient` lève des `APIError` typées ; les ViewModels les
  remappent en `AppError` pour l'UI.
- **Naming** : structures Codable des requêtes en `XxxRequest`, réponses en
  `XxxResponse`.

## Workflows GitHub

Trois workflows automatisent la gestion du repo :

- `auto-pr.yml` — création automatique de PR
- `issue-list.yml` — synchro des issues
- `jira-integration.yml` — intégration Jira (suivi des tickets TEM-xxx)

## Liens utiles

- [DocC — Apple documentation](https://www.swift.org/documentation/docc/)
- [MusicKit for Swift](https://developer.apple.com/documentation/musickit)
- [Mercure](https://mercure.rocks/)
- [API Platform](https://api-platform.com/) (côté backend)

## Équipe

Projet T-ESP — Epitech. Voir l'historique git (`git shortlog -sn`) pour la
liste des contributeurs.
