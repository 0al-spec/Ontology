import Foundation

/// Layout direction for a package diagram.
public enum OntologyDiagramDirection: String, Sendable {
    case leftToRight = "LR"
    case topToBottom = "TB"
}

extension OntologyCompiler {
    /// Validates a YAML package and projects its normalized declarations into deterministic DOT.
    /// Imported references remain external placeholders without loading their declarations.
    public func diagramDOT(
        path: OntologySourcePath,
        direction: OntologyDiagramDirection = .leftToRight
    ) throws -> String {
        diagnostics = []
        guard let package = load(path: path.path) else {
            throw OntologyCompilerError.packageError(diagnostics)
        }
        validate(package)
        guard !hasErrors(diagnostics) else {
            throw OntologyCompilerError.packageError(diagnostics)
        }
        var diagram = PackageDiagram(ir: normalize(package))
        return diagram.render(direction: direction)
    }
}

struct PackageDiagram {
    let ir: JSONObject
    private var externalNodes: [String: String] = [:]
    private var edges: [String] = []

    init(ir: JSONObject) {
        self.ir = ir
    }

    mutating func render(direction: OntologyDiagramDirection) -> String {
        let title = "\(text(ir, "id"))@\(text(ir, "version"))"
        var lines = [
            "digraph ontology {",
            "  graph [rankdir=\(direction.rawValue), bgcolor=\"#ffffff\", pad=0.35, nodesep=0.35, ranksep=0.7,",
            "    fontname=\"Helvetica\", fontsize=18, labelloc=t, label=\(quote(title))];",
            "  node [shape=box, style=\"rounded,filled\", fontname=\"Helvetica\", fontsize=11,",
            "    color=\"#94a3b8\", fontcolor=\"#0f172a\", fillcolor=\"#eff6ff\", margin=\"0.16,0.1\"];",
            "  edge [fontname=\"Helvetica\", fontsize=9, color=\"#64748b\", fontcolor=\"#334155\", arrowsize=0.7];"
        ]
        lines += classNodes()
        lines += protocolNodes()
        lines += policyNodes()
        lines += machineNodes()
        relationEdges()
        lines += edges.sorted()
        lines += ["  subgraph cluster_external {", "    label=\"External references (declarations not loaded)\";",
                  "    fontsize=11; color=\"#cbd5e1\"; style=dashed;"]
        lines += externalNodes.keys.sorted().compactMap { externalNodes[$0] }
        lines += ["  }", "}"]
        return lines.joined(separator: "\n") + "\n"
    }

    private mutating func classNodes() -> [String] {
        records("classes").map { definition in
            let id = text(definition, "fqid")
            let central = definition["central"] as? Bool == true
            let heading = central ? "«class · central»" : "«class»"
            let fields = (definition["fields"] as? [JSONObject] ?? []).map { field in
                let optional = field["required"] as? Bool == true ? "" : "?"
                return "\(text(field, "id"))\(optional): \(text(field, "type"))"
            }
            let label = ([heading, id] + fields).joined(separator: "\n")
            let source = nodeID("classes", id)
            inheritance(from: source, definition: definition, kind: "classes")
            for ref in definition["implements"] as? [String] ?? [] {
                edge(source, reference(ref, kind: "protocols"), label: "implements", style: "dashed", arrow: "empty")
            }
            if let lifecycle = definition["lifecycle"] as? String {
                edge(source, nodeID("stateMachines", "\(namespace):\(lifecycle)"), label: "lifecycle", style: "dotted")
            }
            return node(source, label: label, fill: "#dbeafe", extra: central ? ", penwidth=2" : "")
        }
    }

    private func protocolNodes() -> [String] {
        records("protocols").map { definition in
            let requirements = ["requiredFields", "requiredRelations"].flatMap { key in
                (definition[key] as? [String] ?? []).map { "\(key): \($0)" }
            }
            let label = (["«protocol»", text(definition, "fqid")] + requirements).joined(separator: "\n")
            return node(nodeID("protocols", text(definition, "fqid")), label: label, fill: "#ede9fe")
        }
    }

    private mutating func policyNodes() -> [String] {
        records("policies").map { definition in
            let source = nodeID("policies", text(definition, "fqid"))
            inheritance(from: source, definition: definition, kind: "policies")
            for target in definition["appliesTo"] as? [String] ?? [] {
                edge(source, reference(target, kind: "classes"), label: "appliesTo", style: "dashed")
            }
            let label = ["«policy · \(text(definition, "enforceability"))»", text(definition, "fqid")].joined(separator: "\n")
            return node(source, label: label, fill: "#fef3c7")
        }
    }

    private mutating func machineNodes() -> [String] {
        records("stateMachines").flatMap { definition in
            let id = text(definition, "fqid")
            let machine = nodeID("stateMachines", id)
            var lines = ["  subgraph \(quote("cluster/" + machine)) {", "    label=\(quote(text(definition, "id")));",
                         "    color=\"#99f6e4\"; style=rounded;",
                         node(machine, label: "«lifecycle»\n\(id)", fill: "#ccfbf1")]
            for state in definition["states"] as? [String] ?? [] {
                lines.append(node(stateID(machine, state), label: state, fill: "#f0fdfa", extra: ", shape=ellipse"))
            }
            for transition in definition["transitions"] as? [JSONObject] ?? [] {
                let triggers = ["command", "event"].compactMap { key in
                    (transition[key] as? String).map { "\(key): \($0)" }
                }
                edge(stateID(machine, text(transition, "from")), stateID(machine, text(transition, "to")),
                     label: triggers.joined(separator: "\n"))
            }
            lines.append("  }")
            return lines
        }
    }

    private mutating func relationEdges() {
        for definition in records("relations") {
            let source = reference(text(definition, "domain"), kind: "classes")
            let range = definition["range"]
            let alternatives = (range as? JSONObject)?["oneOf"] as? [String]
            let targets = alternatives ?? (range as? String).map { [$0] } ?? []
            let cardinality = definition["cardinality"] as? JSONObject ?? [:]
            let bounds = cardinality.isEmpty ? "" : " [\(cardinality["min"] ?? "?")..\(cardinality["max"] ?? "?")]"
            let choice = alternatives == nil ? "" : " · oneOf"
            let label = text(definition, "id") + bounds + choice
            for target in targets {
                edge(source, reference(target, kind: "classes"), label: label)
            }
        }
    }

    private mutating func inheritance(from source: String, definition: JSONObject, kind: String) {
        edge(source, reference(text(definition, "extends"), kind: kind), label: "extends", arrow: "empty")
    }

    private mutating func reference(_ ref: String, kind: String) -> String {
        if records(kind).contains(where: { text($0, "fqid") == ref }) { return nodeID(kind, ref) }
        let id = "external/\(kind)/\(ref)"
        let importNamespace = ref.split(separator: ":").first.map(String.init) ?? ""
        let imported = records("imports").first { text($0, "namespace") == importNamespace } ?? [:]
        let origin = "\(text(imported, "id"))@\(text(imported, "version"))"
        externalNodes[id] = node(id, label: "«external reference»\n\(ref)\n\(origin)",
                                 fill: "#f1f5f9", extra: ", style=\"rounded,dashed,filled\"")
        return id
    }

    private mutating func edge(_ from: String, _ to: String, label: String, style: String = "solid", arrow: String = "normal") {
        edges.append("  \(quote(from)) -> \(quote(to)) [label=\(quote(label)), style=\(style), arrowhead=\(arrow)];")
    }

    private func node(_ id: String, label: String, fill: String, extra: String = "") -> String {
        "  \(quote(id)) [label=\(quote(label)), fillcolor=\(quote(fill))\(extra)];"
    }

    private var namespace: String { text(ir, "namespace") }

    private func nodeID(_ kind: String, _ ref: String) -> String { "\(kind)/\(ref)" }

    private func stateID(_ machine: String, _ state: String) -> String { "\(machine)/states/\(state)" }

    private func records(_ key: String) -> [JSONObject] { ir[key] as? [JSONObject] ?? [] }

    private func text(_ object: JSONObject, _ key: String) -> String { object[key] as? String ?? "" }

    private func quote(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\n", with: "\\n") + "\""
    }
}
