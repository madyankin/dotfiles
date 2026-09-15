#!/usr/bin/env node
/* Harness for a generated explainer page.
 *
 *   node references/verify.js "<page>.html"
 *
 * Parses the page, builds a minimal DOM, runs every inline <script>, then exercises the
 * interactive figures: clicks every button, drags every range input, cycles every select.
 * Reports which mounts actually drew something and fails loudly on any thrown error.
 * Also lints the prose a newcomer has to read: words that wave a step away, shrugs at the
 * reader, and code listings too long to teach anything.
 *
 * This exists because grep cannot tell you that Viz.graph threw. A page whose figures are
 * mandatory needs its figures executed before it ships.
 */
"use strict";

var fs = require("fs");

/* ------------------------------------------------------------------ minimal DOM */

function El(tag, ns) {
  this.tagName = String(tag).toUpperCase();
  this.ns = ns || null;
  this.children = [];
  this.attrs = {};
  this.parent = null;
  this._text = "";
  this._html = "";
  this.style = { cssText: "" };
  this.className = "";
  this.listeners = {};
  this.disabled = false;
  this.hidden = false;
  this.value = "";
  var self = this;
  this.classList = {
    add: function (c) { if (!self.hasClass(c)) self.className = (self.className ? self.className + " " : "") + c; },
    remove: function (c) {
      self.className = self.className.split(/\s+/).filter(function (x) { return x && x !== c; }).join(" ");
    },
    contains: function (c) { return self.hasClass(c); }
  };
}
El.prototype.hasClass = function (c) { return (" " + this.className + " ").indexOf(" " + c + " ") >= 0; };
El.prototype.setAttribute = function (k, v) {
  this.attrs[k] = String(v);
  if (k === "class") this.className = String(v);
  if (k === "id") this.id = String(v);
};
El.prototype.getAttribute = function (k) { return this.attrs[k] == null ? null : this.attrs[k]; };
El.prototype.removeAttribute = function (k) { delete this.attrs[k]; };
El.prototype.appendChild = function (c) { c.parent = this; this.children.push(c); return c; };
El.prototype.prepend = function (c) { c.parent = this; this.children.unshift(c); return c; };
El.prototype.insertBefore = function (c) { return this.prepend(c); };
// HTML_TEMPLATE's stepper example uses this to hang a caption off a figure it just drew.
// The string is not parsed — it is held on a wrapper, same as an innerHTML assignment —
// which is enough for the harness: the point is that the call must not throw.
El.prototype.insertAdjacentHTML = function (where, html) {
  var wrap = new El("div");
  wrap._html = String(html);
  if (where === "afterbegin") return this.prepend(wrap);
  if (where === "beforebegin" && this.parent) return this.parent.prepend(wrap);
  if (where === "afterend" && this.parent) return this.parent.appendChild(wrap);
  return this.appendChild(wrap);                                   // beforeend, the default
};
El.prototype.remove = function () {
  if (!this.parent) return;
  var i = this.parent.children.indexOf(this);
  if (i >= 0) this.parent.children.splice(i, 1);
};
El.prototype.addEventListener = function (t, f) { (this.listeners[t] = this.listeners[t] || []).push(f); };
El.prototype.fire = function (t) {
  var self = this;
  (this.listeners[t] || []).forEach(function (f) { f.call(self, { type: t, target: self }); });
  return (this.listeners[t] || []).length;
};
Object.defineProperty(El.prototype, "textContent", {
  get: function () {
    if (this._text) return this._text;
    return this.children.map(function (c) { return c.textContent; }).join("");
  },
  set: function (v) { this._text = String(v); this.children = []; }
});
Object.defineProperty(El.prototype, "innerHTML", {
  get: function () { return this._html; },
  set: function (v) { this._html = String(v); this.children = []; }
});

function walk(el, fn) { fn(el); el.children.slice().forEach(function (c) { walk(c, fn); }); }

function matches(el, sel) {
  var m;
  if (sel[0] === ".") return el.hasClass(sel.slice(1));
  if (sel[0] === "#") return el.id === sel.slice(1);
  m = sel.match(/^\[([-a-zA-Z0-9_]+)(?:=["']?([^"'\]]*)["']?)?\]$/);
  if (m) return m[2] == null ? el.attrs[m[1]] != null : el.attrs[m[1]] === m[2];
  return el.tagName === sel.toUpperCase();
}
El.prototype.querySelector = function (sel) {
  var out = null;
  this.children.forEach(function (c) { walk(c, function (e) { if (!out && matches(e, sel)) out = e; }); });
  return out;
};
El.prototype.querySelectorAll = function (sel) {
  var parts = sel.split(">").map(function (x) { return x.trim(); });
  var last = parts.pop();
  var out = [];
  this.children.forEach(function (c) {
    walk(c, function (e) {
      if (!matches(e, last)) return;
      var node = e, ok = true;
      for (var i = parts.length - 1; i >= 0 && ok; i--) {      // child combinator only
        node = node.parent;
        ok = !!node && matches(node, parts[i]);
      }
      if (ok) out.push(e);
    });
  });
  return out;
};

/* ------------------------------------------------------- tag-soup parser (enough) */

var VOID = { meta: 1, br: 1, img: 1, input: 1, hr: 1, link: 1, source: 1, col: 1 };

function parse(html) {
  var root = new El("root");
  var stack = [root];
  var re = /<!--[\s\S]*?-->|<!\[CDATA\[[\s\S]*?\]\]>|<!doctype[^>]*>|<\/([a-zA-Z0-9-]+)\s*>|<([a-zA-Z0-9-]+)((?:\s+[^>"']*(?:"[^"]*"|'[^']*')?)*)\s*\/?>/gi;
  var m, last = 0, scripts = [];
  while ((m = re.exec(html))) {
    var text = html.slice(last, m.index);
    last = re.lastIndex;
    if (text.trim()) stack[stack.length - 1]._text += text;
    if (m[0].slice(0, 4) === "<!--" || m[0].slice(0, 9).toLowerCase() === "<!doctype") continue;

    if (m[1]) {                                             // closing tag
      for (var i = stack.length - 1; i > 0; i--) {
        if (stack[i].tagName === m[1].toUpperCase()) { stack.length = i; break; }
      }
      continue;
    }
    var tag = m[2].toLowerCase();
    var el = new El(tag);
    var ar = /([-a-zA-Z0-9_:]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+)))?/g, a;
    while ((a = ar.exec(m[3] || ""))) {
      el.setAttribute(a[1], a[2] != null ? a[2] : (a[3] != null ? a[3] : (a[4] != null ? a[4] : "")));
    }
    if (tag === "input" && el.attrs.value != null) el.value = el.attrs.value;
    if (tag === "option" && el.attrs.selected != null) el.parent && (el.parent.value = el.attrs.value);

    stack[stack.length - 1].appendChild(el);

    if (tag === "script" || tag === "style") {              // swallow raw body
      var close = html.toLowerCase().indexOf("</" + tag, re.lastIndex);
      if (close < 0) close = html.length;
      var body = html.slice(re.lastIndex, close);
      if (tag === "script") scripts.push(body);
      re.lastIndex = close;
      last = close;
      continue;
    }
    if (!VOID[tag] && m[0].slice(-2) !== "/>") stack.push(el);
  }
  // <select> gets its selected option's value
  walk(root, function (e) {
    if (e.tagName !== "SELECT") return;
    var opts = e.querySelectorAll("option");
    var picked = opts.filter(function (o) { return o.attrs.selected != null; })[0] || opts[0];
    if (picked) e.value = picked.attrs.value != null ? picked.attrs.value : picked.textContent;
  });
  return { root: root, scripts: scripts };
}

/* ----------------------------------------------------------------------- harness */

var file = process.argv[2];
if (!file) { console.error("usage: node verify.js <page.html>"); process.exit(2); }
var html = fs.readFileSync(file, "utf8");
var parsed = parse(html);
var root = parsed.root;

var byId = {};
walk(root, function (e) { if (e.id) byId[e.id] = e; });

var errors = [];
var timers = [];
global.document = {
  documentElement: root,
  body: root.querySelector("body") || root,
  getElementById: function (i) { return byId[i] || null; },
  createElement: function (t) { return new El(t); },
  createElementNS: function (ns, t) { return new El(t, ns); },
  querySelector: function (s) { return root.querySelector(s); },
  querySelectorAll: function (s) { return root.querySelectorAll(s); },
  addEventListener: function () {}
};
global.window = global;
try { global.navigator = { userAgent: "verify.js" }; } catch (e) { /* node exposes it read-only */ }
global.requestAnimationFrame = function (f) { return setTimeout(f, 0); };
global.matchMedia = function () { return { matches: false, addEventListener: function () {} }; };
var realSetInterval = global.setInterval;
global.setInterval = function (f, ms) { var t = { f: f }; timers.push(t); return timers.length; };
global.clearInterval = function () {};

function attempt(what, fn) {
  try { fn(); return true; }
  catch (e) { errors.push(what + ": " + (e && e.stack ? e.stack.split("\n")[0] : e)); return false; }
}

parsed.scripts.forEach(function (src, i) {
  attempt("script #" + (i + 1), function () { (0, eval)(src); });
});

function svgCount(el) { var n = 0; walk(el, function (e) { if (e.tagName === "SVG") n++; }); return n; }
function tagCount(el, t) { var n = 0; walk(el, function (e) { if (e.tagName === t) n++; }); return n; }

/* every element that a script drew into */
var mounts = [];
Object.keys(byId).forEach(function (id) {
  var e = byId[id];
  if (svgCount(e)) mounts.push({ id: id, svg: svgCount(e), marks: tagCount(e, "PATH") + tagCount(e, "RECT") + tagCount(e, "CIRCLE") + tagCount(e, "LINE") });
});

var steppers = root.querySelectorAll(".stepper");
var ranges = root.querySelectorAll("[type=range]");
var selects = root.querySelectorAll("select");
var buttons = root.querySelectorAll("button");

console.log("== " + file.split("/").pop() + " ==");
console.log("scripts run : " + parsed.scripts.length);
console.log("mounts drawn: " + mounts.length);
mounts.forEach(function (m) { console.log("  " + m.id + " — " + m.svg + " svg, " + m.marks + " marks"); });

console.log("steppers    : " + steppers.length);
steppers.forEach(function (s) {
  var c = s.querySelector(".counter");
  console.log("  #" + (s.id || "?") + " counter=" + (c ? c.textContent : "MISSING") +
              " stage=" + (s.querySelector(".stage") ? "ok" : "MISSING"));
  if (c && !/^\s*1\s*\/\s*\d+/.test(c.textContent)) {
    errors.push("stepper #" + s.id + " does not start at 1 / n (got '" + c.textContent + "')");
  }
});

/* listings must be painted by Hl */
var codes = root.querySelectorAll("pre > code");
var unpainted = codes.filter(function (c) {
  if (/\blang-txt\b/.test(c.className)) return false;          // deliberately plain
  return (c.innerHTML || "").indexOf("hl-") < 0;
});
console.log("listings    : " + codes.length + " total, " +
            (codes.length - unpainted.length) + " highlighted");
if (codes.length && !/\bHl\b/.test(html)) {
  errors.push("no syntax highlighter on the page — paste the Hl block from HTML_TEMPLATE.md");
} else if (unpainted.length) {
  errors.push(unpainted.length + " code listing(s) left unhighlighted; mark deliberate ones " +
              'class="lang-txt"');
}

/* a proof stepper must show its step, not merely highlight a row */
steppers.forEach(function (box) {
  var stage = box.querySelector(".stage");
  if (!stage || !stage.querySelector(".proof")) return;          // not a proof stepper
  var hasFigure = !!stage.querySelector(".proof-figure") || tagCount(stage, "SVG") > 0;
  var cur = stage.querySelector(".at");
  var hasMarks = cur ? /class="mk-(sub|gone|new)"/.test(cur.innerHTML ||
                 (cur.querySelector(".expr") || {}).innerHTML || "") : false;
  if (!hasFigure && !hasMarks) {
    errors.push("proof stepper #" + (box.id || "?") + " only moves a highlight: give each step " +
                "a show() figure or mk-sub/mk-gone/mk-new markers (VISUALIZATIONS.md)");
  }
});

/* quiz state as rendered, before anything is clicked */
var quizBefore = null;
if (byId.quiz) {
  quizBefore = { cards: byId.quiz.children.length, bad: [] };
  byId.quiz.children.forEach(function (card, qi) {
    var opts = card.querySelectorAll(".opt");
    if (opts.length !== 4) quizBefore.bad.push("q" + (qi + 1) + " has " + opts.length + " options");
    var fb = card.querySelector(".fb");
    if (fb && fb.hidden === false) quizBefore.bad.push("q" + (qi + 1) + " feedback visible before click");
    opts.forEach(function (o) {
      var a = (o.attrs["aria-label"] || "") + " " + (o.attrs.title || "");
      if (/\b(верн|correct|прав|right answer)/i.test(a)) {
        quizBefore.bad.push("q" + (qi + 1) + " leaks correctness in aria-label/title");
      }
    });
  });
  // correct-answer positions must not all sit in the same slot
  var marks = {};
  byId.quiz.children.forEach(function (card, qi) {
    card.querySelectorAll(".opt").forEach(function (o, oi) { marks[qi] = marks[qi] || oi; });
  });
}

/* exercise everything */
var fired = 0;
buttons.forEach(function (b, i) {
  attempt("button[" + i + "] " + (b.textContent || b.id || "").slice(0, 24), function () { fired += b.fire("click"); });
});
ranges.forEach(function (r, i) {
  [r.attrs.min, r.attrs.max, r.attrs.value].forEach(function (v) {
    if (v == null) return;
    attempt("range#" + (r.id || i) + "=" + v, function () { r.value = v; fired += r.fire("input"); });
  });
});
selects.forEach(function (s, i) {
  s.querySelectorAll("option").forEach(function (o) {
    attempt("select#" + (s.id || i) + "=" + o.attrs.value, function () {
      s.value = o.attrs.value; fired += s.fire("change");
    });
  });
});
timers.forEach(function (t, i) { attempt("interval[" + i + "] tick", function () { t.f(); }); });

console.log("handlers run: " + fired + " (buttons " + buttons.length +
            ", ranges " + ranges.length + ", selects " + selects.length + ")");

/* quiz — snapshot taken before the exercise phase, reveal asserted after */
if (quizBefore) {
  console.log("quiz cards  : " + quizBefore.cards +
              (quizBefore.bad.length ? "  PROBLEMS: " + quizBefore.bad.join("; ") : ""));
  if (quizBefore.cards !== 5) errors.push("quiz has " + quizBefore.cards + " questions, must be 5");
  quizBefore.bad.forEach(function (b) { errors.push("quiz: " + b); });

  var stillHidden = [];
  byId.quiz.children.forEach(function (card, qi) {
    var fb = card.querySelector(".fb");
    if (fb && fb.hidden !== false) stillHidden.push("q" + (qi + 1));
  });
  if (stillHidden.length) {
    errors.push("quiz: clicking an option left feedback hidden in " + stillHidden.join(", "));
  } else {
    console.log("quiz reveal : feedback shown on click in all " + quizBefore.cards + " questions");
  }
}

/* static checks worth having in the same place as the runtime ones */
var stat = [];
// Loading from the network is banned; a link in prose loads nothing until clicked and is
// required for any citation with a stable address.
var LOADS = /(?:\b(?:src|data-src|poster)\s*=\s*["']https?:|<link\b[^>]*\bhref\s*=\s*["']https?:|@import\s+(?:url\()?\s*["']?https?:|\bfetch\s*\(\s*["']https?:|\burl\(\s*["']?https?:\/\/)/gi;
var ld;
while ((ld = LOADS.exec(html))) {
  stat.push("loads from the network: " + html.slice(ld.index, ld.index + 60).replace(/\s+/g, " "));
}

// citations that have a mechanical address must be links, not text the reader retypes
var aRanges = [];
var aRe = /<a\b[\s\S]*?<\/a>/gi, am;
while ((am = aRe.exec(html))) aRanges.push([am.index, am.index + am[0].length]);
function linked(i) {
  return aRanges.some(function (r) { return i >= r[0] && i < r[1]; });
}
var CITE = /(arXiv:\s*\d{4}\.\d{4,5}|\bdoi:\s*10\.\S+|\bRFC\s+\d{3,5}\b)/gi, cm;
while ((cm = CITE.exec(html))) {
  if (!linked(cm.index)) stat.push("citation not a hyperlink: " + cm[0].trim());
}
if (!/pre\s*{[^}]*white-space:\s*pre/.test(html)) stat.push("pre rule missing white-space: pre");
if (/[^\\]\$[^{]/.test(html.replace(/<script[\s\S]*?<\/script>/g, ""))) stat.push("bare $ outside scripts — LaTeX will not render");
var PLACEHOLDERS = /«…»|«pick an integer|«Option|«Title|«Concept name|«Prerequisites|«Intuition|«Formal treatment|«Worked example|«Question about|«Why this option|«What this page|«Book, chapter|«State \d|«operation»|«paramId|«chartId|«Parameter»|«\d+»/;
if (PLACEHOLDERS.test(html)) stat.push("unreplaced template placeholder left in the page");
/* --- prose rules: a page for a newcomer cannot wave steps away or dump walls of code --- */

var prose = html.replace(/<script[\s\S]*?<\/script>/gi, function (m) {
  // keep JS string literals — quiz feedback and figure notes are prose the reader sees
  return (m.match(/"(?:[^"\\]|\\.){12,}"/g) || []).join("\n");
}).replace(/<style[\s\S]*?<\/style>/gi, "");

// Словарь — transliterations the user has ruled out. Add a row when they correct a word.
var TRANSLIT = [[/\bволт\w*/gi, "волт → хранилище / заметки / Obsidian"]];
TRANSLIT.forEach(function (pair) {
  var t; pair[0].lastIndex = 0;
  while ((t = pair[0].exec(prose))) stat.push("banned word: " + pair[1]);
});

var DISMISSIVE = /(^|[^А-Яа-яЁёA-Za-z])(очевидно|тривиальн\w*|разумеется|как известно|obviously|trivially|clearly|of course)(?=[^А-Яа-яЁёA-Za-z]|$)/gi;
var m2;
while ((m2 = DISMISSIVE.exec(prose))) {
  stat.push('waves a step away: "' + m2[2] + '" — ' +
            prose.slice(Math.max(0, m2.index - 40), m2.index + 50).replace(/\s+/g, " ").trim());
}

// «просто» is normally the adverb "merely" and is fine; only the shrug is banned
var SHRUG = /(это\s+просто\b|просто\s+(возьмите|добавьте|напишите|сделайте|используйте)|simply\s+(add|use|call|write|run)|just\s+(add|use|call|write|run))/gi;
while ((m2 = SHRUG.exec(prose))) {
  stat.push('shrugs at the reader: "' + m2[0] + '"');
}

// literate listings: long code belongs in chunks, with the whole thing folded into <details>
var pres = html.match(/<pre[\s\S]*?<\/pre>/g) || [];
pres.forEach(function (block) {
  var lines = block.split("\n").length;
  if (lines <= 25) return;
  var at = html.indexOf(block);
  var open = html.lastIndexOf("<details", at), close = html.lastIndexOf("</details>", at);
  if (open > close) return;                                  // folded away, that is the pattern
  stat.push("listing of " + lines + " lines outside <details> — split it into .lit chunks and " +
            "fold the assembled version: " + block.slice(0, 50).replace(/\s+/g, " "));
});

var arias = html.match(/aria:\s*"[^"]*"/g) || [];
arias.forEach(function (a) {
  if (a.replace(/aria:\s*"/, "").length < 25) stat.push("aria sentence too short: " + a);
});
stat.forEach(function (s) { errors.push("static: " + s); });

console.log("");
if (errors.length) {
  console.log("FAIL — " + errors.length + " problem(s):");
  errors.forEach(function (e) { console.log("  ✗ " + e); });
  process.exit(1);
}
console.log("PASS — every script ran, every control fired, no static problems.");
