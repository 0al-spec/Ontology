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

        return load(source: source, path: path)
    }

    /// Detect the declared package kind without treating nested examples as packages.
    public func declaresPackage(_ source: String) -> Bool {
        func hasKind(_ document: Any?) -> Bool {
            let value = (document as? JSONObject)?["kind"] as? String ?? ""
            return ExpectedDomainOntologyPackageKindSpec().isSatisfiedBy(OntologyPackageKind(rawValue: value))
        }
        do {
            return try hasKind(Yams.load(yaml: source))
        } catch {
            // A broken body can still have a readable, unindented kind declaration.
            return source.split(whereSeparator: \.isNewline).contains { line in
                guard line.hasPrefix("kind:") else { return false }
                return hasKind(try? Yams.load(yaml: String(line)))
            }
        }
    }

    func load(source rawSource: String, path: String) -> LoadedPackage? {
        var source = rawSource
        // Foundation's UTF-8 file decoding differs across supported Swift versions.
        // Normalize the optional BOM once before parsing and computing IR digests.
        if source.hasPrefix("\u{feff}") { source.removeFirst() }
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

        if !ExpectedOntologyApiVersionSpec().isSatisfiedBy(OntologyApiVersion(rawValue: string(root["apiVersion"]) ?? "")) {
            add("apiVersion.invalid", "apiVersion", "apiVersion must be \(apiVersion)")
        }
        if !ExpectedDomainOntologyPackageKindSpec().isSatisfiedBy(OntologyPackageKind(rawValue: string(root["kind"]) ?? "")) {
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
            OntologyIdPatternSpec().isSatisfiedBy(OntologyPackageId(rawValue: $0))
        }
        validate(namespace, path: "metadata.namespace", code: "metadata.invalid") {
            OntologyNamespacePatternSpec().isSatisfiedBy(OntologyNamespace(rawValue: $0))
        }
        validate(version, path: "metadata.version", code: "metadata.invalid") {
            OntologySemVerPatternSpec().isSatisfiedBy(OntologySemanticVersion(rawValue: $0))
        }

        return LoadedPackage(
            path: path,
            source: source,
            root: root,
            metadata: metadata,
            spec: spec,
            packageMetadata: LoadedPackageMetadata(
                id: OntologyPackageId(rawValue: id),
                namespace: OntologyNamespace(rawValue: namespace),
                version: OntologySemanticVersion(rawValue: version)
            )
        )
    }
}
