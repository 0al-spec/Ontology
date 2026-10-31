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
    let compiler = OntologyCompiler()
    let renderer = GraphvizRenderer()
    let files: [String]
    if arguments.format == .json {
        let json = try compiler.diagramJSON(path: arguments.input, options: arguments.diagram)
        files = try renderer.writeJSON(json, arguments: arguments)
    } else {
        let dot = try compiler.diagramDOT(path: arguments.input, options: arguments.diagram)
        files = try renderer.render(dot: dot, arguments: arguments)
    }
    for file in files {
        print(arguments.output.appendingPathComponent(file).path)
    }
} catch {
    fail(String(describing: error), code: 1)
}
