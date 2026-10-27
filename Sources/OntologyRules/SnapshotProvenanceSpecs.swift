import Foundation
import SpecificationCore

/// Admission of declared origin under explicit external authority, never truth.
package struct SnapshotProvenanceSpec: DecisionSpec {
    package init() {}

    package func decide(_ context: InstanceGraphValidationContext) -> [InstanceGraphIssue]? {
        guard let document = context.provenanceAuthority else {
            return [graphIssue("provenance.authority.required", "authority", "The selected provenance profile requires a separately supplied trusted authority input.")]
        }
        var authority = SnapshotAuthorityCheck(context: context, document: document)
        authority.validate()
        guard authority.issues.isEmpty else { return authority.issues }
        var check = SnapshotProvenanceCheck(index: InstanceGraphIndex(context: context), document: document)
        check.validate()
        return check.issues
    }
}

struct SnapshotProvenanceCheck {
    let index: InstanceGraphIndex
    let document: GraphObject
    var issues = [InstanceGraphIssue]()
    let alternatives = [
        ("snapshotSourceOrigin", "SourceSnapshotOrigin", "confirm-source"),
        ("snapshotDirectOrigin", "DirectObservationOrigin", "confirm-observation"),
        ("snapshotOperatorOrigin", "OperatorSnapshotOrigin", "supply-operator-state")
    ]

    var confirmations: [GraphObject] { document["confirmations"] as? [GraphObject] ?? [] }
    var enrichments: [GraphObject] { document["enrichments"] as? [GraphObject] ?? [] }

    mutating func validate() {
        validateOrigins()
        validateConfirmationTargets()
        for snapshot in index.nodes(of: "StateSnapshot") { validateSnapshot(snapshot) }
        validateCaptureBoundaries()
        validateEnrichments()
    }

    mutating func require(_ condition: Bool, _ suffix: String, _ path: String, _ message: String) {
        if !condition { issues.append(graphIssue("provenance.\(suffix)", path, message)) }
    }

    func grant(_ key: String, capability: String, snapshot: GraphObject) -> Bool {
        let grants = document["grants"] as? [GraphObject] ?? []
        let fields = graphFields(snapshot)
        return grants.contains {
            graphText($0, "authorityKey") == key &&
                ($0["capabilities"] as? [String] ?? []).contains(capability) &&
                ($0["scopeKeys"] as? [String] ?? []).contains(graphText(fields, "scopeKey")) &&
                ($0["projectionKeys"] as? [String] ?? []).contains(graphText(fields, "projectionKey"))
        }
    }

    mutating func validateOrigins() {
        var keys = Set<String>()
        let snapshots = index.nodes(of: "StateSnapshot")
        for (relation, type, _) in alternatives {
            for origin in index.nodes(of: type) {
                let path = index.path(origin)
                let fields = graphFields(origin)
                require(fields.values.compactMap { $0 as? String }.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
                        "origin.blank", path, "Origin identities and declarations must be nonblank.")
                require(keys.insert(graphText(fields, "originKey")).inserted, "origin.duplicate", path, "Origin key must be unique across origin alternatives.")
                let owners = snapshots.filter { index.targets($0, relation).contains { graphText($0, "id") == graphText(origin, "id") } }
                require(owners.count == 1, "origin.owner", path, "Every origin is owned by exactly one snapshot; it cannot stand in for another snapshot's observation.")
                if type == "DirectObservationOrigin" {
                    require((graphInteger(fields["observedAt"]) ?? -1) >= 0 && validDigest(graphText(fields, "artifactDigest")),
                            "origin.capture", path, "Direct capture needs a nonnegative time and a sha256 artifact identity; authenticity remains unverified.")
                }
                if type == "SourceSnapshotOrigin" {
                    for citation in index.targets(origin, "originCitesAssertion") {
                        require(validDigest(graphText(graphFields(citation), "sourceDigest")), "origin.sourceDigest", path, "Source extraction must pin cited source bytes with a sha256 identity.")
                    }
                }
                if type == "OperatorSnapshotOrigin" {
                    require(!graphText(fields, "rationale").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                            "origin.rationale", path, "Operator supply requires an explicit nonblank rationale.")
                }
            }
        }
    }

    mutating func validateConfirmationTargets() {
        for entry in confirmations {
            let snapshot = index.byID[graphText(entry, "snapshotId")] ?? [:]
            let originID = graphText(entry, "originId")
            let origins = alternatives.flatMap { index.targets(snapshot, $0.0) }
            require(graphText(snapshot, "type") == "eventcore:StateSnapshot" && origins.contains { graphText($0, "id") == originID },
                    "confirmation.target", "authority.confirmations", "Confirmation must name an existing snapshot and its actual typed origin.")
        }
    }

    mutating func validateSnapshot(_ snapshot: GraphObject) {
        let origins = alternatives.flatMap { relation, _, capability in index.targets(snapshot, relation).map { ($0, capability) } }
        let path = index.path(snapshot)
        require(origins.count == 1, "origin.required", path, "Every snapshot, including an empty state, needs exactly one typed origin.")
        guard origins.count == 1, let (origin, capability) = origins.first else { return }
        let entries = confirmations.filter { graphText($0, "snapshotId") == graphText(snapshot, "id") && graphText($0, "originId") == graphText(origin, "id") }
        require(entries.count == 1, "confirmation.required", path, "Source presence or graph review is not origin confirmation; an external confirmation is required.")
        guard let entry = entries.first else { return }
        let authority = graphText(entry, "authorityKey")
        require(grant(authority, capability: capability, snapshot: snapshot), "confirmation.authority", path, "Confirming authority lacks the required capability or exact scope/projection grant.")
        if capability == "supply-operator-state" {
            require(graphText(graphFields(origin), "operatorKey") == authority, "operator.identity", path, "Operator-supplied state must be confirmed by that explicitly authorized operator.")
        }
    }

    mutating func validateCaptureBoundaries() {
        for record in index.nodes(of: "RecordedEvent") {
            for (relation, boundary) in [("recordBeforeSnapshot", "intervalStart"), ("recordAfterSnapshot", "intervalFinish")] {
                let origin = index.target(index.target(record, relation), "snapshotDirectOrigin")
                guard !origin.isEmpty else { continue }
                let fields = graphFields(origin)
                let recordFields = graphFields(record)
                require(graphText(fields, "clockKey") == graphText(recordFields, "clockKey") && graphInteger(fields["observedAt"]) == graphInteger(recordFields[boundary]),
                        "capture.boundary", index.path(record), "Direct snapshot capture time/clock must match the corresponding recorded boundary.")
            }
        }
    }

    func hasEnrichment(_ candidate: GraphObject, record: GraphObject) -> Bool {
        index.targets(candidate, "candidateEnrichedByRecord").contains { graphText($0, "id") == graphText(record, "id") }
    }

    mutating func validateEnrichments() {
        for entry in enrichments {
            let candidate = index.byID[graphText(entry, "candidateId")] ?? [:]
            let record = index.byID[graphText(entry, "recordId")] ?? [:]
            require(graphText(candidate, "type") == "eventcore:EventCandidate" && graphText(record, "type") == "eventcore:RecordedEvent" && hasEnrichment(candidate, record: record),
                    "enrichment.target", "authority.enrichments", "Enrichment admission must name an actual candidate-to-record edge.")
        }
        for candidate in index.nodes(of: "EventCandidate") {
            for record in index.targets(candidate, "candidateEnrichedByRecord") {
                validatePreservedObservations(candidate, record: record)
                let entries = enrichments.filter { graphText($0, "candidateId") == graphText(candidate, "id") && graphText($0, "recordId") == graphText(record, "id") }
                require(entries.count == 1, "enrichment.required", index.path(candidate), "Candidate enrichment requires separate explicit authority admission.")
                if let entry = entries.first {
                    let allowed = ["recordBeforeSnapshot", "recordAfterSnapshot"].allSatisfy {
                        grant(graphText(entry, "authorityKey"), capability: "enrich-candidate", snapshot: index.target(record, $0))
                    }
                    require(allowed, "enrichment.authority", index.path(candidate), "Enrichment requires capability in both state scopes/projections.")
                }
            }
        }
        for candidate in index.nodes(of: "InterpretationCandidate") {
            for view in index.targets(candidate, "candidateResolvedAsInterpretation") {
                require(hasEnrichment(index.target(candidate, "describesCandidateEvent"), record: index.target(view, "interpretsRecord")),
                        "resolution.enrichment", index.path(candidate), "Interpretation resolution requires an explicitly enriched event candidate; review alone is insufficient.")
            }
        }
    }

    mutating func validatePreservedObservations(_ candidate: GraphObject, record: GraphObject) {
        for (observationRelation, snapshotRelation) in [("candidateBeforeObservation", "recordBeforeSnapshot"), ("candidateAfterObservation", "recordAfterSnapshot")] {
            let observation = index.target(candidate, observationRelation)
            let snapshot = index.target(record, snapshotRelation)
            switch graphText(graphFields(observation), "availability") {
            case "known":
                require(graphText(index.target(observation, "observationSnapshot"), "id") == graphText(snapshot, "id"),
                        "enrichment.known", index.path(candidate), "Enrichment must preserve a supplied known snapshot's identity.")
            case "partial":
                let supplied = factValues(index.targets(observation, "observationSuppliesFact"))
                let recorded = factValues(index.targets(snapshot, "snapshotContainsFact"))
                require(supplied.isSubset(of: recorded), "enrichment.partial", index.path(candidate), "Enrichment must retain all explicitly supplied partial facts, including their polarities.")
            default: break // Unknown or absent states remain on the original candidate.
            }
        }
    }

    func factValues(_ facts: [GraphObject]) -> Set<[String]> {
        Set(facts.map { [graphText(graphFields($0), "propositionKey"), graphText(graphFields($0), "polarity")] })
    }

    func validDigest(_ value: String) -> Bool {
        value.range(of: #"\Asha256:[a-f0-9]{64}\z"#, options: .regularExpression) != nil
    }
}
