import Foundation
import OntologyCompiler

func runInstanceGraphCommand(_ command: String, arguments: ArraySlice<String>, compiler: OntologyCompiler) {
    let parsed = parseArguments(arguments, allowedOptions: ["--ontology-ir", "--out"], command: command)
    requirePositionals(command == "validate-instances" ? 1 : 0, in: parsed, command: command)
    let ontologyIR = OntologySourcePath(path: requireOption("--ontology-ir", in: parsed, command: command))
    do {
        if command == "export-instance-contract" {
            let output = requireOption("--out", in: parsed, command: command)
            try compiler.exportInstanceContract(ontologyIRPath: ontologyIR, outDirectory: OntologyOutputDirectory(path: output))
            print("ontologyc export-instance-contract: PASS \(output)")
        } else {
            let result = try compiler.validateInstanceGraph(
                graphPath: OntologySourcePath(path: parsed.positional[0]), ontologyIRPath: ontologyIR,
                outPath: parsed.options["--out"].map(OntologyOutputPath.init(path:))
            )
            if !result.passed {
                compiler.printDiagnostics(result.diagnostics)
                fputs("ontologyc validate-instances: FAIL\n", stderr)
                exit(1)
            }
            print("ontologyc validate-instances: PASS (structural only)")
        }
    } catch {
        fputs("ontologyc \(command): FAIL \(error)\n", stderr)
        exit(1)
    }
}
