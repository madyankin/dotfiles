// Apple Reminders CLI over EventKit. Built and run by the `reminders` wrapper next to this file.
// Read everything; write only add / update / complete / reopen. No delete.

import Darwin
import EventKit
import Foundation

struct UsageError: Error { let message: String }

let store = EKEventStore()

func fail(_ message: String, hint: String? = nil, code: Int32 = 1) -> Never {
    var obj: [String: Any] = ["error": message]
    if let hint { obj["hint"] = hint }
    let data = try! JSONSerialization.data(withJSONObject: obj)
    FileHandle.standardError.write(data + Data("\n".utf8))
    exit(code)
}

func printJSON(_ value: Any) {
    let data = try! JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
    FileHandle.standardOutput.write(data + Data("\n".utf8))
}

func parseArgs(_ argv: [String]) -> (String, [String: String]) {
    var flags: [String: String] = [:]
    var positional: [String] = []
    var i = 0
    while i < argv.count {
        let a = argv[i]
        if a.hasPrefix("--") {
            let key = String(a.dropFirst(2))
            if i + 1 < argv.count, !argv[i + 1].hasPrefix("--") {
                flags[key] = argv[i + 1]
                i += 1
            } else {
                flags[key] = "true"
            }
        } else {
            positional.append(a)
        }
        i += 1
    }
    return (positional.first ?? "", flags)
}

func need(_ flags: [String: String], _ key: String) throws -> String {
    guard let v = flags[key], v != "true" else { throw UsageError(message: "--\(key) is required") }
    return v
}

// "YYYY-MM-DD" is a date-only due; "YYYY-MM-DDTHH:MM" carries a time.
func dueComponents(_ s: String) throws -> DateComponents {
    let parts = s.split(separator: "T")
    let d = parts[0].split(separator: "-").compactMap { Int($0) }
    guard d.count == 3 else { throw UsageError(message: "bad date \"\(s)\", want YYYY-MM-DD or YYYY-MM-DDTHH:MM") }
    var c = DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, year: d[0], month: d[1], day: d[2])
    if parts.count == 2 {
        let t = parts[1].split(separator: ":").compactMap { Int($0) }
        guard t.count >= 2 else { throw UsageError(message: "bad time in \"\(s)\"") }
        c.hour = t[0]
        c.minute = t[1]
    }
    return c
}

func dayStart(_ s: String) throws -> Date {
    guard let d = try dueComponents(s).date else { throw UsageError(message: "bad date \"\(s)\"") }
    return d
}

let isoFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.timeZone = TimeZone.current
    return f
}()

func dueString(_ c: DateComponents?) -> Any {
    guard let c, let date = Calendar.current.date(from: c) else { return NSNull() }
    if c.hour == nil {
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
    return isoFormatter.string(from: date)
}

let priorities: [String: Int] = ["none": 0, "high": 1, "medium": 5, "low": 9]

func priorityName(_ p: Int) -> String {
    switch p {
    case 0: return "none"
    case 1...4: return "high"
    case 5: return "medium"
    default: return "low"
    }
}

func json(_ r: EKReminder) -> [String: Any] {
    [
        "id": r.calendarItemIdentifier,
        "title": r.title ?? "",
        "list": r.calendar.title,
        "due": dueString(r.dueDateComponents),
        "completed": r.isCompleted,
        "completedAt": r.completionDate.map { isoFormatter.string(from: $0) } ?? NSNull(),
        "priority": priorityName(r.priority),
        "notes": r.notes ?? "",
        "url": r.url?.absoluteString ?? NSNull(),
    ]
}

// Claude Desktop, Codex Desktop and similar hosts start tools with TCC
// responsibility on the host app, which has no Reminders usage string, so
// macOS refuses access without a prompt. Re-exec once with responsibility
// disclaimed: TCC then reads the Info.plist embedded in this binary.
func disclaimResponsibility() {
    guard getenv("AGENT_SKILL_DISCLAIMED") == nil, let path = Bundle.main.executablePath else { return }
    typealias SetDisclaim = @convention(c) (UnsafeMutablePointer<posix_spawnattr_t?>, Int32) -> Int32
    let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)
    guard let sym = dlsym(rtldDefault, "responsibility_spawnattrs_setdisclaim") else { return }
    setenv("AGENT_SKILL_DISCLAIMED", "1", 1)
    var attr: posix_spawnattr_t?
    guard posix_spawnattr_init(&attr) == 0 else { return }
    posix_spawnattr_setflags(&attr, Int16(POSIX_SPAWN_SETEXEC))
    _ = unsafeBitCast(sym, to: SetDisclaim.self)(&attr, 1)
    var pid: pid_t = 0
    _ = posix_spawn(&pid, path, nil, &attr, CommandLine.unsafeArgv, environ)
    posix_spawnattr_destroy(&attr)  // reached only if the re-exec failed; carry on undisclaimed
}

func requestAccess() {
    let sem = DispatchSemaphore(value: 0)
    var granted = false
    if #available(macOS 14.0, *) {
        store.requestFullAccessToReminders { ok, _ in granted = ok; sem.signal() }
    } else {
        store.requestAccess(to: .reminder) { ok, _ in granted = ok; sem.signal() }
    }
    sem.wait()
    if !granted {
        fail("no access to Reminders", hint: "allow \"reminders\" in System Settings > Privacy & Security > Reminders")
    }
}

func list(named name: String) throws -> EKCalendar {
    let hits = store.calendars(for: .reminder).filter { $0.title == name || $0.calendarIdentifier == name }
    guard let cal = hits.first else { throw UsageError(message: "list \"\(name)\" not found") }
    if hits.count > 1 { throw UsageError(message: "list name \"\(name)\" is ambiguous, pass its id") }
    return cal
}

func fetch(_ predicate: NSPredicate) -> [EKReminder] {
    let sem = DispatchSemaphore(value: 0)
    var out: [EKReminder] = []
    store.fetchReminders(matching: predicate) { r in out = r ?? []; sem.signal() }
    sem.wait()
    return out
}

func reminder(_ id: String) throws -> EKReminder {
    guard let r = store.calendarItem(withIdentifier: id) as? EKReminder else {
        throw UsageError(message: "reminder \"\(id)\" not found")
    }
    return r
}

func sortByDue(_ items: [EKReminder]) -> [EKReminder] {
    items.sorted {
        let a = $0.dueDateComponents.flatMap { Calendar.current.date(from: $0) } ?? .distantFuture
        let b = $1.dueDateComponents.flatMap { Calendar.current.date(from: $0) } ?? .distantFuture
        return a < b
    }
}

func apply(_ r: EKReminder, _ f: [String: String]) throws {
    if let v = f["title"] { r.title = v }
    if let v = f["notes"] { r.notes = v == "none" ? nil : v }
    if let v = f["url"] { r.url = v == "none" ? nil : URL(string: v) }
    if let v = f["due"] {
        r.alarms?.forEach { r.removeAlarm($0) }
        if v == "none" {
            r.dueDateComponents = nil
        } else {
            let c = try dueComponents(v)
            r.dueDateComponents = c
            if c.hour != nil, let date = c.date { r.addAlarm(EKAlarm(absoluteDate: date)) }
        }
    }
    if let v = f["priority"] {
        guard let p = priorities[v] else { throw UsageError(message: "--priority must be none, low, medium or high") }
        r.priority = p
    }
    if let v = f["move-to"] { r.calendar = try list(named: v) }
}

func run(_ cmd: String, _ f: [String: String]) throws -> Any {
    switch cmd {
    case "lists":
        let def = store.defaultCalendarForNewReminders()?.calendarIdentifier
        return store.calendars(for: .reminder).map {
            ["id": $0.calendarIdentifier, "title": $0.title, "source": $0.source.title,
             "default": $0.calendarIdentifier == def, "writable": $0.allowsContentModifications] as [String: Any]
        }
    case "list":
        let cals = try f["list"].map { [try list(named: $0)] }
        let limit = Int(f["limit"] ?? "") ?? 50
        let pred: NSPredicate
        if f["include-completed"] != nil {
            pred = store.predicateForReminders(in: cals)
        } else {
            let after = try f["due-after"].map(dayStart)
            let before = try f["due-before"].map(dayStart)
            pred = store.predicateForIncompleteReminders(withDueDateStarting: after, ending: before, calendars: cals)
        }
        return sortByDue(fetch(pred)).prefix(limit).map(json)
    case "search":
        let q = try need(f, "query").lowercased()
        let pred = f["include-completed"] != nil
            ? store.predicateForReminders(in: nil)
            : store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        let hits = fetch(pred).filter {
            ($0.title ?? "").lowercased().contains(q) || ($0.notes ?? "").lowercased().contains(q)
        }
        return sortByDue(hits).prefix(Int(f["limit"] ?? "") ?? 30).map(json)
    case "get":
        return json(try reminder(try need(f, "id")))
    case "add":
        let r = EKReminder(eventStore: store)
        r.title = try need(f, "title")
        guard let cal = try f["list"].map(list(named:)) ?? store.defaultCalendarForNewReminders() else {
            throw UsageError(message: "no default list, pass --list")
        }
        r.calendar = cal
        var rest = f
        rest["title"] = nil
        try apply(r, rest)
        try store.save(r, commit: true)
        return json(r)
    case "update":
        let r = try reminder(try need(f, "id"))
        try apply(r, f)
        try store.save(r, commit: true)
        return json(r)
    case "complete", "reopen":
        let r = try reminder(try need(f, "id"))
        r.isCompleted = cmd == "complete"
        try store.save(r, commit: true)
        return json(r)
    default:
        fail("unknown command \"\(cmd)\"", code: 2)
    }
}

let commands: Set = ["lists", "list", "search", "get", "add", "update", "complete", "reopen"]
let (cmd, flags) = parseArgs(Array(CommandLine.arguments.dropFirst()))
if !commands.contains(cmd) {
    fail("unknown command \"\(cmd)\"", hint: commands.sorted().joined(separator: ", "), code: 2)
}
disclaimResponsibility()
requestAccess()
do {
    printJSON(try run(cmd, flags))
} catch let e as UsageError {
    fail(e.message)
} catch {
    fail(error.localizedDescription)
}
