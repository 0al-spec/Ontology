import Foundation
import OntologyCompiler

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
        fputs("ontologyc validate-golden-intent: FAIL \(compilerError)\n", stderr)
        exit(1)
    } catch {
        fputs("ontologyc validate-golden-intent: FAIL \(error)\n", stderr)
        exit(1)
    }

case "validate-governance-decision":
    let parsed = parseArguments(commandArgs, allowedOptions: ["--package", "--golden-report", "--out"], command: command)
    requirePositionals(1, in: parsed, command: command)
    let decisionPath = parsed.positional[0]
    do {
        let result = try compiler.validateGovernanceDecision(
            decisionPath: OntologySourcePath(path: decisionPath),
            packagePath: parsed.options["--package"].map(OntologySourcePath.init(path:)),
            goldenReportPath: parsed.options["--golden-report"].map(OntologySourcePath.init(path:)),
            outPath: parsed.options["--out"].map(OntologyOutputPath.init(path:))
        )
        let reportTarget = parsed.options["--out"].map { " report=\($0)" } ?? ""
        if !result.passed {
            compiler.printDiagnostics(result.diagnostics)
            fputs("ontologyc validate-governance-decision: FAIL \(decisionPath)\(reportTarget)\n", stderr)
            exit(1)
        }
        print("ontologyc validate-governance-decision: PASS \(decisionPath)\(reportTarget)")
    } catch let compilerError as OntologyCompilerError {
        fputs("ontologyc validate-governance-decision: FAIL \(compilerError)\n", stderr)
        exit(1)
    } catch {
        fputs("ontologyc validate-governance-decision: FAIL \(error)\n", stderr)
        exit(1)
    }

default:
    usageError("unknown command \(command)")
}
