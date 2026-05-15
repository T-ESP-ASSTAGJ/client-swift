//
//  Report.swift
//  jamly
//
//  Created by REVERSS on 16/04/2026.
//

/// Motif de signalement présenté à l'utilisateur lors d'un report.
///
/// `key` est la valeur envoyée à l'API tandis que `label` est le texte affiché à l'écran,
/// déjà localisé côté serveur.
struct ReportReason: Codable {
    let key: String
    let label: String
}

/// Corps de la requête envoyée à l'API pour signaler une entité (actuellement un post).
///
/// `entityClass` est figé à `App\Entity\Post` car seul ce type d'entité est signalable.
/// Si d'autres types deviennent signalables (commentaire, utilisateur…), il faudra rendre
/// ce champ paramétrable.
struct ReportBody: Encodable {
    let entityClass: String = "App\\Entity\\Post"
    let entityId: Int
    /// Clé du motif de signalement, issue d'un ``ReportReason``.
    let reason: String
    /// Message libre fourni par l'utilisateur en complément du motif.
    let message: String
}
