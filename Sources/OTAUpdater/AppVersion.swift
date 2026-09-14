import Foundation

public struct AppVersion: Comparable, CustomStringConvertible, Sendable {
    public let components: [Int]
    public let build: Int

    public init(version: String, build: String) {
        components = version.split(separator: ".").map { Int($0) ?? 0 }
        self.build = Int(build) ?? 0
    }

    public init(bundle: Bundle) {
        let info = bundle.infoDictionary ?? [:]
        self.init(
            version: info["CFBundleShortVersionString"] as? String ?? "0",
            build: info["CFBundleVersion"] as? String ?? "0"
        )
    }

    public var description: String {
        "\(components.map(String.init).joined(separator: ".")) (\(build))"
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let width = max(lhs.components.count, rhs.components.count)
        let left = lhs.components + Array(repeating: 0, count: width - lhs.components.count)
        let right = rhs.components + Array(repeating: 0, count: width - rhs.components.count)
        if left != right {
            return left.lexicographicallyPrecedes(right)
        }
        return lhs.build < rhs.build
    }

    public static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }
}
