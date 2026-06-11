import Foundation
import Yams

public struct InductionDraftValidationResult {
    public let passed: Bool
    public let report: [String: Any]
    public let diagnostics: [Diagnostic]
}

struct InductionDraftArtifactDescriptor {
    let name: String
    let fileName: String
}

extension OntologyCompiler {
    var inductionDraftApiVersion: String { "ontology-induction.specgraph.io/v1alpha1" }

    public func validateInductionDraft(
        directory: OntologySourcePath,
        outPath: OntologyOutputPath?
    ) throws -> InductionDraftValidationResult {
        diagnostics = []
        let directoryURL = URL(fileURLWithPath: directory.path, isDirectory: true)
        let artifactReports = [
            validateIntentClassification(in: directoryURL),
            validateProductOntologyDraft(in: directoryURL),
            validateDraftCritique(in: directoryURL),
            validateDomainOntologyPackageDraft(in: directoryURL)
        ]
        let sorted = sortedInductionDraftDiagnostics()
        let passed = sorted.allSatisfy { $0.severity != "error" }
        let report = inductionDraftReport(
            directory: directory.path,
            passed: passed,
            artifactReports: artifactReports,
            diagnostics: sorted
        )
        if let outPath {
            try writeYAML(report, to: outPath.url)
        }
        return InductionDraftValidationResult(passed: passed, report: report, diagnostics: sorted)
    }

    private func validateIntentClassification(in directory: URL) -> JSONObject {
        let artifact = InductionDraftArtifactDescriptor(
            name: "IntentClassification",
            fileName: "intent-classification.yaml"
        )
        let start = diagnostics.count
        guard let root = loadInductionDraftArtifact(artifact, in: directory) else {
            return artifactStatus(artifact, from: start)
        }
        validateInductionArtifactHeader(
            root,
            artifact: artifact,
            allowedKeys: [
                "apiVersion", "kind", "intentType", "domain", "subdomain", "productType",
                "criticality", "primaryConcern", "requiresExistingOntology", "confidence",
                "uncertainties", "provenance"
            ]
        )
        let intentType = requiredString(
            root,
            "intentType",
            path: "\(artifact.name).intentType",
            code: "inductionDraft.intentType.required"
        )
        validateEnum(
            intentType,
            allowed: [
                "ProductCreationIntent", "FeatureIntent", "ChangeIntent",
                "ClarificationIntent", "EvidenceIntent", "ArchitectureIntent", "PolicyIntent"
            ],
            path: "\(artifact.name).intentType",
            code: "inductionDraft.intentType.invalid"
        )
        _ = requiredString(root, "domain", path: "\(artifact.name).domain", code: "inductionDraft.domain.required")
        _ = requiredString(
            root,
            "productType",
            path: "\(artifact.name).productType",
            code: "inductionDraft.productType.required"
        )
        let criticality = requiredString(
            root,
            "criticality",
            path: "\(artifact.name).criticality",
            code: "inductionDraft.criticality.required"
        )
        validateEnum(
            criticality,
            allowed: ["low", "medium", "high"],
            path: "\(artifact.name).criticality",
            code: "inductionDraft.criticality.invalid"
        )
        _ = requiredString(
            root,
            "primaryConcern",
            path: "\(artifact.name).primaryConcern",
            code: "inductionDraft.primaryConcern.required"
        )
        _ = requiredBool(
            root,
            "requiresExistingOntology",
            path: "\(artifact.name).requiresExistingOntology",
            code: "inductionDraft.requiresExistingOntology.required"
        )
        _ = requiredConfidence(root, "confidence", path: "\(artifact.name).confidence")
        validateUncertainties(root, path: "\(artifact.name).uncertainties")
        validateProvenance(root, path: "\(artifact.name).provenance")
        return artifactStatus(artifact, from: start)
    }

    private func validateProductOntologyDraft(in directory: URL) -> JSONObject {
        let artifact = InductionDraftArtifactDescriptor(
            name: "ProductOntologyDraft",
            fileName: "product-ontology-draft.yaml"
        )
        let start = diagnostics.count
        guard let root = loadInductionDraftArtifact(artifact, in: directory) else {
            return artifactStatus(artifact, from: start)
        }
        validateInductionArtifactHeader(root, artifact: artifact, allowedKeys: ["apiVersion", "kind", "metadata", "spec"])
        validateProductOntologyDraftMetadata(root, artifact: artifact)
        validateProductOntologyDraftSpec(root, artifact: artifact)
        return artifactStatus(artifact, from: start)
    }

    private func validateDraftCritique(in directory: URL) -> JSONObject {
        let artifact = InductionDraftArtifactDescriptor(name: "DraftCritique", fileName: "draft-critique.yaml")
        let start = diagnostics.count
        guard let root = loadInductionDraftArtifact(artifact, in: directory) else {
            return artifactStatus(artifact, from: start)
        }
        validateInductionArtifactHeader(
            root,
            artifact: artifact,
            allowedKeys: ["apiVersion", "kind", "status", "summary", "scores", "issues", "questions", "provenance"]
        )
        let status = requiredString(
            root,
            "status",
            path: "\(artifact.name).status",
            code: "inductionDraft.critique.status.required"
        )
        validateEnum(
            status,
            allowed: ["approved_for_yaml", "needs_clarification", "needs_revision", "rejected"],
            path: "\(artifact.name).status",
            code: "inductionDraft.critique.status.invalid"
        )
        _ = requiredString(
            root,
            "summary",
            path: "\(artifact.name).summary",
            code: "inductionDraft.critique.summary.required"
        )
        _ = requiredObject(
            root,
            "scores",
            path: "\(artifact.name).scores",
            code: "inductionDraft.critique.scores.required"
        )
        validateIssues(root, path: "\(artifact.name).issues")
        validateQuestions(root, path: "\(artifact.name).questions")
        validateProvenance(root, path: "\(artifact.name).provenance")
        return artifactStatus(artifact, from: start)
    }

    private func validateDomainOntologyPackageDraft(in directory: URL) -> JSONObject {
        let artifact = InductionDraftArtifactDescriptor(
            name: "DomainOntologyPackageDraft",
            fileName: "domain-ontology-package-draft.yaml"
        )
        let start = diagnostics.count
        let path = directory.appendingPathComponent(artifact.fileName).path
        guard let package = load(path: path) else {
            return artifactStatus(artifact, from: start)
        }
        validate(package)
        if string(package.metadata["approvalStatus"]) != "draft" {
            add(
                "inductionDraft.package.approvalStatus.invalid",
                "\(artifact.name).metadata.approvalStatus",
                "DomainOntologyPackageDraft metadata.approvalStatus must be draft"
            )
        }
        return artifactStatus(artifact, from: start)
    }

    private func validateProductOntologyDraftMetadata(_ root: JSONObject, artifact: InductionDraftArtifactDescriptor) {
        guard let metadata = requiredObject(
            root,
            "metadata",
            path: "\(artifact.name).metadata",
            code: "inductionDraft.metadata.required"
        ) else { return }
        validateKnownKeys(
            metadata,
            allowed: ["status", "sourceIntentId", "producedBy", "confidence", "provenance", "uncertainties"],
            path: "\(artifact.name).metadata"
        )
        let status = requiredString(
            metadata,
            "status",
            path: "\(artifact.name).metadata.status",
            code: "inductionDraft.metadata.status.required"
        )
        if status != nil, status != "candidate" {
            add(
                "inductionDraft.metadata.status.invalid",
                "\(artifact.name).metadata.status",
                "ProductOntologyDraft metadata.status must be candidate"
            )
        }
        _ = requiredString(
            metadata,
            "sourceIntentId",
            path: "\(artifact.name).metadata.sourceIntentId",
            code: "inductionDraft.metadata.sourceIntentId.required"
        )
        _ = requiredString(
            metadata,
            "producedBy",
            path: "\(artifact.name).metadata.producedBy",
            code: "inductionDraft.metadata.producedBy.required"
        )
        _ = requiredConfidence(metadata, "confidence", path: "\(artifact.name).metadata.confidence")
        validateProvenance(metadata, path: "\(artifact.name).metadata.provenance")
        validateUncertainties(metadata, path: "\(artifact.name).metadata.uncertainties")
    }

    private func validateProductOntologyDraftSpec(_ root: JSONObject, artifact: InductionDraftArtifactDescriptor) {
        guard let spec = requiredObject(
            root,
            "spec",
            path: "\(artifact.name).spec",
            code: "inductionDraft.spec.required"
        ) else { return }
        validateKnownKeys(
            spec,
            allowed: [
                "namespaceCandidate", "governingConcept", "classes", "relations",
                "protocols", "policies", "stateMachines", "assumptions", "validationNotes"
            ],
            path: "\(artifact.name).spec"
        )
        _ = requiredString(
            spec,
            "namespaceCandidate",
            path: "\(artifact.name).spec.namespaceCandidate",
            code: "inductionDraft.spec.namespaceCandidate.required"
        )
        validateGoverningConcept(spec, path: "\(artifact.name).spec.governingConcept")
        for key in ["classes", "relations", "policies", "stateMachines", "assumptions", "validationNotes"] {
            _ = requiredArray(
                spec,
                key,
                path: "\(artifact.name).spec.\(key)",
                code: "inductionDraft.spec.\(key).required"
            )
        }
        if spec.keys.contains("protocols"), spec["protocols"] as? [Any] == nil {
            add("inductionDraft.spec.protocols.type", "\(artifact.name).spec.protocols", "protocols must be an array")
        }
    }

    private func loadInductionDraftArtifact(
        _ artifact: InductionDraftArtifactDescriptor,
        in directory: URL
    ) -> JSONObject? {
        let url = directory.appendingPathComponent(artifact.fileName)
        let source: String
        do {
            source = try String(contentsOf: url, encoding: .utf8)
        } catch {
            add("inductionDraft.io.read", artifact.fileName, "Cannot read file: \(error.localizedDescription)")
            return nil
        }
        scanUnsafeSource(source, filePath: url.path)

        let parsed: Any?
        do {
            parsed = try Yams.load(yaml: source)
        } catch {
            add("inductionDraft.yaml.parse", artifact.fileName, "YAML parse error: \(error)")
            return nil
        }
        guard let root = parsed as? JSONObject else {
            add("inductionDraft.type", artifact.name, "\(artifact.name) root must be a mapping object")
            return nil
        }
        scanUnsafeNode(root, path: artifact.name)
        return root
    }

    private func validateInductionArtifactHeader(
        _ root: JSONObject,
        artifact: InductionDraftArtifactDescriptor,
        allowedKeys: Set<String>
    ) {
        validateKnownKeys(root, allowed: allowedKeys, path: artifact.name)
        if string(root["apiVersion"]) != inductionDraftApiVersion {
            add(
                "inductionDraft.apiVersion.invalid",
                "\(artifact.name).apiVersion",
                "apiVersion must be \(inductionDraftApiVersion)"
            )
        }
        if string(root["kind"]) != artifact.name {
            add("inductionDraft.kind.invalid", "\(artifact.name).kind", "kind must be \(artifact.name)")
        }
    }
}
