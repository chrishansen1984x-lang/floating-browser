import Foundation

enum BrowserPolicy {
    static let internalHost = "local.floating-browser.invalid"

    static func normalizedURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let explicitURL = URL(string: trimmed), explicitURL.scheme != nil {
            return isAllowedWebURL(explicitURL) ? explicitURL : nil
        }

        if trimmed.contains(".") && !trimmed.contains(where: \.isWhitespace),
           let webURL = URL(string: "https://\(trimmed)"),
           isAllowedWebURL(webURL) {
            return webURL
        }

        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        return components?.url
    }

    static func isAllowedWebURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return false
        }
        return url.host?.isEmpty == false
    }

    static func isInternalURL(_ url: URL) -> Bool {
        url.host?.lowercased() == internalHost
    }

    static func persistedURL(from url: URL) -> URL? {
        guard isAllowedWebURL(url),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.user = nil
        components.password = nil
        components.query = nil
        components.fragment = nil
        return components.url
    }

    static func shouldPauseContentBlocking(for url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return streamingCompatibilityHosts.contains { host == $0 || host.hasSuffix(".\($0)") }
    }

    static func embeddedPlaybackServiceName(for url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }

        for service in embeddedPlaybackServices where
            host == service.domain || host.hasSuffix(".\(service.domain)") {
            return service.name
        }
        return nil
    }

    private static let embeddedPlaybackServices = [
        (domain: "disneyplus.com", name: "Disney+"),
        (domain: "primevideo.com", name: "Prime Video"),
        (domain: "amazon.com", name: "Prime Video")
    ]

    private static let streamingCompatibilityHosts = [
        "disneyplus.com",
        "hulu.com",
        "netflix.com",
        "max.com",
        "primevideo.com",
        "amazon.com",
        "peacocktv.com",
        "paramountplus.com",
        "tv.youtube.com",
        "tv.apple.com",
        "tubitv.com"
    ]
}
