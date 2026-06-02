import Foundation
import OntologyCompiler
import OntologyRules

let generalUsage = """
Usage:
  ontologyc <command> [options]

Commands:
  check               Validate a package YAML.
  compile             Compile a package YAML to TypeScript artifacts.
  validate-specgraph  Validate SpecGraph semantic bindings against ontology IR.
  diff                Compare two package YAML files for compatibility.
  publish             Publish compiled ontology IR to a registry.
  pull                Download published ontology IR from a registry.
  compat-check        Compare local package compatibility against registry IR.
  import-hypercode    Convert Hypercode IR into a DomainOntologyPackage draft.
  validate-golden-intent
                      Validate candidate ontology YAML against a golden intent expectation.
  validate-governance-decision
                      Validate ontology governance decision YAML.

Run `ontologyc <command> --help` for command-specific usage.
"""

let commandUsage: [String: String] = [
    "check": "Usage:\n  ontologyc check <package.yaml>",
    "compile": "Usage:\n  ontologyc compile <package.yaml> --target typescript --out <directory>",
    "validate-specgraph": "Usage:\n  ontologyc validate-specgraph <binding.yaml> --ontology-ir <ontology.normalized.json> --out <directory>",
    "diff": "Usage:\n  ontologyc diff --from <old-package.yaml> --to <new-package.yaml> --out <report.yaml>",
    "publish": "Usage:\n  ontologyc publish <package.yaml> --registry <url> [--token <token>]",
    "pull": "Usage:\n  ontologyc pull <id>@<version> --registry <url> --out <directory> [--token <token>]",
    "compat-check": "Usage:\n  ontologyc compat-check <package.yaml> --against <id>@<version> --registry <url> [--out <report.yaml>] [--token <token>]",
    "import-hypercode": "Usage:\n  ontologyc import-hypercode <hypercode-ir.json> --out <draft.yaml> --id <package-id> --namespace <namespace> --version <semver>",
    "validate-golden-intent": "Usage:\n  ontologyc validate-golden-intent <expectation.yaml> --candidate <package.yaml> [--out <report.yaml>]",
    "validate-governance-decision": "Usage:\n  ontologyc validate-governance-decision <decision.yaml> [--package <package.yaml>] [--golden-report <report.yaml>] [--out <report.yaml>]"
]

struct ParsedArguments {
    let positional: [String]
    let options: [String: String]
}

func printHelp(_ text: String) -> Never {
    print(text)
    exit(0)
}

func usageError(_ message: String, command: String? = nil) -> Never {
    fputs("ontologyc: \(message)\n\n", stderr)
    fputs((command.flatMap { commandUsage[$0] } ?? generalUsage) + "\n", stderr)
    exit(2)
}

func parseArguments(
    _ raw: ArraySlice<String>,
    allowedOptions: Set<String>,
    command: String
) -> ParsedArguments {
    var positional: [String] = []
    var options: [String: String] = [:]
    var index = raw.startIndex

    while index < raw.endIndex {
        let value = raw[index]
        if value == "--" {
            index = raw.index(after: index)
            positional.append(contentsOf: raw[index...])
            break
        } else if value.hasPrefix("--") {
            let parts = value.split(separator: "=", maxSplits: 1).map(String.init)
            let optionName = parts[0]
            guard allowedOptions.contains(optionName) else {
                usageError("unknown option \(optionName)", command: command)
            }
            if parts.count == 2 {
                guard !parts[1].isEmpty else {
                    usageError("missing value for \(optionName)", command: command)
                }
                options[optionName] = parts[1]
                index = raw.index(after: index)
                continue
            }
            let next = raw.index(after: index)
            guard next < raw.endIndex, raw[next] != "--" else {
                usageError("missing value for \(optionName)", command: command)
            }
            if raw[next].hasPrefix("--"), allowedOptions.contains(raw[next]) {
                usageError("missing value for \(optionName)", command: command)
            }
            options[optionName] = raw[next]
            index = raw.index(after: next)
        } else if value.hasPrefix("-") {
            usageError("unknown option \(value)", command: command)
        } else {
            positional.append(value)
            index = raw.index(after: index)
        }
    }

    return ParsedArguments(positional: positional, options: options)
}

func requireOption(_ name: String, in parsed: ParsedArguments, command: String) -> String {
    guard let value = parsed.options[name] else {
        usageError("missing required option \(name)", command: command)
    }
    return value
}

func requirePositionals(_ count: Int, in parsed: ParsedArguments, command: String) {
    guard parsed.positional.count == count else {
        let noun = count == 1 ? "argument" : "arguments"
        usageError("expected \(count) positional \(noun), got \(parsed.positional.count)", command: command)
    }
}

func authToken(from parsed: ParsedArguments) -> String? {
    parsed.options["--token"] ?? ProcessInfo.processInfo.environment["ONTOLOGYC_TOKEN"]
}

func registryBaseURL(_ value: String, command: String) -> RegistryBaseURL {
    guard let registry = RegistryBaseURL(string: value) else {
        usageError("invalid registry URL \(value)", command: command)
    }
    return registry
}

func packageReference(_ value: String, command: String) -> OntologyPackageReference {
    guard let ref = OntologyPackageReference(rawValue: value) else {
        usageError("expected package reference <id>@<version>, got \(value)", command: command)
    }
    return ref
}

func packageId(_ value: String, command: String) -> OntologyPackageId {
    let id = OntologyPackageId(rawValue: value)
    guard OntologyIdPatternSpec().isSatisfiedBy(id) else {
        usageError("invalid package id \(value)", command: command)
    }
    return id
}

func namespace(_ value: String, command: String) -> OntologyNamespace {
    let namespace = OntologyNamespace(rawValue: value)
    guard OntologyNamespacePatternSpec().isSatisfiedBy(namespace) else {
        usageError("invalid namespace \(value)", command: command)
    }
    return namespace
}

func semanticVersion(_ value: String, command: String) -> OntologySemanticVersion {
    let version = OntologySemanticVersion(rawValue: value)
    guard OntologySemVerPatternSpec().isSatisfiedBy(version) else {
        usageError("invalid semantic version \(value)", command: command)
    }
    return version
}
