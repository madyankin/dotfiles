// Apple Mail CLI over JXA. Run through the `mail` wrapper next to this file.
// Read everything; write only mark / move / draft. No send, no delete, no move to Trash or Junk.
//
// A message ref is "account|mailbox/path|id". Mailbox ids are not stable, names are,
// and a message id is unique only inside its mailbox.

ObjC.import("Foundation");
ObjC.import("stdlib");

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

function mailboxPath(box) {
  const parts = [box.name()];
  let c = box.container;
  while (true) {
    let name = null;
    try { name = c.name(); } catch (e) { break; }
    if (!name) break;
    parts.unshift(name);
    c = c.container;
  }
  return parts.join("/");
}

function refOf(msg) {
  const box = msg.mailbox();
  return [box.account().name(), mailboxPath(box), msg.id()].join("|");
}

function findMailbox(M, account, path) {
  const acc = M.accounts.byName(account);
  try { acc.name(); } catch (e) { throw new UsageError(`account "${account}" not found`); }
  const box = acc.mailboxes.byName(path);
  try { box.name(); } catch (e) { throw new UsageError(`mailbox "${path}" not found in "${account}"`); }
  return box;
}

function findMessage(M, ref) {
  const parts = ref.split("|");
  if (parts.length < 3) throw new UsageError(`bad ref "${ref}"`);
  const id = +parts.pop();
  const account = parts.shift();
  const msg = findMailbox(M, account, parts.join("|")).messages.byId(id);
  try { msg.id(); } catch (e) { throw new UsageError(`message ${ref} not found (moved or deleted?)`); }
  return msg;
}

function scope(M, a) {
  if (a.account && a.mailbox) return [findMailbox(M, a.account, a.mailbox)];
  if (a.account) {
    const blocked = specialPaths(M, a.account, ["trashMailbox", "junkMailbox"]);
    return M.accounts.byName(a.account).mailboxes().filter((b) => !blocked.has(mailboxPath(b)));
  }
  if (a.mailbox) throw new UsageError("--mailbox needs --account");
  return [M.inbox];
}

// Paths of an account's special mailboxes (Trash, Junk, ...), from Mail's own
// unified mailboxes, so this works for every language and provider.
function specialPaths(M, account, kinds) {
  const out = new Set();
  for (const kind of kinds) {
    for (const b of M[kind].mailboxes()) {
      try { if (b.account().name() === account) out.add(mailboxPath(b)); } catch (e) { /* skip */ }
    }
  }
  return out;
}

function summaries(spec, limit) {
  const n = spec.length;
  if (n === 0) return [];
  const dates = spec.dateReceived();
  const order = dates.map((d, i) => i).sort((x, y) => dates[y] - dates[x]).slice(0, limit);
  const subj = spec.subject(), from = spec.sender(), read = spec.readStatus(), flag = spec.flaggedStatus();
  return order.map((i) => ({
    ref: refOf(spec[i]),
    date: dates[i].toISOString(),
    from: from[i],
    subject: subj[i],
    read: read[i],
    flagged: flag[i],
  }));
}

function query(M, a, extra) {
  const conds = extra.slice();
  if (a.unread) conds.push({ readStatus: false });
  if (a.since) conds.push({ dateReceived: { _greaterThan: parseDate(a.since) } });
  const limit = +(a.limit || 20);
  let out = [];
  for (const box of scope(M, a)) {
    const spec = conds.length === 0 ? box.messages : box.messages.whose(conds.length === 1 ? conds[0] : { _and: conds });
    out = out.concat(summaries(spec, limit));
  }
  return out.sort((x, y) => (x.date < y.date ? 1 : -1)).slice(0, limit);
}

function addresses(list) {
  return list.map((r) => r.address());
}

function makeDraft(M, a) {
  const msg = M.OutgoingMessage({ subject: need(a, "subject"), content: need(a, "body"), visible: false });
  M.outgoingMessages.push(msg);
  if (a.from) msg.sender = a.from;
  for (const addr of need(a, "to").split(",")) msg.toRecipients.push(M.ToRecipient({ address: addr.trim() }));
  if (a.cc) for (const addr of a.cc.split(",")) msg.ccRecipients.push(M.CcRecipient({ address: addr.trim() }));
  msg.save();
  return msg;
}

const COMMANDS = {
  accounts(M) {
    return M.accounts().map((x) => ({ name: x.name(), type: x.accountType(), enabled: x.enabled(), addresses: x.emailAddresses() }));
  },
  mailboxes(M, a) {
    const accs = a.account ? [M.accounts.byName(a.account)] : M.accounts.whose({ enabled: true })();
    return accs.map((x) => ({
      account: x.name(),
      mailboxes: x.mailboxes().map((b) => ({ path: mailboxPath(b), unread: b.unreadCount() })),
    }));
  },
  list(M, a) {
    return query(M, a, []);
  },
  search(M, a) {
    const q = need(a, "query");
    const field = a.field || "any";
    const byField = { subject: { subject: { _contains: q } }, sender: { sender: { _contains: q } } };
    const match = field === "any" ? { _or: [byField.subject, byField.sender] } : byField[field];
    if (!match) throw new UsageError("--field must be subject, sender or any");
    const since = new Date(Date.now() - (+(a.days || 30)) * 864e5);
    return query(M, Object.assign({}, a, { since: undefined }), [match, { dateReceived: { _greaterThan: since } }]);
  },
  read(M, a) {
    const msg = findMessage(M, need(a, "ref"));
    const max = +(a["max-chars"] || 20000);
    const body = msg.content() || "";
    return {
      ref: a.ref,
      date: msg.dateReceived().toISOString(),
      from: msg.sender(),
      to: addresses(msg.toRecipients()),
      cc: addresses(msg.ccRecipients()),
      subject: msg.subject(),
      messageId: msg.messageId(),
      read: msg.readStatus(),
      flagged: msg.flaggedStatus(),
      attachments: msg.mailAttachments.name(),
      body: body.slice(0, max),
      truncated: body.length > max,
    };
  },
  mark(M, a) {
    const msg = findMessage(M, need(a, "ref"));
    if (a.read) msg.readStatus = true;
    if (a.unread) msg.readStatus = false;
    if (a.flag) msg.flaggedStatus = true;
    if (a.unflag) msg.flaggedStatus = false;
    return { ref: a.ref, read: msg.readStatus(), flagged: msg.flaggedStatus() };
  },
  move(M, a) {
    const msg = findMessage(M, need(a, "ref"));
    const account = a.ref.split("|")[0];
    const to = need(a, "to");
    if (specialPaths(M, account, ["trashMailbox", "junkMailbox"]).has(to)) {
      throw new UsageError(`moving to "${to}" is a delete; do it in Mail yourself`);
    }
    const target = findMailbox(M, account, to);
    M.move(msg, { to: target });
    return { moved: a.ref, to: `${account}|${to}` };
  },
  draft(M, a) {
    const msg = makeDraft(M, a);
    return { saved: "Drafts", subject: msg.subject(), to: addresses(msg.toRecipients()) };
  },
  "reply-draft"(M, a) {
    const orig = findMessage(M, need(a, "ref"));
    const msg = M.reply(orig, { openingWindow: false, replyToAll: !!a.all });
    msg.content = need(a, "body") + "\n\n" + (msg.content() || "");
    msg.save();
    return { saved: "Drafts", subject: msg.subject(), to: addresses(msg.toRecipients()) };
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
    return JSON.stringify(COMMANDS[cmd](Application("Mail"), a), null, 1);
  } catch (e) {
    const msg = String(e.message || e);
    const hint = /not allowed|-1743/.test(msg)
      ? "allow this app to control Mail: System Settings > Privacy & Security > Automation"
      : undefined;
    stderr(JSON.stringify({ error: msg, hint }));
    $.exit(1);
  }
}
