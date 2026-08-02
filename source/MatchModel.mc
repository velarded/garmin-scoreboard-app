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

    // A finished set is not banked immediately: the scoreboard stays on it so
    // the final score can be reviewed, and the set clock freezes at
    // setEndedAt. Proceeding opens the next set; undoing reopens this one and
    // resumes the clock where it stopped.
    var setAwaitingReview = false;
    var setEndedAt = null;

    // stack of:
    //   {"t"=>"p","team"=>0/1,"auto"=>bool,"elapsedMs"=>n,"prev"=>{...}}
    //   {"t"=>"e","prev"=>{...}}   manual set end
    //   {"t"=>"a","prev"=>{...}}   advanced into the next set
    // "prev" snapshots the volatile state as it was *before* the event, so
    // undo() can restore it verbatim instead of reverse-computing it.
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
            "firstSideOutDone" => firstSideOutDone,
            "awaitingReview" => setAwaitingReview,
            "endedAt" => setEndedAt
        };
    }

    // Elapsed time in the current set, frozen while the set is being
    // reviewed so the review pause is not counted against it.
    function elapsedMs() {
        var end = (setAwaitingReview && setEndedAt != null)
            ? setEndedAt : Sys.getTimer();
        return end - setStartTimes[cur];
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
        if (!started || done || setAwaitingReview) {
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
            "elapsedMs" => elapsedMs(),
            "prev" => snapshot
        });

        if (auto) {
            enterSetReview();
            return false; // set is over; rotation no longer matters
        }
        return needsPrompt;
    }

    // The set is over, but stay on it so the score can be reviewed.
    function enterSetReview() {
        setAwaitingReview = true;
        setEndedAt = Sys.getTimer();
    }

    // START from the review screen: bank the set and open the next one (or
    // finish the match). Recorded as its own event so undo can come back.
    function proceedToNextSet() {
        if (!setAwaitingReview) {
            return;
        }
        events = events.add({"t" => "a", "prev" => serveSnapshot()});
        setAwaitingReview = false;
        setEndedAt = null;
        advance();
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

    // Manual set end (Pause screen "End Set"). Any score is allowed. Lands on
    // the same review screen as a set that finished on its own.
    function endSetManual() {
        if (!started || done || setAwaitingReview) {
            return;
        }
        events = events.add({"t" => "e", "prev" => serveSnapshot()});
        enterSetReview();
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

        var wasAwaiting = setAwaitingReview;
        var pausedSince = setEndedAt;

        if (e["t"].equals("a")) {
            // Step back out of the set this advance opened.
            if (done) {
                done = false;
            } else {
                sets = popLast(sets);
                setStartTimes = popLast(setStartTimes);
                cur = cur - 1;
            }
        } else if (e["t"].equals("p")) {
            var s = sets[cur];
            s[e["team"]] = s[e["team"]] - 1;
        }
        // "e" (manual set end) changes no score; its snapshot restores the
        // review state on its own.

        // Restore the volatile state exactly as it stood before this event,
        // rather than trying to reverse-compute a rotation.
        var prev = e["prev"];
        if (prev != null) {
            serveTeam = prev["serveTeam"];
            positions = [prev["pos0"], prev["pos1"]];
            firstSideOutDone = prev["firstSideOutDone"];
            setAwaitingReview = prev["awaitingReview"];
            setEndedAt = prev["endedAt"];
        }

        // Undoing back out of the review screen resumes the set clock where
        // it froze, so time spent reviewing is not charged to the set.
        if (wasAwaiting && !setAwaitingReview && pausedSince != null) {
            setStartTimes[cur] = setStartTimes[cur] + (Sys.getTimer() - pausedSince);
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

    // Number of completed sets won by team (0 or 1). A set being reviewed is
    // finished, so it counts even though it has not been banked yet.
    function setsWon(team) {
        var other = 1 - team;
        var count = 0;
        var completed = done ? sets.size() : (setAwaitingReview ? cur + 1 : cur);
        for (var i = 0; i < completed; i++) {
            if (sets[i][team] > sets[i][other]) {
                count = count + 1;
            }
        }
        return count;
    }

    // Point events (chronological order) belonging to the set currently on
    // screen. Advancing ("a") is what opens a new set, so it is the only
    // boundary -- a set being reviewed still shows the points that won it.
    function currentSetEvents() {
        var reversed = [];
        var i = events.size() - 1;
        while (i >= 0) {
            var e = events[i];
            if (e["t"].equals("a")) {
                break;
            }
            if (e["t"].equals("p")) {
                reversed = reversed.add(e);
            }
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
