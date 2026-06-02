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
    public let reference: OntologyConceptReferenceLiteral
    public let localSymbols: Set<OntologySymbolName>
    public let namespace: OntologyNamespace
    public let importedNamespaces: Set<OntologyNamespace>

    public var ref: String { reference.rawValue }
    public var localNames: Set<String> { Set(localSymbols.map(\.rawValue)) }
    public var packageNamespace: String { namespace.rawValue }
    public var importNamespaces: Set<String> { Set(importedNamespaces.map(\.rawValue)) }

    public init(
        ref: String,
        localNames: Set<String>,
        packageNamespace: String,
        importNamespaces: Set<String>
    ) {
        self.init(
            reference: OntologyConceptReferenceLiteral(rawValue: ref),
            localSymbols: Set(localNames.map(OntologySymbolName.init(rawValue:))),
            namespace: OntologyNamespace(rawValue: packageNamespace),
            importedNamespaces: Set(importNamespaces.map(OntologyNamespace.init(rawValue:)))
        )
    }

    public init(
        reference: OntologyConceptReferenceLiteral,
        localSymbols: Set<OntologySymbolName>,
        namespace: OntologyNamespace,
        importedNamespaces: Set<OntologyNamespace>
    ) {
        self.reference = reference
        self.localSymbols = localSymbols
        self.namespace = namespace
        self.importedNamespaces = importedNamespaces
    }
}

/// Inputs required to decide whether a command or event trigger reference is local to the package.
public struct TriggerRefResolutionContext: Equatable, Sendable {
    public let reference: OntologyConceptReferenceLiteral
    public let localSymbols: Set<OntologySymbolName>
    public let namespace: OntologyNamespace

    public var ref: String { reference.rawValue }
    public var names: Set<String> { Set(localSymbols.map(\.rawValue)) }
    public var packageNamespace: String { namespace.rawValue }

    public init(ref: String, names: Set<String>, packageNamespace: String) {
        self.init(
            reference: OntologyConceptReferenceLiteral(rawValue: ref),
            localSymbols: Set(names.map(OntologySymbolName.init(rawValue:))),
            namespace: OntologyNamespace(rawValue: packageNamespace)
        )
    }

    public init(
        reference: OntologyConceptReferenceLiteral,
        localSymbols: Set<OntologySymbolName>,
        namespace: OntologyNamespace
    ) {
        self.reference = reference
        self.localSymbols = localSymbols
        self.namespace = namespace
    }
}

/// Inputs required to test whether a state name belongs to a declared state set.
public struct StateMembershipContext: Equatable, Sendable {
    public let stateName: OntologyStateName
    public let declaredStates: Set<OntologyStateName>

    public var state: String { stateName.rawValue }
    public var states: Set<String> { Set(declaredStates.map(\.rawValue)) }

    public init(state: String, states: Set<String>) {
        self.init(
            stateName: OntologyStateName(rawValue: state),
            declaredStates: Set(states.map(OntologyStateName.init(rawValue:)))
        )
    }

    public init(stateName: OntologyStateName, declaredStates: Set<OntologyStateName>) {
        self.stateName = stateName
        self.declaredStates = declaredStates
    }
}
