using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

// Row indices for the pause screen.
const PAUSE_ROW_RESUME = 0;
const PAUSE_ROW_END_SET = 1;
const PAUSE_ROW_POINTS_HISTORY = 2;
const PAUSE_ROW_SETS_HISTORY = 3;
const PAUSE_ROW_QUIT = 4;
const PAUSE_NUM_ROWS = 5;

// Mid-match pause menu, opened from the Scoreboard/Server Tracking/Point
// Progression pages via START/ENTER.
// UP/DOWN move between rows, ENTER activates the selected row.
// BACK (unhandled here, falls through to the default pop) resumes.
class PauseView extends Ui.View {

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
        dc.drawText(w / 2, h * 0.16, Gfx.FONT_SMALL, "Paused",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        var labels = ["Resume", "End Set", "Points History", "Sets History", "Quit"];

        var rowH = h * 0.115;
        var startY = h * 0.27;

        for (var i = 0; i < PAUSE_NUM_ROWS; i++) {
            var y = startY + i * rowH;

            if (i == sel) {
                dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(w * 0.12, y, w * 0.76, rowH - 2, 6);
            }

            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(w / 2, y + rowH / 2, Gfx.FONT_SMALL, labels[i],
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        }
    }
}

class PauseDelegate extends Ui.BehaviorDelegate {

    var match;
    var view;

    function initialize(match, view) {
        BehaviorDelegate.initialize();
        me.match = match;
        me.view = view;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_UP) {
            view.sel = (view.sel - 1 + PAUSE_NUM_ROWS) % PAUSE_NUM_ROWS;
            Ui.requestUpdate();
            return true;
        } else if (key == Ui.KEY_DOWN) {
            view.sel = (view.sel + 1) % PAUSE_NUM_ROWS;
            Ui.requestUpdate();
            return true;
        } else if (key == Ui.KEY_ENTER) {
            return onSelect();
        }
        return false;
    }

    function onSelect() {
        if (view.sel == PAUSE_ROW_RESUME) {

        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_START);
        }
            Ui.popView(Ui.SLIDE_DOWN);
        } else if (view.sel == PAUSE_ROW_END_SET) {
            match.endSetManual();
            Ui.popView(Ui.SLIDE_DOWN);
        } else if (view.sel == PAUSE_ROW_POINTS_HISTORY) {
            var phv = new PointsHistoryView(match);
            Ui.pushView(phv, new PointsHistoryDelegate(phv), Ui.SLIDE_LEFT);
        } else if (view.sel == PAUSE_ROW_SETS_HISTORY) {
            var shv = new SetsHistoryView(match);
            Ui.pushView(shv, new SetsHistoryDelegate(shv), Ui.SLIDE_LEFT);
        } else if (view.sel == PAUSE_ROW_QUIT) {
            // Save/Discard is the confirmation -- it ends the session and
            // returns to Landing, popping itself, this Pause screen and the
            // scoreboard beneath it.
            var asv = new ActivitySaveView();
            Ui.pushView(asv, new ActivitySaveDelegate(match, asv, 3), Ui.SLIDE_UP);
        }
        return true;
    }
}
