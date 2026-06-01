import Foundation
import OntologyRules
import Yams

extension OntologyCompiler {
    func load(path: String) -> LoadedPackage? {
        let url = URL(fileURLWithPath: path)
        let source: String
        do {
            source = try String(contentsOf: url, encoding: .utf8)
        } catch {
            add("io.read", path, "Cannot read file: \(error.localizedDescription)")
            return nil
        }

        scanUnsafeSource(source, filePath: path)

        let parsed: Any?
        do {
            parsed = try Yams.load(yaml: source)
        } catch {
            add("yaml.parse", path, "YAML parse error: \(error)")
            return nil
        }

        guard let root = parsed as? JSONObject else {
            add("package.type", "package", "Package root must be a mapping object")
            return nil
        }

        scanUnsafeNode(root, path: "package")
        validateKnownKeys(root, allowed: ["apiVersion", "kind", "metadata", "spec"], path: "package")

        if !ExpectedOntologyApiVersionSpec().isSatisfiedBy(string(root["apiVersion"]) ?? "") {
            add("apiVersion.invalid", "apiVersion", "apiVersion must be \(apiVersion)")
        }
        if !ExpectedDomainOntologyPackageKindSpec().isSatisfiedBy(string(root["kind"]) ?? "") {
            add("kind.invalid", "kind", "kind must be \(kind)")
        }

        guard let metadata = root["metadata"] as? JSONObject else {
            add("metadata.required", "metadata", "metadata object is required")
            return nil
        }
        guard let spec = root["spec"] as? JSONObject else {
            add("spec.required", "spec", "spec object is required")
            return nil
        }

        validateKnownKeys(metadata, allowed: ["id", "namespace", "version", "publisher", "source", "approvalStatus"], path: "metadata")

        let id = requiredString(metadata, "id", path: "metadata.id", code: "metadata.required") ?? ""
        let namespace = requiredString(metadata, "namespace", path: "metadata.namespace", code: "metadata.required") ?? ""
        let version = requiredString(metadata, "version", path: "metadata.version", code: "metadata.required") ?? ""

        validate(id, path: "metadata.id", code: "metadata.invalid") {
            OntologyIdPatternSpec().isSatisfiedBy($0)
        }
        validate(namespace, path: "metadata.namespace", code: "metadata.invalid") {
            OntologyNamespacePatternSpec().isSatisfiedBy($0)
        }
        validate(version, path: "metadata.version", code: "metadata.invalid") {
            OntologySemVerPatternSpec().isSatisfiedBy($0)
        }

        return LoadedPackage(
            path: path,
            source: source,
            root: root,
            metadata: metadata,
            spec: spec,
            id: id,
            namespace: namespace,
            version: version
        )
    }
}
