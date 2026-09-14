import Foundation

public struct UpdateFeed: Decodable, Sendable {
    public let version: String
    public let build: String
    public let title: String
    public let notes: String?
    public let manifest: URL

    public var appVersion: AppVersion {
        AppVersion(version: version, build: build)
    }

    public var installURL: URL {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        let manifestQuery = manifest.absoluteString.addingPercentEncoding(withAllowedCharacters: allowed) ?? manifest.absoluteString
        return URL(string: "itms-services://?action=download-manifest&url=\(manifestQuery)")!
    }
}
