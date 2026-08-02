using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Activity as Activity;
using Toybox.Timer as Timer;

// Primary scoreboard: clock, elapsed set time, Home/Away scores with sets
// won, heart rate and set number. See ScoreboardDelegate for the buttons.
class ScoreboardPrimaryView extends Ui.View {

    var match;
    var clockTimer;

    function initialize(match) {
        View.initialize();
        me.match = match;
    }

    // Also fires when a pushed view (Pause, the first-serve prompt) is popped
    // and this scoreboard is revealed again, so repaint immediately rather
    // than showing the pre-push frame until the next clock tick.
    function onShow() {
        stopClock();
        clockTimer = new Timer.Timer();
        clockTimer.start(method(:onClockTick), 1000, true);
        Ui.requestUpdate();
    }

    function onHide() {
        stopClock();
    }

    function stopClock() {
        if (clockTimer != null) {
            clockTimer.stop();
            clockTimer = null;
        }
    }

    function onClockTick() as Void {
        Ui.requestUpdate();
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

        // Top: current time, with elapsed set time (or a start hint) below.
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.10, Gfx.FONT_SMALL, formatClockTime(),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        var sub = match.started
            ? formatElapsed(Sys.getTimer() - match.setStartTimes[match.cur])
            : "press START";
        dc.drawText(w / 2, h * 0.19, Gfx.FONT_XTINY, sub,
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        // Middle: thin divider line instead of a colon.
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(w / 2, h * 0.28, w / 2, h * 0.62);

        // Middle-left: Home
        dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w * 0.28, h * 0.34, Gfx.FONT_TINY, "Home",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w * 0.09, h * 0.52, Gfx.FONT_XTINY, match.setsWon(0).toString(),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w * 0.28, h * 0.52, Gfx.FONT_NUMBER_HOT, s[0].toString(),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        // Middle-right: Away
        dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w * 0.72, h * 0.34, Gfx.FONT_TINY, "Away",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w * 0.72, h * 0.52, Gfx.FONT_NUMBER_HOT, s[1].toString(),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w * 0.91, h * 0.52, Gfx.FONT_XTINY, match.setsWon(1).toString(),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        // Bottom: heart icon + heart rate (left) / set # (right)
        drawHeartIcon(dc, w * 0.20, h * 0.83, h * 0.03);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w * 0.30, h * 0.83, Gfx.FONT_XTINY, heartRateString(),
                    Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w * 0.72, h * 0.83, Gfx.FONT_XTINY,
                    "Set " + (match.cur + 1) + "/" + match.numSets,
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    function heartRateString() {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            return info.currentHeartRate.toString();
        }
        return "--";
    }

    function drawSummary(dc, w, h) {
        var homeWon = match.setsWon(0);
        var awayWon = match.setsWon(1);

        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.13, Gfx.FONT_SMALL, "MATCH DONE",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var result;
        if (homeWon > awayWon) {
            result = "Home wins " + homeWon + "-" + awayWon;
        } else if (awayWon > homeWon) {
            result = "Away wins " + awayWon + "-" + homeWon;
        } else {
            result = "Tied " + homeWon + "-" + awayWon;
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
        dc.drawText(w / 2, h * 0.87, Gfx.FONT_XTINY, "START: exit",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}

// Button handling shared by both scoreboard pages:
//   UP / MENU (short) = cycle data pages (subclasses pick the destination)
//   MENU (long)       = no-op (not implemented anywhere)
//   DOWN              = Home +1
//   BACK (short)      = Away +1
//   BACK (long)       = undo last point
//   START             = begin recording, or Stop popup -> Pause
// Scoring and undo are inert until the session is actually recording;
// page cycling always works.
class ScoreboardDelegate extends Ui.BehaviorDelegate {

    const HOLD_MS = 600;

    // Window within which a second dispatch of the same physical BACK press
    // (devices deliver different subsets of onKeyReleased and onBack, in
    // either order) is ignored instead of acting twice.
    const BACK_DEDUPE_MS = 300;

    var match;
    var view;
    var backHoldTimer;
    var backHoldFired = false;
    var backPressActive = false;
    var lastBackActionAt = 0;
    var hasBackAction = false;

    function initialize(match, view) {
        BehaviorDelegate.initialize();
        me.match = match;
        me.view = view;
    }

    // Overridden by each page to say where UP/MENU goes from here.
    function onCyclePage() {
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_UP || key == Ui.KEY_MENU) {
            onCyclePage();
            return true;
        } else if (key == Ui.KEY_DOWN) {
            scorePoint(0);
            return true;
        } else if (key == Ui.KEY_ENTER) {
            onStartStop();
            return true;
        }
        return false;
    }

    function scorePoint(team) {
        if (!match.started || match.done) {
            return;
        }
        if (match.addPoint(team)) {
            var prompt = new FirstServePromptView();
            Ui.pushView(prompt, new FirstServePromptDelegate(match, prompt),
                        Ui.SLIDE_UP);
        }
        Ui.requestUpdate();
    }

    function onStartStop() {
        if (match.done) {
            Ui.popView(Ui.SLIDE_RIGHT);
            return;
        }
        if (!match.started) {
            // Same flow as START on the Landing page, but this scoreboard is
            // already on the stack, so the popup returns here instead of
            // pushing another one.
            var sp = new StartPopupView(match, false);
            Ui.pushView(sp, new StartPopupDelegate(), Ui.SLIDE_UP);
            return;
        }
        var stop = new StopPopupView(match);
        Ui.pushView(stop, new StopPopupDelegate(), Ui.SLIDE_UP);
    }

    // BACK: short press = Away point, long press (hold) = undo.
    //
    // The hold fires from a timer started on key-down, the moment the
    // threshold is reached and while the button is still held -- rather than
    // measuring the duration on release. That means it depends only on
    // onKeyPressed arriving, not on onKeyPressed *and* onKeyReleased both
    // arriving, which is the more fragile of the two on real hardware.
    //
    // Fallback chain, because devices differ in which callbacks they deliver:
    //   onKeyPressed fires -> hold works (timer) and short press works
    //   only onBack fires  -> short press still scores Away; hold is lost to
    //                         the system, which reserves long-press BACK on
    //                         many Forerunner/Fenix models for the widget loop
    function onKeyPressed(keyEvent) {
        if (keyEvent.getKey() == Ui.KEY_ESC) {
            backHoldFired = false;
            backPressActive = true;
            cancelBackHold();
            backHoldTimer = new Timer.Timer();
            backHoldTimer.start(method(:onBackHold), HOLD_MS, false);
            return true;
        }
        return false;
    }

    // Only a button still being held is a hold. Any path that ends the press
    // clears backPressActive, so a timer that slips through (because the
    // press ended via a callback that could not cancel it in time) is inert
    // rather than undoing the point that press just scored.
    function onBackHold() as Void {
        backHoldTimer = null;
        if (!backPressActive) {
            return;
        }
        backHoldFired = true;
        markBackHandled();
        if (match.started && !match.done) {
            match.undo();
            Ui.requestUpdate();
        }
    }

    function onKeyReleased(keyEvent) {
        if (keyEvent.getKey() == Ui.KEY_ESC) {
            finishBackPress();
            return true;
        }
        return false;
    }

    function onBack() {
        finishBackPress();
        return true;
    }

    // The single place a BACK press is completed. Both onKeyReleased and
    // onBack route here because devices deliver one, the other, or both, in
    // either order -- so neither may assume it runs first, and both must
    // share one guard. (Scoring straight from onKeyReleased while only
    // onBack was guarded double-scored the Away team whenever onBack
    // happened to arrive first.)
    function finishBackPress() {
        var wasHold = backHoldFired;
        backHoldFired = false;
        backPressActive = false;
        cancelBackHold();

        if (wasHold) {
            // The hold already undid a point; mark so the trailing callback
            // for this same press does not then score one.
            markBackHandled();
            return;
        }
        if (backHandledRecently()) {
            return; // the other callback already scored this press
        }
        markBackHandled();
        scorePoint(1);
    }

    function cancelBackHold() {
        if (backHoldTimer != null) {
            backHoldTimer.stop();
            backHoldTimer = null;
        }
    }

    // Sys.getTimer() tracks device uptime and rolls over, so a negative gap
    // counts as "not a duplicate" rather than wedging this closed forever.
    function backHandledRecently() {
        var elapsed = Sys.getTimer() - lastBackActionAt;
        return hasBackAction && elapsed >= 0 && elapsed < BACK_DEDUPE_MS;
    }

    function markBackHandled() {
        hasBackAction = true;
        lastBackActionAt = Sys.getTimer();
    }
}

class ScoreboardPrimaryDelegate extends ScoreboardDelegate {

    function initialize(match, view) {
        ScoreboardDelegate.initialize(match, view);
    }

    // Primary always advances to Secondary.
    function onCyclePage() {
        var sv = new ScoreboardSecondaryView(match);
        Ui.switchToView(sv, new ScoreboardSecondaryDelegate(match, sv), Ui.SLIDE_LEFT);
    }
}

class QuitConfirmDelegate extends Ui.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response) {
        if (response == Ui.CONFIRM_YES) {
            // Pop the two views under the (auto-dismissed) dialog: PauseView,
            // then the scoreboard -- landing back on LandingView. Primary and
            // Secondary replace each other via switchToView, so the scoreboard
            // is always exactly one view deep here.
            Ui.popView(Ui.SLIDE_RIGHT);
            Ui.popView(Ui.SLIDE_RIGHT);
        }
        return true;
    }
}
