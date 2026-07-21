import Foundation

enum APIError: Error { case status(Int) }

/// Thin async client over the existing Vercel backend — no rewrite needed,
/// the web app and the iOS app share the same endpoints.
struct APIClient {
    static let baseURL = URL(string: "https://gold-rush-tau.vercel.app")!

    static func prices() async throws -> PricesResponse {
        try await get("api/prices")
    }

    static func history(tf: String, metal: String) async throws -> HistoryResponse {
        try await get("api/history?tf=\(tf)&metal=\(metal)")
    }

    static func content() async throws -> ContentResponse {
        try await get("api/content")
    }

    static func liveDealers() async throws -> LiveDealersResponse {
        try await get("api/live-dealers")
    }

    private static func get<T: Decodable>(_ path: String) async throws -> T {
        let url = URL(string: path, relativeTo: baseURL)!
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 12
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
            throw APIError.status(http.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
