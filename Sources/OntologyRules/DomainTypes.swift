/// A local ontology symbol name such as a class, relation, policy, protocol, or state-machine identifier.
public struct OntologySymbolName: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A state name inside an ontology state machine.
public struct OntologyStateName: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A concept reference literal, either local (`Exam`) or namespace-qualified (`foundation:Policy`).
public struct OntologyConceptReferenceLiteral: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A package identifier such as `org.0al.examcalc`.
public struct OntologyPackageId: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A package-local namespace used to qualify ontology references.
public struct OntologyNamespace: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A semantic version literal for an ontology package.
public struct OntologySemanticVersion: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// The ontology package API version literal.
public struct OntologyApiVersion: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// The top-level ontology package kind literal.
public struct OntologyPackageKind: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A policy enforceability mode literal.
public struct PolicyEnforceability: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A YAML mapping key scanned for executable-looking configuration names.
public struct YamlMappingKey: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A YAML scalar string scanned for executable-looking content.
public struct YamlScalarText: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A raw YAML source line scanned before YAML parsing.
public struct YamlSourceLine: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// Inputs required to decide whether a concept reference resolves against local or imported ontology names.
public struct ConceptRefResolutionContext: Equatable, Sendable {
    public let ref: String
    public let localNames: Set<String>
    public let packageNamespace: String
    public let importNamespaces: Set<String>

    public init(
        ref: String,
        localNames: Set<String>,
        packageNamespace: String,
        importNamespaces: Set<String>
    ) {
        self.ref = ref
        self.localNames = localNames
        self.packageNamespace = packageNamespace
        self.importNamespaces = importNamespaces
    }
}

/// Inputs required to decide whether a command or event trigger reference is local to the package.
public struct TriggerRefResolutionContext: Equatable, Sendable {
    public let ref: String
    public let names: Set<String>
    public let packageNamespace: String

    public init(ref: String, names: Set<String>, packageNamespace: String) {
        self.ref = ref
        self.names = names
        self.packageNamespace = packageNamespace
    }
}

/// Inputs required to test whether a state name belongs to a declared state set.
public struct StateMembershipContext: Equatable, Sendable {
    public let state: String
    public let states: Set<String>

    public init(state: String, states: Set<String>) {
        self.state = state
        self.states = states
    }
}
