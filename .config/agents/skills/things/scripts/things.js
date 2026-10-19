// Things 3 CLI over JXA. Run through the `things` wrapper next to this file.
// Read everything; write only add / update / complete / reopen. No delete.

ObjC.import("Foundation");
ObjC.import("stdlib");

// Built-in lists by id: the names are localized, the ids are not.
const LISTS = {
  inbox: "TMInboxListSource",
  today: "TMTodayListSource",
  upcoming: "TMCalendarListSource",
  anytime: "TMNextListSource",
  someday: "TMSomedayListSource",
  logbook: "TMLogbookListSource",
};

class UsageError extends Error {}

function parseArgs(argv) {
  const out = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith("--")) { out._.push(a); continue; }
    const key = a.slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith("--")) out[key] = true;
    else { out[key] = next; i++; }
  }
  return out;
}

function need(args, key) {
  if (args[key] === undefined || args[key] === true) throw new UsageError(`--${key} is required`);
  return args[key];
}

function parseDate(s) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s);
  if (!m) throw new UsageError(`bad date "${s}", want YYYY-MM-DD`);
  return new Date(+m[1], +m[2] - 1, +m[3]);
}

function ymd(d) {
  if (!d) return null;
  const p = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

function iso(d) {
  return d ? d.toISOString() : null;
}

function ref(spec) {
  if (!spec) return null;
  try { return { id: spec.id(), name: spec.name() }; } catch (e) { return null; }
}

function todo(t, full) {
  const p = t.properties();
  const notes = p.notes || "";
  return {
    id: p.id,
    title: p.name,
    status: p.status,
    when: ymd(p.activationDate),
    deadline: ymd(p.dueDate),
    project: ref(p.project),
    area: ref(p.area),
    tags: p.tagNames ? p.tagNames.split(", ") : [],
    notes: full ? notes : notes.slice(0, 300),
    created: iso(p.creationDate),
    completed: iso(p.completionDate),
  };
}

function firstN(elements, limit) {
  const n = Math.min(elements.length, limit);
  const out = [];
  for (let i = 0; i < n; i++) out.push(todo(elements[i], false));
  return out;
}

function findBy(collection, value, kind) {
  try {
    const byId = collection.byId(value);
    byId.id();
    return byId;
  } catch (e) { /* not an id, try name */ }
  const hits = collection.whose({ name: value });
  if (hits.length === 0) throw new UsageError(`${kind} "${value}" not found`);
  if (hits.length > 1) throw new UsageError(`${kind} name "${value}" is ambiguous, pass its id`);
  return hits[0];
}

function getTodo(T, id) {
  const t = T.toDos.byId(id);
  try { t.id(); } catch (e) { throw new UsageError(`to-do "${id}" not found`); }
  return t;
}

// JXA's move fails with "Can't convert types" for Things; plain AppleScript works.
function moveToList(todoId, listId) {
  if (!/^[A-Za-z0-9-]+$/.test(todoId)) throw new UsageError(`bad to-do id "${todoId}"`);
  const src = `tell application "Things3" to move to do id "${todoId}" to list id "${listId}"`;
  const err = Ref();
  const res = $.NSAppleScript.alloc.initWithSource(src).executeAndReturnError(err);
  if (res.isNil()) throw new Error(`move failed: ${JSON.stringify(ObjC.deepUnwrap(err[0]))}`);
}

function applyFields(T, t, args) {
  if (args.title !== undefined) t.name = args.title;
  if (args.notes !== undefined) t.notes = args.notes;
  if (args.deadline === "none") t.dueDate.delete();  // assigning null fails, undefined writes 1904-01-01
  else if (args.deadline !== undefined) t.dueDate = parseDate(args.deadline);
  if (args.tags !== undefined) t.tagNames = args.tags === "none" ? "" : args.tags.split(",").map((s) => s.trim()).join(", ");
  if (args.project !== undefined) t.project = findBy(T.projects, args.project, "project");
  if (args.area !== undefined) t.area = findBy(T.areas, args.area, "area");
  if (args.when !== undefined) {
    const w = args.when;
    if (w === "anytime" || w === "someday") moveToList(t.id(), LISTS[w]);
    else {
      let d;
      if (w === "today") d = new Date();
      else if (w === "tomorrow") { d = new Date(); d.setDate(d.getDate() + 1); }
      else d = parseDate(w);
      T.schedule(t, { for: d });
    }
  }
}

const COMMANDS = {
  show(T, a) {
    const key = a.list || "today";
    if (!LISTS[key]) throw new UsageError(`--list must be one of ${Object.keys(LISTS).join(", ")}`);
    return firstN(T.lists.byId(LISTS[key]).toDos, +(a.limit || 50));
  },
  projects(T) {
    return T.projects().filter((p) => p.status() === "open").map((p) => ({
      id: p.id(), title: p.name(), area: ref(p.area()), deadline: ymd(p.dueDate()), when: ymd(p.activationDate()),
    }));
  },
  areas(T) {
    return T.areas().map((x) => ({ id: x.id(), title: x.name() }));
  },
  tags(T) {
    return T.tags.name();
  },
  "project-todos"(T, a) {
    return firstN(findBy(T.projects, need(a, "project"), "project").toDos, +(a.limit || 100));
  },
  search(T, a) {
    const q = need(a, "query");
    const limit = +(a.limit || 30);
    const match = { _or: [{ name: { _contains: q } }, { notes: { _contains: q } }] };
    const open = firstN(T.toDos.whose(match), limit).filter((x) => x.status === "open");
    // The app-wide to-do collection leaves out the Logbook.
    const done = a["include-done"] ? firstN(T.lists.byId(LISTS.logbook).toDos.whose(match), limit) : [];
    return open.concat(done).slice(0, limit);
  },
  get(T, a) {
    return todo(getTodo(T, need(a, "id")), true);
  },
  add(T, a) {
    const t = T.ToDo({ name: need(a, "title") });
    T.toDos.push(t);
    const created = T.toDos.byId(t.id());
    applyFields(T, created, Object.assign({}, a, { title: undefined }));
    return todo(created, true);
  },
  update(T, a) {
    const t = getTodo(T, need(a, "id"));
    applyFields(T, t, a);
    return todo(t, true);
  },
  complete(T, a) {
    const t = getTodo(T, need(a, "id"));
    t.status = "completed";
    return todo(t, false);
  },
  reopen(T, a) {
    const t = getTodo(T, need(a, "id"));
    t.status = "open";
    return todo(t, false);
  },
};

function stderr(s) {
  $.NSFileHandle.fileHandleWithStandardError.writeData($(s + "\n").dataUsingEncoding($.NSUTF8StringEncoding));
}

function run(argv) {
  const a = parseArgs(argv);
  const cmd = a._[0];
  if (!COMMANDS[cmd]) {
    stderr(JSON.stringify({ error: `unknown command "${cmd || ""}"`, commands: Object.keys(COMMANDS) }));
    $.exit(2);
  }
  try {
    return JSON.stringify(COMMANDS[cmd](Application("Things3"), a), null, 1);
  } catch (e) {
    const msg = String(e.message || e);
    const hint = /not allowed|-1743/.test(msg)
      ? "allow this app to control Things3: System Settings > Privacy & Security > Automation"
      : undefined;
    stderr(JSON.stringify({ error: msg, hint }));
    $.exit(1);
  }
}
