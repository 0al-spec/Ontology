import Foundation
import OntologyRules

/// Binds only explicit, known catalog bytes to foundation identities in the dependency closure.
struct DiagramFoundationModels {
    let bindings: [JSONObject]

    init(paths: [OntologySourcePath], imports: [DiagramImportDeclaration], digest: (Data) -> String) throws {
        var models = [String: (JSONObject, String)]()
        for path in paths {
            let data: Data
            do { data = try Data(contentsOf: path.url) } catch {
                throw OntologyCompilerError.invalidArgument("Cannot read foundation model \(path.path): \(error.localizedDescription)")
            }
            guard let model = try JSONSerialization.jsonObject(with: data) as? JSONObject,
                  model["schemaVersion"] as? String == "ontology.foundation-model/v1",
                  model["id"] as? String == "ontology.foundation",
                  let version = model["version"] as? String else {
                throw OntologyCompilerError.invalidArgument("Invalid foundation model \(path.path)")
            }
            let hash = digest(data)
            guard FoundationModelBytesSpec().isSatisfiedBy(.init(version: version, digest: hash)) else {
                throw OntologyCompilerError.invalidArgument("Unsupported or modified foundation model \(version): \(path.path)")
            }
            guard models.updateValue((model, hash), forKey: version) == nil else {
                throw OntologyCompilerError.invalidArgument("Duplicate foundation model version \(version)")
            }
        }
        for version in models.keys {
            guard imports.contains(where: { $0.version.rawValue == version }) else {
                throw OntologyCompilerError.invalidArgument("Foundation model \(version) is not imported by this diagram")
            }
        }
        bindings = imports.compactMap { item in
            guard let (model, hash) = models[item.version.rawValue],
                  let exports = FoundationExports.catalog(packageID: item.id.rawValue, version: item.version.rawValue) else { return nil }
            return ["id": item.id.rawValue, "version": item.version.rawValue, "alias": item.namespace.rawValue,
                    "catalogByteDigest": hash, "policyBases": exports.policyBases, "catalog": model]
        }
    }
}
