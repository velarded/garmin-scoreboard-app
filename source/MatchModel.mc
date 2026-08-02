using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Lang as Lang;

// Players cycle through six rotation positions, 1..6.
const ROTATION_POSITIONS = 6;

// Reads the persisted setup configuration, falling back to defaults.
// Shared by SetupView (to edit) and LandingView (to start a session).
function loadMatchSettings() {
    var out = {"sets" => 3, "target" => 25, "winby2" => true};
    var stored = App.Storage.getValue("settings");
    if (stored instanceof Lang.Dictionary) {
        var d = stored as Lang.Dictionary;
        if (d.get("sets") != null) {
            out["sets"] = d.get("sets");
        }
        if (d.get("target") != null) {
            out["target"] = d.get("target");
        }
        if (d.get("winby2") != null) {
            out["winby2"] = d.get("winby2");
        }
    }
    return out;
}

function newMatchFromSettings() {
    var s = loadMatchSettings();
    return new Match(s["sets"], s["target"], s["winby2"]);
}

// Holds all state for one scoring session.
// Every point and manual set-end is pushed onto an event stack, so undo()
// can fully reverse any action, including reopening a set that was ended
// automatically or manually, and restoring serve/rotation state.
class Match {

    var numSets;
    var target;
    var winBy2;

    // False until the session is actually being recorded. The scoreboards
    // are browsable before this, but scoring and undo are inert.
    var started = false;

    var sets;       // array of [home, away] score pairs, one per set
    var cur = 0;    // index of the set in progress
    var done = false;

    // Sys.getTimer() value when each set began, parallel to `sets` (same
    // push/pop lifecycle), used to compute each point's elapsed-in-set time.
    var setStartTimes;

    // Serve + rotation, reset at the start of every set.
    var serveTeam = null;        // null until the first point of the set
    var positions;               // [homePos, awayPos], each 1..6
    var firstSideOutDone = false;

    // stack of {"t"=>"p","team"=>0/1,"auto"=>bool,"elapsedMs"=>n,"prev"=>{...}}
    // or {"t"=>"e","prev"=>{...}}. "prev" snapshots the serve/rotation state
    // as it was *before* the event, so undo() can restore it verbatim.
    var events;

    function initialize(n, t, w) {
        numSets = n;
        target = t;
        winBy2 = w;
        sets = [[0, 0]];
        setStartTimes = [Sys.getTimer()];
        positions = [1, 1];
        events = [];
    }

    // Begins recording. Restarts the set clock so elapsed time counts from
    // the real start rather than from when this object was constructed.
    function start() {
        started = true;
        setStartTimes[cur] = Sys.getTimer();
    }

    function serveSnapshot() {
        return {
            "serveTeam" => serveTeam,
            "pos0" => positions[0],
            "pos1" => positions[1],
            "firstSideOutDone" => firstSideOutDone
        };
    }

    // Scores a point for team (0 = Home, 1 = Away).
    //
    // Serve/rotation follows official side-out rules: the serving team keeps
    // serving and does not rotate when it scores; a receiving team that wins
    // a point takes serve and rotates 1->2->...->6->1.
    //
    // Returns true when the caller must show the "Stay 1 on serve?" prompt --
    // on the second team's first point of a set the app cannot infer whether
    // they were the original servers, so the user decides. The model never
    // pushes UI itself.
    function addPoint(team) {
        if (!started || done) {
            return false;
        }

        var snapshot = serveSnapshot();

        var s = sets[cur];
        s[team] = s[team] + 1;

        var needsPrompt = false;
        if (serveTeam == null) {
            // First point of the set: this team is serving, nobody rotates.
            serveTeam = team;
        } else if (serveTeam != team) {
            // Side-out.
            serveTeam = team;
            if (!firstSideOutDone) {
                firstSideOutDone = true;
                needsPrompt = true;
            } else {
                positions[team] = positions[team] % ROTATION_POSITIONS + 1;
            }
        }
        // else: the serving team scored again -- keeps serve, no rotation.

        var auto = isSetComplete(s);
        events = events.add({
            "t" => "p",
            "team" => team,
            "auto" => auto,
            "elapsedMs" => Sys.getTimer() - setStartTimes[cur],
            "prev" => snapshot
        });

        if (auto) {
            advance();
            return false; // set is over; rotation no longer matters
        }
        return needsPrompt;
    }

    // Applies the answer to "Stay 1 on serve?" -- No moves the team that just
    // took serve to Position 2.
    function resolveFirstServe(stayAtOne) {
        if (!stayAtOne && serveTeam != null) {
            positions[serveTeam] = 2;
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

    // Manual set end (Pause screen "End Set"). Any score is allowed.
    function endSetManual() {
        if (!started || done) {
            return;
        }
        events = events.add({"t" => "e", "prev" => serveSnapshot()});
        advance();
    }

    function advance() {
        if (cur + 1 >= numSets) {
            done = true;
        } else {
            cur = cur + 1;
            sets = sets.add([0, 0]);
            setStartTimes = setStartTimes.add(Sys.getTimer());
        }
        resetServeState();
    }

    function resetServeState() {
        serveTeam = null;
        positions = [1, 1];
        firstSideOutDone = false;
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
                setStartTimes = popLast(setStartTimes);
                cur = cur - 1;
            }
        }
        if (e["t"].equals("p")) {
            var s = sets[cur];
            s[e["team"]] = s[e["team"]] - 1;
        }

        // Restore serve/rotation exactly as it stood before this event,
        // rather than trying to reverse-compute a rotation.
        var prev = e["prev"];
        if (prev != null) {
            serveTeam = prev["serveTeam"];
            positions = [prev["pos0"], prev["pos1"]];
            firstSideOutDone = prev["firstSideOutDone"];
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

    function isServing(team) {
        return serveTeam == team;
    }

    function positionLabel(team) {
        return "Position " + positions[team];
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

    // Point events (chronological order) belonging to the currently
    // active/in-progress set, i.e. everything after the event that ended
    // the previous set, if any.
    function currentSetEvents() {
        var reversed = [];
        var i = events.size() - 1;
        while (i >= 0) {
            var e = events[i];
            var isBoundary = e["t"].equals("e")
                || (e["t"].equals("p") && e["auto"] == true);
            if (isBoundary) {
                break;
            }
            reversed = reversed.add(e);
            i = i - 1;
        }
        var n = reversed.size();
        var chrono = new [n];
        for (var j = 0; j < n; j++) {
            chrono[j] = reversed[n - 1 - j];
        }
        return chrono;
    }
}
