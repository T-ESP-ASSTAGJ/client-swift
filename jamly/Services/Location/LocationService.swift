import Foundation
import CoreLocation
import MapKit

/// Service one-shot pour récupérer la ville + le pays de l'utilisateur via Core Location
/// puis reverse geocoding. Utilisé par ``CreatePostViewModel`` pour pré-remplir le champ
/// `location` du post.
@MainActor
final class LocationService: NSObject {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Demande la permission si nécessaire, récupère la position, et reverse-geocode
    /// pour retourner "Ville, Pays". Retourne `nil` si la permission est refusée
    /// ou si le geocoding échoue.
    func currentCityAndCountry() async -> String? {
        print("📍 currentCityAndCountry() called")
        let status = await requestAuthorizationIfNeeded()
        print("📍 Authorization status: \(status.rawValue)")
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            print("📍 Permission not granted, aborting")
            return nil
        }
        guard let location = await requestLocation() else {
            print("📍 Location request returned nil")
            return nil
        }
        print("📍 Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        let result = await reverseGeocode(location: location)
        print("📍 Reverse geocode result: \(result ?? "nil")")
        return result
    }

    private func requestAuthorizationIfNeeded() async -> CLAuthorizationStatus {
        let current = manager.authorizationStatus
        if current != .notDetermined {
            return current
        }
        return await withCheckedContinuation { continuation in
            self.authContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    private func requestLocation() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation()
        }
    }

    private func reverseGeocode(location: CLLocation) async -> String? {
        guard let request = MKReverseGeocodingRequest(location: location) else {
            print("📍 MKReverseGeocodingRequest init returned nil")
            return nil
        }
        do {
            let mapItems = try await request.mapItems
            print("📍 Got \(mapItems.count) map items")
            guard let placemark = mapItems.first?.placemark else {
                print("📍 No placemark on first map item")
                return nil
            }
            let city = placemark.locality
                ?? placemark.subAdministrativeArea
                ?? placemark.administrativeArea
                ?? ""
            let country = placemark.country ?? ""
            print("📍 Placemark city='\(city)' country='\(country)'")
            switch (city.isEmpty, country.isEmpty) {
            case (false, false): return "\(city), \(country)"
            case (false, true): return city
            case (true, false): return country
            case (true, true): return nil
            }
        } catch {
            print("📍 Reverse geocode failed: \(error)")
            return nil
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            locationContinuation?.resume(returning: locations.first)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        print("📍 Location request failed: \(error)")
        Task { @MainActor in
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authContinuation?.resume(returning: status)
            authContinuation = nil
        }
    }
}
