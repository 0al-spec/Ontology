import SpecificationCore

/// Detects YAML mapping keys that imply executable hooks, plugins, or scripts.
public struct UnsafeYamlKeySpec: Specification {
    public typealias T = YamlMappingKey

    private let unsafeKeys = Set([
        "eval", "exec", "executable", "expression", "hook", "hooks",
        "plugin", "plugins", "posthook", "prehook", "script", "scripts"
    ])

    public init() {}

    public func isSatisfiedBy(_ candidate: YamlMappingKey) -> Bool {
        unsafeKeys.contains(candidate.rawValue.lowercased())
    }
}

/// Detects YAML scalar strings that look like executable shell, template, or runtime calls.
public struct ExecutableLookingYamlValueSpec: Specification {
    public typealias T = YamlScalarText

    private let unsafeValuePatterns = [
        #"\$\("#, #"`"#, #"<%"#, #"eval\("#, #"child_process"#,
        #"subprocess"#, #"os\.system"#, #"Runtime\.getRuntime"#
    ]

    public init() {}

    public func isSatisfiedBy(_ candidate: YamlScalarText) -> Bool {
        unsafeValuePatterns.contains { matches(candidate.rawValue, $0) }
    }
}

/// Detects YAML tags that can request non-data object construction in unsafe YAML loaders.
public struct UnsafeYamlTagSpec: Specification {
    public typealias T = YamlSourceLine

    public init() {}

    public func isSatisfiedBy(_ candidate: YamlSourceLine) -> Bool {
        matches(candidate.rawValue, #"!![A-Za-z0-9_.:-]+|!<[^>]+>"#, caseInsensitive: true)
    }
}
