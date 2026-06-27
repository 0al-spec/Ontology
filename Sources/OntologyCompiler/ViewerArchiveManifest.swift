import Foundation

public struct ViewerArchiveManifestResult: Equatable, Sendable {
    public let artifactCount: Int
}

extension OntologyCompiler {
    public func exportViewerArchiveManifest(
        packagePath: OntologySourcePath,
        generatedDirectory: OntologyOutputDirectory,
        outPath: OntologyOutputPath
    ) throws -> ViewerArchiveManifestResult {
        diagnostics = []
        guard let package = load(path: packagePath.path) else {
            throw OntologyCompilerError.packageError(diagnostics)
        }
        validate(package)
        if hasErrors(diagnostics) {
            throw OntologyCompilerError.packageError(diagnostics)
        }

        let packageURL = packagePath.url.standardizedFileURL
        let generatedURL = generatedDirectory.url.standardizedFileURL
        let manifestURL = outPath.url
        let normalizedIRURL = generatedURL.appendingPathComponent("ontology.normalized.json")

        guard FileManager.default.fileExists(atPath: normalizedIRURL.path) else {
            add(
                "viewerArchive.normalizedIR.missing",
                generatedDirectory.path,
                "generated directory must contain ontology.normalized.json"
            )
            throw OntologyCompilerError.packageError(diagnostics)
        }

        let artifacts = viewerArchiveArtifacts(
            packageURL: packageURL,
            generatedURL: generatedURL,
            manifestURL: manifestURL
        )

        let manifest: JSONObject = [
            "artifact_kind": "ontology_viewer_archive_manifest",
            "schema_version": 1,
            "package": [
                "id": package.id,
                "namespace": package.namespace,
                "version": package.version
            ],
            "authority_boundary": [
                "viewer_manifest_is_authority": false,
                "may_write_ontology_package": false,
                "may_publish_registry_entry": false,
                "may_mutate_specgraph": false
            ],
            "artifacts": artifacts,
            "public_safety": [
                "public_safe_roles": ["package_source", "normalized_ir", "generated_sdk"],
                "local_only_roles": ["governance_evidence", "private_decision_record"],
                "notes": [
                    "The viewer archive manifest is an inert input contract for SpecSpace.",
                    "SpecSpace must not execute generated SDK files or treat this manifest as publication approval."
                ]
            ]
        ]

        if let parent = manifestURL.deletingLastPathComponent().nilIfRoot {
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        }
        try write(json: manifest, to: manifestURL)
        return ViewerArchiveManifestResult(artifactCount: artifacts.count)
    }

    private func viewerArchiveArtifacts(
        packageURL: URL,
        generatedURL: URL,
        manifestURL: URL
    ) -> [JSONObject] {
        var artifacts: [JSONObject] = [
            [
                "path": relativePath(from: manifestURL, to: packageURL),
                "role": "package_source",
                "required": true,
                "media_type": "application/yaml"
            ],
            [
                "path": relativePath(
                    from: manifestURL,
                    to: generatedURL.appendingPathComponent("ontology.normalized.json")
                ),
                "role": "normalized_ir",
                "required": true,
                "media_type": "application/json"
            ]
        ]

        for filename in generatedViewerSDKFiles() {
            let url = generatedURL.appendingPathComponent(filename)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            artifacts.append([
                "path": relativePath(from: manifestURL, to: url),
                "role": "generated_sdk",
                "required": false,
                "media_type": "text/typescript"
            ])
        }

        return artifacts.sorted {
            (string($0["role"]) ?? "", string($0["path"]) ?? "") <
                (string($1["role"]) ?? "", string($1["path"]) ?? "")
        }
    }

    private func generatedViewerSDKFiles() -> [String] {
        [
            "refs.ts",
            "types.ts",
            "relations.ts",
            "policies.ts",
            "state-machines.ts",
            "protocols.ts",
            "schemas.ts",
            "registry.ts",
            "validators.ts"
        ]
    }

    private func relativePath(from baseFile: URL, to target: URL) -> String {
        let base = baseFile.deletingLastPathComponent().standardizedFileURL.pathComponents
        let targetComponents = target.standardizedFileURL.pathComponents
        var index = 0
        while index < base.count, index < targetComponents.count, base[index] == targetComponents[index] {
            index += 1
        }
        let up = Array(repeating: "..", count: base.count - index)
        let down = targetComponents[index...]
        let joined = (up + down).joined(separator: "/")
        return joined.isEmpty ? "." : joined
    }
}

private extension URL {
    var nilIfRoot: URL? {
        path == "/" ? nil : self
    }
}
