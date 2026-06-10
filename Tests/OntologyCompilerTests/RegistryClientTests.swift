import Foundation
import XCTest
@testable import OntologyCompiler

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class RegistryClientTests: XCTestCase {
    private var stubSession: URLSession?

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        stubSession = URLSession(configuration: config)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        stubSession = nil
        super.tearDown()
    }

    private func makeClient() throws -> RegistryClient {
        RegistryClient(session: try XCTUnwrap(stubSession), sleep: { _ in })
    }

    private func stubResponse(for request: URLRequest, status: Int = 200) -> HTTPURLResponse {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)
        else {
            preconditionFailure("Could not create stub HTTPURLResponse for request")
        }
        return response
    }

    // MARK: - GET

    func testGetReturnsResponseBody() throws {
        let expected = Data("payload".utf8)
        MockURLProtocol.requestHandler = { request in (self.stubResponse(for: request), expected) }

        let url = try XCTUnwrap(URL(string: "https://registry.example.com/ontologies/test/1.0.0"))
        let result = try makeClient().get(url: url, token: nil)
        XCTAssertEqual(result, expected)
    }

    func testGetSendsBearerToken() throws {
        var capturedAuth: String?
        MockURLProtocol.requestHandler = { request in
            capturedAuth = request.value(forHTTPHeaderField: "Authorization")
            return (self.stubResponse(for: request), Data())
        }

        let url = try XCTUnwrap(URL(string: "https://registry.example.com/ontologies/test/1.0.0"))
        _ = try makeClient().get(url: url, token: "secret-token")
        XCTAssertEqual(capturedAuth, "Bearer secret-token")
    }

    func testGetOmitsAuthHeaderWhenNoToken() throws {
        var capturedAuth: String?
        MockURLProtocol.requestHandler = { request in
            capturedAuth = request.value(forHTTPHeaderField: "Authorization")
            return (self.stubResponse(for: request), Data())
        }

        let url = try XCTUnwrap(URL(string: "https://registry.example.com/ontologies/test/1.0.0"))
        _ = try makeClient().get(url: url, token: nil)
        XCTAssertNil(capturedAuth)
    }

    // MARK: - PUT

    func testPutSendsBodyAndContentType() throws {
        let body = Data("json-payload".utf8)
        var capturedBody: Data?
        var capturedContentType: String?
        MockURLProtocol.requestHandler = { request in
            capturedBody = request.bodyData
            capturedContentType = request.value(forHTTPHeaderField: "Content-Type")
            return (self.stubResponse(for: request), Data())
        }

        let url = try XCTUnwrap(URL(string: "https://registry.example.com/ontologies/test/1.0.0"))
        try makeClient().put(url: url, body: body, token: nil)
        XCTAssertEqual(capturedBody, body)
        XCTAssertEqual(capturedContentType, "application/json")
    }

    // MARK: - Error handling

    func testGetThrowsHTTPErrorOn404() throws {
        MockURLProtocol.requestHandler = { request in (self.stubResponse(for: request, status: 404), Data("not found".utf8)) }

        let url = try XCTUnwrap(URL(string: "https://registry.example.com/ontologies/missing/1.0.0"))
        XCTAssertThrowsError(try makeClient().get(url: url, token: nil)) { error in
            guard let registryError = error as? RegistryError,
                  case .httpError(let code, _) = registryError else {
                return XCTFail("Expected RegistryError.httpError, got \(error)")
            }
            XCTAssertEqual(code, 404)
        }
    }

    func testGetDoesNotRetryOn4xx() throws {
        var attempts = 0
        MockURLProtocol.requestHandler = { request in
            attempts += 1
            return (self.stubResponse(for: request, status: 401), Data("unauthorized".utf8))
        }

        let url = try XCTUnwrap(URL(string: "https://registry.example.com/ontologies/test/1.0.0"))
        XCTAssertThrowsError(try makeClient().get(url: url, token: nil))
        XCTAssertEqual(attempts, 1, "4xx errors must not be retried")
    }

    // MARK: - Retry

    func testGetRetriesOn500AndSucceedsOnThirdAttempt() throws {
        var attempts = 0
        MockURLProtocol.requestHandler = { request in
            attempts += 1
            return attempts < 3
                ? (self.stubResponse(for: request, status: 500), Data("server error".utf8))
                : (self.stubResponse(for: request), Data("ok".utf8))
        }

        let url = try XCTUnwrap(URL(string: "https://registry.example.com/ontologies/test/1.0.0"))
        let result = try makeClient().get(url: url, token: nil)
        XCTAssertEqual(attempts, 3)
        XCTAssertEqual(String(data: result, encoding: .utf8), "ok")
    }

    func testGetThrowsAfterMaxRetriesOn500() throws {
        var attempts = 0
        MockURLProtocol.requestHandler = { request in
            attempts += 1
            return (self.stubResponse(for: request, status: 500), Data("always fails".utf8))
        }

        let url = try XCTUnwrap(URL(string: "https://registry.example.com/ontologies/test/1.0.0"))
        XCTAssertThrowsError(try makeClient().get(url: url, token: nil)) { error in
            guard let registryError = error as? RegistryError,
                  case .httpError(500, _) = registryError else {
                return XCTFail("Expected RegistryError.httpError(500), got \(error)")
            }
        }
        XCTAssertEqual(attempts, 3)
    }

    // MARK: - compatibilityReport (no HTTP)

    func testCompatibilityReportBreakingClassRemoval() {
        let compiler = OntologyCompiler()
        let fromIR: [String: Any] = [
            "id": "test-ontology",
            "namespace": "test",
            "version": "1.0.0",
            "sourceDigest": "",
            "classes": [["id": "RemovedClass", "fqid": "test:RemovedClass", "kind": "Entity"] as [String: Any]],
            "protocols": [] as [Any],
            "relations": [] as [Any],
            "policies": [] as [Any],
            "stateMachines": [] as [Any]
        ]
        let toIR: [String: Any] = [
            "id": "test-ontology",
            "namespace": "test",
            "version": "2.0.0",
            "sourceDigest": "",
            "classes": [] as [Any],
            "protocols": [] as [Any],
            "relations": [] as [Any],
            "policies": [] as [Any],
            "stateMachines": [] as [Any]
        ]

        let report = compiler.compatibilityReport(fromIR: fromIR, toIR: toIR)
        let compatible = (report["result"] as? [String: Any])?["compatible"] as? Bool ?? true
        XCTAssertFalse(compatible, "Removing a class must be a breaking change")
    }

    func testCompatibilityReportAddingClassIsCompatible() {
        let compiler = OntologyCompiler()
        let fromIR: [String: Any] = [
            "id": "test-ontology",
            "namespace": "test",
            "version": "1.0.0",
            "sourceDigest": "",
            "classes": [] as [Any],
            "protocols": [] as [Any],
            "relations": [] as [Any],
            "policies": [] as [Any],
            "stateMachines": [] as [Any]
        ]
        let toIR: [String: Any] = [
            "id": "test-ontology",
            "namespace": "test",
            "version": "2.0.0",
            "sourceDigest": "",
            "classes": [["id": "NewClass", "fqid": "test:NewClass", "kind": "Entity"] as [String: Any]],
            "protocols": [] as [Any],
            "relations": [] as [Any],
            "policies": [] as [Any],
            "stateMachines": [] as [Any]
        ]

        let report = compiler.compatibilityReport(fromIR: fromIR, toIR: toIR)
        let compatible = (report["result"] as? [String: Any])?["compatible"] as? Bool ?? false
        XCTAssertTrue(compatible, "Adding a class must not be a breaking change")
    }

    func testCompatibilityReportClassFieldChanges() {
        let compiler = OntologyCompiler()
        let fromIR: [String: Any] = [
            "id": "test-ontology",
            "namespace": "test",
            "version": "1.0.0",
            "sourceDigest": "",
            "classes": [
                [
                    "id": "Exam",
                    "fqid": "test:Exam",
                    "kind": "Entity",
                    "fields": [
                        ["id": "title", "type": "string", "required": false],
                        ["id": "durationMinutes", "type": "integer", "required": false],
                        ["id": "legacyCode", "type": "string", "required": false]
                    ]
                ] as [String: Any]
            ],
            "protocols": [] as [Any],
            "relations": [] as [Any],
            "policies": [] as [Any],
            "stateMachines": [] as [Any]
        ]
        let toIR: [String: Any] = [
            "id": "test-ontology",
            "namespace": "next",
            "version": "2.0.0",
            "sourceDigest": "",
            "classes": [
                [
                    "id": "Exam",
                    "fqid": "next:Exam",
                    "kind": "Entity",
                    "fields": [
                        ["id": "title", "type": "string", "required": true],
                        ["id": "durationMinutes", "type": "number", "required": false],
                        ["id": "optionalNote", "type": "string", "required": false],
                        ["id": "requiredCode", "type": "string", "required": true]
                    ]
                ] as [String: Any]
            ],
            "protocols": [] as [Any],
            "relations": [] as [Any],
            "policies": [] as [Any],
            "stateMachines": [] as [Any]
        ]

        let report = compiler.compatibilityReport(fromIR: fromIR, toIR: toIR)
        let changes = try? XCTUnwrap(report["changes"] as? [String: Any])
        let breaking = changes?["breakingChanges"] as? [String] ?? []

        XCTAssertEqual(changes?["addedFields"] as? [String], ["next:Exam.optionalNote", "next:Exam.requiredCode"])
        XCTAssertEqual(changes?["removedFields"] as? [String], ["test:Exam.legacyCode"])
        XCTAssertEqual(changes?["changedFields"] as? [String], ["test:Exam.durationMinutes", "test:Exam.title"])
        XCTAssertTrue(breaking.contains("add required field next:Exam.requiredCode"), "\(breaking)")
        XCTAssertTrue(breaking.contains("remove field test:Exam.legacyCode"), "\(breaking)")
        XCTAssertTrue(breaking.contains("change field type test:Exam.durationMinutes"), "\(breaking)")
        XCTAssertTrue(breaking.contains("make field required test:Exam.title"), "\(breaking)")
    }

    func testCompatCheckReportsLocalPackageDiagnosticsBeforeRegistryPull() throws {
        let compiler = OntologyCompiler()
        let invalidPackage = repoRoot
            .appendingPathComponent("SPECS/ontology/fixtures/invalid/missing-metadata.yaml")

        XCTAssertThrowsError(
            try compiler.compatCheckPackage(
                path: OntologySourcePath(url: invalidPackage),
                against: try XCTUnwrap(OntologyPackageReference(rawValue: "examcalc@0.1.0")),
                registry: try XCTUnwrap(RegistryBaseURL(string: "https://registry.example.com")),
                token: nil,
                outPath: nil
            )
        ) { error in
            guard case OntologyCompilerError.packageError(let diagnostics) = error else {
                return XCTFail("Expected local package diagnostics, got \(error)")
            }

            XCTAssertTrue(
                diagnostics.contains { $0.code == "metadata.required" },
                "Expected missing metadata diagnostic, got \(diagnostics)"
            )
        }
    }

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

private extension URLRequest {
    var bodyData: Data? {
        if let httpBody {
            return httpBody
        }
        guard let stream = httpBodyStream else {
            return nil
        }
        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let readCount = stream.read(&buffer, maxLength: buffer.count)
            if readCount <= 0 {
                break
            }
            data.append(buffer, count: readCount)
        }
        return data
    }
}
