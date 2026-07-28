using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Activity as Activity;
using Toybox.Timer as Timer;

// Number of swappable data pages shown while a match is in progress.
const NUM_MATCH_PAGES = 3;
const PAGE_SCOREBOARD = 0;
const PAGE_SERVER_TRACKING = 1;
const PAGE_POINT_PROGRESSION = 2;

// Live scoreboard, with 3 swappable data pages while a match is active:
// Scoreboard, Server Tracking, Point Progression History.
//   UP/DOWN (Scoreboard page)   = Home / Away point
//   UP/DOWN (other pages)       = switch page (wraps through all 3)
//   MENU short-press (Scoreboard)= Home point
//   MENU long-press (Scoreboard) = jump to Server Tracking page
//   BACK                        = undo last point
//   START/ENTER                 = brief "Stop" popup, then Pause screen
//                                  (Resume/End Set/Quit)
//   START/ENTER (summary screen)= exit to setup
class MatchView extends Ui.View {

    var match;
    var page = PAGE_SCOREBOARD;
    var clockTimer;

    function initialize(match) {
        View.initialize();
        me.match = match;
    }

    function onShow() {
        clockTimer = new Timer.Timer();
        clockTimer.start(method(:onClockTick), 1000, true);
    }

    function onHide() {
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
        } else if (page == PAGE_SERVER_TRACKING) {
            drawServerTracking(dc, w, h);
        } else if (page == PAGE_POINT_PROGRESSION) {
            drawPointProgression(dc, w, h);
        } else {
            drawScoreboard(dc, w, h);
        }
    }

    function drawScoreboard(dc, w, h) {
        var s = match.sets[match.cur];

        // Top section: current time
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.13, Gfx.FONT_SMALL, currentTimeString(),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        // Middle section: thin divider line instead of a colon
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

        // Bottom section: heart rate (left) / set # (right)
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w * 0.28, h * 0.83, Gfx.FONT_XTINY, heartRateString(),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w * 0.72, h * 0.83, Gfx.FONT_XTINY,
                    "Set " + (match.cur + 1) + "/" + match.numSets,
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    // Placeholder pages; layout to be specified.
    function drawServerTracking(dc, w, h) {
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.13, Gfx.FONT_TINY, "SERVER TRACKING",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2, Gfx.FONT_SMALL, "Coming soon",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    function drawPointProgression(dc, w, h) {
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.13, Gfx.FONT_TINY, "POINT PROGRESSION",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2, Gfx.FONT_SMALL, "Coming soon",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    function currentTimeString() {
        var now = Sys.getClockTime();
        var settings = Sys.getDeviceSettings();
        if (settings.is24Hour) {
            return now.hour.format("%02d") + ":" + now.min.format("%02d");
        }
        var hour = now.hour % 12;
        if (hour == 0) {
            hour = 12;
        }
        var suffix = now.hour < 12 ? "AM" : "PM";
        return hour + ":" + now.min.format("%02d") + " " + suffix;
    }

    function heartRateString() {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            return info.currentHeartRate.toString();
        }
        return "--";
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
        dc.drawText(w / 2, h * 0.87, Gfx.FONT_XTINY, "START: exit    BACK: undo",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}

class MatchDelegate extends Ui.BehaviorDelegate {

    const LONG_PRESS_MS = 600;

    // Window within which a duplicate dispatch of the same physical MENU
    // tap (onKey's fallback and onKeyReleased can both fire for one press
    // on some devices) is ignored instead of acting on it twice.
    const KEY_DEDUPE_MS = 400;

    var match;
    var view;
    var menuDownAt = null;
    var lastMenuActionAt = 0;
    var hasMenuAction = false;

    function initialize(match, view) {
        BehaviorDelegate.initialize();
        me.match = match;
        me.view = view;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_UP) {
            if (view.page == PAGE_SCOREBOARD) {
                match.addPoint(0);
            } else {
                changePage(-1);
            }
            Ui.requestUpdate();
            return true;
        } else if (key == Ui.KEY_DOWN) {
            if (view.page == PAGE_SCOREBOARD) {
                match.addPoint(1);
            } else {
                changePage(1);
            }
            Ui.requestUpdate();
            return true;
        } else if (key == Ui.KEY_ENTER) {
            if (match.done) {
                Ui.popView(Ui.SLIDE_RIGHT);
            } else {
                var sp = new StopPopupView(match);
                Ui.pushView(sp, new StopPopupDelegate(), Ui.SLIDE_UP);
            }
            return true;
        } else if (key == Ui.KEY_MENU) {
            tryMenu(false);
            return true;
        }
        return false;
    }

    function changePage(dir) {
        view.page = (view.page + dir + NUM_MATCH_PAGES) % NUM_MATCH_PAGES;
    }

    // Long-press detection for MENU (scoreboard page only): press = Home
    // point, hold = jump to Server Tracking page.
    function onKeyPressed(keyEvent) {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_MENU) {
            menuDownAt = Sys.getTimer();
            return true;
        }
        return false;
    }

    function onKeyReleased(keyEvent) {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_MENU) {
            var longPress = menuDownAt != null
                && (Sys.getTimer() - menuDownAt) >= LONG_PRESS_MS;
            menuDownAt = null;
            tryMenu(longPress);
            return true;
        }
        return false;
    }

    // Sole handler for the Back behavior: undoes the last point. Per
    // Garmin's docs, a BehaviorDelegate function returning true suppresses
    // the corresponding InputDelegate (onKey) call for that same press, so
    // this is the single place BACK is handled — no onKey/onKeyReleased
    // handling for KEY_ESC, and no dedupe needed.
    function onBack() {
        match.undo();
        Ui.requestUpdate();
        return true;
    }

    // Performs the MENU action at most once per physical tap, regardless
    // of which of onKey/onKeyReleased fire for it on a given device.
    function tryMenu(longPress) {
        var now = Sys.getTimer();
        if (hasMenuAction && isRecent(now, lastMenuActionAt)) {
            return;
        }
        hasMenuAction = true;
        lastMenuActionAt = now;
        if (view.page == PAGE_SCOREBOARD) {
            if (longPress) {
                view.page = PAGE_SERVER_TRACKING;
            } else {
                match.addPoint(0);
            }
            Ui.requestUpdate();
        }
    }

    // Sys.getTimer() tracks device uptime (not app uptime) and rolls over
    // every ~25-50 days, so it can go negative or jump backwards. Treat an
    // out-of-range/negative gap as "not a duplicate" (fail open) rather
    // than "not enough time has passed" (which would fail closed forever
    // once getTimer() goes negative).
    function isRecent(now, at) {
        var elapsed = now - at;
        return elapsed >= 0 && elapsed < KEY_DEDUPE_MS;
    }
}

class QuitConfirmDelegate extends Ui.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response) {
        if (response == Ui.CONFIRM_YES) {
            // Pop the (auto-dismissed) dialog's two views underneath:
            // PauseView, then MatchView.
            Ui.popView(Ui.SLIDE_RIGHT);
            Ui.popView(Ui.SLIDE_RIGHT);
        }
        return true;
    }
}
