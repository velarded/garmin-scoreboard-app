using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

const FIRST_SERVE_YES = 0;
const FIRST_SERVE_NO = 1;
const FIRST_SERVE_NUM_ROWS = 2;

// Asked once per set, the first time the receiving team scores. Their point
// is already on the board by this stage; what the app cannot infer is
// whether they were the original servers, so the user decides:
//   Yes = they stay on Position 1
//   No  = they rotate on to Position 2
// UP/DOWN highlight, START confirms, BACK returns leaving them on Position 1.
class FirstServePromptView extends Ui.View {

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
        dc.drawText(w / 2, h * 0.19, Gfx.FONT_SMALL, "Stay 1 on serve?",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        var labels = ["Yes", "No"];
        var rowH = h * 0.17;
        var startY = h * 0.36;

        for (var i = 0; i < FIRST_SERVE_NUM_ROWS; i++) {
            var y = startY + i * rowH;

            if (i == sel) {
                dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT);
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

class FirstServePromptDelegate extends Ui.BehaviorDelegate {

    // This prompt is pushed from inside a BACK handler (BACK scores the Away
    // point). Devices that deliver both onKeyReleased and onBack for that one
    // press would otherwise hand the trailing onBack to this brand-new view
    // and dismiss it instantly, so input is ignored very briefly on open.
    const INPUT_GRACE_MS = 350;

    var match;
    var view;
    var openedAt;

    function initialize(match, view) {
        BehaviorDelegate.initialize();
        me.match = match;
        me.view = view;
        openedAt = Sys.getTimer();
    }

    function settling() {
        var elapsed = Sys.getTimer() - openedAt;
        return elapsed >= 0 && elapsed < INPUT_GRACE_MS;
    }

    function onKey(keyEvent) {
        if (settling()) {
            return true;
        }
        var key = keyEvent.getKey();
        if (key == Ui.KEY_UP || key == Ui.KEY_MENU) {
            move(-1);
            return true;
        } else if (key == Ui.KEY_DOWN) {
            move(1);
            return true;
        } else if (key == Ui.KEY_ENTER) {
            match.resolveFirstServe(view.sel == FIRST_SERVE_YES);
            // The scoreboard repaints from its own onShow() when revealed --
            // requesting an update here would target this view, which is
            // about to be destroyed.
            Ui.popView(Ui.SLIDE_DOWN);
            return true;
        }
        return false;
    }

    function move(dir) {
        view.sel = (view.sel + dir + FIRST_SERVE_NUM_ROWS) % FIRST_SERVE_NUM_ROWS;
        Ui.requestUpdate();
    }

    // Dismissing without choosing leaves the team at Position 1, which is
    // what the model already applied -- "Stay at 1" is the safe default.
    function onBack() {
        if (settling()) {
            return true;
        }
        return false; // falls through to the framework's pop
    }
}
