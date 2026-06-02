import Foundation
import OntologyCompiler
import OntologyRules

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
  import-hypercode    Convert Hypercode IR into a DomainOntologyPackage draft.
  validate-golden-intent
                      Validate candidate ontology YAML against a golden intent expectation.

Run `ontologyc <command> --help` for command-specific usage.
"""

private let commandUsage: [String: String] = [
    "check": "Usage:\n  ontologyc check <package.yaml>",
    "compile": "Usage:\n  ontologyc compile <package.yaml> --target typescript --out <directory>",
    "validate-specgraph": "Usage:\n  ontologyc validate-specgraph <binding.yaml> --ontology-ir <ontology.normalized.json> --out <directory>",
    "diff": "Usage:\n  ontologyc diff --from <old-package.yaml> --to <new-package.yaml> --out <report.yaml>",
    "publish": "Usage:\n  ontologyc publish <package.yaml> --registry <url> [--token <token>]",
    "pull": "Usage:\n  ontologyc pull <id>@<version> --registry <url> --out <directory> [--token <token>]",
    "compat-check": "Usage:\n  ontologyc compat-check <package.yaml> --against <id>@<version> --registry <url> [--out <report.yaml>] [--token <token>]",
    "import-hypercode": "Usage:\n  ontologyc import-hypercode <hypercode-ir.json> --out <draft.yaml> --id <package-id> --namespace <namespace> --version <semver>",
    "validate-golden-intent": "Usage:\n  ontologyc validate-golden-intent <expectation.yaml> --candidate <package.yaml> [--out <report.yaml>]"
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

private func registryBaseURL(_ value: String, command: String) -> RegistryBaseURL {
    guard let registry = RegistryBaseURL(string: value) else {
        usageError("invalid registry URL \(value)", command: command)
    }
    return registry
}

private func packageReference(_ value: String, command: String) -> OntologyPackageReference {
    guard let ref = OntologyPackageReference(rawValue: value) else {
        usageError("expected package reference <id>@<version>, got \(value)", command: command)
    }
    return ref
}

private func packageId(_ value: String, command: String) -> OntologyPackageId {
    let id = OntologyPackageId(rawValue: value)
    guard OntologyIdPatternSpec().isSatisfiedBy(id) else {
        usageError("invalid package id \(value)", command: command)
    }
    return id
}

private func namespace(_ value: String, command: String) -> OntologyNamespace {
    let namespace = OntologyNamespace(rawValue: value)
    guard OntologyNamespacePatternSpec().isSatisfiedBy(namespace) else {
        usageError("invalid namespace \(value)", command: command)
    }
    return namespace
}

private func semanticVersion(_ value: String, command: String) -> OntologySemanticVersion {
    let version = OntologySemanticVersion(rawValue: value)
    guard OntologySemVerPatternSpec().isSatisfiedBy(version) else {
        usageError("invalid semantic version \(value)", command: command)
    }
    return version
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
    let diagnostics = compiler.check(path: OntologySourcePath(path: path))
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
        let diagnostics = try compiler.compile(
            path: OntologySourcePath(path: path),
            outDirectory: OntologyOutputDirectory(path: outDirectory)
        )
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
            bindingPath: OntologySourcePath(path: bindingPath),
            ontologyIRPath: OntologySourcePath(path: ontologyIR),
            outDirectory: OntologyOutputDirectory(path: outDirectory)
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
        let diagnostics = try compiler.diffPackages(
            from: OntologySourcePath(path: from),
            to: OntologySourcePath(path: to),
            outPath: OntologyOutputPath(path: outPath)
        )
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
            path: OntologySourcePath(path: publishPath),
            registry: registryBaseURL(publishRegistry, command: command),
            token: authToken(from: parsed)
        )
        print("ontologyc publish: PASS \(result.packageRef.rawValue)")
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
            ref: packageReference(pullRef, command: command),
            registry: registryBaseURL(pullRegistry, command: command),
            token: authToken(from: parsed),
            outDirectory: OntologyOutputDirectory(path: pullOutDirectory)
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
            path: OntologySourcePath(path: compatPath),
            against: packageReference(compatRef, command: command),
            registry: registryBaseURL(compatRegistry, command: command),
            token: authToken(from: parsed),
            outPath: parsed.options["--out"].map(OntologyOutputPath.init(path:))
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

case "import-hypercode":
    let parsed = parseArguments(
        commandArgs,
        allowedOptions: ["--out", "--id", "--namespace", "--version"],
        command: command
    )
    requirePositionals(1, in: parsed, command: command)
    let irPath = parsed.positional[0]
    let outPath = requireOption("--out", in: parsed, command: command)
    let packageId = packageId(requireOption("--id", in: parsed, command: command), command: command)
    let packageNamespace = namespace(requireOption("--namespace", in: parsed, command: command), command: command)
    let packageVersion = semanticVersion(requireOption("--version", in: parsed, command: command), command: command)
    do {
        let diagnostics = try compiler.importHypercode(
            path: OntologySourcePath(path: irPath),
            outPath: OntologyOutputPath(path: outPath),
            packageId: packageId,
            namespace: packageNamespace,
            version: packageVersion
        )
        if compiler.hasErrors(diagnostics) {
            compiler.printDiagnostics(diagnostics)
            exit(1)
        }
        print("ontologyc import-hypercode: PASS \(outPath)")
    } catch {
        fputs("ontologyc import-hypercode: FAIL \(error)\n", stderr)
        exit(1)
    }

case "validate-golden-intent":
    let parsed = parseArguments(commandArgs, allowedOptions: ["--candidate", "--out"], command: command)
    requirePositionals(1, in: parsed, command: command)
    let expectationPath = parsed.positional[0]
    let candidatePath = requireOption("--candidate", in: parsed, command: command)
    do {
        let result = try compiler.validateGoldenIntent(
            expectationPath: OntologySourcePath(path: expectationPath),
            candidatePath: OntologySourcePath(path: candidatePath),
            outPath: parsed.options["--out"].map(OntologyOutputPath.init(path:))
        )
        let reportTarget = parsed.options["--out"].map { " report=\($0)" } ?? ""
        if !result.passed {
            fputs("ontologyc validate-golden-intent: FAIL \(candidatePath)\(reportTarget)\n", stderr)
            exit(1)
        }
        print("ontologyc validate-golden-intent: PASS \(candidatePath)\(reportTarget)")
    } catch let compilerError as OntologyCompilerError {
        if case .packageError(let diagnostics) = compilerError { compiler.printDiagnostics(diagnostics) }
        fputs("ontologyc validate-golden-intent: FAIL \(compilerError)\n", stderr)
        exit(1)
    } catch {
        fputs("ontologyc validate-golden-intent: FAIL \(error)\n", stderr)
        exit(1)
    }

default:
    usageError("unknown command \(command)")
}
