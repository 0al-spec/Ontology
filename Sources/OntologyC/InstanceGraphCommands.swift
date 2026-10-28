import Foundation
import OntologyCompiler

func runInstanceGraphCommand(_ command: String, arguments: ArraySlice<String>, compiler: OntologyCompiler) {
    let parsed = parseArguments(arguments, allowedOptions: ["--ontology-ir", "--out", "--profile", "--provenance-authority"], command: command)
    requirePositionals(command == "validate-instances" ? 1 : 0, in: parsed, command: command)
    let ontologyIR = OntologySourcePath(path: requireOption("--ontology-ir", in: parsed, command: command))
    let profile = parsed.options["--profile"] ?? "eventcore-v1"
    do {
        if command == "export-instance-contract" {
            guard parsed.options["--provenance-authority"] == nil else {
                throw OntologyCompilerError.invalidArgument("authority input is only valid for validate-instances")
            }
            let output = requireOption("--out", in: parsed, command: command)
            try compiler.exportInstanceContract(ontologyIRPath: ontologyIR, outDirectory: OntologyOutputDirectory(path: output), profile: profile)
            print("ontologyc export-instance-contract: PASS \(output)")
        } else {
            let result = try compiler.validateInstanceGraph(
                graphPath: OntologySourcePath(path: parsed.positional[0]), ontologyIRPath: ontologyIR,
                outPath: parsed.options["--out"].map(OntologyOutputPath.init(path:)), profile: profile,
                provenanceAuthorityPath: parsed.options["--provenance-authority"].map(OntologySourcePath.init(path:))
            )
            if !result.passed {
                compiler.printDiagnostics(result.diagnostics)
                fputs("ontologyc validate-instances: FAIL\n", stderr)
                exit(1)
            }
            let scope = profile == "eventcore-v1" ? "structural only" : "bounded profile; source truth unverified"
            print("ontologyc validate-instances: PASS (\(scope))")
        }
    } catch {
        fputs("ontologyc \(command): FAIL \(error)\n", stderr)
        exit(1)
    }
}
