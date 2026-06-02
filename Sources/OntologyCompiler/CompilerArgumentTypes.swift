import Foundation

/// Filesystem path to an ontology source artifact consumed by compiler workflows.
public struct OntologySourcePath: Equatable, Hashable, Sendable {
    public let path: String

    public init(url: URL) {
        self.path = url.path
    }

    public init(path: String) {
        self.path = path
    }

    public var url: URL {
        URL(fileURLWithPath: path)
    }
}

/// Filesystem directory where compiler workflows write generated artifacts.
public struct OntologyOutputDirectory: Equatable, Hashable, Sendable {
    public let path: String

    public init(url: URL) {
        self.path = url.path
    }

    public init(path: String) {
        self.path = path
    }

    public var url: URL {
        URL(fileURLWithPath: path)
    }
}

/// Filesystem path to one compiler output file.
public struct OntologyOutputPath: Equatable, Hashable, Sendable {
    public let path: String

    public init(url: URL) {
        self.path = url.path
    }

    public init(path: String) {
        self.path = path
    }

    public var url: URL {
        URL(fileURLWithPath: path)
    }
}

/// Base URL for an ontology registry endpoint.
public struct RegistryBaseURL: Equatable, Hashable, Sendable {
    public let url: URL

    public init?(string: String) {
        guard let url = URL(string: string), url.scheme != nil, url.host != nil else {
            return nil
        }
        self.url = url
    }

    public init?(url: URL) {
        guard url.scheme != nil, url.host != nil else {
            return nil
        }
        self.url = url
    }

    public var absoluteString: String {
        url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}

/// Registry package reference in `<id>@<version>` form.
public struct OntologyPackageReference: Equatable, Hashable, Sendable {
    public let id: String
    public let version: String

    public init(id: String, version: String) {
        self.id = id
        self.version = version
    }

    public init?(rawValue: String) {
        let parts = rawValue.split(separator: "@", maxSplits: 1).map(String.init)
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else {
            return nil
        }
        self.id = parts[0]
        self.version = parts[1]
    }

    public var rawValue: String {
        "\(id)@\(version)"
    }
}
