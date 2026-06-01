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
    private let maxRetries = 3
    private let timeoutInterval: TimeInterval = 30

    func get(url: URL, token: String?) throws -> Data {
        try withRetry { try self.performRequest(method: "GET", url: url, body: nil, token: token) }
    }

    func put(url: URL, body: Data, token: String?) throws {
        _ = try withRetry { try self.performRequest(method: "PUT", url: url, body: body, token: token) }
    }

    private func withRetry(_ perform: () throws -> Data) throws -> Data {
        var lastError: Error = RegistryError.invalidResponse
        for attempt in 0..<maxRetries {
            do {
                return try perform()
            } catch RegistryError.httpError(let code, let message) where code >= 500 {
                lastError = RegistryError.httpError(code, message)
                if attempt < maxRetries - 1 { Thread.sleep(forTimeInterval: Double(1 << attempt)) }
            } catch {
                lastError = error
                if attempt < maxRetries - 1 { Thread.sleep(forTimeInterval: Double(1 << attempt)) }
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

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
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
