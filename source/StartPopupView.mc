using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer as Timer;
using Toybox.Lang as Lang;
using Toybox.Attention as Attention;

const START_POPUP_DURATION_MS = 700;

// Brief, non-interactive "Start" confirmation shown when a session begins,
// mirroring Garmin's native start-activity popup. Begins recording, then
// either opens the Primary scoreboard (when launched from LandingView) or
// returns to the scoreboard already underneath it.
class StartPopupView extends Ui.View {

    var match;
    var openPrimary;
    var timer;

    function initialize(match, openPrimary) {
        View.initialize();
        me.match = match;
        me.openPrimary = openPrimary;
    }

    function onShow() {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_START);
        }
        timer = new Timer.Timer();
        timer.start(method(:onTimeout), START_POPUP_DURATION_MS, false);
    }

    function onHide() {
        if (timer != null) {
            timer.stop();
            timer = null;
        }
    }

    function onTimeout() as Void {
        match.start();
        if (openPrimary) {
            // Replace this popup so the scoreboard sits directly on Landing.
            var pv = new ScoreboardPrimaryView(match);
            Ui.switchToView(pv, new ScoreboardPrimaryDelegate(match, pv), Ui.SLIDE_LEFT);
        } else {
            Ui.popView(Ui.SLIDE_IMMEDIATE);
        }
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        // Start icon: white play triangle inside a green circle.
        var cx = w / 2;
        var cy = h * 0.42;
        var r = h * 0.16;
        dc.setColor(Gfx.COLOR_DK_GREEN, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var pts = [
            [cx - r * 0.3, cy - r * 0.5],
            [cx - r * 0.3, cy + r * 0.5],
            [cx + r * 0.55, cy]
        ] as Lang.Array<Gfx.Point2D>;
        dc.fillPolygon(pts);

        dc.drawText(w / 2, h * 0.68, Gfx.FONT_MEDIUM, "Start",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}

// Non-interactive: input is swallowed while the popup shows itself, and it
// auto-advances via its own timer.
class StartPopupDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onKey(keyEvent) {
        return true;
    }

    function onBack() {
        return true;
    }
}
