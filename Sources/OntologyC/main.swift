import Foundation
import OntologyCompiler
import OntologyRules

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
case "validate-instances", "export-instance-contract":
    runInstanceGraphCommand(command, arguments: commandArgs, compiler: compiler)

case "export-foundation":
    let parsed = parseArguments(commandArgs, allowedOptions: [], command: command)
    requirePositionals(0, in: parsed, command: command)
    printJSON(FoundationExports.version010)

case "check":
    let parsed = parseArguments(commandArgs, allowedOptions: ["--format"], command: command)
    requirePositionals(1, in: parsed, command: command)
    let path = parsed.positional[0]
    let format = parsed.options["--format"] ?? "text"
    guard ["text", "json"].contains(format) else { usageError("expected --format text or json", command: command) }
    let diagnostics = compiler.check(path: OntologySourcePath(path: path))
    if format == "json" {
        printJSON(diagnostics)
        exit(compiler.hasErrors(diagnostics) ? 1 : 0)
    }
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
        writeDiagnostic("ontologyc compile: FAIL \(error)\n")
        exit(1)
    }

case "validate-specgraph":
    let parsed = parseArguments(
        commandArgs,
        allowedOptions: ["--ontology-ir", "--out", "--source-uri", "--source-ref"],
        command: command
    )
    requirePositionals(1, in: parsed, command: command)
    let bindingPath = parsed.positional[0]
    let ontologyIR = requireOption("--ontology-ir", in: parsed, command: command)
    let outDirectory = requireOption("--out", in: parsed, command: command)
    do {
        let result = try compiler.validateSpecGraph(
            bindingPath: OntologySourcePath(path: bindingPath),
            ontologyIRPath: OntologySourcePath(path: ontologyIR),
            outDirectory: OntologyOutputDirectory(path: outDirectory),
            sourceURI: parsed.options["--source-uri"] ?? "",
            sourceRef: parsed.options["--source-ref"] ?? ""
        )
        print("ontologyc validate-specgraph: PASS \(bindingPath) resolved=\(result.resolved) gaps=\(result.gaps)")
    } catch {
        writeDiagnostic("ontologyc validate-specgraph: FAIL \(error)\n")
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
        writeDiagnostic("ontologyc diff: FAIL \(error)\n")
        exit(1)
    }

case "publish":
    let parsed = parseArguments(
        commandArgs,
        allowedOptions: ["--registry", "--token", "--channel", "--decision", "--golden-report"],
        command: command
    )
    requirePositionals(1, in: parsed, command: command)
    let publishPath = parsed.positional[0]
    let publishRegistry = requireOption("--registry", in: parsed, command: command)
    let channel = publishChannel(parsed.options["--channel"] ?? "candidate", command: command)
    do {
        let result = try compiler.publishPackage(
            path: OntologySourcePath(path: publishPath),
            registry: registryBaseURL(publishRegistry, command: command),
            token: authToken(from: parsed),
            channel: channel,
            governanceDecisionPath: parsed.options["--decision"].map(OntologySourcePath.init(path:)),
            goldenReportPath: parsed.options["--golden-report"].map(OntologySourcePath.init(path:))
        )
        print("ontologyc publish: PASS \(result.packageRef.rawValue) channel=\(channel.rawValue)")
    } catch let compilerError as OntologyCompilerError {
        if case .packageError(let diagnostics) = compilerError { compiler.printDiagnostics(diagnostics) }
        writeDiagnostic("ontologyc publish: FAIL \(compilerError)\n")
        exit(1)
    } catch {
        writeDiagnostic("ontologyc publish: FAIL \(error)\n")
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
        writeDiagnostic("ontologyc pull: FAIL \(error)\n")
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
            writeDiagnostic("ontologyc compat-check: BREAKING CHANGES DETECTED in \(compatPath)\n")
            exit(1)
        }
        print("ontologyc compat-check: PASS \(compatPath)")
    } catch let compilerError as OntologyCompilerError {
        if case .packageError(let diagnostics) = compilerError { compiler.printDiagnostics(diagnostics) }
        writeDiagnostic("ontologyc compat-check: FAIL \(compilerError)\n")
        exit(1)
    } catch {
        writeDiagnostic("ontologyc compat-check: FAIL \(error)\n")
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
        writeDiagnostic("ontologyc import-hypercode: FAIL \(error)\n")
        exit(1)
    }

case "validate-draft":
    let parsed = parseArguments(commandArgs, allowedOptions: ["--out"], command: command)
    requirePositionals(1, in: parsed, command: command)
    let draftDirectory = parsed.positional[0]
    do {
        let result = try compiler.validateInductionDraft(
            directory: OntologySourcePath(path: draftDirectory),
            outPath: parsed.options["--out"].map(OntologyOutputPath.init(path:))
        )
        let reportTarget = parsed.options["--out"].map { " report=\($0)" } ?? ""
        if !result.passed {
            compiler.printDiagnostics(result.diagnostics)
            writeDiagnostic("ontologyc validate-draft: FAIL \(draftDirectory)\(reportTarget)\n")
            exit(1)
        }
        print("ontologyc validate-draft: PASS \(draftDirectory)\(reportTarget)")
    } catch let compilerError as OntologyCompilerError {
        writeDiagnostic("ontologyc validate-draft: FAIL \(compilerError)\n")
        exit(1)
    } catch {
        writeDiagnostic("ontologyc validate-draft: FAIL \(error)\n")
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
            writeDiagnostic("ontologyc validate-golden-intent: FAIL \(candidatePath)\(reportTarget)\n")
            exit(1)
        }
        print("ontologyc validate-golden-intent: PASS \(candidatePath)\(reportTarget)")
    } catch let compilerError as OntologyCompilerError {
        writeDiagnostic("ontologyc validate-golden-intent: FAIL \(compilerError)\n")
        exit(1)
    } catch {
        writeDiagnostic("ontologyc validate-golden-intent: FAIL \(error)\n")
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
            writeDiagnostic("ontologyc validate-governance-decision: FAIL \(decisionPath)\(reportTarget)\n")
            exit(1)
        }
        print("ontologyc validate-governance-decision: PASS \(decisionPath)\(reportTarget)")
    } catch let compilerError as OntologyCompilerError {
        writeDiagnostic("ontologyc validate-governance-decision: FAIL \(compilerError)\n")
        exit(1)
    } catch {
        writeDiagnostic("ontologyc validate-governance-decision: FAIL \(error)\n")
        exit(1)
    }

case "export-specgraph-owner-decisions":
    let parsed = parseArguments(commandArgs, allowedOptions: ["--out"], command: command)
    requirePositionals(1, in: parsed, command: command)
    let decisionSetPath = parsed.positional[0]
    let outPath = requireOption("--out", in: parsed, command: command)
    do {
        let result = try compiler.exportSpecGraphOwnerDecisions(
            decisionSetPath: OntologySourcePath(path: decisionSetPath),
            outPath: OntologyOutputPath(path: outPath)
        )
        print("ontologyc export-specgraph-owner-decisions: PASS \(outPath) decisions=\(result.decisionCount)")
    } catch let compilerError as OntologyCompilerError {
        if case .packageError(let diagnostics) = compilerError { compiler.printDiagnostics(diagnostics) }
        writeDiagnostic("ontologyc export-specgraph-owner-decisions: FAIL \(compilerError)\n")
        exit(1)
    } catch {
        writeDiagnostic("ontologyc export-specgraph-owner-decisions: FAIL \(error)\n")
        exit(1)
    }

case "export-viewer-archive-manifest":
    let parsed = parseArguments(commandArgs, allowedOptions: ["--generated", "--out"], command: command)
    requirePositionals(1, in: parsed, command: command)
    let packagePath = parsed.positional[0]
    let generatedDirectory = requireOption("--generated", in: parsed, command: command)
    let outPath = requireOption("--out", in: parsed, command: command)
    do {
        let result = try compiler.exportViewerArchiveManifest(
            packagePath: OntologySourcePath(path: packagePath),
            generatedDirectory: OntologyOutputDirectory(path: generatedDirectory),
            outPath: OntologyOutputPath(path: outPath)
        )
        print("ontologyc export-viewer-archive-manifest: PASS \(outPath) artifacts=\(result.artifactCount)")
    } catch let compilerError as OntologyCompilerError {
        if case .packageError(let diagnostics) = compilerError { compiler.printDiagnostics(diagnostics) }
        writeDiagnostic("ontologyc export-viewer-archive-manifest: FAIL \(compilerError)\n")
        exit(1)
    } catch {
        writeDiagnostic("ontologyc export-viewer-archive-manifest: FAIL \(error)\n")
        exit(1)
    }

default:
    usageError("unknown command \(command)")
}
