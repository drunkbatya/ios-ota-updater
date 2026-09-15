import UIKit

@MainActor
enum UpdatePrompt {
    static func updateAvailable(_ feed: UpdateFeed, allowSkip: Bool, install: @escaping () -> Void, skip: @escaping () -> Void) -> UIAlertController {
        var message = "\(feed.title) \(feed.appVersion)"
        if let notes = feed.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
            message += "\n\n" + notes
        }
        message += "\n\nThe app closes after you confirm the install; open it again once the icon finishes loading."
        let alert = UIAlertController(title: "Update available", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Update", style: .default) { _ in install() })
        if allowSkip {
            alert.addAction(UIAlertAction(title: "Skip this version", style: .destructive) { _ in skip() })
        }
        alert.addAction(UIAlertAction(title: "Later", style: .cancel))
        return alert
    }

    static func message(title: String, text: String) -> UIAlertController {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        return alert
    }
}
