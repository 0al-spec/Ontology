import SpecificationCore

public struct UnsafeYamlKeySpec: Specification {
    public typealias T = String

    private let unsafeKeys = Set([
        "eval", "exec", "executable", "expression", "hook", "hooks",
        "plugin", "plugins", "posthook", "prehook", "script", "scripts"
    ])

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        unsafeKeys.contains(candidate.lowercased())
    }
}

public struct ExecutableLookingYamlValueSpec: Specification {
    public typealias T = String

    private let unsafeValuePatterns = [
        #"\$\("#, #"`"#, #"<%"#, #"eval\("#, #"child_process"#,
        #"subprocess"#, #"os\.system"#, #"Runtime\.getRuntime"#
    ]

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        unsafeValuePatterns.contains { matches(candidate, $0) }
    }
}

public struct UnsafeYamlTagSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        matches(candidate, #"!![A-Za-z0-9_.:-]+|!<[^>]+>"#, caseInsensitive: true)
    }
}
