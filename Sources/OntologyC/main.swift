import Foundation
import OntologyCompiler

private let generalUsage = """
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

Run `ontologyc <command> --help` for command-specific usage.
"""

private let commandUsage: [String: String] = [
    "check": """
    Usage:
      ontologyc check <package.yaml>
    """,
    "compile": """
    Usage:
      ontologyc compile <package.yaml> --target typescript --out <directory>
    """,
    "validate-specgraph": """
    Usage:
      ontologyc validate-specgraph <binding.yaml> --ontology-ir <ontology.normalized.json> --out <directory>
    """,
    "diff": """
    Usage:
      ontologyc diff --from <old-package.yaml> --to <new-package.yaml> --out <report.yaml>
    """,
    "publish": """
    Usage:
      ontologyc publish <package.yaml> --registry <url> [--token <token>]
    """,
    "pull": """
    Usage:
      ontologyc pull <id>@<version> --registry <url> --out <directory> [--token <token>]
    """,
    "compat-check": """
    Usage:
      ontologyc compat-check <package.yaml> --against <id>@<version> --registry <url> [--out <report.yaml>] [--token <token>]
    """
]

private struct ParsedArguments {
    let positional: [String]
    let options: [String: String]
}

private func printHelp(_ text: String) -> Never {
    print(text)
    exit(0)
}

private func usageError(_ message: String, command: String? = nil) -> Never {
    fputs("ontologyc: \(message)\n\n", stderr)
    fputs((command.flatMap { commandUsage[$0] } ?? generalUsage) + "\n", stderr)
    exit(2)
}

private func parseArguments(
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

private func requireOption(_ name: String, in parsed: ParsedArguments, command: String) -> String {
    guard let value = parsed.options[name] else {
        usageError("missing required option \(name)", command: command)
    }
    return value
}

private func requirePositionals(_ count: Int, in parsed: ParsedArguments, command: String) {
    guard parsed.positional.count == count else {
        let noun = count == 1 ? "argument" : "arguments"
        usageError("expected \(count) positional \(noun), got \(parsed.positional.count)", command: command)
    }
}

private func authToken(from parsed: ParsedArguments) -> String? {
    parsed.options["--token"] ?? ProcessInfo.processInfo.environment["ONTOLOGYC_TOKEN"]
}

let args = Array(CommandLine.arguments.dropFirst())

if args.first == "--help" || args.first == "-h" {
    printHelp(generalUsage)
}

guard let command = args.first else {
    usageError("missing command")
}

guard commandUsage.keys.contains(command) else {
    usageError("unknown command \(command)")
}

let commandArgs = args.dropFirst()
if commandArgs.contains("--help") || commandArgs.contains("-h") {
    printHelp(commandUsage[command] ?? generalUsage)
}

let compiler = OntologyCompiler()

switch command {
case "check":
    let parsed = parseArguments(commandArgs, allowedOptions: [], command: command)
    requirePositionals(1, in: parsed, command: command)
    let path = parsed.positional[0]
    let diagnostics = compiler.check(path: path)
    if compiler.hasErrors(diagnostics) {
        compiler.printDiagnostics(diagnostics)
        exit(1)
    }
    print("ontologyc check: PASS \(path)")

case "compile":
    let parsed = parseArguments(commandArgs, allowedOptions: ["--target", "--out"], command: command)
    requirePositionals(1, in: parsed, command: command)
    let path = parsed.positional[0]
    let target = requireOption("--target", in: parsed, command: command)
    guard target == "typescript" else {
        usageError("unsupported target \(target); expected typescript", command: command)
    }
    let outDirectory = requireOption("--out", in: parsed, command: command)
    do {
        let diagnostics = try compiler.compile(path: path, outDirectory: outDirectory)
        if compiler.hasErrors(diagnostics) {
            compiler.printDiagnostics(diagnostics)
            exit(1)
        }
        print("ontologyc compile: PASS \(outDirectory)")
    } catch {
        fputs("ontologyc compile: FAIL \(error)\n", stderr)
        exit(1)
    }

case "validate-specgraph":
    let parsed = parseArguments(commandArgs, allowedOptions: ["--ontology-ir", "--out"], command: command)
    requirePositionals(1, in: parsed, command: command)
    let bindingPath = parsed.positional[0]
    let ontologyIR = requireOption("--ontology-ir", in: parsed, command: command)
    let outDirectory = requireOption("--out", in: parsed, command: command)
    do {
        let result = try compiler.validateSpecGraph(
            bindingPath: bindingPath,
            ontologyIRPath: ontologyIR,
            outDirectory: outDirectory
        )
        print("ontologyc validate-specgraph: PASS \(bindingPath) resolved=\(result.resolved) gaps=\(result.gaps)")
    } catch {
        fputs("ontologyc validate-specgraph: FAIL \(error)\n", stderr)
        exit(1)
    }

case "diff":
    let parsed = parseArguments(commandArgs, allowedOptions: ["--from", "--to", "--out"], command: command)
    requirePositionals(0, in: parsed, command: command)
    let from = requireOption("--from", in: parsed, command: command)
    let to = requireOption("--to", in: parsed, command: command)
    let outPath = requireOption("--out", in: parsed, command: command)
    do {
        let diagnostics = try compiler.diffPackages(from: from, to: to, outPath: outPath)
        if compiler.hasErrors(diagnostics) {
            compiler.printDiagnostics(diagnostics)
            exit(1)
        }
        print("ontologyc diff: PASS \(outPath)")
    } catch {
        fputs("ontologyc diff: FAIL \(error)\n", stderr)
        exit(1)
    }

case "publish":
    let parsed = parseArguments(commandArgs, allowedOptions: ["--registry", "--token"], command: command)
    requirePositionals(1, in: parsed, command: command)
    let publishPath = parsed.positional[0]
    let publishRegistry = requireOption("--registry", in: parsed, command: command)
    do {
        let result = try compiler.publishPackage(
            path: publishPath,
            registry: publishRegistry,
            token: authToken(from: parsed)
        )
        print("ontologyc publish: PASS \(result.packageRef)")
    } catch let compilerError as OntologyCompilerError {
        if case .packageError(let diagnostics) = compilerError { compiler.printDiagnostics(diagnostics) }
        fputs("ontologyc publish: FAIL \(compilerError)\n", stderr)
        exit(1)
    } catch {
        fputs("ontologyc publish: FAIL \(error)\n", stderr)
        exit(1)
    }

case "pull":
    let parsed = parseArguments(commandArgs, allowedOptions: ["--registry", "--out", "--token"], command: command)
    requirePositionals(1, in: parsed, command: command)
    let pullRef = parsed.positional[0]
    let pullRegistry = requireOption("--registry", in: parsed, command: command)
    let pullOutDirectory = requireOption("--out", in: parsed, command: command)
    do {
        try compiler.pullPackage(
            ref: pullRef,
            registry: pullRegistry,
            token: authToken(from: parsed),
            outDirectory: pullOutDirectory
        )
        print("ontologyc pull: PASS \(pullRef)")
    } catch {
        fputs("ontologyc pull: FAIL \(error)\n", stderr)
        exit(1)
    }

case "compat-check":
    let parsed = parseArguments(
        commandArgs,
        allowedOptions: ["--against", "--registry", "--out", "--token"],
        command: command
    )
    requirePositionals(1, in: parsed, command: command)
    let compatPath = parsed.positional[0]
    let compatRef = requireOption("--against", in: parsed, command: command)
    let compatRegistry = requireOption("--registry", in: parsed, command: command)
    do {
        let compatible = try compiler.compatCheckPackage(
            path: compatPath,
            against: compatRef,
            registry: compatRegistry,
            token: authToken(from: parsed),
            outPath: parsed.options["--out"]
        )
        if !compatible {
            fputs("ontologyc compat-check: BREAKING CHANGES DETECTED in \(compatPath)\n", stderr)
            exit(1)
        }
        print("ontologyc compat-check: PASS \(compatPath)")
    } catch let compilerError as OntologyCompilerError {
        if case .packageError(let diagnostics) = compilerError { compiler.printDiagnostics(diagnostics) }
        fputs("ontologyc compat-check: FAIL \(compilerError)\n", stderr)
        exit(1)
    } catch {
        fputs("ontologyc compat-check: FAIL \(error)\n", stderr)
        exit(1)
    }

default:
    usageError("unknown command \(command)")
}
