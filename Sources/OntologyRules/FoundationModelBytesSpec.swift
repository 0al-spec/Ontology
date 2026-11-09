import SpecificationCore

/// The exact bytes of the source-derived foundation models shipped for each version.
public struct FoundationModelBytesContext {
    public let version: String
    public let digest: String

    public init(version: String, digest: String) {
        self.version = version
        self.digest = digest
    }
}

public struct FoundationModelBytesSpec: Specification {
    public typealias T = FoundationModelBytesContext

    public init() {}

    public func isSatisfiedBy(_ context: T) -> Bool {
        let expected = [
            "0.1.0": "sha256:7999a4ce110535c8093f177493532420a04ab7db9ff86492db802580531d7e48",
            "0.2.0": "sha256:2f43dbd772c8356de107e3ea48cd548405023edb6a641702ddbec52c4942033b",
        ]
        return expected[context.version] == context.digest
    }
}

/// Keep explicit catalog input bounded before parsing or hashing it.
public struct FoundationModelSizeSpec: Specification {
    public typealias T = Int
    public static let maximum = 1024 * 1024
    public init() {}
    public func isSatisfiedBy(_ count: Int) -> Bool { count >= 0 && count <= Self.maximum }
}

/// A diagram never needs an unlimited number of distinct model files.
public struct FoundationModelCountSpec: Specification {
    public typealias T = Int
    public static let maximum = 16
    public init() {}
    public func isSatisfiedBy(_ count: Int) -> Bool { count >= 0 && count <= Self.maximum }
}
