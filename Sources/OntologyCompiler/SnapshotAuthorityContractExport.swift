import Foundation
import OntologyRules

extension OntologyCompiler {
    func snapshotAuthoritySchema(_ profile: EventCoreProfileSelection) -> JSONObject {
        let strings: JSONObject = ["type": "array", "items": nonemptyStringSchema, "minItems": 1, "maxItems": 1000, "uniqueItems": true]
        let grant = closedObject([
            "authorityKey": nonemptyStringSchema, "scopeKeys": strings, "projectionKeys": strings,
            "capabilities": ["type": "array", "items": ["enum": ["confirm-source", "confirm-observation", "supply-operator-state", "enrich-candidate"]], "minItems": 1, "maxItems": 4, "uniqueItems": true]
        ])
        let confirmation = closedObject(["snapshotId": nonemptyStringSchema, "originId": nonemptyStringSchema, "authorityKey": nonemptyStringSchema, "rationale": nonemptyStringSchema])
        let enrichment = closedObject(["candidateId": nonemptyStringSchema, "recordId": nonemptyStringSchema, "authorityKey": nonemptyStringSchema, "rationale": nonemptyStringSchema])
        var schema = closedObject([
            "apiVersion": ["const": "ontology.specgraph.io/snapshot-authority/v1alpha1"],
            "kind": ["const": "SnapshotProvenanceAuthority"],
            "profilePin": closedObject(profile.definitionPin.mapValues { ["const": $0] }),
            "graphKey": identifierSchema, "revisionKey": identifierSchema,
            "graphSHA256": ["type": "string", "pattern": "^[a-f0-9]{64}$"],
            "grants": finiteArray(grant, maximum: 10_000), "confirmations": finiteArray(confirmation, maximum: 10_000),
            "enrichments": finiteArray(enrichment, maximum: 10_000)
        ])
        schema["$schema"] = "https://json-schema.org/draft/2020-12/schema"
        schema["description"] = "Caller-selected trusted input; no identity authentication or source truth. Cross-input binding and scoped admission require validate-instances."
        return schema
    }

    var snapshotAuthorityTypeScript: String {
        """
        export type SnapshotCapability = "confirm-source" | "confirm-observation" | "supply-operator-state" | "enrich-candidate";
        export interface SnapshotProvenanceAuthority {
          readonly apiVersion: "ontology.specgraph.io/snapshot-authority/v1alpha1";
          readonly kind: "SnapshotProvenanceAuthority";
          readonly profilePin: InstanceGraph["profilePin"];
          readonly graphKey: string;
          readonly revisionKey: string;
          readonly graphSHA256: string;
          readonly grants: readonly { readonly authorityKey: string; readonly capabilities: readonly SnapshotCapability[]; readonly scopeKeys: readonly string[]; readonly projectionKeys: readonly string[] }[];
          readonly confirmations: readonly { readonly snapshotId: string; readonly originId: string; readonly authorityKey: string; readonly rationale: string }[];
          readonly enrichments: readonly { readonly candidateId: string; readonly recordId: string; readonly authorityKey: string; readonly rationale: string }[];
        }

        """
    }
}
