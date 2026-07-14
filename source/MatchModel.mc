using Toybox.Application as App;
using Toybox.Lang as Lang;
using Toybox.Time as Time;

// Holds all state for one scoring session.
// Every point and manual set-end is pushed onto an event stack,
// so undo() can fully reverse any action, including reopening a
// set that was ended automatically or manually.
class Match {

    var numSets;
    var target;
    var winBy2;

    var sets;       // array of [a, b] score pairs, one per set
    var cur = 0;    // index of the set in progress
    var done = false;

    var events;     // stack: {"t"=>"p","team"=>0/1,"auto"=>bool} or {"t"=>"e"}

    function initialize(n, t, w) {
        numSets = n;
        target = t;
        winBy2 = w;
        sets = [[0, 0]];
        events = [];
    }

    function addPoint(team) {
        if (done) {
            return;
        }
        var s = sets[cur];
        s[team] = s[team] + 1;
        var auto = isSetComplete(s);
        events = events.add({"t" => "p", "team" => team, "auto" => auto});
        if (auto) {
            advance();
        }
    }

    function isSetComplete(s) {
        var hi = s[0] > s[1] ? s[0] : s[1];
        var lead = s[0] - s[1];
        if (lead < 0) {
            lead = -lead;
        }
        if (winBy2) {
            return hi >= target && lead >= 2;
        }
        return hi >= target;
    }

    // Manual set end (long-press BACK). Any score is allowed.
    function endSetManual() {
        if (done) {
            return;
        }
        events = events.add({"t" => "e"});
        advance();
    }

    function advance() {
        if (cur + 1 >= numSets) {
            done = true;
        } else {
            cur = cur + 1;
            sets = sets.add([0, 0]);
        }
    }

    // Reverses the last event. Returns true if something was undone.
    function undo() {
        if (events.size() == 0) {
            return false;
        }
        var e = events[events.size() - 1];
        events = popLast(events);

        var reopens = e["t"].equals("e") || e["auto"] == true;
        if (reopens) {
            if (done) {
                done = false;
            } else {
                sets = popLast(sets);
                cur = cur - 1;
            }
        }
        if (e["t"].equals("p")) {
            var s = sets[cur];
            s[e["team"]] = s[e["team"]] - 1;
        }
        return true;
    }

    function popLast(arr) {
        var n = arr.size() - 1;
        var out = new [n];
        for (var i = 0; i < n; i++) {
            out[i] = arr[i];
        }
        return out;
    }

    // Number of completed sets won by team (0 or 1).
    function setsWon(team) {
        var other = 1 - team;
        var count = 0;
        var completed = done ? sets.size() : cur;
        for (var i = 0; i < completed; i++) {
            if (sets[i][team] > sets[i][other]) {
                count = count + 1;
            }
        }
        return count;
    }

    // Persist the finished session to watch storage (newest first, max 20).
    function saveToHistory() {
        var stored = App.Storage.getValue("history");
        var history = [];
        if (stored instanceof Lang.Array) {
            history = stored as Lang.Array;
        }
        var entry = {
            "ts" => Time.now().value(),
            "scores" => sets,
            "target" => target
        };
        var capped = [entry];
        var max = history.size() < 19 ? history.size() : 19;
        for (var i = 0; i < max; i++) {
            capped = capped.add(history[i]);
        }
        App.Storage.setValue("history", capped);
    }
}
