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
    let direction: OntologyDiagramDirection
    let dotPath: String?

    init(_ arguments: [String]) throws {
        var options = [String: String]()
        var positionals = [String]()
        var index = 0
        while index < arguments.count {
            let value = arguments[index]
            if value == "--" {
                positionals += arguments.dropFirst(index + 1)
                break
            }
            if value.hasPrefix("--") {
                guard ["--out", "--format", "--direction", "--dot"].contains(value) else {
                    throw VizFailure(description: "Unknown option \(value)")
                }
                guard options[value] == nil else { throw VizFailure(description: "Duplicate option \(value)") }
                index += 1
                guard index < arguments.count, !arguments[index].hasPrefix("--"), !arguments[index].isEmpty else {
                    throw VizFailure(description: "Missing value for \(value)")
                }
                options[value] = arguments[index]
            } else {
                positionals.append(value)
            }
            index += 1
        }
        guard positionals.count == 1, !positionals[0].isEmpty else {
            throw VizFailure(description: "Expected one package YAML path")
        }
        guard let output = options["--out"] else { throw VizFailure(description: "Missing required option --out") }
        guard let format = VizFormat(rawValue: options["--format"] ?? "both") else {
            throw VizFailure(description: "Expected --format both, svg, png or dot")
        }
        guard let direction = OntologyDiagramDirection(rawValue: options["--direction"] ?? "LR") else {
            throw VizFailure(description: "Expected --direction LR or TB")
        }
        self.input = OntologySourcePath(path: positionals[0])
        self.output = URL(fileURLWithPath: output, isDirectory: true)
        self.format = format
        self.direction = direction
        self.dotPath = options["--dot"]
    }

    static let help = """
    Usage: ontologyviz <package.yaml> --out <directory> [options]

    Render a DomainOntologyPackage locally as a graph.

      --format both|svg|png|dot   Default: both. DOT is always retained.
      --direction LR|TB          Left-to-right (default) or top-to-bottom.
      --dot <executable>         Graphviz dot path; otherwise search PATH.
      --help                     Show this help.

    Writes ontology.dot and the selected ontology.svg / ontology.png files.
    SVG/PNG require Graphviz: brew install graphviz / apt-get install graphviz.
    External references are placeholders; imported declarations are not loaded.
    Exit codes: 0 success, 1 package/render/I/O failure, 2 invalid arguments.
    """
}
