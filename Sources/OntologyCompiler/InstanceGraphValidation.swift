import CryptoKit
import Foundation
import OntologyRules

/// Structural validation only; no source-truth, causation or liability attestation.
public struct InstanceGraphValidationResult {
    public let passed: Bool
    public let report: [String: Any]
    public let diagnostics: [Diagnostic]
}

extension OntologyCompiler {
    /// Validates a local graph against the exact reviewed eventcore-v1 artifact.
    public func validateInstanceGraph(
        graphPath: OntologySourcePath,
        ontologyIRPath: OntologySourcePath,
        outPath: OntologyOutputPath? = nil
    ) throws -> InstanceGraphValidationResult {
        var graph = JSONObject()
        var found = [Diagnostic]()
        do {
            let ir = try pinnedEventCoreIR(at: ontologyIRPath)
            graph = try boundedJSONObject(at: graphPath)
            let context = InstanceGraphValidationContext(graph: graph, ontologyIR: ir)
            guard let issues = InstanceGraphValidationSpec().decide(context) else {
                throw OntologyCompilerError.invalidArgument("instanceGraph.decision.unavailable: validation could not decide")
            }
            found = issues.map { Diagnostic(code: $0.code, severity: "error", path: $0.path, message: $0.message, hint: nil) }
        } catch {
            found = [Diagnostic(code: "instanceGraph.input", severity: "error", path: "input", message: String(describing: error), hint: nil)]
        }
        let passed = found.isEmpty
        let report: JSONObject = [
            "apiVersion": EventCoreInstanceProfile.apiVersion, "kind": "InstanceGraphValidationReport",
            "profile": EventCoreInstanceProfile.name, "status": passed ? "passed" : "failed",
            "graphKey": graphTextValue(graph, "graphKey"), "revisionKey": graphTextValue(graph, "revisionKey"),
            "ontology": EventCoreInstanceProfile.ontology, "irSHA256": EventCoreInstanceProfile.irSHA256,
            "authority": ["structuralOnly": true, "sourceTruthVerified": false, "causationVerified": false, "responsibilityVerified": false],
            "diagnostics": found.map { ["code": $0.code, "path": $0.path, "message": $0.message, "severity": $0.severity] }
        ]
        if let outPath { try write(json: report, to: outPath.url) }
        return InstanceGraphValidationResult(passed: passed, report: report, diagnostics: found)
    }

    func pinnedEventCoreIR(at path: OntologySourcePath) throws -> JSONObject {
        let data = try boundedJSONData(at: path)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard digest == EventCoreInstanceProfile.irSHA256 else {
            throw OntologyCompilerError.invalidArgument("instanceGraph.ir.pin: expected the exact reviewed eventcore-v1 normalized artifact")
        }
        return try jsonObject(data)
    }

    func boundedJSONObject(at path: OntologySourcePath) throws -> JSONObject {
        try jsonObject(boundedJSONData(at: path))
    }

    private func boundedJSONData(at path: OntologySourcePath) throws -> Data {
        let handle = try FileHandle(forReadingFrom: path.url)
        defer { try? handle.close() }
        let limit = 10 * 1024 * 1024
        let data = try handle.read(upToCount: limit + 1) ?? Data()
        guard data.count <= limit else { throw OntologyCompilerError.invalidArgument("instanceGraph.input.limit: input exceeds 10 MiB") }
        return data
    }

    private func jsonObject(_ data: Data) throws -> JSONObject {
        guard let object = try JSONSerialization.jsonObject(with: data) as? JSONObject else {
            throw OntologyCompilerError.invalidArgument("instanceGraph.input.object: input must be a JSON object")
        }
        var uniqueKeys = InstanceJSONKeyCheck(bytes: Array(data))
        try uniqueKeys.validate()
        return object
    }

    private func graphTextValue(_ object: JSONObject, _ key: String) -> String { object[key] as? String ?? "" }
}
