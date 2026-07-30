import Foundation
import Testing
@testable import FloatingBrowser

@Test func normalizesWebAddressesAndSearches() throws {
    #expect(BrowserPolicy.normalizedURL(from: "example.com/docs")?.absoluteString == "https://example.com/docs")
    #expect(BrowserPolicy.normalizedURL(from: "https://example.com")?.host == "example.com")

    let searchURL = try #require(BrowserPolicy.normalizedURL(from: "floating browser mac"))
    let query = URLComponents(url: searchURL, resolvingAgainstBaseURL: false)?
        .queryItems?
        .first(where: { $0.name == "q" })?
        .value
    #expect(query == "floating browser mac")
}

@Test func rejectsUnsafeAndLocalSchemes() {
    #expect(BrowserPolicy.normalizedURL(from: "file:///etc/passwd") == nil)
    #expect(BrowserPolicy.normalizedURL(from: "javascript:alert(1)") == nil)
    #expect(BrowserPolicy.normalizedURL(from: "data:text/html,hello") == nil)
}

@Test func stripsSecretsFromPersistedAddresses() throws {
    let source = try #require(URL(string: "https://user:pass@example.com/watch/42?token=secret#chapter"))
    let persisted = try #require(BrowserPolicy.persistedURL(from: source))
    #expect(persisted.absoluteString == "https://example.com/watch/42")
}

@Test func streamingHostMatchingDoesNotAcceptLookalikes() throws {
    #expect(BrowserPolicy.shouldPauseContentBlocking(for: try #require(URL(string: "https://www.netflix.com/watch/1"))))
    #expect(BrowserPolicy.shouldPauseContentBlocking(for: try #require(URL(string: "https://video.amazon.com"))))
    #expect(!BrowserPolicy.shouldPauseContentBlocking(for: try #require(URL(string: "https://notamazon.com"))))
}

@Test func identifiesServicesThatMayRejectEmbeddedPlayback() throws {
    #expect(BrowserPolicy.embeddedPlaybackServiceName(
        for: try #require(URL(string: "https://www.disneyplus.com/play/example"))
    ) == "Disney+")
    #expect(BrowserPolicy.embeddedPlaybackServiceName(
        for: try #require(URL(string: "https://www.primevideo.com/detail/example"))
    ) == "Prime Video")
    #expect(BrowserPolicy.embeddedPlaybackServiceName(
        for: try #require(URL(string: "https://www.youtube.com/watch?v=example"))
    ) == nil)
    #expect(BrowserPolicy.embeddedPlaybackServiceName(
        for: try #require(URL(string: "https://notprimevideo.com"))
    ) == nil)
}
