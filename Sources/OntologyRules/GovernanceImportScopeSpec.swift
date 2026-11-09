import SpecificationCore

/// Whether dependency sources have an owning package to validate.
public struct GovernanceImportScope {
    public let hasPackage: Bool
    public let hasImports: Bool

    public init(hasPackage: Bool, hasImports: Bool) {
        self.hasPackage = hasPackage
        self.hasImports = hasImports
    }
}

/// Imports are meaningful only when the governance decision checks a package.
public struct GovernanceImportScopeSpec: Specification {
    public typealias T = GovernanceImportScope

    public init() {}

    public func isSatisfiedBy(_ context: GovernanceImportScope) -> Bool {
        context.hasPackage || !context.hasImports
    }
}
