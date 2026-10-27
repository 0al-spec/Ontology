struct EventCoreFactCheck {
    let index: InstanceGraphIndex
    var issues = [InstanceGraphIssue]()

    mutating func validate() {
        for fact in index.nodes(of: "Fact") {
            if !["positive", "negative"].contains(graphText(graphFields(fact), "polarity")) {
                issues.append(graphIssue("fact.polarity", index.path(fact), "Fact polarity must be positive or negative; neither implies the other."))
            }
        }
        for snapshot in index.nodes(of: "StateSnapshot") {
            _ = factSet(snapshot, relation: "snapshotContainsFact")
        }
        validateDeltas()
        validateSources()
    }

    mutating func factSet(_ node: GraphObject, relation: String) -> Set<[String]> {
        let facts = index.targets(node, relation)
        let values = facts.map { [graphText(graphFields($0), "propositionKey"), graphText(graphFields($0), "polarity")] }
        let unique = Set(values)
        if unique.count != values.count {
            issues.append(graphIssue("fact.duplicate", "\(index.path(node)).\(relation)", "Repeated proposition/polarity value in a finite set is forbidden."))
        }
        return unique
    }

    mutating func validateDeltas() {
        var owners = Set<String>()
        for delta in index.nodes(of: "Delta") {
            let record = index.target(delta, "deltaOfRecord")
            if !owners.insert(graphText(record, "id")).inserted {
                issues.append(graphIssue("delta.duplicate", index.path(delta), "At most one Delta node per registered record, including identical duplicates."))
            }
            let before = factSet(index.target(record, "recordBeforeSnapshot"), relation: "snapshotContainsFact")
            let after = factSet(index.target(record, "recordAfterSnapshot"), relation: "snapshotContainsFact")
            let added = factSet(delta, relation: "deltaAddsFact")
            let removed = factSet(delta, relation: "deltaRemovesFact")
            if added != after.subtracting(before) || removed != before.subtracting(after) {
                issues.append(graphIssue("delta.exact", index.path(delta), "Delta must equal the exact Added/Removed sets of its owning record."))
            }
        }
    }

    mutating func validateSources() {
        for assertion in index.nodes(of: "SourceAssertion") {
            let fields = graphFields(assertion)
            let start = graphInteger(fields["startOffset"]) ?? -1
            let end = graphInteger(fields["endOffset"]) ?? -1
            if start < 0 || end < start || end - start != Double(graphText(fields, "quote").utf16.count) {
                issues.append(graphIssue("source.offsets", index.path(assertion), "Quote offsets must be ordered nonnegative UTF-16 offsets matching quote length; source truth is unverified."))
            }
        }
    }
}
