//
//  WindowManager.swift
//  Project X
//
//  Created by Aryan Palit on 12/20/24.
//
import SwiftUI
import AppKit

class WindowManager {
    static let shared = WindowManager()
    
    // Store references to open windows
    private var windows: [NSWindow] = []
    
    /// Opens a new window with the given SwiftUI view and title.
    /// - Parameters:
    ///   - content: The SwiftUI view to display in the new window.
    ///   - title: The title of the new window.
    func openNewWindow<Content: View>(_ content: Content, title: String) {
        let hostingController = NSHostingController(rootView: content)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false)
        window.center()
        window.title = title
        window.contentViewController = hostingController
        window.makeKeyAndOrderFront(nil)
        
        // Retain the window by storing it in the windows array
        windows.append(window)
        
        // Optionally, remove the window from the array when it's closed to free memory
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            self?.windows.removeAll { $0 == window }
        }
    }
}

