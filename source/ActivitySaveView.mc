using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer as Timer;
using Toybox.Attention as Attention;

const ACTIVITY_ROW_SAVE = 0;
const ACTIVITY_ROW_DISCARD = 1;
const ACTIVITY_NUM_ROWS = 2;
const ACTIVITY_RESULT_DURATION_MS = 900;

// End-of-session screen: write the volleyball activity to Garmin, or throw the
// recording away. Either choice returns to LandingView.
//   UP/DOWN = highlight an option
//   START   = confirm
//   BACK    = go back without ending the session
class ActivitySaveView extends Ui.View {

    var sel = 0;

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.19, Gfx.FONT_SMALL, "Save activity?",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        var labels = ["Save", "Discard"];
        var rowH = h * 0.17;
        var startY = h * 0.36;

        for (var i = 0; i < ACTIVITY_NUM_ROWS; i++) {
            var y = startY + i * rowH;

            if (i == sel) {
                dc.setColor(i == ACTIVITY_ROW_SAVE ? Gfx.COLOR_DK_GREEN : Gfx.COLOR_DK_RED,
                            Gfx.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(w * 0.12, y, w * 0.76, rowH - 4, 6);
            }

            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(w / 2, y + (rowH - 4) / 2, Gfx.FONT_SMALL, labels[i],
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        }

        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.85, Gfx.FONT_XTINY, "START: confirm",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}

class ActivitySaveDelegate extends Ui.BehaviorDelegate {

    var match;
    var view;
    var viewsToPop;

    // viewsToPop counts this view plus everything between it and LandingView,
    // since Monkey C can only pop one view at a time:
    //   from Pause    -> ActivitySave + Pause + scoreboard = 3
    //   from the      -> ActivitySave + scoreboard         = 2
    //   match summary
    function initialize(match, view, viewsToPop) {
        BehaviorDelegate.initialize();
        me.match = match;
        me.view = view;
        me.viewsToPop = viewsToPop;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_UP || key == Ui.KEY_MENU) {
            move(-1);
            return true;
        } else if (key == Ui.KEY_DOWN) {
            move(1);
            return true;
        } else if (key == Ui.KEY_ENTER) {
            var saved = (view.sel == ACTIVITY_ROW_SAVE);
            if (saved) {
                match.saveActivity();
            } else {
                match.discardActivity();
            }
            // Replace this view rather than stacking on it, so the result
            // screen sits at the same depth and viewsToPop still holds.
            var rv = new ActivityResultView(saved, viewsToPop);
            Ui.switchToView(rv, new ActivityResultDelegate(), Ui.SLIDE_IMMEDIATE);
            return true;
        }
        return false;
    }

    function move(dir) {
        view.sel = (view.sel + dir + ACTIVITY_NUM_ROWS) % ACTIVITY_NUM_ROWS;
        Ui.requestUpdate();
    }

    // Backing out leaves the session recording and returns to where this was
    // opened from, so the quit can be reconsidered.
    function onBack() {
        return false; // falls through to the framework's pop
    }
}

// Brief, non-interactive confirmation that the activity was written or
// thrown away, mirroring the feedback Garmin's own activity apps give.
// Dismisses itself and returns to LandingView.
class ActivityResultView extends Ui.View {

    var saved;
    var viewsToPop;
    var timer;

    function initialize(saved, viewsToPop) {
        View.initialize();
        me.saved = saved;
        me.viewsToPop = viewsToPop;
    }

    function onShow() {
        if (Attention has :playTone) {
            Attention.playTone(saved ? Attention.TONE_SUCCESS : Attention.TONE_RESET);
        }
        timer = new Timer.Timer();
        timer.start(method(:onTimeout), ACTIVITY_RESULT_DURATION_MS, false);
    }

    function onHide() {
        if (timer != null) {
            timer.stop();
            timer = null;
        }
    }

    function onTimeout() as Void {
        for (var i = 0; i < viewsToPop; i++) {
            Ui.popView(Ui.SLIDE_RIGHT);
        }
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        var cx = w / 2;
        var cy = h * 0.42;
        var r = h * 0.16;

        dc.setColor(saved ? Gfx.COLOR_DK_GREEN : Gfx.COLOR_DK_RED,
                    Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r);

        // Tick for saved, cross for discarded.
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(4);
        if (saved) {
            dc.drawLine(cx - r * 0.45, cy, cx - r * 0.12, cy + r * 0.36);
            dc.drawLine(cx - r * 0.12, cy + r * 0.36, cx + r * 0.48, cy - r * 0.36);
        } else {
            dc.drawLine(cx - r * 0.35, cy - r * 0.35, cx + r * 0.35, cy + r * 0.35);
            dc.drawLine(cx - r * 0.35, cy + r * 0.35, cx + r * 0.35, cy - r * 0.35);
        }
        dc.setPenWidth(1);

        dc.drawText(w / 2, h * 0.68, Gfx.FONT_MEDIUM,
                    saved ? "Saved" : "Discarded",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }
}

// Non-interactive: input is swallowed while the result shows itself.
class ActivityResultDelegate extends Ui.BehaviorDelegate {

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
