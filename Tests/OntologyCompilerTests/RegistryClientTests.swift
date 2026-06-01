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
    private var stubSession: URLSession!

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

    private func makeClient() -> RegistryClient {
        RegistryClient(session: stubSession)
    }

    private func okResponse(for request: URLRequest) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    // MARK: - GET

    func testGetReturnsResponseBody() throws {
        let expected = Data("payload".utf8)
        MockURLProtocol.requestHandler = { request in (self.okResponse(for: request), expected) }

        let url = URL(string: "https://registry.example.com/ontologies/test/1.0.0")!
        let result = try makeClient().get(url: url, token: nil)
        XCTAssertEqual(result, expected)
    }

    func testGetSendsBearerToken() throws {
        var capturedAuth: String?
        MockURLProtocol.requestHandler = { request in
            capturedAuth = request.value(forHTTPHeaderField: "Authorization")
            return (self.okResponse(for: request), Data())
        }

        let url = URL(string: "https://registry.example.com/ontologies/test/1.0.0")!
        _ = try makeClient().get(url: url, token: "secret-token")
        XCTAssertEqual(capturedAuth, "Bearer secret-token")
    }

    func testGetOmitsAuthHeaderWhenNoToken() throws {
        var capturedAuth: String?
        MockURLProtocol.requestHandler = { request in
            capturedAuth = request.value(forHTTPHeaderField: "Authorization")
            return (self.okResponse(for: request), Data())
        }

        let url = URL(string: "https://registry.example.com/ontologies/test/1.0.0")!
        _ = try makeClient().get(url: url, token: nil)
        XCTAssertNil(capturedAuth)
    }

    // MARK: - PUT

    func testPutSendsBodyAndContentType() throws {
        let body = Data("json-payload".utf8)
        var capturedBody: Data?
        var capturedContentType: String?
        MockURLProtocol.requestHandler = { request in
            capturedBody = request.httpBody
            capturedContentType = request.value(forHTTPHeaderField: "Content-Type")
            return (self.okResponse(for: request), Data())
        }

        let url = URL(string: "https://registry.example.com/ontologies/test/1.0.0")!
        try makeClient().put(url: url, body: body, token: nil)
        XCTAssertEqual(capturedBody, body)
        XCTAssertEqual(capturedContentType, "application/json")
    }

    // MARK: - Error handling

    func testGetThrowsHTTPErrorOn404() throws {
        MockURLProtocol.requestHandler = { request in
            let resp = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (resp, Data("not found".utf8))
        }

        let url = URL(string: "https://registry.example.com/ontologies/missing/1.0.0")!
        XCTAssertThrowsError(try makeClient().get(url: url, token: nil)) { error in
            guard case RegistryError.httpError(let code, _) = error as! RegistryError else {
                return XCTFail("Expected httpError, got \(error)")
            }
            XCTAssertEqual(code, 404)
        }
    }

    func testGetDoesNotRetryOn4xx() throws {
        var attempts = 0
        MockURLProtocol.requestHandler = { request in
            attempts += 1
            let resp = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (resp, Data("unauthorized".utf8))
        }

        let url = URL(string: "https://registry.example.com/ontologies/test/1.0.0")!
        XCTAssertThrowsError(try makeClient().get(url: url, token: nil))
        XCTAssertEqual(attempts, 1, "4xx errors must not be retried")
    }

    // MARK: - Retry

    func testGetRetriesOn500AndSucceedsOnThirdAttempt() throws {
        var attempts = 0
        MockURLProtocol.requestHandler = { request in
            attempts += 1
            if attempts < 3 {
                let resp = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
                return (resp, Data("server error".utf8))
            }
            return (self.okResponse(for: request), Data("ok".utf8))
        }

        let url = URL(string: "https://registry.example.com/ontologies/test/1.0.0")!
        let result = try makeClient().get(url: url, token: nil)
        XCTAssertEqual(attempts, 3)
        XCTAssertEqual(String(data: result, encoding: .utf8), "ok")
    }

    func testGetThrowsAfterMaxRetriesOn500() throws {
        var attempts = 0
        MockURLProtocol.requestHandler = { request in
            attempts += 1
            let resp = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (resp, Data("always fails".utf8))
        }

        let url = URL(string: "https://registry.example.com/ontologies/test/1.0.0")!
        XCTAssertThrowsError(try makeClient().get(url: url, token: nil)) { error in
            guard case RegistryError.httpError(500, _) = error as! RegistryError else {
                return XCTFail("Expected httpError(500), got \(error)")
            }
        }
        XCTAssertEqual(attempts, 3)
    }

    // MARK: - compatibilityReport logic (no HTTP)

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
}
