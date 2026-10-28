pragma Singleton

import QtQuick
import Quickshell
import "../ds"
import "../ds/TextCut.js" as TextCut

// Pure text functions for notifications (spec 008, research R7, FR-006, FR-007, FR-036). Nothing a
// notification sends is ever interpreted beyond <b>, <i> and <u>: everything else is escaped or
// dropped, links become their text, and the result is drawn with Text.StyledText. "Visible"
// characters are what the reader sees: an entity or a line break counts as one.
Singleton {
    id: root

    readonly property var kept: ["b", "i", "u"]

    function escape(text: string): string {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
    }

    // The app's body → safe styled text: only well-formed <b>, <i>, <u> survive; line breaks become <br>.
    function sanitize(markup: var): string {
        const src = String(markup ?? "");
        const tagRe = /<\/?([A-Za-z][A-Za-z0-9]*)\b[^<>]*>/g;
        let out = "";
        let last = 0;
        const open = [];
        const text = t => root.escape(root.decode(t)).replace(/\r\n|\r|\n/g, "<br>");
        let m;
        while ((m = tagRe.exec(src)) !== null) {
            out += text(src.slice(last, m.index));
            last = tagRe.lastIndex;
            const name = m[1].toLowerCase();
            const closing = m[0][1] === "/";
            if (name === "br") {
                out += "<br>";
                continue;
            }
            if (!kept.includes(name) || !/^<\/?[A-Za-z]+\s*>$/.test(m[0]))
                continue;                            // anything else, or a kept tag with attributes: dropped
            if (!closing) {
                open.push(name);
                out += `<${name}>`;
            } else if (open.length > 0 && open[open.length - 1] === name) {
                open.pop();
                out += `</${name}>`;
            }
        }
        out += text(src.slice(last));
        while (open.length > 0)
            out += `</${open.pop()}>`;
        return out;
    }

    // Styled text without tags, entities decoded (lengths, the dump, the saved log's titles).
    function plain(markup: var): string {
        return TextCut.plain(markup);
    }
    function decode(text: var): string {
        return TextCut.decode(text);
    }
    // How many visible characters a styled text has.
    function visibleLength(styled: var): int {
        return TextCut.visibleLength(styled);
    }
    // The first `n` visible characters of a styled text, closing the tags left open (R7), so bold text
    // doesn't jump at the end of the typing.
    function cut(styled: var, n: int): string {
        return TextCut.cut(styled, n);
    }

    // Index of the first visible character where two styled texts differ (a replacement types
    // from there, FR-006); the length of the shorter when one starts the other.
    function firstDiff(a: var, b: var): int {
        const x = Array.from(plain(a)), y = Array.from(plain(b));
        const n = Math.min(x.length, y.length);
        for (let i = 0; i < n; i++)
            if (x[i] !== y[i])
                return i;
        return n;
    }

    // How long a transmission stays after it is typed out (FR-007), in ms; null = until dismissed.
    // The app's own time wins; otherwise low 4 s, normal 6 s + 1 s per 80 characters beyond 120
    // (12 s at most), both times `factor` (the Duration option).
    function duration(entry: var, factor: real): var {
        const N = Tokens.notify;
        if (!entry)
            return null;
        if (entry.urgency === "critical")
            return null;
        if (Number(entry.timeout) > 0)
            return Math.round(Number(entry.timeout));
        const f = factor > 0 ? factor : 1;
        if (entry.urgency === "low")
            return Math.round(N.lowMs * f);
        const len = Array.from(plain(entry.body)).length;
        const extra = Math.ceil(Math.max(0, len - N.freeChars) / N.perChars) * N.perCharsMs;
        return Math.round(Math.min(N.maxMs, N.normalMs + extra) * f);
    }
}
