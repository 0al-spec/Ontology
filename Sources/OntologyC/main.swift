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
    guard args.count >= 4, args[2] == "--registry" else { usage() }
    let publishToken: String? = args.count >= 6 && args[4] == "--token"
        ? args[5]
        : ProcessInfo.processInfo.environment["ONTOLOGYC_TOKEN"]
    do {
        let diagnostics = try compiler.publishPackage(path: args[1], registry: args[3], token: publishToken)
        if compiler.hasErrors(diagnostics) { compiler.printDiagnostics(diagnostics); exit(1) }
        print("ontologyc publish: PASS \(args[1])")
    } catch {
        fputs("ontologyc publish: FAIL \(error)\n", stderr)
        exit(1)
    }

case "pull":
    // pull <id>@<version> --registry <url> --out <directory>
    guard args.count == 6, args[2] == "--registry", args[4] == "--out" else { usage() }
    let pullToken: String? = ProcessInfo.processInfo.environment["ONTOLOGYC_TOKEN"]
    do {
        try compiler.pullPackage(ref: args[1], registry: args[3], token: pullToken, outDirectory: args[5])
        print("ontologyc pull: PASS \(args[1])")
    } catch {
        fputs("ontologyc pull: FAIL \(error)\n", stderr)
        exit(1)
    }

case "compat-check":
    // compat-check <package.yaml> --against <id>@<version> --registry <url> [--out <report.yaml>]
    guard args.count >= 6, args[2] == "--against", args[4] == "--registry" else { usage() }
    let compatOutPath: String? = args.count >= 8 && args[6] == "--out" ? args[7] : nil
    let compatToken: String? = ProcessInfo.processInfo.environment["ONTOLOGYC_TOKEN"]
    do {
        let compatible = try compiler.compatCheckPackage(
            path: args[1],
            against: args[3],
            registry: args[5],
            token: compatToken,
            outPath: compatOutPath
        )
        if !compatible {
            fputs("ontologyc compat-check: BREAKING CHANGES DETECTED in \(args[1])\n", stderr)
            exit(1)
        }
        print("ontologyc compat-check: PASS \(args[1])")
    } catch {
        fputs("ontologyc compat-check: FAIL \(error)\n", stderr)
        exit(1)
    }

default:
    usage()
}
