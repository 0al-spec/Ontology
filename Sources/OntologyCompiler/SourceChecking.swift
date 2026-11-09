import Foundation

extension OntologyCompiler {
    /// Load and validate the package and all explicit dependency snapshots together.
    func loadValidatedPackage(path: OntologySourcePath, imports: [OntologySourcePath]) -> (package: LoadedPackage, imports: [LoadedPackage])? {
        guard let package = load(path: path.path) else { return nil }
        let supplied = imports.compactMap { load(path: $0.path) }
        for imported in supplied {
            var dependencies = supplied.filter { $0.path != imported.path }
            if package.path != imported.path { dependencies.append(package) }
            validate(imported, suppliedImports: dependencies)
        }
        validate(package, suppliedImports: supplied)
        if !hasErrors(diagnostics) {
            for imported in supplied {
                var dependencies = supplied.filter { $0.path != imported.path }
                if package.path != imported.path { dependencies.append(package) }
                validateSemanticInheritance(imported, suppliedImports: dependencies)
            }
            validateSemanticInheritance(package, suppliedImports: supplied)
        }
        return (package, supplied)
    }

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

    /// Validate explicitly supplied snapshots without reading their paths from disk.
    public func checkSources(source: OntologySourceSnapshot, imports: [OntologySourceSnapshot]) -> [OntologySourcedDiagnostic] {
        let sources = [source] + imports.filter { $0.path != source.path }
        var findings: [OntologySourcedDiagnostic] = []
        var packages: [LoadedPackage] = []
        for snapshot in sources {
            diagnostics = []
            let package = load(source: snapshot.source, path: snapshot.path.path)
            findings += diagnostics.map { OntologySourcedDiagnostic(source: snapshot.path, diagnostic: $0) }
            if let package { packages.append(package) }
        }
        for (index, package) in packages.enumerated() {
            diagnostics = []
            let dependencies = packages.enumerated().filter { $0.offset != index }.map(\.element)
            validate(package, suppliedImports: dependencies)
            findings += diagnostics.map { OntologySourcedDiagnostic(source: OntologySourcePath(path: package.path), diagnostic: $0) }
        }
        if packages.count == sources.count, !findings.contains(where: { $0.diagnostic.severity == "error" }) {
            for (index, package) in packages.enumerated() {
                diagnostics = []
                let dependencies = packages.enumerated().filter { $0.offset != index }.map(\.element)
                validateSemanticInheritance(package, suppliedImports: dependencies)
                findings += diagnostics.map { OntologySourcedDiagnostic(source: OntologySourcePath(path: package.path), diagnostic: $0) }
            }
        }
        return findings.sorted {
            [$0.source.path, $0.diagnostic.path, $0.diagnostic.code, $0.diagnostic.message].joined(separator: "\u{1f}") <
                [$1.source.path, $1.diagnostic.path, $1.diagnostic.code, $1.diagnostic.message].joined(separator: "\u{1f}")
        }
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
        if !hasErrors(diagnostics) {
            for imported in supplied {
                var dependencies = supplied.filter { $0.path != imported.path }
                if let package, package.path != imported.path { dependencies.append(package) }
                validateSemanticInheritance(imported, suppliedImports: dependencies)
            }
            if let package { validateSemanticInheritance(package, suppliedImports: supplied) }
        }
        return diagnostics.sorted {
            [$0.path, $0.code, $0.message].joined(separator: "\u{1f}") <
                [$1.path, $1.code, $1.message].joined(separator: "\u{1f}")
        }
    }

    /// Check exactly the supplied source closure without writing SDK artifacts.
    func validateSemanticInheritance(_ package: LoadedPackage, suppliedImports: [LoadedPackage]) {
        let ir = normalize(package, suppliedImports: suppliedImports)
        _ = TypeScriptInheritance(compiler: self, root: package, imports: suppliedImports, rootIR: ir).project(ir)
    }
}
