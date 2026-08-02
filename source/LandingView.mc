using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer as Timer;

// App home screen: title and readiness state across the top and middle,
// current time in the bottom half.
//   MENU/UP = Setup    DOWN = browse the scoreboards    START = begin
//   BACK    = exit the app (this is the root view)
class LandingView extends Ui.View {

    var clockTimer;

    function initialize() {
        View.initialize();
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

        // Title
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.27, Gfx.FONT_MEDIUM, "Volleyball",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        drawReady(dc, w, h);

        // Bottom half: current time.
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.72, Gfx.FONT_SMALL, formatClockTime(),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        // Hint glyph at the centre of the left edge, beside the MENU/UP
        // button. Vertical centre is the widest point of a round display,
        // so a small inset clears the bezel.
        drawMenuGlyph(dc, w * 0.06, h / 2, h * 0.013, h * 0.04);
    }

    // Green status dot followed by "Ready", measured together so the pair
    // stays centred.
    function drawReady(dc, w, h) {
        var text = "Ready";
        var font = Gfx.FONT_SMALL;
        var textW = dc.getTextWidthInPixels(text, font);

        var dotR = h * 0.018;
        var gap = w * 0.03;
        var y = h * 0.42;
        var left = w / 2 - (dotR * 2 + gap + textW) / 2;

        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(left + dotR, y, dotR);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(left + dotR * 2 + gap, y, font, text,
                    Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}

class LandingDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_UP || key == Ui.KEY_MENU) {
            var sv = new SetupView();
            Ui.pushView(sv, new SetupDelegate(sv), Ui.SLIDE_LEFT);
            return true;
        } else if (key == Ui.KEY_DOWN) {
            // Browse the scoreboards without recording anything yet.
            var match = newMatchFromSettings();
            var pv = new ScoreboardPrimaryView(match);
            Ui.pushView(pv, new ScoreboardPrimaryDelegate(match, pv), Ui.SLIDE_LEFT);
            return true;
        } else if (key == Ui.KEY_ENTER) {
            var match = newMatchFromSettings();
            var sp = new StartPopupView(match, true);
            Ui.pushView(sp, new StartPopupDelegate(), Ui.SLIDE_UP);
            return true;
        }
        return false;
    }

    // onBack is intentionally not overridden: this is the root view, so BACK
    // falls through to the default behavior and exits the app.
}
