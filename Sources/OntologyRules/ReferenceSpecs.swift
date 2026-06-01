import SpecificationCore

public struct ImportedConceptRefSpec: Specification {
    public typealias T = ConceptRefResolutionContext

    public init() {}

    public func isSatisfiedBy(_ candidate: ConceptRefResolutionContext) -> Bool {
        guard let namespace = refNamespace(candidate.ref) else { return false }
        return candidate.importNamespaces.contains(namespace)
    }
}

public struct LocalConceptRefSpec: Specification {
    public typealias T = ConceptRefResolutionContext

    public init() {}

    public func isSatisfiedBy(_ candidate: ConceptRefResolutionContext) -> Bool {
        if let namespace = refNamespace(candidate.ref) {
            return namespace == candidate.packageNamespace && candidate.localNames.contains(refName(candidate.ref))
        }
        return candidate.localNames.contains(candidate.ref)
    }
}

public struct ResolvableConceptRefSpec: Specification {
    public typealias T = ConceptRefResolutionContext

    private let syntax = OntologyConceptRefPatternSpec()
    private let imported = ImportedConceptRefSpec()
    private let local = LocalConceptRefSpec()

    public init() {}

    public func isSatisfiedBy(_ candidate: ConceptRefResolutionContext) -> Bool {
        syntax.isSatisfiedBy(candidate.ref) &&
            (imported.isSatisfiedBy(candidate) || local.isSatisfiedBy(candidate))
    }
}

public struct LocalTriggerRefSpec: Specification {
    public typealias T = TriggerRefResolutionContext

    public init() {}

    public func isSatisfiedBy(_ candidate: TriggerRefResolutionContext) -> Bool {
        if let namespace = refNamespace(candidate.ref), namespace != candidate.packageNamespace {
            return false
        }
        return candidate.names.contains(refName(candidate.ref))
    }
}

func refNamespace(_ ref: String) -> String? {
    let parts = ref.split(separator: ":", maxSplits: 1)
    return parts.count == 2 ? String(parts[0]) : nil
}

func refName(_ ref: String) -> String {
    let parts = ref.split(separator: ":", maxSplits: 1)
    return String(parts.count == 2 ? parts[1] : parts[0])
}
