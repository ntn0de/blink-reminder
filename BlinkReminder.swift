import SwiftUI
import UserNotifications
import AppKit
import Combine
import ServiceManagement

@main
struct BlinkReminderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

struct Quotes {
    static let english = [
        "Look at something 20 feet away.",
        "Take a deep breath and relax.",
        "Blink often to keep your eyes hydrated.",
        "Stretch your neck and shoulders.",
        "Drink some water.",
        "Your eyes need rest to stay sharp.",
        "Focus on something distant.",
        "Relax your jaw and shoulders.",
        "Give your mind a moment of silence.",
        "Stare out the window and pretend you're in a music video.",
        "Your monitor misses you, but it needs space.",
        "A quick blink is a tiny nap for your eyes.",
        "Hydrate before you dy-drate! (Wait, just drink water).",
        "The pixels will be here when you get back.",
        "Is that a bird? Is that a plane? No, it's just a break.",
        "If you can read this, you're not looking 20 feet away!",
        "Rumor has it, blinking makes you 1% more awesome.",
        "Stretch like a cat. No one is watching. Probably."
    ]
    
    static let hindi = [
        "Tension nahi lene ka, break lene ka!",
        "Ae Circuit, isko bol break lene ko!",
        "Bhidu, aankhein hai toh jahaan hai. Relax kar!",
        "Load nahi lene ka, mast rehne ka.",
        "Kya re bhidu, thak gaya kya?",
        "Jadoo ki jhappi... for your eyes.",
        "All Izz Well!",
        "Utha le re baba, utha le... mereko nahi, is laptop ko utha le!",
        "Yeh Baburao ka style hai! Break toh banta hai.",
        "Dene wala jab bhi deta, deta chappar faad ke... toh break bhi chappar faad ke le!",
        "Khopdi tod saale ka! Break nahi lega toh?",
        "Mast joke maara re! Ab break le."
    ]
    
    static let nepali = [
        "Sathi, aankha ko jyoti nai thulo kura ho. Ekchin aaram gara.",
        "Mero naam Rajesh Hamal, ra ma bhanchu: Break leu!",
        "Herne katha hoina, herne byatha ho. Aankha lai aaram deu!",
        "Eh... aankha dukhyo bhane maile ke garne? Break leu na!",
        "Aankha futla hai! Ekchin aaram garnu pardaina?",
        "Tyo monitor lai katti hereko? Maile ta break liye hai!",
        "Namaste! Sanchai hunuhuncha? Aankha lai ali aaram chaincha hai.",
        "Desh banauna gaaro cha, tara aankha jogauna sajilo cha. Break linus!",
        "Gaaun ma huda ta hariyali herinthyo, yaha ta screen matra. Ekchin baaira herau!"
    ]
    
    static func getActiveQuotes() -> [String] {
        let defaults = UserDefaults.standard
        // Defaults: English enabled, others disabled if not set.
        // Actually, let's respect the stored values.
        // We will register defaults in AppDelegate.
        
        var quotes: [String] = []
        
        if defaults.bool(forKey: "LangEnglish") {
            quotes.append(contentsOf: english)
        }
        if defaults.bool(forKey: "LangHindi") {
            quotes.append(contentsOf: hindi)
        }
        if defaults.bool(forKey: "LangNepali") {
            quotes.append(contentsOf: nepali)
        }
        
        // Fallback to English if nothing selected but feature is enabled, 
        // or empty if strictly following selection. 
        // Let's fallback to English if empty to avoid blank screen.
        if quotes.isEmpty {
            quotes.append(contentsOf: english)
        }
        
        return quotes
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusItem: NSStatusItem?
    var timer: Timer?
    var interval: TimeInterval = 20 * 60 // 20 minutes
    var overlayEnabled: Bool = true // Default to overlay since notifications are flaky
    var overlayWindows: [OverlayWindow] = []
    var isPaused: Bool = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        
        // Register User Defaults
        UserDefaults.standard.register(defaults: [
            "MotivationEnabled": true,
            "LangEnglish": true,
            "LangHindi": false,
            "LangNepali": false,
            "FirstRun": true,
            "StrictMode": false,
            "MaxSkipsPerHour": -1 // -1 = Unlimited
        ])
        
        // Handle Launch at Login on First Run
        if UserDefaults.standard.bool(forKey: "FirstRun") {
            enableLaunchAtLogin()
            UserDefaults.standard.set(false, forKey: "FirstRun")
        }
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Blink Reminder")
        }
        
        setupMenu()
        requestNotificationPermission()
        
        // Add Sleep/Wake Observers
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(suspendTimer), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(resumeTimer), name: NSWorkspace.didWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(suspendTimer), name: NSWorkspace.screensDidSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(resumeTimer), name: NSWorkspace.screensDidWakeNotification, object: nil)
        
        startTimer()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        cleanup()
    }
    
    deinit {
        cleanup()
    }
    
    private func cleanup() {
        // Remove notification observers to prevent memory leaks
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        
        // Invalidate timer
        timer?.invalidate()
        timer = nil
        
        // Close all overlay windows
        overlayWindows.forEach { $0.close() }
        overlayWindows.removeAll()
        
        // Remove status item
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        menu.addItem(NSMenuItem(title: "Blink Reminder v\(version)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Launch at Login
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchAtLoginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchAtLoginItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Interval Submenu
        let intervalMenu = NSMenuItem(title: "Interval", action: nil, keyEquivalent: "")
        let subMenu = NSMenu()
        let intervals = [
            ("20 Minutes", 20 * 60.0),
            ("10 Minutes", 10 * 60.0),
            ("5 Minutes", 5 * 60.0),
            ("1 Minute (Test)", 60.0),
            ("10 Seconds (Test)", 10.0)
        ]
        
        for (title, time) in intervals {
            let item = NSMenuItem(title: title, action: #selector(changeInterval(_:)), keyEquivalent: "")
            item.representedObject = time
            if time == interval { item.state = .on }
            subMenu.addItem(item)
        }
        intervalMenu.submenu = subMenu
        menu.addItem(intervalMenu)
        
        // Max Skips / Hour Submenu
        let skipsMenu = NSMenuItem(title: "Max Skips / Hour", action: nil, keyEquivalent: "")
        let skipsSubMenu = NSMenu()
        let currentMaxSkips = UserDefaults.standard.integer(forKey: "MaxSkipsPerHour")
        let skipOptions = [
            ("Strict (0)", 0),
            ("1 Skip", 1),
            ("3 Skips", 3),
            ("5 Skips", 5),
            ("Unlimited", -1)
        ]
        
        for (title, val) in skipOptions {
            let item = NSMenuItem(title: title, action: #selector(changeMaxSkips(_:)), keyEquivalent: "")
            item.tag = val
            item.state = (val == currentMaxSkips) ? .on : .off
            skipsSubMenu.addItem(item)
        }
        skipsMenu.submenu = skipsSubMenu
        menu.addItem(skipsMenu)
        
        // Settings Submenu (Motivations)
        let settingsMenu = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        let settingsSubMenu = NSMenu()
        
        // Motivation Toggle
        let motivationItem = NSMenuItem(title: "Enable Motivation Text", action: #selector(toggleMotivation(_:)), keyEquivalent: "")
        motivationItem.state = UserDefaults.standard.bool(forKey: "MotivationEnabled") ? .on : .off
        settingsSubMenu.addItem(motivationItem)
        
        settingsSubMenu.addItem(NSMenuItem.separator())
        settingsSubMenu.addItem(NSMenuItem(title: "Languages:", action: nil, keyEquivalent: ""))
        
        let langEnglish = NSMenuItem(title: "English", action: #selector(toggleLanguage(_:)), keyEquivalent: "")
        langEnglish.representedObject = "LangEnglish"
        langEnglish.state = UserDefaults.standard.bool(forKey: "LangEnglish") ? .on : .off
        settingsSubMenu.addItem(langEnglish)
        
        let langHindi = NSMenuItem(title: "Hindi", action: #selector(toggleLanguage(_:)), keyEquivalent: "")
        langHindi.representedObject = "LangHindi"
        langHindi.state = UserDefaults.standard.bool(forKey: "LangHindi") ? .on : .off
        settingsSubMenu.addItem(langHindi)
        
        let langNepali = NSMenuItem(title: "Nepali", action: #selector(toggleLanguage(_:)), keyEquivalent: "")
        langNepali.representedObject = "LangNepali"
        langNepali.state = UserDefaults.standard.bool(forKey: "LangNepali") ? .on : .off
        settingsSubMenu.addItem(langNepali)
        
        settingsMenu.submenu = settingsSubMenu
        menu.addItem(settingsMenu)
        
        // Strict Mode Toggle
        let strictModeItem = NSMenuItem(title: "Strict Mode", action: #selector(toggleStrictMode(_:)), keyEquivalent: "")
        strictModeItem.state = UserDefaults.standard.bool(forKey: "StrictMode") ? .on : .off
        menu.addItem(strictModeItem)
        
        // Overlay Toggle
        let overlayItem = NSMenuItem(title: "Use Screen Overlay", action: #selector(toggleOverlay(_:)), keyEquivalent: "")
        overlayItem.state = overlayEnabled ? .on : .off
        menu.addItem(overlayItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Pause", action: #selector(togglePause(_:)), keyEquivalent: "p"))
        menu.addItem(NSMenuItem(title: "Trigger Break Now", action: #selector(triggerBreak), keyEquivalent: "b"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    // MARK: - Launch at Login Logic
    func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false // Fallback/Unknown for older OS
    }
    
    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if service.status == .enabled {
                    try service.unregister()
                    sender.state = .off
                } else {
                    try service.register()
                    sender.state = .on
                }
            } catch {
                print("Failed to toggle Launch at Login: \(error)")
            }
        }
    }
    
    func enableLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            if service.status != .enabled {
                try? service.register()
            }
        }
    }
    
    @objc func changeInterval(_ sender: NSMenuItem) {
        if let newInterval = sender.representedObject as? TimeInterval {
            self.interval = newInterval
            startTimer()
            updateMenuStates()
        }
    }
    
    @objc func changeMaxSkips(_ sender: NSMenuItem) {
        let val = sender.tag
        UserDefaults.standard.set(val, forKey: "MaxSkipsPerHour")
        updateMenuStates()
    }
    
    @objc func toggleOverlay(_ sender: NSMenuItem) {
        overlayEnabled.toggle()
        updateMenuStates()
    }
    
    @objc func toggleMotivation(_ sender: NSMenuItem) {
        let current = UserDefaults.standard.bool(forKey: "MotivationEnabled")
        UserDefaults.standard.set(!current, forKey: "MotivationEnabled")
        sender.state = !current ? .on : .off
    }
    
    @objc func toggleLanguage(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        let current = UserDefaults.standard.bool(forKey: key)
        UserDefaults.standard.set(!current, forKey: key)
        sender.state = !current ? .on : .off
    }
    
    @objc func toggleStrictMode(_ sender: NSMenuItem) {
        let current = UserDefaults.standard.bool(forKey: "StrictMode")
        UserDefaults.standard.set(!current, forKey: "StrictMode")
        sender.state = !current ? .on : .off
    }

    @objc func togglePause(_ sender: NSMenuItem) {
        isPaused.toggle()
        if isPaused {
            timer?.invalidate()
            statusItem?.button?.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: "Blink Reminder (Paused)")
        } else {
            startTimer()
            statusItem?.button?.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Blink Reminder")
        }
        updateMenuStates()
    }
    
    func updateMenuStates() {
        guard let menu = statusItem?.menu else { return }
        
        // Update Interval Checks
        if let intervalItem = menu.items.first(where: { $0.title == "Interval" }), let sub = intervalItem.submenu {
            for item in sub.items {
                item.state = (item.representedObject as? TimeInterval == interval) ? .on : .off
            }
        }
        
        // Update Max Skips Check
        let currentMax = UserDefaults.standard.integer(forKey: "MaxSkipsPerHour")
        if let skipItem = menu.items.first(where: { $0.title == "Max Skips / Hour" }), let sub = skipItem.submenu {
            for item in sub.items {
                item.state = (item.tag == currentMax) ? .on : .off
            }
        }
        
        // Update Overlay Check
        if let overlayItem = menu.items.first(where: { $0.title == "Use Screen Overlay" }) {
            overlayItem.state = overlayEnabled ? .on : .off
        }
        
        // Update Strict Mode
        if let strictItem = menu.items.first(where: { $0.title == "Strict Mode" }) {
            strictItem.state = UserDefaults.standard.bool(forKey: "StrictMode") ? .on : .off
        }

        // Update Pause Title
        if let pauseItem = menu.items.first(where: { $0.action == #selector(togglePause(_:)) }) {
            pauseItem.title = isPaused ? "Resume" : "Pause"
        }
    }
    
    @objc func suspendTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc func resumeTimer() {
        startTimer()
    }

    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            // Permission handler
        }
        
        center.getNotificationSettings { settings in
            // Settings handler
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = nil
        guard !isPaused else { return }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.triggerBreak()
        }
        // Add to common runloop modes to ensure it fires even in certain app states
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    @objc func triggerBreak() {
        if overlayEnabled {
            showOverlay()
        } else {
            sendNotification()
        }
    }
    
    var skipTimestamps: [Date] = []
    
    func showOverlay() {
        DispatchQueue.main.async {
            // Close existing if any
            self.overlayWindows.forEach { $0.close() }
            self.overlayWindows.removeAll()
            
            // Prepare motivations
            let enabled = UserDefaults.standard.bool(forKey: "MotivationEnabled")
            let quotes = enabled ? Quotes.getActiveQuotes() : []
            
            // Check strict mode
            let isStrict = UserDefaults.standard.bool(forKey: "StrictMode")
            
            // Check Skip Limit
            let maxSkips = UserDefaults.standard.integer(forKey: "MaxSkipsPerHour")
            
            // Cleanup old timestamps (older than 1 hour)
            let now = Date()
            self.skipTimestamps = self.skipTimestamps.filter { now.timeIntervalSince($0) < 3600 }
            
            let canSkip = (maxSkips == -1) || (self.skipTimestamps.count < maxSkips)
            
            for screen in NSScreen.screens {
                let window = OverlayWindow(frame: screen.frame)
                let view = OverlayView(onDismiss: {
                    // Close all windows when any one dismisses
                    self.overlayWindows.forEach { $0.close() }
                    self.overlayWindows.removeAll()
                }, onSkipAction: {
                    // Record skip
                    self.skipTimestamps.append(Date())
                }, quotes: quotes, isStrict: isStrict, canSkip: canSkip)
                window.contentView = NSHostingView(rootView: view)
                window.makeKeyAndOrderFront(nil)
                // Ensure it floats above everything
                window.level = .floating
                self.overlayWindows.append(window)
            }
            
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time to Blink!"
        content.body = "Rest your eyes for 20 seconds."
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Overlay Window
class OverlayWindow: NSPanel {
    init(frame: NSRect) {
        super.init(
            contentRect: frame,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        self.isFloatingPanel = true
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
}

// MARK: - Overlay View
struct OverlayView: View {
    var onDismiss: () -> Void
    var onSkipAction: () -> Void
    var quotes: [String]
    var isStrict: Bool
    var canSkip: Bool
    
    @State private var timeLeft = 20
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
    @State private var connectedTimer: Cancellable?
    @State private var isEyeOpen = true
    @State private var isBreathing = false
    @State private var motivationText = ""
    @State private var isActive = true
    
    var body: some View {
        ZStack {
            // Dark Background
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Two Eyes Face
                HStack(spacing: 20) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 80))
                    Image(systemName: "eye.fill")
                        .font(.system(size: 80))
                }
                .foregroundColor(.white)
                .scaleEffect(y: isEyeOpen ? 1.0 : 0.1)
                .animation(.easeInOut(duration: 0.15), value: isEyeOpen)
                .scaleEffect(isBreathing ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isBreathing)
                .onAppear {
                    isBreathing = true
                    if let randomQuote = quotes.randomElement() {
                        motivationText = randomQuote
                    } else {
                        // If motivation is disabled or empty list
                         motivationText = ""
                    }
                }
                
                Text("Rest Your Eyes")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                
                if !motivationText.isEmpty {
                    Text(motivationText)
                        .font(.title2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Text("\(timeLeft)")
                    .font(.system(size: 60, weight: .heavy, design: .monospaced))
                    .foregroundColor(.blue)
                    .padding()
                    .background(Circle().stroke(Color.blue, lineWidth: 4))
                
                if !isStrict && canSkip {
                    Button(action: {
                        onSkipAction()
                        onDismiss()
                    }) {
                        Text("Skip Break")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                } else {
                     Text(isStrict ? "Strict Mode On" : "Skip Limit Reached")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 10)
                }
            }
        }
        .onAppear {
            isActive = true
            self.connectedTimer = self.timer.connect()
            startBlinking()
        }
        .onDisappear {
            isActive = false
            connectedTimer?.cancel()
            connectedTimer = nil
        }
        .onReceive(timer) { _ in
            guard isActive else { return }
            if timeLeft > 0 {
                timeLeft -= 1
            } else {
                onDismiss()
            }
        }
    }
    
    func startBlinking() {
        guard isActive else { return }
        
        // More frequent blink interval between 1 and 3 seconds
        let randomInterval = Double.random(in: 1.0...3.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + randomInterval) {
            guard self.isActive else { return }
            
            // Close eye
            self.isEyeOpen = false
            
            // Open eye after 150ms
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                guard self.isActive else { return }
                
                self.isEyeOpen = true
                
                // Maybe double blink? (20% chance)
                if Double.random(in: 0...1) < 0.2 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        guard self.isActive else { return }
                        self.isEyeOpen = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            guard self.isActive else { return }
                            self.isEyeOpen = true
                            self.startBlinking()
                        }
                    }
                } else {
                    self.startBlinking()
                }
            }
        }
    }
}
            