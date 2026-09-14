import Foundation

public enum UpdateFeedError: Error, LocalizedError {
    case httpStatus(URL, Int)

    public var errorDescription: String? {
        switch self {
        case .httpStatus(let url, let status): return "Update feed \(url.absoluteString) http=\(status)"
        }
    }
}

struct UpdateFeedClient {
    let feedURL: URL
    let urlSession: URLSession

    func fetch() async throws -> UpdateFeed {
        var request = URLRequest(url: feedURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (body, response) = try await urlSession.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw UpdateFeedError.httpStatus(feedURL, status) }
        return try JSONDecoder().decode(UpdateFeed.self, from: body)
    }
}
