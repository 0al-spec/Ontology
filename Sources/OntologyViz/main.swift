import Foundation
import OntologyCompiler

func fail(_ message: String, code: Int32) -> Never {
    FileHandle.standardError.write(Data("ontologyviz: \(message)\n".utf8))
    exit(code)
}

let rawArguments = Array(CommandLine.arguments.dropFirst())
if rawArguments.prefix(while: { $0 != "--" }).contains("--help") {
    print(VizArguments.help)
    exit(0)
}

let arguments: VizArguments
do {
    arguments = try VizArguments(rawArguments)
} catch {
    fail("\(error)\n\(VizArguments.help)", code: 2)
}

do {
    let dot = try OntologyCompiler().diagramDOT(path: arguments.input, direction: arguments.direction)
    let files = try GraphvizRenderer().render(dot: dot, arguments: arguments)
    for file in files {
        print(arguments.output.appendingPathComponent(file).path)
    }
} catch {
    fail(String(describing: error), code: 1)
}
