import "scripts/fzf.js" as Fzf
import "scripts/fuzzysort.js" as Fuzzy
import QtQuick
import Quickshell

Singleton {
    required property list<QtObject> list
    property string key: "name"
    property bool useFuzzy: false
    property bool useSloppy: false
    property real sloppyThreshold: 0.2
    property var extraOpts: ({})

    // Extra stuff for fuzzy
    property list<string> keys: [key]
    property list<real> weights: [1]

    readonly property var fzf: useFuzzy || useSloppy ? [] : new Fzf.Finder(list, Object.assign({
        selector
    }, extraOpts))
    readonly property list<var> fuzzyPrepped: useFuzzy ? list.map(e => {
        const obj = {
            _item: e
        };
        for (const k of keys)
            obj[k] = Fuzzy.prepare(e[k]);
        return obj;
    }) : []

    function transformSearch(search: string): string {
        return search;
    }

    function selector(item: var): string {
        // Only for fzf
        return item[key];
    }

    function levenshtein(first: string, second: string): int {
        if (first === second)
            return 0;
        if (!first.length)
            return second.length;
        if (!second.length)
            return first.length;

        let previous = Array.from({
            length: second.length + 1
        }, (_, index) => index);
        for (let row = 1; row <= first.length; row++) {
            const current = [row];
            for (let column = 1; column <= second.length; column++) {
                const substitution = previous[column - 1] + (first[row - 1] === second[column - 1] ? 0 : 1);
                current[column] = Math.min(previous[column] + 1, current[column - 1] + 1, substitution);
            }
            previous = current;
        }
        return previous[second.length];
    }

    function sloppyScore(candidate: string, search: string): real {
        candidate = candidate.toLowerCase();
        search = search.toLowerCase();
        if (candidate === search)
            return 1;
        if (!candidate || !search)
            return 0;

        const full = 1 - root.levenshtein(candidate, search) / Math.max(candidate.length, search.length);
        let partial = 0;
        if (candidate.length >= search.length) {
            for (let index = 0; index <= candidate.length - search.length; index++)
                partial = Math.max(partial, 1 - root.levenshtein(search, candidate.slice(index, index + search.length)) / search.length);
        } else {
            partial = 1 - root.levenshtein(candidate, search.slice(0, candidate.length)) / candidate.length;
        }

        const prefixBonus = candidate.startsWith(search) ? 0.08 : 0;
        const containsBonus = candidate.includes(search) ? 0.08 : 0;
        return Math.max(0, Math.min(1, full * 0.7 + partial * 0.3 + prefixBonus + containsBonus));
    }

    function sloppyItemScore(item: var, search: string): real {
        let score = 0;
        for (let index = 0; index < keys.length; index++) {
            const raw = item[keys[index]];
            const text = Array.isArray(raw) ? raw.join(" ") : String(raw ?? "");
            score += root.sloppyScore(text, search) * (weights[index] ?? 1);
        }
        return score;
    }

    function query(search: string): var {
        search = transformSearch(search.trim().replace(/\s+/g, " "));
        if (!search)
            return [...list];

        if (useSloppy)
            return list.map(item => ({
                item,
                score: root.sloppyItemScore(item, search)
            })).filter(result => result.score > sloppyThreshold).sort((first, second) => second.score - first.score).map(result => result.item);

        if (useFuzzy)
            return Fuzzy.go(search, fuzzyPrepped, Object.assign({
                all: true,
                keys,
                scoreFn: r => weights.reduce((a, w, i) => a + r[i].score * w, 0)
            }, extraOpts)).map(r => r.obj._item);

        return fzf.find(search).sort((a, b) => {
            if (a.score === b.score)
                return selector(a.item).trim().length - selector(b.item).trim().length;
            return b.score - a.score;
        }).map(r => r.item);
    }
}
