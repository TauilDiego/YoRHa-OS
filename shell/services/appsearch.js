.pragma library

// App search of the pause menu's APPS (spec 007, FR-010, research R5). Pure functions, no QML:
// the same order for the test catalog and for the real apps.
// An app here is { name, genericName, keywords: [string], command: [string], uses }.

// Lower case, without diacritics: "Café" -> "cafe", "FIRE" -> "fire".
function normalize(s) {
    return String(s === undefined || s === null ? "" : s)
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "")
        .toLowerCase();
}

// The words of a normalized name: split on spaces and punctuation.
function words(s) {
    return s.split(/[\s\-_.,;:\/\\()\[\]+&'"!?]+/).filter(function (w) { return w.length > 0; });
}

// How well `app` matches the query `q` (FR-010), best first:
//   0 the name starts with it; 1 a word of the name starts with it; 2 the name contains it;
//   3 the generic name or a keyword contains it; 4 the command contains it; -1 no match.
function tier(app, q) {
    var query = normalize(q).trim();
    if (query === "" || !app)
        return -1;
    var name = normalize(app.name);
    if (name.indexOf(query) === 0)
        return 0;
    var ws = words(name);
    for (var i = 0; i < ws.length; i++) {
        if (ws[i].indexOf(query) === 0)
            return 1;
    }
    if (name.indexOf(query) >= 0)
        return 2;
    if (normalize(app.genericName).indexOf(query) >= 0)
        return 3;
    var kws = app.keywords || [];
    for (var k = 0; k < kws.length; k++) {
        if (normalize(kws[k]).indexOf(query) >= 0)
            return 3;
    }
    if (normalize((app.command || []).join(" ")).indexOf(query) >= 0)
        return 4;
    return -1;
}

// The apps that match `q`, in order: tier, then more uses, then the name A-Z. An empty query
// matches nothing.
function rank(apps, q) {
    var scored = [];
    var list = apps || [];
    for (var i = 0; i < list.length; i++) {
        var t = tier(list[i], q);
        if (t >= 0)
            scored.push({ app: list[i], tier: t, uses: Number(list[i].uses) || 0, key: normalize(list[i].name) });
    }
    scored.sort(function (a, b) {
        if (a.tier !== b.tier)
            return a.tier - b.tier;
        if (a.uses !== b.uses)
            return b.uses - a.uses;
        return a.key < b.key ? -1 : a.key > b.key ? 1 : 0;
    });
    return scored.map(function (x) { return x.app; });
}
