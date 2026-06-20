import Foundation
import OntologyRules

struct CompatibilityLayerChangeInput {
    let symbolKind: String
    let symbolId: String
    let before: JSONObject
    let after: JSONObject
    let namespace: String
    let decisionKind: CompatibilityChangeKind
}

struct CompatibilityLayerScanInput {
    let symbolKind: String
    let fromSymbols: [String: JSONObject]
    let toSymbols: [String: JSONObject]
    let namespace: String
    let decisionKind: CompatibilityChangeKind
}

extension OntologyCompiler {
    func compatibilityLayerChanges(
        fromClasses: [String: JSONObject],
        toClasses: [String: JSONObject],
        fromRelations: [String: JSONObject],
        toRelations: [String: JSONObject],
        fromNamespace: String,
        decision: CompatibilityChangeDecisionSpec
    ) -> [JSONObject] {
        var changes = [JSONObject]()
        appendLayerChanges(to: &changes, input: CompatibilityLayerScanInput(
            symbolKind: "class",
            fromSymbols: fromClasses,
            toSymbols: toClasses,
            namespace: fromNamespace,
            decisionKind: .classLayerChanged
        ), decision: decision)
        appendLayerChanges(to: &changes, input: CompatibilityLayerScanInput(
            symbolKind: "relation",
            fromSymbols: fromRelations,
            toSymbols: toRelations,
            namespace: fromNamespace,
            decisionKind: .relationLayerChanged
        ), decision: decision)
        return changes
    }

    private func appendLayerChanges(
        to changes: inout [JSONObject],
        input: CompatibilityLayerScanInput,
        decision: CompatibilityChangeDecisionSpec
    ) {
        for symbolId in Set(input.fromSymbols.keys).intersection(Set(input.toSymbols.keys)).sorted() {
            guard let before = input.fromSymbols[symbolId], let after = input.toSymbols[symbolId],
                  let change = compatibilityLayerChange(input: CompatibilityLayerChangeInput(
                      symbolKind: input.symbolKind,
                      symbolId: symbolId,
                      before: before,
                      after: after,
                      namespace: input.namespace,
                      decisionKind: input.decisionKind
                  ), decision: decision)
            else { continue }
            changes.append(change)
        }
    }

    private func compatibilityLayerChange(
        input: CompatibilityLayerChangeInput,
        decision: CompatibilityChangeDecisionSpec
    ) -> JSONObject? {
        let beforeLayer = string(input.before["layer"]) ?? ""
        let afterLayer = string(input.after["layer"]) ?? ""
        guard beforeLayer != afterLayer else { return nil }
        let compatibility = decision.decide(CompatibilityChangeContext(
            kind: input.decisionKind,
            namespace: input.namespace,
            symbolId: input.symbolId,
            beforeComparable: beforeLayer,
            afterComparable: afterLayer
        ))
        return [
            "symbol": "\(input.namespace):\(input.symbolId)",
            "kind": input.symbolKind,
            "classification": layerChangeClassification(before: beforeLayer, after: afterLayer),
            "before": beforeLayer,
            "after": afterLayer,
            "compatibility": compatibilityLabel(compatibility)
        ]
    }

    private func compatibilityLabel(_ decision: CompatibilityChangeDecision?) -> String {
        switch decision {
        case .breaking:
            return "breaking"
        default:
            return "compatible"
        }
    }

    private func layerChangeClassification(before: String, after: String) -> String {
        if before.isEmpty { return "layerAdded" }
        if after.isEmpty { return "layerRemoved" }
        return "layerChanged"
    }
}
