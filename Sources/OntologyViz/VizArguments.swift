import Foundation
import OntologyCompiler

enum VizFormat: String {
    case both, svg, png, dot

    var renderedFormats: [String] {
        switch self {
        case .both: return ["svg", "png"]
        case .svg: return ["svg"]
        case .png: return ["png"]
        case .dot: return []
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

    init(_ arguments: [String]) throws {
        let parsed = try Self.parse(arguments)
        let options = parsed.options
        let positionals = parsed.positionals
        guard positionals.count == 1, !positionals[0].isEmpty else {
            throw VizFailure(description: "Expected one package YAML path")
        }
        guard let output = options["--out"]?.first else { throw VizFailure(description: "Missing required option --out") }
        guard let format = VizFormat(rawValue: options["--format"]?.first ?? "both") else {
            throw VizFailure(description: "Expected --format both, svg, png or dot")
        }
        guard let direction = OntologyDiagramDirection(rawValue: options["--direction"]?.first ?? "LR") else {
            throw VizFailure(description: "Expected --direction LR or TB")
        }
        guard let view = OntologyDiagramView(rawValue: options["--view"]?.first ?? "full") else {
            throw VizFailure(description: "Expected --view full or relations")
        }
        let imports = options["--import"] ?? []
        let expanded = (options["--expand"] ?? []).flatMap { $0.components(separatedBy: ",") }
        guard !expanded.contains(where: \.isEmpty), imports.isEmpty == expanded.isEmpty else {
            throw VizFailure(description: "Supply --import and nonempty --expand selectors together")
        }
        guard view == .relations || imports.isEmpty else { throw VizFailure(description: "Import expansion requires --view relations") }
        self.input = OntologySourcePath(path: positionals[0])
        self.output = URL(fileURLWithPath: output, isDirectory: true)
        self.format = format
        self.dotPath = options["--dot"]?.first
        self.diagram = OntologyDiagramOptions(direction: direction, view: view,
                                              imports: imports.map(OntologySourcePath.init(path:)), expandedTypes: expanded)
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
                guard ["--out", "--format", "--direction", "--dot", "--view", "--import", "--expand"].contains(value) else {
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

    Render a DomainOntologyPackage locally as a graph.

      --format both|svg|png|dot   Default: both. DOT is always retained.
      --direction LR|TB          Left-to-right (default) or top-to-bottom.
      --dot <executable>         Graphviz dot path; otherwise search PATH.
      --view full|relations      Default: full. Relations hides scaffolding.
      --import <package.yaml>    Explicit local direct import (repeatable).
      --expand <ns:Class,...>     Selected imported classes (repeatable).
      --help                     Show this help.

    Writes ontology.dot and the selected ontology.svg / ontology.png files.
    SVG/PNG require Graphviz: brew install graphviz / apt-get install graphviz.
    Import expansion requires relations view and an exact declared id/version.
    Unselected external references remain unloaded placeholders.
    Exit codes: 0 success, 1 package/render/I/O failure, 2 invalid arguments.
    """
}
