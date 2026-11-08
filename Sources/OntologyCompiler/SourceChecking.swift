import Foundation

extension OntologyCompiler {
    /// Parses and validates one ontology package, returning sorted diagnostics without writing output files.
    public func check(path: OntologySourcePath, imports: [OntologySourcePath] = []) -> [Diagnostic] {
        diagnostics = []
        return checked(load(path: path.path), imports: imports)
    }

    /// Validate supplied bytes decoded as UTF-8, using their source path for diagnostics.
    public func check(source: String, path: OntologySourcePath, imports: [OntologySourcePath] = []) -> [Diagnostic] {
        diagnostics = []
        return checked(load(source: source, path: path.path), imports: imports)
    }

    /// Validate a source and explicitly supplied snapshots without reading those imports from disk.
    public func check(source: String, path: OntologySourcePath, importSources: [OntologySourceSnapshot]) -> [Diagnostic] {
        diagnostics = []
        let package = load(source: source, path: path.path)
        let supplied = importSources.compactMap { load(source: $0.source, path: $0.path.path) }
        return checked(package, supplied: supplied)
    }

    private func checked(_ package: LoadedPackage?, imports: [OntologySourcePath]) -> [Diagnostic] {
        let supplied = imports.compactMap { load(path: $0.path) }
        return checked(package, supplied: supplied)
    }

    private func checked(_ package: LoadedPackage?, supplied: [LoadedPackage]) -> [Diagnostic] {
        for imported in supplied {
            var dependencies = supplied.filter { $0.path != imported.path }
            if let package, package.path != imported.path { dependencies.append(package) }
            validate(imported, suppliedImports: dependencies)
        }
        if let package { validate(package, suppliedImports: supplied) }
        return diagnostics.sorted {
            [$0.path, $0.code, $0.message].joined(separator: "\u{1f}") <
                [$1.path, $1.code, $1.message].joined(separator: "\u{1f}")
        }
    }
}
