.pragma library

// Pure helpers for styled text (spec 008, research R7): the typed text (ds/base/TypedText) and
// NotifyText (services) share them. A styled text holds only <b>, <i>, <u>, <br> and entities
// (NotifyText.sanitize); a "visible" character is what the reader sees (an entity or a <br> = one).

const named = { amp: "&", lt: "<", gt: ">", quot: "\"", apos: "'", nbsp: " " };

function decode(text) {
    return String(text ?? "").replace(/&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);/g, (m, e) => {
        if (e[0] === "#") {
            const code = e[1] === "x" || e[1] === "X" ? parseInt(e.slice(2), 16) : parseInt(e.slice(1), 10);
            return code > 0 && code < 0x110000 ? String.fromCodePoint(code) : "";
        }
        return named[e.toLowerCase()] ?? m;
    });
}

// Styled text without tags, entities decoded.
function plain(markup) {
    return decode(String(markup ?? "").replace(/<br\s*\/?>/gi, "\n").replace(/<[^<>]*>/g, ""));
}

// { text, count }: the first n visible characters (all with n < 0), the open tags closed.
function walk(styled, n) {
    const s = String(styled ?? "");
    let out = "";
    let count = 0;
    const open = [];
    let i = 0;
    while (i < s.length && (n < 0 || count < n)) {
        const c = s[i];
        if (c === "<") {
            const end = s.indexOf(">", i);
            if (end < 0)
                break;
            const tag = s.slice(i, end + 1);
            i = end + 1;
            if (tag === "<br>") {
                out += tag;
                count++;
            } else if (tag[1] === "/") {
                open.pop();
                out += tag;
            } else {
                open.push(tag.slice(1, -1));
                out += tag;
            }
            continue;
        }
        if (c === "&") {
            const end = s.indexOf(";", i);
            const ent = end > i ? s.slice(i, end + 1) : c;
            out += ent;
            i += ent.length;
            count++;
            continue;
        }
        const ch = String.fromCodePoint(s.codePointAt(i));
        out += ch;
        i += ch.length;
        count++;
    }
    for (let k = open.length - 1; k >= 0; k--)
        out += "</" + open[k] + ">";
    return { text: out, count: count };
}

function cut(styled, n) {
    return walk(styled, n).text;
}

function visibleLength(styled) {
    return walk(styled, -1).count;
}
