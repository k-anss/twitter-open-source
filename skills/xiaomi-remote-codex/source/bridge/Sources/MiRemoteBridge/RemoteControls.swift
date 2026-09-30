import AppKit
import ApplicationServices
import IOKit.hid

/// Hardware usages from mi-ao's Xiaomi 2 Pro (2671) profile.
final class RemoteControls {
    static let shared = RemoteControls()
    private let names: [Int: String] = [82:"up",81:"down",80:"left",79:"right",40:"center",241:"back",74:"home",53:"tv",102:"power",128:"previous",129:"next",101:"menu"]
    private var active: String?
    private var activeElement: IOHIDElementCookie = 0
    private var pressedAt = Date()
    private var repeatTimer: Timer?
    private var hold: DispatchWorkItem?
    private(set) var paused = false
    private var ownsMapping = false
    private let ui = RemoteCodexActions()
    var onPause: (() -> Void)?

    func connected() {
        let current = mapping(["--get", "UserKeyMapping"])
        // Preserve mappings installed by another tool.
        guard !current.contains("HIDKeyboardModifierMappingSrc") || ownsMapping else {
            print("[REMOTE] 已有其他映射，未接管按钮")
            return
        }
        let entries = names.keys.sorted().map {
            ["HIDKeyboardModifierMappingSrc": UInt64(7) << 32 | UInt64($0),
             "HIDKeyboardModifierMappingDst": UInt64(7) << 32]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: ["UserKeyMapping":entries]),
              let json = String(data:data,encoding:.utf8) else { return }
        _ = mapping(["--set",json])
        ownsMapping = mapping(["--get","UserKeyMapping"]).contains("HIDKeyboardModifierMappingSrc")
        print("[REMOTE] 按键接管=\(ownsMapping)，语音映射保持不变")
    }

    func receive(_ value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let page = Int(IOHIDElementGetUsagePage(element))
        let usage = Int(IOHIDElementGetUsage(element))
        let raw = IOHIDValueGetIntegerValue(value)
        let cookie = IOHIDElementGetCookie(element)
        guard page == 7 || page == 9 else { return }
        guard ownsMapping else { return }
        if raw == 0 {
            if cookie == activeElement { release() }
            return
        }
        var normalized = usage
        if usage == Int(UInt32.max) {
            var bits = UInt(bitPattern: raw)
            while bits > 0 && bits & 255 == 0 { bits >>= 8 }
            normalized = Int(bits & 255)
        }
        if page == 7 && [61,62].contains(normalized) { return } // Existing voice filter owns voice.
        let name = page == 9 && normalized == 2 ? "menu" : (page == 7 ? names[normalized] : nil)
        guard let name else { print("[REMOTE] 未映射 page=\(page) usage=\(normalized)"); return }
        guard active != name else { return }
        release()
        active = name
        activeElement = cookie
        pressedAt = Date()
        print("[REMOTE] DOWN \(name)")
        if name == "power" {
            paused.toggle()
            if paused { onPause?() }
            NSSound.beep()
            print("[REMOTE] \(paused ? "已暂停" : "已恢复")")
            return
        }
        guard !paused else { return }
        if name == "tv" {
            guard let target = ui.approvalButton() else { print("[REMOTE] 当前没有唯一的单次授权请求"); return }
            print("[REMOTE] TV 已找到允许一次，等待持续按住 1 秒")
            let work = DispatchWorkItem { [weak self] in
                guard let self, self.active == "tv", !self.paused else { return }
                print("[REMOTE] TV 长按计时完成")
                self.ui.approve(target)
            }
            hold = work
            DispatchQueue.main.asyncAfter(deadline:.now()+1, execute:work)
            return
        }
        perform(name)
        if ["up","down","left","right"].contains(name) {
            let work = DispatchWorkItem { [weak self] in
                guard let self, self.active == name else { return }
                self.repeatTimer = Timer.scheduledTimer(withTimeInterval:0.12,repeats:true) { [weak self] _ in self?.perform(name) }
            }
            hold = work
            DispatchQueue.main.asyncAfter(deadline:.now()+0.4,execute:work)
        }
    }

    func release() {
        if active == "tv" {
            print("[REMOTE] TV 松开，持续毫秒=\(Int(Date().timeIntervalSince(pressedAt)*1000))")
        }
        hold?.cancel(); hold = nil
        repeatTimer?.invalidate(); repeatTimer = nil
        active = nil
    }
    func stop() {
        release()
        if ownsMapping { _ = mapping(["--set","{\"UserKeyMapping\":[]}"]); ownsMapping = false }
    }
    private func perform(_ name: String) {
        switch name {
        case "home": ui.home()
        case "previous": ui.task(previous:true)
        case "next": ui.task(previous:false)
        case "menu": ui.locateApproval()
        case "back": ui.cancelOrStop()
        case "center": ui.confirm()
        case "left": ui.key(48,flags:.maskShift)
        case "right": ui.key(48)
        case "up", "down": ui.scroll(name == "up" ? 5 : -5)
        default: break
        }
    }
    private func mapping(_ args: [String]) -> String {
        let process = Process(); let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath:"/usr/bin/hidutil")
        process.arguments = ["property","--matching","{\"VendorID\":10007,\"ProductID\":12984}"] + args
        process.standardOutput = pipe; process.standardError = pipe
        do { try process.run() } catch { print("[REMOTE] hidutil: \(error)"); return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data:data,encoding:.utf8) ?? ""
    }
}

final class RemoteCodexActions {
    private let bundleID = "com.openai.codex"
    private var app: NSRunningApplication? { NSRunningApplication.runningApplications(withBundleIdentifier:bundleID).first }
    private var foreground: Bool { NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleID }
    private func value(_ e: AXUIElement, _ name: String) -> CFTypeRef? {
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(e,name as CFString,&result) == .success else { return nil }
        return result
    }
    private func element(_ e: AXUIElement, _ name: String) -> AXUIElement? {
        guard let v = value(e,name), CFGetTypeID(v) == AXUIElementGetTypeID() else { return nil }
        return (v as! AXUIElement)
    }
    private var root: AXUIElement? {
        guard let app else { return nil }
        let application = AXUIElementCreateApplication(app.processIdentifier)
        _ = AXUIElementSetAttributeValue(application,"AXManualAccessibility" as CFString,kCFBooleanTrue)
        return element(application,kAXFocusedWindowAttribute)
            ?? element(application,kAXMainWindowAttribute)
            ?? (value(application,kAXWindowsAttribute) as? [AXUIElement])?.first
    }
    private func all(_ root: AXUIElement) -> [AXUIElement] {
        var queue = [root]; var cursor = 0
        while cursor < queue.count && cursor < 10000 {
            let e = queue[cursor]; cursor += 1
            if let children = value(e,kAXChildrenAttribute) as? [AXUIElement] { queue.append(contentsOf:children) }
        }
        return Array(queue.prefix(10000))
    }
    private func text(_ e: AXUIElement) -> String {
        for attribute in [kAXTitleAttribute,kAXDescriptionAttribute] {
            if let s = value(e,attribute) as? String, !s.isEmpty { return s }
        }
        return ""
    }
    private func buttons(_ labels: Set<String>, in scope: AXUIElement? = nil) -> [AXUIElement] {
        guard let root = scope ?? root else { return [] }
        return all(root).filter {
            value($0,kAXRoleAttribute) as? String == "AXButton" && labels.contains(text($0)) &&
            (value($0,kAXEnabledAttribute) as? Bool ?? true) && !(value($0,"AXHidden") as? Bool ?? false)
        }
    }
    func approvalButton() -> AXUIElement? {
        guard foreground else { return nil }
        let found = buttons(["允许一次","Allow once"])
        return found.count == 1 ? found[0] : nil
    }
    func approve(_ original: AXUIElement) {
        guard let current = approvalButton(), CFEqual(original,current) else { print("[REMOTE] 授权请求已变化，取消"); return }
        let result = AXUIElementPerformAction(current,kAXPressAction as CFString)
        print("[REMOTE] 允许一次 result=\(result.rawValue)")
    }
    func locateApproval() {
        guard let target = approvalButton() else { NSSound.beep(); print("[REMOTE] 找不到唯一待授权请求"); return }
        AXUIElementPerformAction(target,"AXScrollToVisible" as CFString)
        AXUIElementSetAttributeValue(target,kAXFocusedAttribute as CFString,kCFBooleanTrue)
        print("[REMOTE] 已定位待授权请求")
    }
    func home() {
        guard let app else {
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.openai.codex") else {
                print("[REMOTE] 未找到 Codex，请先安装并打开 Codex")
                return
            }
            NSWorkspace.shared.open(url)
            return
        }
        app.activate(options:[.activateAllWindows])
        DispatchQueue.main.asyncAfter(deadline:.now()+0.3) { [weak self] in
            guard let self, self.foreground, let root = self.root else { print("[REMOTE] 主页：无法读取前台窗口"); return }
            let inputs = self.all(root).filter { self.value($0,kAXRoleAttribute) as? String == "AXTextArea" && (self.value($0,kAXEnabledAttribute) as? Bool ?? true) }
            guard inputs.count == 1 else { print("[REMOTE] 输入框不唯一，未切换焦点"); return }
            let input = inputs[0]
            let result = AXUIElementSetAttributeValue(input,kAXFocusedAttribute as CFString,kCFBooleanTrue)
            let application = AXUIElementCreateApplication(app.processIdentifier)
            if let focused = self.element(application,kAXFocusedUIElementAttribute), CFEqual(focused,input) {
                print("[REMOTE] 主页：输入框已聚焦")
                return
            }
            // Some Electron editors expose focus as read-only; click the verified editor bounds.
            var position = CGPoint.zero; var size = CGSize.zero
            guard let p = self.value(input,kAXPositionAttribute), CFGetTypeID(p) == AXValueGetTypeID(),
                  let s = self.value(input,kAXSizeAttribute), CFGetTypeID(s) == AXValueGetTypeID(),
                  AXValueGetValue(p as! AXValue,.cgPoint,&position),
                  AXValueGetValue(s as! AXValue,.cgSize,&size), size.width > 0, size.height > 0 else {
                print("[REMOTE] 主页：无法定位输入框 result=\(result.rawValue)"); return
            }
            let point = CGPoint(x:position.x+size.width/2,y:position.y+size.height/2)
            for type in [CGEventType.leftMouseDown,.leftMouseUp] {
                CGEvent(mouseEventSource:nil,mouseType:type,mouseCursorPosition:point,mouseButton:.left)?.post(tap:.cghidEventTap)
            }
            print("[REMOTE] 主页：已点击输入框")
        }
    }
    func task(previous: Bool) {
        // Installed Codex defines Command+Option+Left/Right for previous/next chat.
        key(previous ? 123 : 124, flags:[.maskCommand,.maskAlternate])
        print("[REMOTE] 已触发\(previous ? "上一个" : "下一个")任务快捷键")
    }
    func cancelOrStop() {
        guard foreground, let root else { return }
        let dialogs = all(root).filter { let role = value($0,kAXRoleAttribute) as? String; return role == "AXSheet" || role == "AXDialog" || value($0,kAXSubroleAttribute) as? String == "AXDialog" }
        if !dialogs.isEmpty { key(53); return }
        let stop = buttons(["停止生成","停止","Stop","Stop generating","Stop response"])
        if stop.count == 1 { AXUIElementPerformAction(stop[0],kAXPressAction as CFString) }
        else { key(53) }
    }
    func confirm() {
        guard foreground, let app,
              let focused = element(AXUIElementCreateApplication(app.processIdentifier),kAXFocusedUIElementAttribute) else { return }
        if value(focused,kAXRoleAttribute) as? String == "AXButton" {
            AXUIElementPerformAction(focused,kAXPressAction as CFString)
        } else { key(36) }
    }
    func key(_ code: CGKeyCode, flags: CGEventFlags = []) {
        guard foreground else { return }
        for down in [true,false] {
            let event = CGEvent(keyboardEventSource:CGEventSource(stateID:.hidSystemState),virtualKey:code,keyDown:down)
            event?.flags = flags
            event?.post(tap:.cghidEventTap)
        }
    }
    func scroll(_ lines: Int32) {
        guard foreground, let root else { return }
        let e = CGEvent(scrollWheelEvent2Source:nil,units:.line,wheelCount:1,wheel1:lines,wheel2:0,wheel3:0)
        // Scroll the conversation area even when the mouse was left over the sidebar.
        var position = CGPoint.zero; var size = CGSize.zero
        if let p = value(root,kAXPositionAttribute), CFGetTypeID(p) == AXValueGetTypeID(),
           let s = value(root,kAXSizeAttribute), CFGetTypeID(s) == AXValueGetTypeID() {
            AXValueGetValue(p as! AXValue,.cgPoint,&position)
            AXValueGetValue(s as! AXValue,.cgSize,&size)
            e?.location = CGPoint(x:position.x+size.width*0.60,y:position.y+size.height*0.50)
        }
        e?.post(tap:.cghidEventTap)
    }
}
