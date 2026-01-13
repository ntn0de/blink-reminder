import SwiftUI
import UserNotifications
import AppKit

@main
struct BlinkReminderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
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
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Blink Reminder")
        }
        
        setupMenu()
        requestNotificationPermission()
        startTimer()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Blink Reminder", action: nil, keyEquivalent: ""))
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
    
    @objc func changeInterval(_ sender: NSMenuItem) {
        if let newInterval = sender.representedObject as? TimeInterval {
            self.interval = newInterval
            startTimer()
            updateMenuStates()
        }
    }
    
    @objc func toggleOverlay(_ sender: NSMenuItem) {
        overlayEnabled.toggle()
        updateMenuStates()
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
        
        // Update Overlay Check
        if let overlayItem = menu.items.first(where: { $0.title == "Use Screen Overlay" }) {
            overlayItem.state = overlayEnabled ? .on : .off
        }

        // Update Pause Title
        if let pauseItem = menu.items.first(where: { $0.action == #selector(togglePause(_:)) }) {
            pauseItem.title = isPaused ? "Resume" : "Pause"
        }
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            print("Notification permission granted: \(granted)")
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        
        center.getNotificationSettings { settings in
            print("Notification settings: \(settings)")
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        guard !isPaused else { return }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.triggerBreak()
        }
    }
    
    @objc func triggerBreak() {
        if overlayEnabled {
            showOverlay()
        } else {
            sendNotification()
        }
    }
    
    func showOverlay() {
        DispatchQueue.main.async {
            // Close existing if any
            self.overlayWindows.forEach { $0.close() }
            self.overlayWindows.removeAll()
            
            for screen in NSScreen.screens {
                let window = OverlayWindow(frame: screen.frame)
                let view = OverlayView {
                    // Close all windows when any one dismisses
                    self.overlayWindows.forEach { $0.close() }
                    self.overlayWindows.removeAll()
                }
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
    @State private var timeLeft = 20
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
    @State private var connectedTimer: Any?
    @State private var isEyeOpen = true
    @State private var isBreathing = false
    
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
                }
                
                Text("Rest Your Eyes")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Look away at something 20 feet away.")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("\(timeLeft)")
                    .font(.system(size: 60, weight: .heavy, design: .monospaced))
                    .foregroundColor(.blue)
                    .padding()
                    .background(Circle().stroke(Color.blue, lineWidth: 4))
                
                Button(action: onDismiss) {
                    Text("Skip Break")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            self.connectedTimer = self.timer.connect()
            startBlinking()
        }
        .onReceive(timer) { _ in
            if timeLeft > 0 {
                timeLeft -= 1
                        } else {
                            onDismiss()
                        }
                    }
                }
                
                    func startBlinking() {
                
                        // More frequent blink interval between 1 and 3 seconds
                
                        let randomInterval = Double.random(in: 1.0...3.0)
                
                        DispatchQueue.main.asyncAfter(deadline: .now() + randomInterval) {
                
                            // Close eye
                
                            isEyeOpen = false
                
                            
                
                            // Open eye after 150ms
                
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                
                                isEyeOpen = true
                
                                
                
                                // Maybe double blink? (20% chance)
                
                                if Double.random(in: 0...1) < 0.2 { 
                
                
                                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                     isEyeOpen = false
                                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                         isEyeOpen = true
                                         startBlinking()
                                     }
                                 }
                            } else {
                                startBlinking()
                            }
                        }
                    }
                }
            }
            