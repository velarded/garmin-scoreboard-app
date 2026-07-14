using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

// Live scoreboard.
//   UP           = Team A point
//   DOWN         = Team B point
//   BACK (press) = undo last point / set end
//   BACK (hold)  = end current set now
//   MENU         = quit session (confirmation)
//   START/ENTER  = save & exit (on the final summary screen)
class MatchView extends Ui.View {

    var match;

    function initialize(match) {
        View.initialize();
        me.match = match;
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        if (match.done) {
            drawSummary(dc, w, h);
        } else {
            drawScoreboard(dc, w, h);
        }
    }

    function drawScoreboard(dc, w, h) {
        var s = match.sets[match.cur];

        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.11, Gfx.FONT_TINY,
                    "SET " + (match.cur + 1) + "/" + match.numSets,
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        // Completed set scores
        if (match.cur > 0) {
            var prev = "";
            for (var i = 0; i < match.cur; i++) {
                if (i > 0) {
                    prev = prev + "  ";
                }
                prev = prev + match.sets[i][0] + "-" + match.sets[i][1];
            }
            dc.drawText(w / 2, h * 0.22, Gfx.FONT_XTINY, prev,
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        }

        // Team labels
        dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w * 0.28, h * 0.34, Gfx.FONT_TINY, "A",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w * 0.72, h * 0.34, Gfx.FONT_TINY, "B",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        // Scores
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w * 0.28, h * 0.52, Gfx.FONT_NUMBER_HOT, s[0].toString(),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w / 2, h * 0.52, Gfx.FONT_NUMBER_MILD, ":",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w * 0.72, h * 0.52, Gfx.FONT_NUMBER_HOT, s[1].toString(),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        // Sets won
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.72, Gfx.FONT_XTINY,
                    "Sets " + match.setsWon(0) + "-" + match.setsWon(1),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        dc.drawText(w / 2, h * 0.83, Gfx.FONT_XTINY, "hold BACK: end set",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    function drawSummary(dc, w, h) {
        var aWon = match.setsWon(0);
        var bWon = match.setsWon(1);

        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.13, Gfx.FONT_SMALL, "MATCH DONE",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var result;
        if (aWon > bWon) {
            result = "A wins " + aWon + "-" + bWon;
        } else if (bWon > aWon) {
            result = "B wins " + bWon + "-" + aWon;
        } else {
            result = "Tied " + aWon + "-" + bWon;
        }
        dc.drawText(w / 2, h * 0.25, Gfx.FONT_MEDIUM, result,
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        var y = h * 0.38;
        for (var i = 0; i < match.sets.size(); i++) {
            dc.drawText(w / 2, y, Gfx.FONT_TINY,
                        "Set " + (i + 1) + ":  " + match.sets[i][0] + " - " + match.sets[i][1],
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            y = y + h * 0.09;
        }

        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.87, Gfx.FONT_XTINY, "START: save    BACK: undo",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}

class MatchDelegate extends Ui.BehaviorDelegate {

    const LONG_PRESS_MS = 600;

    var match;
    var view;
    var backDownAt = null;
    var backHandledAt = 0;

    function initialize(match, view) {
        BehaviorDelegate.initialize();
        me.match = match;
        me.view = view;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_UP) {
            match.addPoint(0);
            Ui.requestUpdate();
            return true;
        } else if (key == Ui.KEY_DOWN) {
            match.addPoint(1);
            Ui.requestUpdate();
            return true;
        } else if (key == Ui.KEY_ENTER) {
            if (match.done) {
                match.saveToHistory();
                Ui.popView(Ui.SLIDE_RIGHT);
            }
            return true;
        } else if (key == Ui.KEY_ESC) {
            return true; // handled via onKeyPressed/onKeyReleased/onBack
        }
        return false;
    }

    // Long-press detection for BACK: press = undo, hold = end set.
    function onKeyPressed(keyEvent) {
        if (keyEvent.getKey() == Ui.KEY_ESC) {
            backDownAt = Sys.getTimer();
            return true;
        }
        return false;
    }

    function onKeyReleased(keyEvent) {
        if (keyEvent.getKey() == Ui.KEY_ESC) {
            var longPress = backDownAt != null
                && (Sys.getTimer() - backDownAt) >= LONG_PRESS_MS;
            backDownAt = null;
            backHandledAt = Sys.getTimer();
            if (longPress) {
                match.endSetManual();
            } else {
                match.undo();
            }
            Ui.requestUpdate();
            return true;
        }
        return false;
    }

    // Swallow the behavioral back event so the app never exits mid-match.
    // If the device didn't deliver onKeyPressed/onKeyReleased for BACK,
    // fall back to treating it as a short press (undo).
    function onBack() {
        if (Sys.getTimer() - backHandledAt > 300) {
            match.undo();
            Ui.requestUpdate();
        }
        return true;
    }

    function onMenu() {
        var dialog = new Ui.Confirmation("Quit session?");
        Ui.pushView(dialog, new QuitConfirmDelegate(), Ui.SLIDE_UP);
        return true;
    }
}

class QuitConfirmDelegate extends Ui.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response) {
        if (response == Ui.CONFIRM_YES) {
            // Pop the match view underneath the (auto-dismissed) dialog.
            Ui.popView(Ui.SLIDE_RIGHT);
        }
        return true;
    }
}
