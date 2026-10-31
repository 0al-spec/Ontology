import Foundation

func writeDiagnostic(_ message: String) {
    FileHandle.standardError.write(Data(message.utf8))
}

func printJSON(_ value: some Encodable) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    do {
        let data = try encoder.encode(value)
        print(String(decoding: data, as: UTF8.self))
    } catch {
        writeDiagnostic("ontologyc: JSON encoding failed: \(error)\n")
        exit(1)
    }
}
