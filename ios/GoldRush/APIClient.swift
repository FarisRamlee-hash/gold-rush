import Foundation

enum APIError: Error { case status(Int) }

/// Thin async client over the existing Vercel backend — no rewrite needed,
/// the web app and the iOS app share the same endpoints.
struct APIClient {
    static let baseURL = URL(string: "https://gold-rush-tau.vercel.app")!

    static func prices() async throws -> PricesResponse {
        try await get("api/prices", as: PricesResponse.self)
    }

    private static func get<T: Decodable>(_ path: String, as: T.Type) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
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
