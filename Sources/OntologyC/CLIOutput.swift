import Foundation

func writeDiagnostic(_ message: String) {
    FileHandle.standardError.write(Data(message.utf8))
}
