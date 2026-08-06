using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer as Timer;

// Secondary scoreboard: serve + rotation tracking. Top and middle form one
// block split by a centre divider -- each side shows its team label, score,
// sets won and current rotation position, with a volleyball icon marking
// whichever side is serving. Current time runs along the bottom.
class ScoreboardSecondaryView extends Ui.View {

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
            drawMatchSummary(dc, w, h, match);
            return;
        }
        if (match.setAwaitingReview) {
            drawSetComplete(dc, w, h, match);
            return;
        }

        // Centre divider spanning the combined top + middle block.
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(w / 2, h * 0.12, w / 2, h * 0.74);

        drawTeam(dc, w, h, 0, w * 0.27, "Home", Gfx.COLOR_BLUE);
        drawTeam(dc, w, h, 1, w * 0.73, "Away", Gfx.COLOR_RED);

        // Bottom: current time.
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.86, Gfx.FONT_SMALL, formatClockTime(),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    function drawTeam(dc, w, h, team, colX, label, labelColor) {
        var s = match.sets[match.cur];

        dc.setColor(labelColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(colX, h * 0.19, Gfx.FONT_TINY, label,
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(colX, h * 0.38, Gfx.FONT_NUMBER_MEDIUM, s[team].toString(),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(colX, h * 0.56, Gfx.FONT_XTINY,
                    "Sets " + match.setsWon(team),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        drawPosition(dc, w, h, team, colX);
    }

    // Rotation position, with the volleyball icon beside it when this team is
    // serving. Icon and text are measured together so the pair stays centred
    // in the column whether or not the icon is present.
    function drawPosition(dc, w, h, team, colX) {
        var text = match.positionLabel(team);
        var font = Gfx.FONT_XTINY;
        var textW = dc.getTextWidthInPixels(text, font);

        var serving = match.isServing(team);
        var iconR = h * 0.025;
        var gap = w * 0.02;
        var iconW = serving ? (iconR * 2 + gap) : 0;

        var y = h * 0.68;
        var left = colX - (iconW + textW) / 2;

        if (serving) {
            drawVolleyballIcon(dc, left + iconR, y, iconR);
        }

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(left + iconW, y, font, text,
                    Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}

class ScoreboardSecondaryDelegate extends ScoreboardDelegate {

    function initialize(match, view) {
        ScoreboardDelegate.initialize(match, view);
    }

    // While recording the cycle collapses to Primary <-> Secondary so a live
    // session can't be navigated away from; before recording it carries on
    // round to the Landing page.
    function onCyclePage() {
        if (match.started) {
            var pv = new ScoreboardPrimaryView(match);
            Ui.switchToView(pv, new ScoreboardPrimaryDelegate(match, pv), Ui.SLIDE_LEFT);
        } else {
            Ui.popView(Ui.SLIDE_LEFT);
        }
    }
}
