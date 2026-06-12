import Foundation
import Yams

extension OntologyCompiler {
    struct OntologycAdapterReportContext {
        let bindingPath: String
        let ontologyIRPath: String
        let ir: JSONObject
        let resolvedCount: Int
        let gapCount: Int
        let sourceURI: String
        let sourceRef: String
    }

    func loadJSON(path: String) throws -> JSONObject {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        guard let object = try JSONSerialization.jsonObject(with: data) as? JSONObject else {
            throw NSError(domain: "ontologyc", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(path) is not a JSON object"])
        }
        return object
    }

    func loadYAMLDocuments(path: String) throws -> [JSONObject] {
        let source = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
        return try source
            .components(separatedBy: "\n---")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .compactMap { document -> JSONObject? in
                guard let parsed = try Yams.load(yaml: document) else { return nil }
                return parsed as? JSONObject
            }
    }

    struct RefOccurrence {
        let ref: String
        let artifactKind: String
        let artifactId: String
    }

    func collectRefOccurrences(_ documents: [JSONObject], namespace: String) -> [RefOccurrence] {
        var occurrences = [RefOccurrence]()
        for document in documents {
            let artifactKind = string(document["kind"]) ?? "SpecGraphArtifact"
            let artifactId = ((document["metadata"] as? JSONObject).flatMap { string($0["id"]) }) ?? "unknown"
            var refs = Set<String>()
            collectNamespaceRefs(document, namespace: namespace, refs: &refs)
            for ref in refs.sorted() {
                occurrences.append(RefOccurrence(ref: ref, artifactKind: artifactKind, artifactId: artifactId))
            }
        }
        return occurrences
    }

    func collectNamespaceRefs(_ value: Any, namespace: String, refs: inout Set<String>) {
        if let object = value as? JSONObject {
            for key in object.keys.sorted() {
                if let child = object[key] {
                    collectNamespaceRefs(child, namespace: namespace, refs: &refs)
                }
            }
        } else if let array = value as? [Any] {
            for child in array {
                collectNamespaceRefs(child, namespace: namespace, refs: &refs)
            }
        } else if let scalar = value as? String, scalar.hasPrefix("\(namespace):") {
            refs.insert(scalar)
        }
    }

    func collectOntologyImports(_ documents: [JSONObject]) -> [JSONObject] {
        var imports = [JSONObject]()
        for document in documents {
            collectOntologyImports(document, imports: &imports)
        }
        return imports.sorted {
            (string($0["namespace"]) ?? "") < (string($1["namespace"]) ?? "")
        }
    }

    func collectOntologyImports(_ value: Any, imports: inout [JSONObject]) {
        if let object = value as? JSONObject {
            if let ontologyImports = object["ontologyImports"] as? [Any] {
                imports.append(contentsOf: ontologyImports.compactMap { $0 as? JSONObject })
            }
            for key in object.keys.sorted() {
                if let child = object[key] {
                    collectOntologyImports(child, imports: &imports)
                }
            }
        } else if let array = value as? [Any] {
            for child in array {
                collectOntologyImports(child, imports: &imports)
            }
        }
    }

    func conceptRefIndex(_ ir: JSONObject) -> [String: JSONObject] {
        let ontologyId = string(ir["id"]) ?? ""
        let namespace = string(ir["namespace"]) ?? ""
        let version = string(ir["version"]) ?? ""
        var index = [String: JSONObject]()

        func addRefs(from items: [JSONObject], kind: (JSONObject) -> String, uriPrefix: String) {
            for item in items {
                guard let id = string(item["id"]) else { continue }
                let alias = "\(namespace):\(id)"
                index[alias] = [
                    "ontology": ontologyId,
                    "version": version,
                    "namespace": namespace,
                    "concept": id,
                    "kindOfConcept": kind(item),
                    "alias": alias,
                    "uri": string(item["uri"]) ?? "ontology://\(ontologyId)/\(version)/\(uriPrefix)/\(id)"
                ]
            }
        }

        addRefs(from: ir["classes"] as? [JSONObject] ?? [], kind: { self.string($0["kind"]) ?? "Class" }, uriPrefix: "classes")
        addRefs(from: ir["relations"] as? [JSONObject] ?? [], kind: { _ in "Relation" }, uriPrefix: "relations")
        addRefs(from: ir["policies"] as? [JSONObject] ?? [], kind: { _ in "Policy" }, uriPrefix: "policies")
        addRefs(from: ir["stateMachines"] as? [JSONObject] ?? [], kind: { _ in "StateMachine" }, uriPrefix: "stateMachines")
        return index
    }

    func ontologyGap(for occurrence: RefOccurrence, ir: JSONObject, ordinal: Int) -> JSONObject {
        [
            "apiVersion": "specgraph.io/v1alpha1",
            "kind": "OntologyGap",
            "metadata": [
                "id": String(format: "gap-%03d", ordinal)
            ],
            "spec": [
                "sourceArtifact": [
                    "kind": occurrence.artifactKind,
                    "id": occurrence.artifactId
                ],
                "missingConcept": occurrence.ref,
                "targetOntology": string(ir["id"]) ?? "",
                "requestedAction": [
                    "type": "proposeOntologyDelta"
                ]
            ]
        ]
    }

    func lockfile(imports: [JSONObject], ir: JSONObject, index: [String: JSONObject]) -> JSONObject {
        let namespace = string(ir["namespace"]) ?? ""
        let aliases = index.keys.sorted().reduce(into: JSONObject()) { output, alias in
            output[refName(alias)] = alias
        }
        let importObject = imports.first { string($0["namespace"]) == namespace }
        return [
            "apiVersion": "specgraph.io/v1alpha1",
            "kind": "OntologyLockfile",
            "metadata": [
                "project": "semantic-validation"
            ],
            "spec": [
                "resolved": [[
                    "ontology": string(importObject?["ontology"]) ?? string(ir["id"]) ?? "",
                    "namespace": namespace,
                    "version": string(importObject?["version"]) ?? string(ir["version"]) ?? "",
                    "digest": string(ir["sourceDigest"]) ?? "",
                    "registryUri": string(importObject?["source"]) ?? "",
                    "aliases": aliases
                ]]
            ]
        ]
    }

    func ontologycAdapterReport(_ context: OntologycAdapterReportContext) -> JSONObject {
        [
            "artifact_kind": "ontologyc_adapter_report",
            "schema_version": 1,
            "proposal_id": "0060",
            "producer": [
                "tool": "ontologyc",
                "command": "validate-specgraph",
                "command_contract_ref": "Ontology:SPECS/ontology/ontologyc.md#validate-specgraph"
            ],
            "package": [
                "package_id": string(context.ir["id"]) ?? "",
                "namespace": string(context.ir["namespace"]) ?? "",
                "version": string(context.ir["version"]) ?? "",
                "source_uri": context.sourceURI,
                "source_ref": context.sourceRef,
                "digest": string(context.ir["sourceDigest"]) ?? ""
            ],
            "inputs": [
                "binding_ref": portableRef(context.bindingPath),
                "normalized_ir_ref": portableRef(context.ontologyIRPath)
            ],
            "outputs": [
                "concept_refs_ref": "concept-refs.yaml",
                "ontology_lock_ref": "ontology.lock.yaml",
                "ontology_gaps_ref": "ontology-gaps.yaml"
            ],
            "summary": [
                "status": "passed",
                "resolved_ref_count": context.resolvedCount,
                "gap_count": context.gapCount,
                "canonical_mutations_allowed": false,
                "tracked_artifacts_written": false
            ],
            "authority_boundary": [
                "report_is_authority": false,
                "digest_authority": "normalized_ir_sourceDigest",
                "ontology_lock_is_canonical": false,
                "automatic_import_lock_update": false,
                "automatic_canonical_node_update": false
            ]
        ]
    }

    func portableRef(_ path: String) -> String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}
