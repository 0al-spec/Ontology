import SpecificationCore

/// Inputs shared by the diagram CLI and library when checking import expansion.
public struct DiagramSelectionContext {
    public let view: String
    public let hasImports: Bool
    public let expandedTypes: [String]

    public init(view: String, hasImports: Bool, expandedTypes: [String]) {
        self.view = view
        self.hasImports = hasImports
        self.expandedTypes = expandedTypes
    }
}

/// Shared acceptance outcome for diagram expansion options.
public enum DiagramSelectionDecision: Equatable {
    case valid
    case requiresRelationsView
    case unpairedSelection
    case emptySelector

    public var message: String {
        switch self {
        case .valid: return "Valid diagram selection"
        case .requiresRelationsView: return "Import expansion requires relations view"
        case .unpairedSelection: return "Supply local imports and expanded types together"
        case .emptySelector: return "Expanded type selectors must be nonempty"
        }
    }
}

/// Classifies the accepted expansion mode, paired inputs and empty selectors.
public struct DiagramSelectionSpec: DecisionSpec {
    public typealias Context = DiagramSelectionContext
    public typealias Result = DiagramSelectionDecision

    public init() {}

    public func decide(_ context: Context) -> Result? {
        if context.view != "relations", context.hasImports || !context.expandedTypes.isEmpty {
            return .requiresRelationsView
        }
        if context.hasImports != !context.expandedTypes.isEmpty { return .unpairedSelection }
        if context.expandedTypes.contains(where: \.isEmpty) { return .emptySelector }
        return .valid
    }
}
