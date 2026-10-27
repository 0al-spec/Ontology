struct EventCoreGraphCheck {
    let index: InstanceGraphIndex
    var issues = [InstanceGraphIssue]()

    mutating func validate() {
        validateEpisodeIdentity()
        validateRegistriesAndRecords()
        validateSnapshots()
        validateObservations()
        validateCandidates()
        validateHypotheses()
        var facts = EventCoreFactCheck(index: index)
        facts.validate()
        issues += facts.issues
    }

    mutating func require(_ condition: Bool, _ code: String, _ node: GraphObject, _ message: String) {
        if !condition { issues.append(graphIssue(code, index.path(node), message)) }
    }

    mutating func validateEpisodeIdentity() {
        var scopes = Set<String>()
        for episode in index.nodes(of: "Episode") {
            require(scopes.insert(graphText(graphFields(episode), "scopeKey")).inserted,
                    "episode.duplicate", episode, "Episode scopeKey must be unique within this graph revision.")
        }
    }

    func validInterval(_ fields: GraphObject) -> Bool {
        guard let start = graphInteger(fields["intervalStart"]), let finish = graphInteger(fields["intervalFinish"]) else { return false }
        return start >= 0 && start <= finish
    }

    mutating func validateRegistriesAndRecords() {
        var registries = Set<[String]>()
        for registry in index.nodes(of: "EventRegistry") {
            let fields = graphFields(registry)
            require(registries.insert([graphText(fields, "registryKey"), graphText(fields, "revisionKey")]).inserted,
                    "registry.duplicate", registry, "Registry revision identity must be unique.")
        }
        var records = Set<[String]>()
        for record in index.nodes(of: "RecordedEvent") {
            let fields = graphFields(record)
            let registry = index.target(record, "recordInRegistry")
            require(records.insert([graphText(registry, "id"), graphText(fields, "recordKey")]).inserted,
                    "record.duplicate", record, "recordKey is duplicated within its registry revision.")
            require(validInterval(fields), "record.interval", record, "Expected 0 <= intervalStart <= intervalFinish.")
            let before = index.target(record, "recordBeforeSnapshot")
            let after = index.target(record, "recordAfterSnapshot")
            let episode = index.target(record, "recordInEpisode")
            let beforeFields = graphFields(before)
            let afterFields = graphFields(after)
            let keys = ["schemaKey", "scopeKey", "projectionKey"]
            let comparable = keys.allSatisfy { graphText(beforeFields, $0) == graphText(afterFields, $0) }
            let scoped = graphText(beforeFields, "scopeKey") == graphText(graphFields(episode), "scopeKey")
            require(comparable && scoped && observationProjection(before) && observationProjection(after),
                    "record.snapshots", record, "Record snapshots must be comparable observation states in its episode scope.")
        }
    }

    func observationProjection(_ snapshot: GraphObject) -> Bool {
        let fields = graphFields(snapshot)
        let projections = index.graph["projections"] as? [GraphObject] ?? []
        return projections.contains {
            graphText($0, "projectionKey") == graphText(fields, "projectionKey") &&
                graphText($0, "schemaKey") == graphText(fields, "schemaKey") && graphText($0, "domain") == "observation"
        }
    }

    mutating func validateSnapshots() {
        let projections = index.graph["projections"] as? [GraphObject] ?? []
        for snapshot in index.nodes(of: "StateSnapshot") {
            let fields = graphFields(snapshot)
            require(projections.contains {
                graphText($0, "projectionKey") == graphText(fields, "projectionKey") && graphText($0, "schemaKey") == graphText(fields, "schemaKey")
            }, "snapshot.projection", snapshot, "Snapshot schema/projection must be declared explicitly.")
        }
    }

    mutating func validateObservations() {
        for observation in index.nodes(of: "StateObservation") {
            let snapshots = index.targets(observation, "observationSnapshot").count
            let facts = index.targets(observation, "observationSuppliesFact").count
            let availability = graphText(graphFields(observation), "availability")
            let valid: Bool
            switch availability {
            case "known": valid = snapshots == 1 && facts == 0
            case "unknown": valid = snapshots == 0 && facts == 0
            case "partial": valid = snapshots == 0 && facts > 0
            default: valid = false
            }
            require(valid, "observation.shape", observation, "Expected known(snapshot only), unknown(neither) or partial(facts only).")
        }
    }

    mutating func validateCandidates() {
        for candidate in index.nodes(of: "EventCandidate") {
            let episode = index.target(candidate, "candidateInEpisode")
            for relation in ["candidateBeforeObservation", "candidateAfterObservation"] {
                let observation = index.target(candidate, relation)
                for snapshot in index.targets(observation, "observationSnapshot") {
                    require(graphText(graphFields(snapshot), "scopeKey") == graphText(graphFields(episode), "scopeKey") && observationProjection(snapshot),
                            "candidate.scope", candidate, "Candidate snapshot must use its own episode's observation projection.")
                }
            }
            for record in index.targets(candidate, "candidateEnrichedByRecord") {
                require(graphText(index.target(record, "recordInEpisode"), "id") == graphText(episode, "id"),
                        "candidate.scope", candidate, "Enrichment cannot change the candidate's episode.")
            }
        }
        for candidate in index.nodes(of: "InterpretationCandidate") {
            let event = index.target(candidate, "describesCandidateEvent")
            let episode = index.target(event, "candidateInEpisode")
            for view in index.targets(candidate, "candidateResolvedAsInterpretation") {
                let record = index.target(view, "interpretsRecord")
                require(graphText(index.target(record, "recordInEpisode"), "id") == graphText(episode, "id"),
                        "candidate.scope", candidate, "Resolved interpretation must preserve the candidate episode.")
            }
        }
    }

    mutating func validateHypotheses() {
        for hypothesis in index.nodes(of: "CausalHypothesis") {
            let causeView = index.target(hypothesis, "hypothesisCauseView")
            let effectView = index.target(hypothesis, "hypothesisEffectView")
            let cause = index.target(causeView, "interpretsRecord")
            let effect = index.target(effectView, "interpretsRecord")
            let causeFields = graphFields(cause)
            let effectFields = graphFields(effect)
            require(graphText(graphFields(hypothesis), "profileRef") == index.profile.rawValue,
                    "hypothesis.profile", hypothesis, "Hypothesis must name the explicitly selected pinned profile.")
            require(graphText(cause, "id") != graphText(effect, "id"),
                    "hypothesis.distinct", hypothesis, "Cause and effect must be distinct registered records.")
            for relation in ["recordInRegistry", "recordInEpisode"] {
                require(graphText(index.target(cause, relation), "id") == graphText(index.target(effect, relation), "id"),
                        "hypothesis.scope", hypothesis, "Hypothesis endpoints must share a registry revision and episode.")
            }
            let sameClock = graphText(causeFields, "clockKey") == graphText(effectFields, "clockKey")
            require(sameClock,
                    "hypothesis.clock", hypothesis, "Endpoint clocks must match before comparing times.")
            if sameClock && validInterval(causeFields) && validInterval(effectFields) {
                require((graphInteger(causeFields["intervalStart"]) ?? 0) <= (graphInteger(effectFields["intervalStart"]) ?? 0),
                        "hypothesis.order", hypothesis, "Cause must start no later than effect; overlap is allowed.")
            }
        }
    }
}
