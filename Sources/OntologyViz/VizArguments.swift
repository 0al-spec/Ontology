import Foundation
import OntologyCompiler
import OntologyRules

enum VizFormat: String {
    case both, svg, png, dot, json

    var renderedFormats: [String] {
        switch self {
        case .both: return ["svg", "png"]
        case .svg: return ["svg"]
        case .png: return ["png"]
        case .dot, .json: return []
        }
    }
}

struct VizFailure: Error, CustomStringConvertible {
    let description: String
}

struct VizArguments {
    let input: OntologySourcePath
    let output: URL
    let format: VizFormat
    let dotPath: String?
    let diagram: OntologyDiagramOptions
    let profileURL: URL?

    var sourceURLs: [URL] {
        ([input] + diagram.imports).map(\.url) + (profileURL.map { [$0] } ?? [])
    }

    init(_ arguments: [String]) throws {
        var parsed = try Self.parse(arguments)
        let profileURL: URL?
        if let path = parsed.options["--profile"]?.first {
            let profile = try VizProfile(path: path)
            parsed = try profile.applying(options: parsed.options, positionals: parsed.positionals)
            profileURL = profile.source
        } else {
            profileURL = nil
        }
        let options = parsed.options
        let positionals = parsed.positionals
        guard positionals.count == 1, !positionals[0].isEmpty else {
            throw VizFailure(description: "Expected one package YAML path")
        }
        guard let output = options["--out"]?.first else { throw VizFailure(description: "Missing required option --out") }
        guard let format = VizFormat(rawValue: options["--format"]?.first ?? "both") else {
            throw VizFailure(description: "Expected --format both, svg, png, dot or json")
        }
        let direction = try parseDiagramDirection(options["--direction"]?.first ?? "LR")
        let view = try parseDiagramView(options["--view"]?.first ?? "full")
        let imports = options["--import"] ?? []
        let expanded = (options["--expand"] ?? []).flatMap { $0.components(separatedBy: ",") }
        let decision = DiagramSelectionSpec().decide(DiagramSelectionContext(
            view: view.rawValue, hasImports: !imports.isEmpty, expandedTypes: expanded
        ))
        guard decision == .valid else {
            throw VizFailure(description: decision?.message ?? "Unknown diagram selection")
        }
        self.input = OntologySourcePath(path: positionals[0])
        self.output = URL(fileURLWithPath: output, isDirectory: true)
        self.format = format
        self.dotPath = options["--dot"]?.first
        self.diagram = OntologyDiagramOptions(direction: direction, view: view,
                                              imports: imports.map(OntologySourcePath.init(path:)), expandedTypes: expanded)
        self.profileURL = profileURL
    }

    private static func parse(_ arguments: [String]) throws -> (options: [String: [String]], positionals: [String]) {
        var options = [String: [String]]()
        var positionals = [String]()
        var index = 0
        while index < arguments.count {
            let value = arguments[index]
            if value == "--" {
                positionals += arguments.dropFirst(index + 1)
                break
            }
            if value.hasPrefix("--") {
                guard ["--out", "--format", "--direction", "--dot", "--view", "--import", "--expand", "--profile"].contains(value) else {
                    throw VizFailure(description: "Unknown option \(value)")
                }
                guard options[value] == nil || ["--import", "--expand"].contains(value) else {
                    throw VizFailure(description: "Duplicate option \(value)")
                }
                index += 1
                guard index < arguments.count, !arguments[index].hasPrefix("--"), !arguments[index].isEmpty else {
                    throw VizFailure(description: "Missing value for \(value)")
                }
                options[value, default: []].append(arguments[index])
            } else {
                positionals.append(value)
            }
            index += 1
        }
        return (options, positionals)
    }

    static let help = """
    Usage: ontologyviz <package.yaml> --out <directory> [options]
           ontologyviz --profile <profile.json> --out <directory> [options]

    Render a DomainOntologyPackage locally as a graph.

      --format both|svg|png|dot|json   Default: both. Image modes retain DOT.
      --direction LR|TB          Left-to-right (default) or top-to-bottom.
      --dot <executable>         Graphviz dot path; otherwise search PATH.
      --view full|relations      Default: full. Relations hides scaffolding.
      --import <package.yaml>    Explicit local direct import (repeatable).
      --expand <ns:Class,...>     Selected imported classes (repeatable).
      --profile <profile.json>   Saved package and selection; paths relative to profile.
      --help                     Show this help.

    Writes ontology.dot and the selected ontology.svg / ontology.png files;
    JSON mode writes ontology.graph.json without Graphviz.
    SVG/PNG require Graphviz: brew install graphviz / apt-get install graphviz.
    Import expansion requires relations view and an exact declared id/version.
    Unselected external references remain unloaded placeholders.
    Profile excludes positional package / --view / --import / --expand.
    CLI --direction overrides profile direction; --format / --out / --dot stay runtime options.
    Exit codes: 0 success, 1 package/render/I/O failure, 2 invalid arguments.
    """
}

func parseDiagramDirection(_ value: String) throws -> OntologyDiagramDirection {
    guard let direction = OntologyDiagramDirection(rawValue: value) else {
        throw VizFailure(description: "Expected direction LR or TB")
    }
    return direction
}

func parseDiagramView(_ value: String) throws -> OntologyDiagramView {
    guard let view = OntologyDiagramView(rawValue: value) else {
        throw VizFailure(description: "Expected view full or relations")
    }
    return view
}
