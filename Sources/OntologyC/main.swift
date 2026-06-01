import Foundation
import OntologyCompiler

func usage() -> Never {
    fputs("""
    Usage:
      swift run ontologyc check <package.yaml>
      swift run ontologyc compile <package.yaml> --target typescript --out <directory>
      swift run ontologyc validate-specgraph <binding.yaml> --ontology-ir <ontology.normalized.json> --out <directory>
      swift run ontologyc diff --from <old-package.yaml> --to <new-package.yaml> --out <report.yaml>

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

default:
    usage()
}
