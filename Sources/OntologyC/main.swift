import Foundation
import OntologyCompiler

func usage() -> Never {
    fputs("""
    Usage:
      swift run ontologyc check <package.yaml>
      swift run ontologyc compile <package.yaml> --target typescript --out <directory>
      swift run ontologyc validate-specgraph <binding.yaml> --ontology-ir <ontology.normalized.json> --out <directory>
      swift run ontologyc diff --from <old-package.yaml> --to <new-package.yaml> --out <report.yaml>
      swift run ontologyc publish <package.yaml> --registry <url> [--token <token>]
      swift run ontologyc pull <id>@<version> --registry <url> --out <directory>
      swift run ontologyc compat-check <package.yaml> --against <id>@<version> --registry <url> [--out <report.yaml>]

    """, stderr)
    exit(2)
}

let args = Array(CommandLine.arguments.dropFirst())
guard let command = args.first else {
    usage()
}

let compiler = OntologyCompiler()

func optionValue(_ name: String) -> String? {
    args.firstIndex(of: name).flatMap { index in
        index + 1 < args.count ? args[index + 1] : nil
    }
}

func authToken() -> String? {
    optionValue("--token") ?? ProcessInfo.processInfo.environment["ONTOLOGYC_TOKEN"]
}

switch command {
case "check":
    guard args.count == 2 else { usage() }
    let path = args[1]
    let diagnostics = compiler.check(path: path)
    if compiler.hasErrors(diagnostics) {
        compiler.printDiagnostics(diagnostics)
        exit(1)
    }
    print("ontologyc check: PASS \(path)")

case "compile":
    guard args.count == 6 else { usage() }
    let path = args[1]
    guard args[2] == "--target", args[3] == "typescript", args[4] == "--out" else {
        usage()
    }
    let outDirectory = args[5]
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
    guard args.count == 6 else { usage() }
    let bindingPath = args[1]
    guard args[2] == "--ontology-ir", args[4] == "--out" else {
        usage()
    }
    do {
        let result = try compiler.validateSpecGraph(bindingPath: bindingPath, ontologyIRPath: args[3], outDirectory: args[5])
        print("ontologyc validate-specgraph: PASS \(bindingPath) resolved=\(result.resolved) gaps=\(result.gaps)")
    } catch {
        fputs("ontologyc validate-specgraph: FAIL \(error)\n", stderr)
        exit(1)
    }

case "diff":
    guard args.count == 7 else { usage() }
    guard args[1] == "--from", args[3] == "--to", args[5] == "--out" else {
        usage()
    }
    do {
        let diagnostics = try compiler.diffPackages(from: args[2], to: args[4], outPath: args[6])
        if compiler.hasErrors(diagnostics) {
            compiler.printDiagnostics(diagnostics)
            exit(1)
        }
        print("ontologyc diff: PASS \(args[6])")
    } catch {
        fputs("ontologyc diff: FAIL \(error)\n", stderr)
        exit(1)
    }

case "publish":
    // publish <package.yaml> --registry <url> [--token <token>]
    guard args.count >= 2,
          let publishRegistry = optionValue("--registry") else { usage() }
    let publishPath = args[1]
    do {
        let result = try compiler.publishPackage(path: publishPath, registry: publishRegistry, token: authToken())
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
    // pull <id>@<version> --registry <url> --out <directory>
    guard args.count >= 2,
          let pullRegistry = optionValue("--registry"),
          let pullOutDirectory = optionValue("--out") else { usage() }
    let pullRef = args[1]
    do {
        try compiler.pullPackage(ref: pullRef, registry: pullRegistry, token: authToken(), outDirectory: pullOutDirectory)
        print("ontologyc pull: PASS \(pullRef)")
    } catch {
        fputs("ontologyc pull: FAIL \(error)\n", stderr)
        exit(1)
    }

case "compat-check":
    // compat-check <package.yaml> --against <id>@<version> --registry <url> [--out <report.yaml>]
    guard args.count >= 2,
          let compatRef = optionValue("--against"),
          let compatRegistry = optionValue("--registry") else { usage() }
    let compatPath = args[1]
    do {
        let compatible = try compiler.compatCheckPackage(
            path: compatPath,
            against: compatRef,
            registry: compatRegistry,
            token: authToken(),
            outPath: optionValue("--out")
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
    usage()
}
