using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer as Timer;
using Toybox.Attention as Attention;

const STOP_POPUP_DURATION_MS = 700;

// Brief, non-interactive "Stop" confirmation shown on START/STOP press,
// mirroring Garmin's native Stop-activity popup, before handing off to
// the Pause screen.
class StopPopupView extends Ui.View {

    var match;
    var timer;

    function initialize(match) {
        View.initialize();
        me.match = match;
    }

    function onShow() {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_STOP);
        }
        timer = new Timer.Timer();
        timer.start(method(:onTimeout), STOP_POPUP_DURATION_MS, false);
    }

    function onHide() {
        if (timer != null) {
            timer.stop();
            timer = null;
        }
    }

    function onTimeout() as Void {
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        var pv = new PauseView();
        Ui.pushView(pv, new PauseDelegate(match, pv), Ui.SLIDE_UP);
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        // Stop icon: white square inside a circle, matching Garmin's
        // native Stop-activity iconography.
        var cx = w / 2;
        var cy = h * 0.42;
        var r = h * 0.16;
        dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var sq = r * 0.7;
        dc.fillRectangle(cx - sq / 2, cy - sq / 2, sq, sq);

        dc.drawText(w / 2, h * 0.68, Gfx.FONT_MEDIUM, "Stop",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}

// Non-interactive: input is swallowed while the popup shows itself, and
// it auto-advances to the Pause screen via its own timer.
class StopPopupDelegate extends Ui.BehaviorDelegate {

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
