import Foundation

enum RegistryError: Error, CustomStringConvertible {
    case httpError(Int, String)
    case networkError(Error)
    case invalidResponse

    var description: String {
        switch self {
        case .httpError(let code, let body): return "HTTP \(code): \(body)"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .invalidResponse: return "Invalid response"
        }
    }
}

private final class SyncBox<T>: @unchecked Sendable {
    var value: T

    init(_ value: T) { self.value = value }
}

final class RegistryClient {
    private let session: URLSession
    private let maxRetries = 3
    private let timeoutInterval: TimeInterval = 30

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(url: URL, token: String?) throws -> Data {
        try withRetry { try self.performRequest(method: "GET", url: url, body: nil, token: token) }
    }

    func put(url: URL, body: Data, token: String?) throws {
        _ = try withRetry { try self.performRequest(method: "PUT", url: url, body: body, token: token) }
    }

    private func isRetriable(_ error: Error) -> Bool {
        guard let e = error as? RegistryError else { return false }
        switch e {
        case .httpError(let code, _): return code >= 500
        case .networkError: return true
        case .invalidResponse: return false
        }
    }

    private func withRetry(_ perform: () throws -> Data) throws -> Data {
        var lastError: Error = RegistryError.invalidResponse
        for attempt in 0 ..< maxRetries {
            do {
                return try perform()
            } catch let e where isRetriable(e) {
                lastError = e
                if attempt < maxRetries - 1 { Thread.sleep(forTimeInterval: Double(1 << attempt)) }
            } catch {
                throw error
            }
        }
        throw lastError
    }

    private func performRequest(method: String, url: URL, body: Data?, token: String?) throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = method
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let result = SyncBox<Result<(Data, URLResponse), Error>>(.failure(URLError(.unknown)))
        let sema = DispatchSemaphore(value: 0)
        let currentSession = session

        Task {
            do {
                let (data, response) = try await currentSession.data(for: request)
                result.value = .success((data, response))
            } catch {
                result.value = .failure(RegistryError.networkError(error))
            }
            sema.signal()
        }
        sema.wait()

        let (data, response) = try result.value.get()
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RegistryError.invalidResponse
        }
        if httpResponse.statusCode >= 400 {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw RegistryError.httpError(httpResponse.statusCode, message)
        }
        return data
    }
}
