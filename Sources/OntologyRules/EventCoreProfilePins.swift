import Foundation

/// Explicit, immutable profile selection. Legacy reports keep their original pin.
package enum EventCoreProfileSelection: String {
    case legacy = "eventcore-v1"
    case provenance = "eventcore-provenance-v1"

    package var ontology: [String: String] {
        switch self {
        case .legacy: EventCoreInstanceProfile.ontology
        case .provenance: [
            "id": "org.0al.events.core", "namespace": "eventcore", "version": "0.2.0",
            "sourceDigest": "sha256:92a3245fc9acd15748fd1fa3cfb8e4fdc8fda429a5fd6cffd7a97bc13f2f359e"
        ]
        }
    }

    package var irSHA256: String {
        switch self {
        case .legacy: EventCoreInstanceProfile.irSHA256
        case .provenance: "e6c932ad8c492d168b63dbe112335c270d88ff758e016f3502031aefe9dea916"
        }
    }

    package var definitionPin: [String: String] {
        ["id": rawValue, "version": "1.0.0", "definitionSHA256": "240d518666905c320df299b5d4d9e08e7c2564b0ca97ca2ab15d0a275dbe2551"]
    }
}
