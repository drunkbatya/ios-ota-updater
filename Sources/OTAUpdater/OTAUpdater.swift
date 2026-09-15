import UIKit
import os

@MainActor
public final class OTAUpdater {
    public enum Availability: Sendable {
        case upToDate
        case available(UpdateFeed)
    }

    private enum Key {
        static let lastCheck = "ota.last_check"
        static let skippedVersion = "ota.skipped_version"
    }

    public let feedURL: URL
    public let installedVersion: AppVersion
    private let client: UpdateFeedClient
    private let defaults: UserDefaults
    private let checkInterval: TimeInterval
    private let log: Logger
    private var launchCheck: Task<Void, Never>?
    private var installObservers: [NSObjectProtocol] = []
    public var terminatesAfterInstall = true

    public init(
        feedURL: URL,
        bundle: Bundle = .main,
        defaults: UserDefaults = .standard,
        urlSession: URLSession = .shared,
        checkInterval: TimeInterval = 24 * 60 * 60
    ) {
        self.feedURL = feedURL
        self.defaults = defaults
        self.checkInterval = checkInterval
        installedVersion = AppVersion(bundle: bundle)
        client = UpdateFeedClient(feedURL: feedURL, urlSession: urlSession)
        log = Logger(subsystem: bundle.bundleIdentifier ?? "OTAUpdater", category: "ota")
    }

    public func check() async throws -> Availability {
        let feed = try await client.fetch()
        defaults.set(Date(), forKey: Key.lastCheck)
        log.info("feed version \(feed.appVersion.description, privacy: .public), installed \(self.installedVersion.description, privacy: .public)")
        return feed.appVersion > installedVersion ? .available(feed) : .upToDate
    }

    public func checkOnLaunch(presenter: @escaping @MainActor () -> UIViewController?) {
        if let last = defaults.object(forKey: Key.lastCheck) as? Date, Date().timeIntervalSince(last) < checkInterval {
            return
        }
        launchCheck?.cancel()
        launchCheck = Task { [weak self] in
            guard let self else { return }
            do {
                guard case .available(let feed) = try await check() else { return }
                if feed.version == defaults.string(forKey: Key.skippedVersion) {
                    log.info("version \(feed.version, privacy: .public) skipped by user")
                    return
                }
                guard let host = presenter() else {
                    log.error("no presenter for update prompt")
                    return
                }
                host.present(prompt(for: feed, allowSkip: true), animated: true)
            } catch {
                log.error("launch check failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    public func checkNow(from viewController: UIViewController) {
        Task {
            do {
                switch try await check() {
                case .upToDate:
                    viewController.present(UpdatePrompt.message(title: "No updates", text: "Installed version \(installedVersion) is the latest"), animated: true)
                case .available(let feed):
                    viewController.present(prompt(for: feed, allowSkip: false), animated: true)
                }
            } catch {
                log.error("manual check failed: \(error.localizedDescription, privacy: .public)")
                viewController.present(UpdatePrompt.message(title: "Update check failed", text: error.localizedDescription), animated: true)
            }
        }
    }

    public func install(_ feed: UpdateFeed) {
        log.info("installing \(feed.appVersion.description, privacy: .public) from \(feed.manifest.absoluteString, privacy: .public)")
        if terminatesAfterInstall {
            terminateWhenInstallPromptCloses()
        }
        UIApplication.shared.open(feed.installURL)
    }

    private func terminateWhenInstallPromptCloses() {
        let center = NotificationCenter.default
        for observer in installObservers {
            center.removeObserver(observer)
        }
        installObservers.removeAll()
        installObservers.append(center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.terminateWhenActiveAgain()
            }
        })
    }

    private func terminateWhenActiveAgain() {
        let center = NotificationCenter.default
        installObservers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.log.info("install prompt closed, terminating so the new bundle can replace the running one")
            exit(0)
        })
    }

    public func skip(_ feed: UpdateFeed) {
        log.info("skipping \(feed.version, privacy: .public)")
        defaults.set(feed.version, forKey: Key.skippedVersion)
    }

    private func prompt(for feed: UpdateFeed, allowSkip: Bool) -> UIAlertController {
        UpdatePrompt.updateAvailable(feed, allowSkip: allowSkip) { [weak self] in
            self?.install(feed)
        } skip: { [weak self] in
            self?.skip(feed)
        }
    }
}
