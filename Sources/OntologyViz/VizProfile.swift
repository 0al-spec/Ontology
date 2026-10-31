import Foundation
import OntologyCompiler

struct VizProfile {
    let source: URL
    private let document: VizProfileDocument
    private let view: OntologyDiagramView
    private let direction: OntologyDiagramDirection

    init(path: String) throws {
        let source = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
        do {
            let document = try JSONDecoder().decode(VizProfileDocument.self, from: Data(contentsOf: source))
            guard document.schemaVersion == 1 else {
                throw VizFailure(description: "Unsupported schemaVersion \(document.schemaVersion); expected 1")
            }
            let view = try parseDiagramView(document.view)
            let direction = try parseDiagramDirection(document.direction)
            let paths = [document.package] + document.imports
            guard paths.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
                throw VizFailure(description: "Profile package and import paths must be nonempty")
            }
            self.source = source
            self.document = document
            self.view = view
            self.direction = direction
        } catch {
            throw VizFailure(description: "Cannot load diagram profile \(source.path): \(error)")
        }
    }

    func applying(
        options: [String: [String]], positionals: [String]
    ) throws -> (options: [String: [String]], positionals: [String]) {
        let conflicts = ["--view", "--import", "--expand"].filter { options[$0] != nil }
        guard positionals.isEmpty, conflicts.isEmpty else {
            throw VizFailure(description: "--profile cannot be combined with a package path, --view, --import or --expand")
        }
        var result = options
        result["--view"] = [view.rawValue]
        result["--direction"] = options["--direction"] ?? [direction.rawValue]
        result["--import"] = document.imports.map(resolve)
        result["--expand"] = document.expand
        return (result, [resolve(document.package)])
    }

    private func resolve(_ path: String) -> String {
        URL(fileURLWithPath: path, relativeTo: source.deletingLastPathComponent()).standardizedFileURL.path
    }
}

private struct VizProfileDocument: Decodable {
    let schemaVersion: Int
    let package: String
    let view: String
    let direction: String
    let imports: [String]
    let expand: [String]

    private enum Keys: String, CodingKey, CaseIterable {
        case schemaVersion, package, view, direction, imports, expand
        case schema = "$schema"
    }

    init(from decoder: Decoder) throws {
        let dynamic = try decoder.container(keyedBy: ProfileKey.self)
        let unknown = Set(dynamic.allKeys.map(\.stringValue)).subtracting(Keys.allCases.map(\.rawValue)).sorted()
        guard unknown.isEmpty else {
            throw VizFailure(description: "Unknown profile fields: \(unknown.joined(separator: ", "))")
        }
        let values = try decoder.container(keyedBy: Keys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        package = try values.decode(String.self, forKey: .package)
        view = values.contains(.view) ? try values.decode(String.self, forKey: .view) : "full"
        direction = values.contains(.direction) ? try values.decode(String.self, forKey: .direction) : "LR"
        imports = values.contains(.imports) ? try values.decode([String].self, forKey: .imports) : []
        expand = values.contains(.expand) ? try values.decode([String].self, forKey: .expand) : []
        if values.contains(.schema) { _ = try values.decode(String.self, forKey: .schema) }
    }
}

private struct ProfileKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) { return nil }
}
