import Foundation
import OntologyRules

extension OntologyCompiler {
    func publishLocalPackage(
        ir: JSONObject,
        ref: OntologyPackageReference,
        registry: RegistryBaseURL,
        channel: OntologyPublishChannel
    ) throws {
        let rootURL = try localRegistryRoot(registry)
        try validateLocalRegistryReference(ref)

        let artifactURL = localRegistryArtifactURL(rootURL: rootURL, ref: ref)
        let packageDirectory = artifactURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: packageDirectory, withIntermediateDirectories: true)
        try write(json: ir, to: artifactURL)

        let sourceDigest = string(ir["sourceDigest"]) ?? ""
        let artifactPath = localRegistryArtifactPath(ref)
        try write(
            text: registryEntryText(ref: ref, channel: channel, sourceDigest: sourceDigest, artifactPath: artifactPath),
            to: packageDirectory.appendingPathComponent("registry-entry.yaml")
        )

        let channelURL = localRegistryChannelURL(rootURL: rootURL, ref: ref, channel: channel)
        try FileManager.default.createDirectory(at: channelURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try write(
            text: registryChannelEntryText(ref: ref, channel: channel, sourceDigest: sourceDigest, artifactPath: artifactPath),
            to: channelURL
        )
    }

    func pullLocalPackageData(ref: OntologyPackageReference, registry: RegistryBaseURL) throws -> Data {
        let rootURL = try localRegistryRoot(registry)
        try validateLocalRegistryReference(ref)
        let artifactURL = localRegistryArtifactURL(rootURL: rootURL, ref: ref)
        guard FileManager.default.fileExists(atPath: artifactURL.path) else {
            throw OntologyCompilerError.invalidArgument("Local registry package not found: \(ref.rawValue)")
        }
        return try Data(contentsOf: artifactURL)
    }

    private func localRegistryRoot(_ registry: RegistryBaseURL) throws -> URL {
        guard let rootURL = registry.fileRootURL else {
            throw OntologyCompilerError.invalidArgument("Registry is not a file registry: \(registry.absoluteString)")
        }
        return rootURL
    }

    private func validateLocalRegistryReference(_ ref: OntologyPackageReference) throws {
        guard OntologyIdPatternSpec().isSatisfiedBy(ref.packageId),
              OntologySemVerPatternSpec().isSatisfiedBy(ref.semanticVersion) else {
            throw OntologyCompilerError.invalidArgument("Invalid local registry package reference: \(ref.rawValue)")
        }
    }

    private func localRegistryArtifactURL(rootURL: URL, ref: OntologyPackageReference) -> URL {
        rootURL
            .appendingPathComponent("ontologies", isDirectory: true)
            .appendingPathComponent(ref.id, isDirectory: true)
            .appendingPathComponent(ref.version, isDirectory: true)
            .appendingPathComponent("ontology.normalized.json")
    }

    private func localRegistryChannelURL(
        rootURL: URL,
        ref: OntologyPackageReference,
        channel: OntologyPublishChannel
    ) -> URL {
        rootURL
            .appendingPathComponent("channels", isDirectory: true)
            .appendingPathComponent(channel.rawValue, isDirectory: true)
            .appendingPathComponent(ref.id, isDirectory: true)
            .appendingPathComponent("\(ref.version).yaml")
    }

    private func localRegistryArtifactPath(_ ref: OntologyPackageReference) -> String {
        "ontologies/\(ref.id)/\(ref.version)/ontology.normalized.json"
    }

    private func registryEntryText(
        ref: OntologyPackageReference,
        channel: OntologyPublishChannel,
        sourceDigest: String,
        artifactPath: String
    ) -> String {
        """
        apiVersion: ontology.registry.specgraph.io/v1alpha1
        kind: OntologyRegistryEntry
        metadata:
          id: \(ref.id)
          version: \(ref.version)
          channel: \(channel.rawValue)
          sourceDigest: \(sourceDigest)
        spec:
          artifact: \(artifactPath)
        """ + "\n"
    }

    private func registryChannelEntryText(
        ref: OntologyPackageReference,
        channel: OntologyPublishChannel,
        sourceDigest: String,
        artifactPath: String
    ) -> String {
        """
        apiVersion: ontology.registry.specgraph.io/v1alpha1
        kind: OntologyRegistryChannelEntry
        metadata:
          id: \(ref.id)
          version: \(ref.version)
          channel: \(channel.rawValue)
        spec:
          artifact: \(artifactPath)
          sourceDigest: \(sourceDigest)
        """ + "\n"
    }
}
