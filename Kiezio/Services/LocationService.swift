import Foundation

protocol LocationService {
    func currentZone() async -> String
}

struct MockLocationService: LocationService {
    func currentZone() async -> String {
        "Demo-Kiez"
    }
}
