import SpecificationCore

/// A model version and the exact reachable package identities for a diagram.
public struct FoundationModelImportEligibilityContext {
    public let version: String
    public let imports: [DiagramImportDeclaration]

    public init(version: String, imports: [DiagramImportDeclaration]) {
        self.version = version
        self.imports = imports
    }
}

/// A catalog may be supplied only when its version is a reachable foundation import.
public struct FoundationModelImportEligibilitySpec: Specification {
    public typealias T = FoundationModelImportEligibilityContext

    public init() {}

    public func isSatisfiedBy(_ context: T) -> Bool {
        context.imports.contains {
            $0.version.rawValue == context.version &&
                FoundationExports.catalog(packageID: $0.id.rawValue, version: $0.version.rawValue) != nil
        }
    }
}
