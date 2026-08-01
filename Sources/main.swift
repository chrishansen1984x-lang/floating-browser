import AppKit
import WebKit

private enum DefaultsKey {
    static let lastURL = "lastURL"
    static let alwaysOnTop = "alwaysOnTop"
    static let windowFrame = "windowFrame"
    static let customSites = "customSites"
    static let blockAds = "blockAds"
    static let migratedLegacyPreferences = "migratedLegacyPreferencesV1"
}

private struct Site: Codable, Equatable {
    let title: String
    let url: String
}

@main
enum FloatingBrowserApp {
    @MainActor private static let appDelegate = AppDelegate()

    @MainActor static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.delegate = appDelegate
        app.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: BrowserWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        openBrowserWindow()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        openBrowserWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @MainActor private func openBrowserWindow() {
        if windowController == nil {
            windowController = BrowserWindowController()
        }

        guard let controller = windowController else { return }
        controller.showWindow(nil)
        controller.forceShow()
        NSRunningApplication.current.activate(options: [.activateAllWindows])
    }

    @MainActor private func setupMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem(title: "Floating Browser", action: nil, keyEquivalent: "")
        let appMenu = NSMenu(title: "Floating Browser")
        let aboutItem = NSMenuItem(title: "About Floating Browser", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        aboutItem.target = NSApp
        appMenu.addItem(aboutItem)
        appMenu.addItem(.separator())

        let servicesItem = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu(title: "Services")
        servicesItem.submenu = servicesMenu
        appMenu.addItem(servicesItem)
        NSApp.servicesMenu = servicesMenu
        appMenu.addItem(.separator())

        let hideItem = NSMenuItem(title: "Hide Floating Browser", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        hideItem.target = NSApp
        appMenu.addItem(hideItem)
        let hideOthersItem = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        hideOthersItem.target = NSApp
        appMenu.addItem(hideOthersItem)
        let showAllItem = NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        showAllItem.target = NSApp
        appMenu.addItem(showAllItem)
        appMenu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Floating Browser", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        appMenu.addItem(quitItem)
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let fileItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileMenu = NSMenu(title: "File")
        let showBrowserItem = NSMenuItem(title: "Show Browser", action: #selector(showWindowFromMenu), keyEquivalent: "n")
        showBrowserItem.target = self
        fileMenu.addItem(showBrowserItem)
        fileMenu.addItem(NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        fileMenu.addItem(.separator())
        let homeItem = NSMenuItem(title: "Home", action: #selector(showHomeFromMenu), keyEquivalent: "h")
        homeItem.keyEquivalentModifierMask = [.command, .shift]
        homeItem.target = self
        fileMenu.addItem(homeItem)
        let addSiteItem = NSMenuItem(title: "Add Current Site", action: #selector(addCurrentSiteFromMenu), keyEquivalent: "")
        addSiteItem.target = self
        fileMenu.addItem(addSiteItem)
        let openSafariItem = NSMenuItem(title: "Open Current Page in Safari", action: #selector(openCurrentPageInSafariFromMenu), keyEquivalent: "")
        openSafariItem.target = self
        fileMenu.addItem(openSafariItem)
        let openPasswordsItem = NSMenuItem(title: "Open Passwords...", action: #selector(openPasswordsFromMenu), keyEquivalent: "")
        openPasswordsItem.target = self
        fileMenu.addItem(openPasswordsItem)
        fileItem.submenu = fileMenu
        mainMenu.addItem(fileItem)

        let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        let redoItem = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redoItem)
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Delete", action: #selector(NSText.delete(_:)), keyEquivalent: ""))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editItem.submenu = editMenu
        mainMenu.addItem(editItem)

        let viewItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        let viewMenu = NSMenu(title: "View")
        let focusAddressItem = NSMenuItem(title: "Focus Address", action: #selector(focusAddressFromMenu), keyEquivalent: "l")
        focusAddressItem.target = self
        viewMenu.addItem(focusAddressItem)
        let reloadItem = NSMenuItem(title: "Reload Page", action: #selector(reloadFromMenu), keyEquivalent: "r")
        reloadItem.target = self
        viewMenu.addItem(reloadItem)
        viewMenu.addItem(.separator())
        let miniItem = NSMenuItem(title: "Toggle Mini Player", action: #selector(toggleMiniPlayerFromMenu), keyEquivalent: "m")
        miniItem.keyEquivalentModifierMask = [.command, .shift]
        miniItem.target = self
        viewMenu.addItem(miniItem)
        viewItem.submenu = viewMenu
        mainMenu.addItem(viewItem)

        let windowItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""))
        windowMenu.addItem(.separator())
        windowMenu.addItem(NSMenuItem(title: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: ""))
        windowItem.submenu = windowMenu
        mainMenu.addItem(windowItem)
        NSApp.windowsMenu = windowMenu

        let helpItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        let helpMenu = NSMenu(title: "Help")
        helpItem.submenu = helpMenu
        mainMenu.addItem(helpItem)
        NSApp.helpMenu = helpMenu

        NSApp.mainMenu = mainMenu
    }

    @MainActor @objc private func showWindowFromMenu() {
        openBrowserWindow()
    }

    @MainActor @objc private func showHomeFromMenu() {
        openBrowserWindow()
        windowController?.showHome()
    }

    @MainActor @objc private func addCurrentSiteFromMenu() {
        openBrowserWindow()
        windowController?.promptToAddCurrentSite()
    }

    @MainActor @objc private func toggleMiniPlayerFromMenu() {
        openBrowserWindow()
        windowController?.toggleMiniPlayer()
    }

    @MainActor @objc private func openCurrentPageInSafariFromMenu() {
        openBrowserWindow()
        windowController?.openCurrentPageInSafari()
    }

    @MainActor @objc private func openPasswordsFromMenu() {
        openBrowserWindow()
        windowController?.openPasswords()
    }

    @MainActor @objc private func focusAddressFromMenu() {
        openBrowserWindow()
        windowController?.focusAddress()
    }

    @MainActor @objc private func reloadFromMenu() {
        openBrowserWindow()
        windowController?.reloadCurrentPage()
    }
}

final class BrowserWindowController: NSWindowController, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    private let addressField = NSSearchField()
    private let statusLabel = NSTextField(labelWithString: "")
    private let statusToast = NSVisualEffectView()
    private let toolbarStack = NSStackView()
    private let miniOverlayButton = NSButton(title: "Full", target: nil, action: nil)
    private let miniCloseButton = NSButton(title: "Close", target: nil, action: nil)
    private let alwaysOnTopButton = NSButton(checkboxWithTitle: "Always on Top", target: nil, action: nil)
    private let blockAdsButton = NSButton(checkboxWithTitle: "Block Ads", target: nil, action: nil)
    private let backButton = NSButton(title: "Back", target: nil, action: nil)
    private let forwardButton = NSButton(title: "Forward", target: nil, action: nil)
    private let reloadButton = NSButton(title: "Reload", target: nil, action: nil)
    private let homeButton = NSButton(title: "Home", target: nil, action: nil)
    private let miniModeButton = NSButton(title: "Mini", target: nil, action: nil)
    private let moreButton = NSButton(title: "", target: nil, action: nil)
    private let webView: WKWebView
    private let defaultSites: [Site] = [
        Site(title: "Netflix", url: "https://www.netflix.com"),
        Site(title: "YouTube", url: "https://www.youtube.com"),
        Site(title: "Hulu", url: "https://www.hulu.com"),
        Site(title: "Disney+", url: "https://www.disneyplus.com"),
        Site(title: "Max", url: "https://www.max.com"),
        Site(title: "Prime Video", url: "https://www.amazon.com/gp/video/collection/IncludedwithPrime"),
        Site(title: "Apple TV+", url: "https://tv.apple.com"),
        Site(title: "Peacock", url: "https://www.peacocktv.com"),
        Site(title: "Paramount+", url: "https://www.paramountplus.com"),
        Site(title: "Tubi", url: "https://tubitv.com")
    ]
    private var customSites: [Site] = []
    private var isMiniMode = false
    private var normalWindowFrame: NSRect?
    private var preMiniAlwaysOnTop: Bool?
    private var contentBlockingActive: Bool?
    private var compiledContentRuleList: WKContentRuleList?
    private var contentBlockingGeneration = 0
    private var navigationGeneration = 0
    private var warnedPlaybackServices = Set<String>()
    private var recentWebContentRestarts: [Date] = []
    private var isShowingProcessRecoveryAlert = false
    private var isShowingStartPage = false
    private var chromeContainer: NSView?
    private var webViewMinimumHeightConstraint: NSLayoutConstraint?
    private var statusDismissWorkItem: DispatchWorkItem?
    private var statusGeneration = 0

    private var allSites: [Site] {
        defaultSites + customSites
    }

    init() {
        Self.migrateLegacyPreferencesIfNeeded()

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.userContentController = WKUserContentController()

        webView = WKWebView(frame: .zero, configuration: configuration)
        // Prime Video's web player rejects WKWebView's default browser identity.
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true

        let frame = BrowserWindowController.restoredWindowFrame() ?? BrowserWindowController.defaultWindowFrame()
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Floating Browser"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.minSize = NSSize(width: 560, height: 420)
        window.contentMinSize = NSSize(width: 560, height: 420)
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.managed, .fullScreenPrimary]
        window.tabbingMode = .disallowed

        super.init(window: window)

        window.delegate = self
        webView.navigationDelegate = self
        webView.uiDelegate = self
        loadCustomSites()
        setupUI()
        restoreAlwaysOnTop()
        restoreContentBlocking { [weak self] in
            self?.loadInitialPage()
            self?.updateNavigationState()
        }
    }

    private static func migrateLegacyPreferencesIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: DefaultsKey.migratedLegacyPreferences) else {
            return
        }

        if let legacyDefaults = UserDefaults(suiteName: "com.local.FloatingBrowser") {
            for key in [
                DefaultsKey.lastURL,
                DefaultsKey.alwaysOnTop,
                DefaultsKey.windowFrame,
                DefaultsKey.customSites,
                DefaultsKey.blockAds
            ] where defaults.object(forKey: key) == nil {
                if let value = legacyDefaults.object(forKey: key) {
                    defaults.set(value, forKey: key)
                }
            }
        }

        defaults.set(true, forKey: DefaultsKey.migratedLegacyPreferences)
    }

    required init?(coder: NSCoder) {
        nil
    }

    private static func defaultWindowFrame() -> NSRect {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width = min(1180, max(760, visibleFrame.width * 0.76))
        let height = min(760, max(520, visibleFrame.height * 0.72))
        return NSRect(
            x: visibleFrame.midX - width / 2,
            y: visibleFrame.midY - height / 2,
            width: width,
            height: height
        )
    }

    private static func restoredWindowFrame() -> NSRect? {
        guard let savedValue = UserDefaults.standard.string(forKey: DefaultsKey.windowFrame) else {
            return nil
        }

        let savedFrame = NSRectFromString(savedValue)
        guard savedFrame.width >= 560,
              savedFrame.height >= 420,
              NSScreen.screens.contains(where: { $0.visibleFrame.intersects(savedFrame) }) else {
            return nil
        }
        return savedFrame
    }

    private static func miniWindowFrame(in visibleFrame: NSRect) -> NSRect {
        let width = min(640, max(460, visibleFrame.width * 0.34))
        let height = width * 9 / 16
        let margin: CGFloat = 18

        return NSRect(
            x: visibleFrame.maxX - width - margin,
            y: visibleFrame.minY + margin,
            width: width,
            height: height
        )
    }

    @MainActor func forceShow() {
        guard let window else { return }

        window.deminiaturize(nil)
        window.makeKeyAndOrderFront(nil)
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let rootStack = NSStackView()
        rootStack.orientation = .vertical
        rootStack.spacing = 0
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        toolbarStack.orientation = .horizontal
        toolbarStack.alignment = .centerY
        toolbarStack.spacing = 6
        toolbarStack.edgeInsets = NSEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        toolbarStack.translatesAutoresizingMaskIntoConstraints = false

        configureSymbolButton(
            miniOverlayButton,
            symbolName: "arrow.up.left.and.arrow.down.right",
            label: "Return to Full Size"
        )
        miniOverlayButton.bezelStyle = .circular
        miniOverlayButton.target = self
        miniOverlayButton.action = #selector(toggleMiniPlayer)
        miniOverlayButton.isHidden = true
        miniOverlayButton.translatesAutoresizingMaskIntoConstraints = false

        configureSymbolButton(miniCloseButton, symbolName: "xmark", label: "Close Mini Player")
        miniCloseButton.bezelStyle = .circular
        miniCloseButton.target = self
        miniCloseButton.action = #selector(closeMiniPlayer)
        miniCloseButton.isHidden = true
        miniCloseButton.translatesAutoresizingMaskIntoConstraints = false

        for button in [backButton, forwardButton, reloadButton, homeButton, miniModeButton, moreButton] {
            button.bezelStyle = .toolbar
            button.setButtonType(.momentaryPushIn)
            button.translatesAutoresizingMaskIntoConstraints = false
        }

        configureSymbolButton(backButton, symbolName: "chevron.left", label: "Back")
        configureSymbolButton(forwardButton, symbolName: "chevron.right", label: "Forward")
        configureSymbolButton(reloadButton, symbolName: "arrow.clockwise", label: "Reload")
        configureSymbolButton(homeButton, symbolName: "house", label: "Home")
        configureSymbolButton(miniModeButton, symbolName: "pip.enter", label: "Mini Player")
        configureSymbolButton(moreButton, symbolName: "ellipsis", label: "More")

        backButton.target = self
        backButton.action = #selector(goBack)
        forwardButton.target = self
        forwardButton.action = #selector(goForward)
        reloadButton.target = self
        reloadButton.action = #selector(reload)
        homeButton.target = self
        homeButton.action = #selector(loadStart)
        miniModeButton.target = self
        miniModeButton.action = #selector(toggleMiniPlayer)
        moreButton.target = self
        moreButton.action = #selector(showMoreMenu(_:))
        alwaysOnTopButton.target = self
        alwaysOnTopButton.action = #selector(toggleAlwaysOnTop)
        blockAdsButton.target = self
        blockAdsButton.action = #selector(toggleContentBlocking)

        addressField.placeholderString = "Search or enter website"
        addressField.target = self
        addressField.action = #selector(loadAddress)
        addressField.sendsSearchStringImmediately = false
        addressField.sendsWholeSearchString = true
        addressField.lineBreakMode = .byTruncatingMiddle
        addressField.translatesAutoresizingMaskIntoConstraints = false
        addressField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addressField.controlSize = .large

        toolbarStack.addArrangedSubview(backButton)
        toolbarStack.addArrangedSubview(forwardButton)
        toolbarStack.addArrangedSubview(reloadButton)
        toolbarStack.addArrangedSubview(homeButton)
        toolbarStack.addArrangedSubview(addressField)
        toolbarStack.addArrangedSubview(miniModeButton)
        toolbarStack.addArrangedSubview(moreButton)

        statusToast.material = .popover
        statusToast.blendingMode = .withinWindow
        statusToast.state = .active
        statusToast.wantsLayer = true
        statusToast.layer?.cornerRadius = 10
        statusToast.layer?.masksToBounds = true
        statusToast.alphaValue = 0
        statusToast.isHidden = true
        statusToast.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.alignment = .center
        statusLabel.lineBreakMode = .byTruncatingMiddle
        statusLabel.maximumNumberOfLines = 2
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusToast.addSubview(statusLabel)

        let chromeContainer = makeChromeContainer(containing: toolbarStack)
        self.chromeContainer = chromeContainer
        webView.translatesAutoresizingMaskIntoConstraints = false
        rootStack.addArrangedSubview(chromeContainer)
        rootStack.addArrangedSubview(webView)

        contentView.addSubview(rootStack)
        contentView.addSubview(miniOverlayButton)
        contentView.addSubview(miniCloseButton)
        contentView.addSubview(statusToast)

        let webViewMinimumHeightConstraint = webView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300)
        self.webViewMinimumHeightConstraint = webViewMinimumHeightConstraint

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rootStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            chromeContainer.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            miniOverlayButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            miniOverlayButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            miniCloseButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            miniCloseButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            statusToast.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            statusToast.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),
            statusToast.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, constant: -32),
            statusLabel.leadingAnchor.constraint(equalTo: statusToast.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: statusToast.trailingAnchor, constant: -12),
            statusLabel.topAnchor.constraint(equalTo: statusToast.topAnchor, constant: 7),
            statusLabel.bottomAnchor.constraint(equalTo: statusToast.bottomAnchor, constant: -7),
            statusLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 440),
            chromeContainer.heightAnchor.constraint(equalToConstant: 54),
            addressField.heightAnchor.constraint(equalToConstant: 30),
            addressField.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            webViewMinimumHeightConstraint
        ])
    }

    private func makeChromeContainer(containing content: NSView) -> NSView {
        let host = NSView()
        host.translatesAutoresizingMaskIntoConstraints = false

        if #available(macOS 26.0, *) {
            let glass = NSGlassEffectView()
            glass.cornerRadius = 15
            glass.style = .regular
            glass.tintColor = NSColor.controlBackgroundColor.withAlphaComponent(0.12)
            glass.contentView = content
            glass.translatesAutoresizingMaskIntoConstraints = false
            if #available(macOS 27.0, *) {
                glass.effectIsInteractive = true
            }
            host.addSubview(glass)
            let glassCenterConstraint = glass.centerXAnchor.constraint(equalTo: host.centerXAnchor)
            glassCenterConstraint.priority = .defaultHigh
            NSLayoutConstraint.activate([
                glassCenterConstraint,
                glass.leadingAnchor.constraint(greaterThanOrEqualTo: host.leadingAnchor, constant: 76),
                glass.trailingAnchor.constraint(lessThanOrEqualTo: host.trailingAnchor, constant: -8),
                glass.widthAnchor.constraint(lessThanOrEqualToConstant: 720),
                glass.topAnchor.constraint(equalTo: host.topAnchor, constant: 6),
                glass.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -6)
            ])
            return host
        }

        let material = NSVisualEffectView()
        material.material = .headerView
        material.blendingMode = .withinWindow
        material.state = .active
        material.wantsLayer = true
        material.layer?.cornerRadius = 15
        material.layer?.masksToBounds = true
        material.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(material)
        material.addSubview(content)
        let materialCenterConstraint = material.centerXAnchor.constraint(equalTo: host.centerXAnchor)
        materialCenterConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            materialCenterConstraint,
            material.leadingAnchor.constraint(greaterThanOrEqualTo: host.leadingAnchor, constant: 76),
            material.trailingAnchor.constraint(lessThanOrEqualTo: host.trailingAnchor, constant: -8),
            material.widthAnchor.constraint(lessThanOrEqualToConstant: 720),
            material.topAnchor.constraint(equalTo: host.topAnchor, constant: 6),
            material.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -6),
            content.leadingAnchor.constraint(equalTo: material.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: material.trailingAnchor),
            content.topAnchor.constraint(equalTo: material.topAnchor),
            content.bottomAnchor.constraint(equalTo: material.bottomAnchor)
        ])
        return host
    }

    private func configureSymbolButton(_ button: NSButton, symbolName: String, label: String) {
        button.title = ""
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: label)
        button.imagePosition = .imageOnly
        button.bezelStyle = .toolbar
        button.toolTip = label
        button.setAccessibilityLabel(label)
        button.widthAnchor.constraint(equalToConstant: 32).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }

    private func showStatus(
        _ message: String,
        duration: TimeInterval? = 3,
        isError: Bool = false
    ) {
        statusDismissWorkItem?.cancel()
        statusGeneration += 1
        statusLabel.stringValue = message
        statusLabel.textColor = isError ? .systemRed : .labelColor
        statusToast.isHidden = false
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            statusToast.animator().alphaValue = 1
        }

        guard let duration else { return }
        let workItem = DispatchWorkItem { [weak self] in
            self?.hideStatus()
        }
        statusDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    private func hideStatus() {
        statusDismissWorkItem?.cancel()
        statusDismissWorkItem = nil
        guard !statusToast.isHidden else { return }
        statusGeneration += 1
        let generation = statusGeneration
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.16
            statusToast.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                guard self?.statusGeneration == generation else { return }
                self?.statusToast.isHidden = true
            }
        })
    }

    @objc private func showMoreMenu(_ sender: NSButton) {
        let menu = NSMenu()
        menu.addItem(menuItem(title: "Add Current Site", action: #selector(addCurrentSite)))
        menu.addItem(menuItem(title: "Manage Saved Sites", action: #selector(manageSites)))
        menu.addItem(menuItem(title: "Open in Safari", action: #selector(openCurrentPageInSafari)))
        menu.addItem(menuItem(title: "Open Passwords...", action: #selector(openPasswords)))
        menu.addItem(.separator())

        let blockerItem = menuItem(title: "Block Ads", action: #selector(toggleContentBlockingFromMenu))
        blockerItem.state = blockAdsButton.state
        menu.addItem(blockerItem)

        let floatingItem = menuItem(title: "Always on Top", action: #selector(toggleAlwaysOnTopFromMenu))
        floatingItem.state = alwaysOnTopButton.state
        menu.addItem(floatingItem)
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Clear Website Data...", action: #selector(clearWebsiteData)))

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.maxY + 4), in: sender)
    }

    private func menuItem(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func restoreAlwaysOnTop() {
        let enabled = UserDefaults.standard.bool(forKey: DefaultsKey.alwaysOnTop)
        alwaysOnTopButton.state = enabled ? .on : .off
        applyAlwaysOnTop(enabled)
    }

    private func applyAlwaysOnTop(_ enabled: Bool, persist: Bool = true) {
        window?.level = enabled ? .floating : .normal
        window?.collectionBehavior = enabled
            ? [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            : [.managed, .fullScreenPrimary]
        if persist {
            UserDefaults.standard.set(enabled, forKey: DefaultsKey.alwaysOnTop)
        }
    }

    private func restoreContentBlocking(completion: @escaping () -> Void) {
        let hasSavedPreference = UserDefaults.standard.object(forKey: DefaultsKey.blockAds) != nil
        let enabled = hasSavedPreference ? UserDefaults.standard.bool(forKey: DefaultsKey.blockAds) : true
        UserDefaults.standard.set(enabled, forKey: DefaultsKey.blockAds)
        blockAdsButton.state = enabled ? .on : .off
        applyContentBlocking(enabled, reloadPage: false, completion: completion)
    }

    private func configureContentBlocking(for url: URL?, reloadPage: Bool) {
        let userEnabled = UserDefaults.standard.bool(forKey: DefaultsKey.blockAds)
        let shouldPauseForStreaming = url.map(BrowserPolicy.shouldPauseContentBlocking) ?? false
        let shouldEnable = userEnabled && !shouldPauseForStreaming
        blockAdsButton.state = userEnabled ? .on : .off
        applyContentBlocking(
            shouldEnable,
            reloadPage: reloadPage,
            statusMessage: shouldPauseForStreaming && userEnabled ? "Ad blocking paused for streaming compatibility" : nil
        )
    }

    private func applyContentBlocking(
        _ enabled: Bool,
        reloadPage: Bool = true,
        statusMessage: String? = nil,
        completion: (() -> Void)? = nil
    ) {
        if contentBlockingActive == enabled {
            if let statusMessage {
                showStatus(statusMessage)
            }
            completion?()
            return
        }

        contentBlockingGeneration += 1
        let generation = contentBlockingGeneration
        let userContentController = webView.configuration.userContentController
        userContentController.removeAllContentRuleLists()
        contentBlockingActive = false

        guard enabled else {
            showStatus(statusMessage ?? "Ad blocking off")
            if reloadPage {
                webView.reload()
            }
            completion?()
            return
        }

        if let compiledContentRuleList {
            userContentController.add(compiledContentRuleList)
            contentBlockingActive = true
            showStatus("Ad blocking on")
            if reloadPage {
                webView.reload()
            }
            completion?()
            return
        }

        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: Self.contentRuleListIdentifier,
            encodedContentRuleList: Self.contentBlockerRules
        ) { [weak self] ruleList, error in
            DispatchQueue.main.async {
                guard let self else { return }
                guard self.contentBlockingGeneration == generation else {
                    completion?()
                    return
                }

                if let ruleList {
                    self.compiledContentRuleList = ruleList
                    userContentController.add(ruleList)
                    self.contentBlockingActive = true
                    self.showStatus("Ad blocking on")
                    if reloadPage {
                        self.webView.reload()
                    }
                    completion?()
                    return
                }

                self.contentBlockingActive = false
                if let error {
                    self.showStatus(
                        "Ad blocker failed: \(error.localizedDescription)",
                        duration: 6,
                        isError: true
                    )
                } else {
                    self.showStatus("Ad blocker unavailable", duration: 6, isError: true)
                }
                completion?()
            }
        }
    }

    private func loadInitialPage() {
        let savedURL = UserDefaults.standard.string(forKey: DefaultsKey.lastURL)
        if let savedURL, !savedURL.isEmpty {
            load(urlString: savedURL)
        } else {
            loadStartPage()
        }
    }

    private func normalizedURL(from rawValue: String) -> URL? {
        BrowserPolicy.normalizedURL(from: rawValue)
    }

    private func load(urlString: String) {
        guard let url = normalizedURL(from: urlString) else {
            showStatus("Enter a valid web address", duration: 6, isError: true)
            return
        }
        isShowingStartPage = false
        addressField.stringValue = url.absoluteString
        showStatus("Loading...", duration: nil)
        persistLastURL(url)
        configureContentBlocking(for: url, reloadPage: false)
        webView.load(URLRequest(url: url))
    }

    private func loadStartPage() {
        isShowingStartPage = true
        addressField.stringValue = ""
        hideStatus()
        configureContentBlocking(for: nil, reloadPage: false)
        webView.loadHTMLString(
            Self.startPageHTML(sites: allSites, customSiteCount: customSites.count),
            baseURL: URL(string: "https://\(BrowserPolicy.internalHost)")
        )
    }

    private func updateNavigationState() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward

        guard let url = webView.url else { return }

        if isShowingStartPage ||
            BrowserPolicy.isInternalURL(url) ||
            url.scheme?.lowercased() == "about" {
            addressField.stringValue = ""
            UserDefaults.standard.removeObject(forKey: DefaultsKey.lastURL)
            return
        }

        if BrowserPolicy.isAllowedWebURL(url) {
            isShowingStartPage = false
            addressField.stringValue = url.absoluteString
            persistLastURL(url)
        }
    }

    private func persistLastURL(_ url: URL) {
        guard let safeURL = BrowserPolicy.persistedURL(from: url) else { return }
        UserDefaults.standard.set(safeURL.absoluteString, forKey: DefaultsKey.lastURL)
    }

    @objc private func loadAddress() {
        let address = addressField.stringValue
        window?.makeFirstResponder(webView)
        load(urlString: address)
    }

    @objc private func loadStart() {
        showHome()
    }

    @MainActor func showHome() {
        if isMiniMode {
            exitMiniMode()
        }
        UserDefaults.standard.removeObject(forKey: DefaultsKey.lastURL)
        loadStartPage()
    }

    @MainActor @objc func toggleMiniPlayer() {
        if isMiniMode {
            exitMiniMode()
        } else {
            enterMiniMode()
        }
    }

    @objc private func closeMiniPlayer() {
        window?.performClose(nil)
    }

    private func enterMiniMode() {
        guard let window else { return }

        isMiniMode = true
        normalWindowFrame = window.frame
        persistNormalWindowFrame()
        preMiniAlwaysOnTop = alwaysOnTopButton.state == .on
        webViewMinimumHeightConstraint?.isActive = false
        applyMiniChrome(true)

        window.styleMask = [.borderless, .resizable]
        window.isMovableByWindowBackground = true
        window.hasShadow = true
        window.minSize = NSSize(width: 360, height: 203)
        window.contentMinSize = NSSize(width: 360, height: 203)

        alwaysOnTopButton.state = .on
        applyAlwaysOnTop(true, persist: false)
        let visibleFrame = window.screen?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        window.setFrame(Self.miniWindowFrame(in: visibleFrame), display: true, animate: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func exitMiniMode() {
        guard let window else { return }

        isMiniMode = false
        applyMiniChrome(false)
        webViewMinimumHeightConstraint?.isActive = true

        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.isMovableByWindowBackground = false
        window.hasShadow = true
        window.minSize = NSSize(width: 560, height: 420)
        window.contentMinSize = NSSize(width: 560, height: 420)

        if let wasAlwaysOnTop = preMiniAlwaysOnTop {
            alwaysOnTopButton.state = wasAlwaysOnTop ? .on : .off
            applyAlwaysOnTop(wasAlwaysOnTop)
        }

        window.setFrame(normalWindowFrame ?? Self.defaultWindowFrame(), display: true, animate: true)
        window.makeKeyAndOrderFront(nil)
        normalWindowFrame = nil
        preMiniAlwaysOnTop = nil
    }

    private func persistNormalWindowFrame() {
        guard let frame = isMiniMode ? normalWindowFrame : window?.frame else { return }
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: DefaultsKey.windowFrame)
    }

    private func applyMiniChrome(_ enabled: Bool) {
        let regularControls: [NSView] = [
            backButton,
            forwardButton,
            reloadButton,
            homeButton,
            addressField,
            moreButton,
            miniModeButton
        ]

        for control in regularControls {
            control.isHidden = enabled
        }

        chromeContainer?.isHidden = enabled
        toolbarStack.isHidden = enabled
        miniOverlayButton.isHidden = !enabled
        miniCloseButton.isHidden = !enabled
    }

    @objc private func addCurrentSite() {
        promptToAddCurrentSite()
    }

    @MainActor func promptToAddCurrentSite() {
        let currentURL = addableCurrentURLString() ?? addressField.stringValue
        let normalizedCurrentURL = normalizedURL(from: currentURL)
        let defaultURL = normalizedCurrentURL?.absoluteString ?? "https://"
        let fallbackTitle = normalizedCurrentURL?.host?.replacingOccurrences(of: "www.", with: "") ?? "New Site"
        let defaultTitle = (webView.title?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? fallbackTitle

        let titleField = NSTextField(string: defaultTitle)
        let urlField = NSTextField(string: defaultURL)
        titleField.placeholderString = "Site name"
        urlField.placeholderString = "https://example.com"

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(NSTextField(labelWithString: "Name"))
        stack.addArrangedSubview(titleField)
        stack.addArrangedSubview(NSTextField(labelWithString: "URL"))
        stack.addArrangedSubview(urlField)

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 116))
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let alert = NSAlert()
        alert.messageText = "Add this site to Home?"
        alert.informativeText = "It will appear in the Saved section on Home."
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        alert.accessoryView = container

        guard alert.runModal() == .alertFirstButtonReturn,
              let normalizedURL = normalizedURL(from: urlField.stringValue),
              normalizedURL.scheme == "http" || normalizedURL.scheme == "https" else {
            return
        }

        let title = titleField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let persistedURL = BrowserPolicy.persistedURL(from: normalizedURL) else {
            return
        }

        let savedSite = Site(
            title: title.isEmpty ? (normalizedURL.host ?? "Site") : title,
            url: persistedURL.absoluteString
        )

        customSites.removeAll { $0.url == savedSite.url }
        customSites.append(savedSite)
        saveCustomSites()
        loadStartPage()
        showStatus("Added \(savedSite.title)")
    }

    @objc private func manageSites() {
        guard !customSites.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "No custom sites yet"
            alert.informativeText = "Open a page and choose Add Current Site from the More menu."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 420, height: 28), pullsDown: false)
        for site in customSites {
            popup.addItem(withTitle: "\(site.title) - \(site.url)")
        }

        let selectionAlert = NSAlert()
        selectionAlert.messageText = "Manage saved sites"
        selectionAlert.informativeText = "Choose a site to edit, reorder, or remove."
        selectionAlert.addButton(withTitle: "Edit")
        selectionAlert.addButton(withTitle: "Cancel")
        selectionAlert.accessoryView = popup

        guard selectionAlert.runModal() == .alertFirstButtonReturn else {
            return
        }

        let index = popup.indexOfSelectedItem
        guard customSites.indices.contains(index) else { return }
        let selectedSite = customSites[index]

        let titleField = NSTextField(string: selectedSite.title)
        let urlField = NSTextField(string: selectedSite.url)
        let positionPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        for position in 1...customSites.count {
            positionPopup.addItem(withTitle: "Position \(position)")
        }
        positionPopup.selectItem(at: index)

        let editorStack = NSStackView()
        editorStack.orientation = .vertical
        editorStack.spacing = 7
        editorStack.translatesAutoresizingMaskIntoConstraints = false
        editorStack.addArrangedSubview(NSTextField(labelWithString: "Name"))
        editorStack.addArrangedSubview(titleField)
        editorStack.addArrangedSubview(NSTextField(labelWithString: "URL"))
        editorStack.addArrangedSubview(urlField)
        editorStack.addArrangedSubview(NSTextField(labelWithString: "Order"))
        editorStack.addArrangedSubview(positionPopup)

        let editorContainer = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 168))
        editorContainer.addSubview(editorStack)
        NSLayoutConstraint.activate([
            editorStack.leadingAnchor.constraint(equalTo: editorContainer.leadingAnchor),
            editorStack.trailingAnchor.constraint(equalTo: editorContainer.trailingAnchor),
            editorStack.topAnchor.constraint(equalTo: editorContainer.topAnchor),
            editorStack.bottomAnchor.constraint(equalTo: editorContainer.bottomAnchor)
        ])

        let editorAlert = NSAlert()
        editorAlert.messageText = "Edit saved site"
        editorAlert.addButton(withTitle: "Save")
        editorAlert.addButton(withTitle: "Remove")
        editorAlert.addButton(withTitle: "Cancel")
        editorAlert.accessoryView = editorContainer

        let response = editorAlert.runModal()
        if response == .alertSecondButtonReturn {
            let removed = customSites.remove(at: index)
            saveCustomSites()
            loadStartPage()
            showStatus("Removed \(removed.title)")
            return
        }

        guard response == .alertFirstButtonReturn else { return }

        let title = titleField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let normalizedURL = normalizedURL(from: urlField.stringValue),
              let persistedURL = BrowserPolicy.persistedURL(from: normalizedURL) else {
            showStatus("Enter a valid web address", duration: 6, isError: true)
            return
        }

        let updatedSite = Site(
            title: title.isEmpty ? (persistedURL.host ?? "Site") : title,
            url: persistedURL.absoluteString
        )
        customSites.remove(at: index)
        let destination = min(positionPopup.indexOfSelectedItem, customSites.count)
        customSites.insert(updatedSite, at: destination)
        saveCustomSites()
        loadStartPage()
        showStatus("Updated \(updatedSite.title)")
    }

    private func addableCurrentURLString() -> String? {
        guard let url = webView.url,
              !BrowserPolicy.isInternalURL(url),
              BrowserPolicy.isAllowedWebURL(url) else {
            return nil
        }

        return BrowserPolicy.persistedURL(from: url)?.absoluteString
    }

    @objc private func goBack() {
        webView.goBack()
    }

    @objc private func goForward() {
        webView.goForward()
    }

    @objc private func reload() {
        webView.reload()
    }

    @objc private func toggleAlwaysOnTop() {
        applyAlwaysOnTop(alwaysOnTopButton.state == .on)
    }

    @objc private func toggleAlwaysOnTopFromMenu() {
        let enabled = alwaysOnTopButton.state != .on
        alwaysOnTopButton.state = enabled ? .on : .off
        applyAlwaysOnTop(enabled)
    }

    @objc private func toggleContentBlocking() {
        UserDefaults.standard.set(blockAdsButton.state == .on, forKey: DefaultsKey.blockAds)
        configureContentBlocking(for: webView.url, reloadPage: true)
    }

    @objc private func toggleContentBlockingFromMenu() {
        blockAdsButton.state = blockAdsButton.state == .on ? .off : .on
        toggleContentBlocking()
    }

    @objc private func clearWebsiteData() {
        let alert = NSAlert()
        alert.messageText = "Clear website data?"
        alert.informativeText = "This removes cookies, caches, and local website storage. You will be signed out of sites."
        alert.addButton(withTitle: "Clear Data")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let dataStore = webView.configuration.websiteDataStore
        dataStore.removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: .distantPast
        ) { [weak self] in
            DispatchQueue.main.async {
                UserDefaults.standard.removeObject(forKey: DefaultsKey.lastURL)
                self?.loadStartPage()
                self?.showStatus("Website data cleared")
            }
        }
    }

    @MainActor func focusAddress() {
        if isMiniMode {
            exitMiniMode()
        }
        window?.makeFirstResponder(addressField)
        addressField.selectText(nil)
    }

    @MainActor func reloadCurrentPage() {
        webView.reload()
    }

    @MainActor @objc func openCurrentPageInSafari() {
        guard let url = webView.url,
              !BrowserPolicy.isInternalURL(url),
              BrowserPolicy.isAllowedWebURL(url) else {
            showStatus("No page to open in Safari", duration: 6, isError: true)
            return
        }

        NSWorkspace.shared.open([url], withApplicationAt: URL(fileURLWithPath: "/Applications/Safari.app"), configuration: NSWorkspace.OpenConfiguration()) { [weak self] _, error in
            if let error {
                DispatchQueue.main.async {
                    self?.showStatus(
                        "Could not open Safari: \(error.localizedDescription)",
                        duration: 6,
                        isError: true
                    )
                }
            }
        }
    }

    @MainActor @objc func openPasswords() {
        guard let passwordsURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Passwords") else {
            showStatus("Passwords is not available on this Mac", duration: 6, isError: true)
            return
        }

        let host = webView.url?.host?.replacingOccurrences(of: "www.", with: "")
        let guidance = host.map { "Search Passwords for \($0), then copy and paste" }
            ?? "Copy the saved login, then return here to paste"
        showStatus(guidance, duration: 10)

        NSWorkspace.shared.openApplication(
            at: passwordsURL,
            configuration: NSWorkspace.OpenConfiguration()
        ) { [weak self] _, error in
            guard let error else { return }
            DispatchQueue.main.async {
                self?.showStatus(
                    "Could not open Passwords: \(error.localizedDescription)",
                    duration: 6,
                    isError: true
                )
            }
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        navigationGeneration += 1
        showStatus("Loading...", duration: nil)
        updateNavigationState()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.targetFrame?.isMainFrame == true,
              let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if BrowserPolicy.isInternalURL(url) || url.scheme?.lowercased() == "about" {
            isShowingStartPage = true
            decisionHandler(.allow)
            return
        }

        if BrowserPolicy.isAllowedWebURL(url) {
            isShowingStartPage = false
            if navigationAction.shouldPerformDownload {
                decisionHandler(.download)
                return
            }
            configureContentBlocking(for: url, reloadPage: false)
            decisionHandler(.allow)
            return
        }

        if let scheme = url.scheme?.lowercased(), scheme == "mailto" || scheme == "tel" {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        showStatus("Blocked unsupported address", duration: 6, isError: true)
        decisionHandler(.cancel)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationResponsePolicy) -> Void
    ) {
        decisionHandler(navigationResponse.canShowMIMEType ? .allow : .download)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideStatus()
        updateNavigationState()
        watchForEmbeddedPlaybackError(generation: navigationGeneration)
    }

    private func watchForEmbeddedPlaybackError(generation: Int) {
        guard let url = webView.url,
              let serviceName = BrowserPolicy.embeddedPlaybackServiceName(for: url),
              !warnedPlaybackServices.contains(serviceName) else {
            return
        }

        for delay in [1.5, 4.0, 8.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self,
                      self.navigationGeneration == generation,
                      !self.warnedPlaybackServices.contains(serviceName) else {
                    return
                }

                self.webView.evaluateJavaScript(
                    """
                    (() => {
                        const text = (document.body?.innerText || "").toLowerCase();
                        const markers = [
                            "video unavailable",
                            "error code 83",
                            "something went wrong. please try again"
                        ];
                        return markers.find(marker => text.includes(marker)) || null;
                    })()
                    """
                ) { [weak self] result, _ in
                    guard let self,
                          self.navigationGeneration == generation,
                          result is String else {
                        return
                    }
                    self.showEmbeddedPlaybackWarning(for: serviceName)
                }
            }
        }
    }

    private func showEmbeddedPlaybackWarning(for serviceName: String) {
        guard !warnedPlaybackServices.contains(serviceName),
              let window else {
            return
        }
        warnedPlaybackServices.insert(serviceName)

        let alert = NSAlert()
        alert.messageText = "\(serviceName) blocked playback here"
        alert.informativeText = "\(serviceName) may allow browsing in Floating Browser but require a supported full browser for protected video. You can open this page in Safari to play it."
        alert.addButton(withTitle: "Open in Safari")
        alert.addButton(withTitle: "Keep Browsing")
        alert.beginSheetModal(for: window) { [weak self] response in
            if response == .alertFirstButtonReturn {
                self?.openCurrentPageInSafari()
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showStatus(error.localizedDescription, duration: 6, isError: true)
        updateNavigationState()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showStatus(error.localizedDescription, duration: 6, isError: true)
        updateNavigationState()
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil,
           let url = navigationAction.request.url,
           BrowserPolicy.isAllowedWebURL(url) {
            webView.load(navigationAction.request)
            showStatus("Opened link in this window")
        } else if navigationAction.targetFrame == nil {
            showStatus("Blocked unsupported popup", duration: 6, isError: true)
        }
        return nil
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        let now = Date()
        recentWebContentRestarts.removeAll { now.timeIntervalSince($0) > 60 }

        guard recentWebContentRestarts.count < 2 else {
            showStatus("Page repeatedly stopped responding", duration: nil, isError: true)
            showWebContentRecoveryAlert()
            return
        }

        recentWebContentRestarts.append(now)
        showStatus("Page process restarted", duration: 5, isError: true)
        webView.reload()
    }

    private func showWebContentRecoveryAlert() {
        guard !isShowingProcessRecoveryAlert,
              let window else {
            return
        }
        isShowingProcessRecoveryAlert = true

        let alert = NSAlert()
        alert.messageText = "This page stopped responding"
        alert.informativeText = "Floating Browser stopped automatically reloading it to avoid a restart loop."
        alert.addButton(withTitle: "Try Reloading")
        alert.addButton(withTitle: "Go Home")
        alert.beginSheetModal(for: window) { [weak self] response in
            guard let self else { return }
            self.isShowingProcessRecoveryAlert = false
            self.recentWebContentRestarts.removeAll()
            if response == .alertFirstButtonReturn {
                self.webView.reload()
            } else {
                self.showHome()
            }
        }
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping @MainActor @Sendable (URL?) -> Void
    ) {
        let panel = NSSavePanel()
        panel.title = "Save Download"
        panel.nameFieldStringValue = suggestedFilename
        panel.canCreateDirectories = true
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        completionHandler(panel.runModal() == .OK ? panel.url : nil)
    }

    func downloadDidFinish(_ download: WKDownload) {
        showStatus("Download finished")
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        showStatus("Download failed: \(error.localizedDescription)", duration: 6, isError: true)
    }

    private func loadCustomSites() {
        guard let data = UserDefaults.standard.data(forKey: DefaultsKey.customSites),
              let decoded = try? JSONDecoder().decode([Site].self, from: data) else {
            customSites = []
            return
        }
        customSites = decoded.compactMap { site in
            guard let url = BrowserPolicy.normalizedURL(from: site.url),
                  let persistedURL = BrowserPolicy.persistedURL(from: url) else {
                return nil
            }
            return Site(title: site.title, url: persistedURL.absoluteString)
        }

        if customSites != decoded {
            saveCustomSites()
        }
    }

    private func saveCustomSites() {
        guard let data = try? JSONEncoder().encode(customSites) else { return }
        UserDefaults.standard.set(data, forKey: DefaultsKey.customSites)
    }

    private static func htmlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private static let contentRuleListIdentifier = "FloatingBrowserBuiltInBlocker"

    private static var contentBlockerRules: String {
        var rules: [[String: Any]] = [
            [
                "trigger": [
                    "url-filter": ".*",
                    "resource-type": ["popup"]
                ],
                "action": [
                    "type": "block"
                ]
            ],
            [
                "trigger": [
                    "url-filter": ".*"
                ],
                "action": [
                    "type": "css-display-none",
                    "selector": "[id*='ad-'], [id*='ads-'], [id^='ad_'], [class*=' ad-'], [class*=' ads-'], [class*='advert'], [class*='sponsor'], iframe[src*='doubleclick'], iframe[src*='googlesyndication']"
                ]
            ]
        ]

        for fragment in blockedAdURLFragments {
            rules.append([
                "trigger": [
                    "url-filter": ".*\(fragment).*",
                    "resource-type": ["script", "image", "style-sheet", "font", "raw", "svg-document"]
                ],
                "action": [
                    "type": "block"
                ]
            ])
        }

        for fragment in blockedTrackingURLFragments {
            rules.append([
                "trigger": [
                    "url-filter": ".*\(fragment).*",
                    "resource-type": ["script", "image", "raw"]
                ],
                "action": [
                    "type": "block"
                ]
            ])
        }

        guard let data = try? JSONSerialization.data(withJSONObject: rules),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }

        return json
    }

    private static let blockedAdURLFragments = [
        "doubleclick",
        "googlesyndication",
        "googleadservices",
        "adservice\\.google",
        "adnxs",
        "adsystem",
        "adsrvr",
        "taboola",
        "outbrain",
        "pubmatic",
        "rubiconproject",
        "criteo",
        "scorecardresearch",
        "quantserve",
        "moatads",
        "zedo",
        "yieldmo",
        "openx",
        "smartadserver"
    ]

    private static let blockedTrackingURLFragments = [
        "google-analytics\\.com",
        "googletagmanager\\.com",
        "api\\.segment\\.io",
        "mixpanel\\.com",
        "amplitude\\.com",
        "hotjar\\.com"
    ]

    private static func startPageHTML(sites: [Site], customSiteCount: Int) -> String {
        let accents = [
            "#ff453a",
            "#ff375f",
            "#30d158",
            "#5e8bff",
            "#bf5af2",
            "#64d2ff",
            "#ff9f0a",
            "#40c8e0"
        ]

        func accent(for site: Site) -> String {
            let host = URL(string: site.url)?.host?.lowercased() ?? site.url.lowercased()
            let knownAccent: [String: String] = [
                "netflix.com": "#ff453a",
                "youtube.com": "#ff375f",
                "hulu.com": "#30d158",
                "disneyplus.com": "#5e8bff",
                "max.com": "#bf5af2",
                "primevideo.com": "#64d2ff",
                "amazon.com": "#64d2ff",
                "tv.apple.com": "#d1d1d6",
                "peacocktv.com": "#ffd60a",
                "paramountplus.com": "#0a84ff",
                "tubitv.com": "#bf5af2"
            ]
            if let match = knownAccent.first(where: { host == $0.key || host.hasSuffix(".\($0.key)") }) {
                return match.value
            }
            let stableIndex = site.url.utf8.reduce(0) { partial, byte in
                (partial * 33 + Int(byte)) % accents.count
            }
            return accents[stableIndex]
        }

        func linksHTML(for siteList: [Site]) -> String {
            siteList.map { site in
            let host = URL(string: site.url)?
                .host?
                .replacingOccurrences(of: "www.", with: "") ?? "Website"
            let initial = String(site.title.prefix(1)).uppercased()
            let accent = accent(for: site)
            return """
              <a href="\(htmlEscaped(site.url))" style="--accent: \(accent)">
                <span class="site-mark">\(htmlEscaped(initial))</span>
                <span class="site-copy">
                  <strong>\(htmlEscaped(site.title))</strong>
                  <small>\(htmlEscaped(host))</small>
                </span>
                <span class="chevron" aria-hidden="true">&rsaquo;</span>
              </a>
            """
            }.joined(separator: "\n")
        }

        let defaultSiteCount = max(0, sites.count - customSiteCount)
        let defaultLinks = linksHTML(for: Array(sites.prefix(defaultSiteCount)))
        let customLinks = linksHTML(for: Array(sites.suffix(customSiteCount)))
        let savedLabel = customSiteCount == 1 ? "1 site" : "\(customSiteCount) sites"
        let customSection = customSiteCount > 0 ? """
        <section>
          <div class="section-heading">
            <h2>Saved</h2>
            <span class="meta">\(savedLabel)</span>
          </div>
          <div class="grid saved-grid">
          \(customLinks)
          </div>
        </section>
        """ : ""

        return """
    <!doctype html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        :root {
          color-scheme: light dark;
          --background: #f2f3f5;
          --surface: rgba(255, 255, 255, 0.72);
          --surface-hover: rgba(255, 255, 255, 0.92);
          --border: rgba(40, 44, 52, 0.12);
          --label: #18191c;
          --secondary: #676b73;
          --shadow: rgba(20, 24, 32, 0.08);
        }
        @media (prefers-color-scheme: dark) {
          :root {
            --background: #0e1013;
            --surface: rgba(255, 255, 255, 0.055);
            --surface-hover: rgba(255, 255, 255, 0.095);
            --border: rgba(255, 255, 255, 0.11);
            --label: #f4f5f7;
            --secondary: #9ca1ab;
            --shadow: rgba(0, 0, 0, 0.28);
          }
        }
        html, body {
          margin: 0;
          min-height: 100%;
          background: var(--background);
          color: var(--label);
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }
        main {
          max-width: 980px;
          margin: 0 auto;
          padding: 42px 32px 64px;
        }
        header {
          margin-bottom: 28px;
        }
        h1 {
          font-size: 32px;
          font-weight: 720;
          margin: 0;
          letter-spacing: 0;
        }
        section + section {
          margin-top: 30px;
        }
        .section-heading {
          display: flex;
          align-items: baseline;
          justify-content: space-between;
          gap: 16px;
          margin: 0 2px 10px;
        }
        h2 {
          margin: 0;
          font-size: 13px;
          font-weight: 650;
          color: var(--secondary);
        }
        .grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
          gap: 12px;
        }
        .saved-grid {
          grid-template-columns: repeat(auto-fill, minmax(220px, 238px));
        }
        a {
          display: flex;
          align-items: center;
          gap: 13px;
          min-height: 72px;
          box-sizing: border-box;
          padding: 14px;
          border: 1px solid var(--border);
          border-radius: 8px;
          background: var(--surface);
          box-shadow: 0 8px 24px var(--shadow);
          backdrop-filter: blur(18px) saturate(135%);
          color: var(--label);
          text-decoration: none;
          transition: background 140ms ease, border-color 140ms ease, transform 140ms ease;
        }
        a:hover {
          background: var(--surface-hover);
          border-color: color-mix(in srgb, var(--accent) 48%, var(--border));
          transform: translateY(-1px);
        }
        a:active {
          transform: translateY(0);
        }
        .site-mark {
          display: grid;
          place-items: center;
          width: 38px;
          height: 38px;
          flex: 0 0 38px;
          border: 1px solid color-mix(in srgb, var(--accent) 38%, transparent);
          border-radius: 50%;
          background: color-mix(in srgb, var(--accent) 16%, transparent);
          color: var(--accent);
          font-size: 15px;
          font-weight: 750;
        }
        .site-copy {
          min-width: 0;
          flex: 1;
        }
        strong, small {
          display: block;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
        strong {
          font-size: 15px;
          font-weight: 650;
        }
        small {
          margin-top: 3px;
          color: var(--secondary);
          font-size: 12px;
        }
        .chevron {
          color: var(--secondary);
          font-size: 24px;
          font-weight: 300;
        }
        .meta {
          flex: 0 0 auto;
          color: var(--secondary);
          font-size: 12px;
        }
        @media (max-width: 640px) {
          main {
            padding: 30px 20px 48px;
          }
          header {
            margin-bottom: 22px;
          }
          .grid {
            grid-template-columns: 1fr;
          }
          .saved-grid {
            grid-template-columns: 1fr;
          }
        }
        @media (prefers-reduced-motion: reduce) {
          a {
            transition: none;
          }
        }
      </style>
    </head>
    <body>
      <main>
        <header>
          <h1>Floating Browser</h1>
        </header>
        <section>
          <div class="section-heading">
            <h2>Streaming</h2>
          </div>
          <div class="grid">
          \(defaultLinks)
          </div>
        </section>
        \(customSection)
      </main>
    </body>
    </html>
    """
    }
}

extension BrowserWindowController: NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        persistNormalWindowFrame()
    }

    func windowDidResize(_ notification: Notification) {
        persistNormalWindowFrame()
    }
}
