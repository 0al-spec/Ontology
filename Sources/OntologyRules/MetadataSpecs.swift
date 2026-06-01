import Foundation
import SpecificationCore

public struct OntologySymbolNameSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        matches(candidate, #"^[A-Za-z][A-Za-z0-9_]*$"#)
    }
}

public struct OntologyStateNameSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        matches(candidate, #"^[a-z][a-z0-9_]*$"#)
    }
}

public struct OntologyConceptRefPatternSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        matches(candidate, #"^([A-Za-z][A-Za-z0-9_]*|[A-Za-z][A-Za-z0-9_.-]*:[A-Za-z][A-Za-z0-9_]*)$"#)
    }
}

public struct OntologyIdPatternSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        matches(candidate, #"^[a-z][a-z0-9]*(\.[a-z0-9][a-z0-9-]*)+$"#)
    }
}

public struct OntologyNamespacePatternSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        matches(candidate, #"^[a-z][a-z0-9-]*$"#)
    }
}

public struct OntologySemVerPatternSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        matches(candidate, #"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)([-+][0-9A-Za-z.-]+)?$"#)
    }
}

func matches(_ value: String, _ pattern: String, caseInsensitive: Bool = false) -> Bool {
    var options: String.CompareOptions = [.regularExpression]
    if caseInsensitive {
        options.insert(.caseInsensitive)
    }
    return value.range(of: pattern, options: options) != nil
}
