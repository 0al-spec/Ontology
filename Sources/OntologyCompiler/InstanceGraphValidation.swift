#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif
import Foundation
import OntologyRules

/// Structural validation only; no source-truth, causation or liability attestation.
public struct InstanceGraphValidationResult {
    public let passed: Bool
    public let report: [String: Any]
    public let diagnostics: [Diagnostic]
}

extension OntologyCompiler {
    /// Validates against an explicitly selected exact profile; legacy remains the default.
    public func validateInstanceGraph(
        graphPath: OntologySourcePath,
        ontologyIRPath: OntologySourcePath,
        outPath: OntologyOutputPath? = nil,
        profile: String = "eventcore-v1",
        provenanceAuthorityPath: OntologySourcePath? = nil
    ) throws -> InstanceGraphValidationResult {
        var graph = JSONObject()
        var graphSHA256 = ""
        var found = [Diagnostic]()
        var authoritySHA256 = ""
        let selected = EventCoreProfileSelection(rawValue: profile)
        do {
            guard let selected else { throw OntologyCompilerError.invalidArgument("instanceGraph.profile: unsupported explicit profile") }
            guard selected == .provenance || provenanceAuthorityPath == nil else {
                throw OntologyCompilerError.invalidArgument("instanceGraph.profile: authority input requires the provenance profile")
            }
            let ir = try pinnedEventCoreIR(at: ontologyIRPath, profile: selected)
            let graphData = try boundedJSONData(at: graphPath)
            graphSHA256 = instanceSHA256(graphData)
            graph = try jsonObject(graphData)
            var authority: JSONObject?
            if let provenanceAuthorityPath {
                let data = try boundedJSONData(at: provenanceAuthorityPath)
                authoritySHA256 = instanceSHA256(data)
                authority = try jsonObject(data)
            }
            let context = InstanceGraphValidationContext(
                graph: graph, ontologyIR: ir, profile: selected, graphSHA256: graphSHA256,
                provenanceAuthority: authority
            )
            guard let issues = InstanceGraphValidationSpec().decide(context) else {
                throw OntologyCompilerError.invalidArgument("instanceGraph.decision.unavailable: validation could not decide")
            }
            found = issues.map { Diagnostic(code: $0.code, severity: "error", path: $0.path, message: $0.message, hint: nil) }
        } catch {
            found = [Diagnostic(code: "instanceGraph.input", severity: "error", path: "input", message: String(describing: error), hint: nil)]
        }
        let passed = found.isEmpty
        var report: JSONObject = [
            "apiVersion": EventCoreInstanceProfile.apiVersion, "kind": "InstanceGraphValidationReport",
            "profile": profile, "status": passed ? "passed" : "failed",
            "graphKey": graphTextValue(graph, "graphKey"), "revisionKey": graphTextValue(graph, "revisionKey"),
            "graphSHA256": graphSHA256,
            "ontology": selected?.ontology ?? [:], "irSHA256": selected?.irSHA256 ?? "",
            "authority": ["structuralOnly": true, "sourceTruthVerified": false, "causationVerified": false, "responsibilityVerified": false],
            "diagnostics": found.map { ["code": $0.code, "path": $0.path, "message": $0.message, "severity": $0.severity] }
        ]
        if selected == .provenance {
            let snapshotCount = (graph["nodes"] as? [JSONObject] ?? []).filter { $0["type"] as? String == "eventcore:StateSnapshot" }.count
            report["profilePin"] = EventCoreProfileSelection.provenance.definitionPin
            report["provenance"] = [
                "confirmationStatus": passed ? (snapshotCount == 0 ? "no-snapshots" : "confirmed-under-supplied-authority") : "not-confirmed",
                "authorityInputSHA256": authoritySHA256,
                "authorityAuthenticationVerified": false, "sourceTruthVerified": false,
                "snapshotCount": snapshotCount
            ]
        }
        if let outPath { try write(json: report, to: outPath.url) }
        return InstanceGraphValidationResult(passed: passed, report: report, diagnostics: found)
    }

    func pinnedEventCoreIR(at path: OntologySourcePath, profile: EventCoreProfileSelection = .legacy) throws -> JSONObject {
        let data = try boundedJSONData(at: path)
        let digest = instanceSHA256(data)
        guard digest == profile.irSHA256 else {
            throw OntologyCompilerError.invalidArgument("instanceGraph.ir.pin: expected the exact reviewed \(profile.rawValue) normalized artifact")
        }
        return try jsonObject(data)
    }

    private func instanceSHA256(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }

    private func boundedJSONData(at path: OntologySourcePath) throws -> Data {
        let handle = try FileHandle(forReadingFrom: path.url)
        defer { try? handle.close() }
        let limit = 10 * 1024 * 1024
        let data = try handle.read(upToCount: limit + 1) ?? Data()
        guard data.count <= limit else { throw OntologyCompilerError.invalidArgument("instanceGraph.input.limit: input exceeds 10 MiB") }
        return data
    }

    private func jsonObject(_ data: Data) throws -> JSONObject {
        guard String(data: data, encoding: .utf8) != nil,
              !data.starts(with: [0xEF, 0xBB, 0xBF]), !data.contains(0) else {
            throw OntologyCompilerError.invalidArgument("instanceGraph.input.encoding: only UTF-8 without BOM is supported")
        }
        guard let object = try JSONSerialization.jsonObject(with: data) as? JSONObject else {
            throw OntologyCompilerError.invalidArgument("instanceGraph.input.object: input must be a JSON object")
        }
        var uniqueKeys = InstanceJSONKeyCheck(bytes: Array(data))
        try uniqueKeys.validate()
        return object
    }

    private func graphTextValue(_ object: JSONObject, _ key: String) -> String { object[key] as? String ?? "" }
}
