// Apple Calendar CLI over EventKit. Built and run by the `calendar` wrapper next to this file.
// Read everything; write only add / update. No delete, no invitations.

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

// "YYYY-MM-DD" is a whole day; "YYYY-MM-DDTHH:MM" is a local time.
func parseDate(_ s: String) throws -> (date: Date, dateOnly: Bool) {
    let parts = s.split(separator: "T")
    let d = parts[0].split(separator: "-").compactMap { Int($0) }
    guard d.count == 3 else { throw UsageError(message: "bad date \"\(s)\", want YYYY-MM-DD or YYYY-MM-DDTHH:MM") }
    var c = DateComponents(year: d[0], month: d[1], day: d[2])
    if parts.count == 2 {
        let t = parts[1].split(separator: ":").compactMap { Int($0) }
        guard t.count >= 2 else { throw UsageError(message: "bad time in \"\(s)\"") }
        c.hour = t[0]
        c.minute = t[1]
    }
    guard let date = Calendar.current.date(from: c) else { throw UsageError(message: "bad date \"\(s)\"") }
    return (date, parts.count == 1)
}

let isoFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.timeZone = TimeZone.current
    return f
}()

func ymd(_ d: Date) -> String {
    let c = Calendar.current.dateComponents([.year, .month, .day], from: d)
    return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
}

let participantStatus: [EKParticipantStatus: String] = [
    .unknown: "unknown", .pending: "pending", .accepted: "accepted", .declined: "declined",
    .tentative: "tentative", .delegated: "delegated", .completed: "completed", .inProcess: "in-process",
]

func json(_ e: EKEvent, full: Bool) -> [String: Any] {
    let attendees = e.attendees ?? []
    let me = attendees.first { $0.isCurrentUser }
    var out: [String: Any] = [
        "id": e.eventIdentifier ?? "",
        "title": e.title ?? "",
        "calendar": e.calendar.title,
        "allDay": e.isAllDay,
        "start": e.isAllDay ? ymd(e.startDate) : isoFormatter.string(from: e.startDate),
        // EventKit ends an all-day event at the next midnight; report the last day instead.
        "end": e.isAllDay ? ymd(e.endDate.addingTimeInterval(-1)) : isoFormatter.string(from: e.endDate),
        "location": e.location ?? NSNull(),
        "recurring": e.hasRecurrenceRules,
        "attendees": attendees.count,
        "myStatus": me.map { participantStatus[$0.participantStatus] ?? "unknown" } ?? NSNull(),
        "editable": isEditable(e),
    ]
    let notes = e.notes ?? ""
    out["notes"] = full ? notes : String(notes.prefix(300))
    if full {
        out["url"] = e.url?.absoluteString ?? NSNull()
        out["organizer"] = e.organizer.map { $0.name ?? $0.url.absoluteString } ?? NSNull()
        out["attendeeList"] = attendees.map {
            ["name": $0.name ?? "", "status": participantStatus[$0.participantStatus] ?? "unknown"]
        }
    }
    return out
}

// A meeting someone else organizes cannot be changed for everyone from here;
// an edit would only fork a local copy that the next sync overwrites.
func isEditable(_ e: EKEvent) -> Bool {
    guard e.calendar.allowsContentModifications else { return false }
    return !e.hasAttendees || e.organizer?.isCurrentUser == true
}

// Claude Desktop, Codex Desktop and similar hosts start tools with TCC
// responsibility on the host app, which has no Calendars usage string, so
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
        store.requestFullAccessToEvents { ok, _ in granted = ok; sem.signal() }
    } else {
        store.requestAccess(to: .event) { ok, _ in granted = ok; sem.signal() }
    }
    sem.wait()
    if !granted {
        fail("no access to Calendars", hint: "allow \"calendar\" in System Settings > Privacy & Security > Calendars")
    }
}

func calendar(named name: String) throws -> EKCalendar {
    let hits = store.calendars(for: .event).filter { $0.title == name || $0.calendarIdentifier == name }
    guard let cal = hits.first else { throw UsageError(message: "calendar \"\(name)\" not found") }
    if hits.count > 1 { throw UsageError(message: "calendar name \"\(name)\" is ambiguous, pass its id") }
    return cal
}

func range(_ f: [String: String], back: Int, ahead: Int) throws -> (Date, Date) {
    let today = Calendar.current.startOfDay(for: Date())
    let from = try f["from"].map { try parseDate($0).date } ?? Calendar.current.date(byAdding: .day, value: -back, to: today)!
    var to = try f["to"].map { try parseDate($0) }.map { $0.dateOnly ? Calendar.current.date(byAdding: .day, value: 1, to: $0.date)! : $0.date }
        ?? Calendar.current.date(byAdding: .day, value: ahead, to: today)!
    if to <= from { to = Calendar.current.date(byAdding: .day, value: 1, to: from)! }
    return (from, to)
}

func events(_ f: [String: String], back: Int, ahead: Int) throws -> [EKEvent] {
    let (from, to) = try range(f, back: back, ahead: ahead)
    let cals = try f["calendar"].map { [try calendar(named: $0)] }
    let pred = store.predicateForEvents(withStart: from, end: to, calendars: cals)
    return store.events(matching: pred).sorted { $0.startDate < $1.startDate }
}

// For a recurring event the id names the series; --occurrence picks one instance.
func event(_ f: [String: String]) throws -> EKEvent {
    let id = try need(f, "id")
    if let occ = f["occurrence"] {
        let day = Calendar.current.startOfDay(for: try parseDate(occ).date)
        let next = Calendar.current.date(byAdding: .day, value: 1, to: day)!
        let pred = store.predicateForEvents(withStart: day, end: next, calendars: nil)
        guard let e = store.events(matching: pred).first(where: { $0.eventIdentifier == id }) else {
            throw UsageError(message: "event \"\(id)\" has no occurrence on \(ymd(day))")
        }
        return e
    }
    guard let e = store.event(withIdentifier: id) else { throw UsageError(message: "event \"\(id)\" not found") }
    return e
}

func apply(_ e: EKEvent, _ f: [String: String]) throws {
    if let v = f["title"] { e.title = v }
    if let v = f["location"] { e.location = v == "none" ? nil : v }
    if let v = f["notes"] { e.notes = v == "none" ? nil : v }
    let start = try f["start"].map(parseDate)
    let end = try f["end"].map(parseDate)
    if let start {
        let length = e.endDate.timeIntervalSince(e.startDate)
        e.isAllDay = start.dateOnly
        e.startDate = start.date
        if end == nil { e.endDate = start.date.addingTimeInterval(max(length, start.dateOnly ? 0 : 3600)) }
    }
    if let end {
        // An all-day end is inclusive for the user and exclusive for EventKit.
        e.endDate = end.dateOnly ? Calendar.current.date(byAdding: .day, value: 1, to: end.date)!.addingTimeInterval(-1) : end.date
    }
    if e.endDate < e.startDate { throw UsageError(message: "end is before start") }
}

func run(_ cmd: String, _ f: [String: String]) throws -> Any {
    switch cmd {
    case "calendars":
        let def = store.defaultCalendarForNewEvents?.calendarIdentifier
        return store.calendars(for: .event).map {
            ["id": $0.calendarIdentifier, "title": $0.title, "source": $0.source.title,
             "default": $0.calendarIdentifier == def, "writable": $0.allowsContentModifications] as [String: Any]
        }
    case "events":
        let limit = Int(f["limit"] ?? "") ?? 200
        return try events(f, back: 0, ahead: 7).prefix(limit).map { json($0, full: false) }
    case "search":
        let q = try need(f, "query").lowercased()
        let hits = try events(f, back: 30, ahead: 90).filter {
            [$0.title, $0.location, $0.notes].contains { ($0 ?? "").lowercased().contains(q) }
        }
        return hits.prefix(Int(f["limit"] ?? "") ?? 50).map { json($0, full: false) }
    case "get":
        return json(try event(f), full: true)
    case "add":
        let e = EKEvent(eventStore: store)
        guard let cal = try f["calendar"].map(calendar(named:)) ?? store.defaultCalendarForNewEvents else {
            throw UsageError(message: "no default calendar, pass --calendar")
        }
        guard cal.allowsContentModifications else { throw UsageError(message: "calendar \"\(cal.title)\" is read-only") }
        e.calendar = cal
        e.title = try need(f, "title")
        _ = try need(f, "start")
        e.startDate = Date()
        e.endDate = Date()
        try apply(e, f)
        try store.save(e, span: .thisEvent, commit: true)
        return json(e, full: true)
    case "update":
        let e = try event(f)
        guard isEditable(e) else {
            throw UsageError(message: "event is read-only or organized by someone else; change it in Calendar or ask the organizer")
        }
        try apply(e, f)
        try store.save(e, span: .thisEvent, commit: true)
        return json(e, full: true)
    default:
        fail("unknown command \"\(cmd)\"", code: 2)
    }
}

let commands: Set = ["calendars", "events", "search", "get", "add", "update"]
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
