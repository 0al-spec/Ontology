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

public struct StateMembershipContext: Equatable, Sendable {
    public let state: String
    public let states: Set<String>

    public init(state: String, states: Set<String>) {
        self.state = state
        self.states = states
    }
}
