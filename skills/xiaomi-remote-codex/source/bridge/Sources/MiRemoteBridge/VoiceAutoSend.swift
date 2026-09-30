import AppKit
import ApplicationServices

/// Sends only new text committed into the Codex editor used for this recording.
final class VoiceAutoSend {
    private var timer: Timer?
    private var editor: AXUIElement?
    private var pid: pid_t = 0
    private var initial = ""

    func cancel() {
        timer?.invalidate()
        timer = nil
        editor = nil
    }

    func begin() {
        cancel()
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.bundleIdentifier == "com.openai.codex" else {
            print("[SEND] 前台不是 Codex，本次只输入")
            return
        }
        // Electron can disable its accessibility tree after an application restart.
        // Request the supported accessibility mode before reading the editor.
        let application = AXUIElementCreateApplication(app.processIdentifier)
        let result = AXUIElementSetAttributeValue(application,
            "AXManualAccessibility" as CFString, kCFBooleanTrue)
        print("[SEND] Codex accessibility request=\(result.rawValue)")
        guard let focused = focusedElement(app.processIdentifier),
              let role = attribute(focused, kAXRoleAttribute) as? String,
              ["AXTextArea", "AXTextField"].contains(role),
              let value = attribute(focused, kAXValueAttribute) as? String else {
            print("[SEND] 当前不是可读取的 Codex 输入框，本次只输入")
            return
        }
        pid = app.processIdentifier
        editor = focused
        initial = value
    }

    func finish() {
        guard let editor else { return }
        let started = Date()
        var lastValue = initial
        var changedAt = started
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            guard Date().timeIntervalSince(started) < 20 else {
                print("[SEND] 等待识别文字超时，保留输入框内容")
                self.cancel()
                return
            }
            guard let value = self.attribute(editor, kAXValueAttribute) as? String else { return }
            if value != lastValue { lastValue = value; changedAt = Date() }
            guard value != self.initial,
                  !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  Date().timeIntervalSince(changedAt) >= 1.5,
                  Date().timeIntervalSince(started) >= 1.5 else { return }
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier == self.pid,
                  let focused = self.focusedElement(self.pid), CFEqual(focused, editor) else {
                print("[SEND] 焦点已改变，取消自动发送")
                self.cancel()
                return
            }
            self.cancel()
            let source = CGEventSource(stateID: .hidSystemState)
            for down in [true, false] {
                let event = CGEvent(keyboardEventSource: source, virtualKey: 0x24, keyDown: down)
                event?.flags = []
                event?.post(tap: .cghidEventTap)
            }
            print("[SEND] 豆包文字稳定后已发送 Return")
        }
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private func focusedElement(_ pid: pid_t) -> AXUIElement? {
        guard let value = attribute(AXUIElementCreateApplication(pid), kAXFocusedUIElementAttribute),
              CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }
}
