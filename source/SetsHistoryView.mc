using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

// Scrollable list of the final score of every completed set so far,
// opened from the Pause screen.
// UP/DOWN scroll the list; BACK returns to the Pause screen.
class SetsHistoryView extends Ui.View {

    var sets; // array of completed [a, b] score pairs
    var topIndex;
    var visibleRows = 1;

    function initialize(match) {
        View.initialize();
        var completed = match.done ? match.sets.size() : match.cur;
        sets = new [completed];
        for (var i = 0; i < completed; i++) {
            sets[i] = match.sets[i];
        }
        // Start scrolled to the most recent set; clamped once the
        // visible row count is known in onUpdate.
        topIndex = sets.size();
    }

    function scroll(dir) {
        topIndex = topIndex + dir;
        clampTopIndex();
    }

    function clampTopIndex() {
        var maxTop = sets.size() - visibleRows;
        if (maxTop < 0) {
            maxTop = 0;
        }
        if (topIndex > maxTop) {
            topIndex = maxTop;
        }
        if (topIndex < 0) {
            topIndex = 0;
        }
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.09, Gfx.FONT_TINY, "SETS HISTORY",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        var listTop = h * 0.22;
        var listBottom = h * 0.90;

        if (sets.size() == 0) {
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(w / 2, (listTop + listBottom) / 2, Gfx.FONT_SMALL,
                        "No sets completed yet",
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var rowH = h * 0.15;
        visibleRows = ((listBottom - listTop) / rowH).toNumber();
        if (visibleRows < 1) {
            visibleRows = 1;
        }
        clampTopIndex();

        var last = topIndex + visibleRows;
        if (last > sets.size()) {
            last = sets.size();
        }

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var y = listTop;
        for (var i = topIndex; i < last; i++) {
            var s = sets[i];
            dc.drawText(w / 2, y + rowH / 2, Gfx.FONT_SMALL,
                        "Set " + (i + 1) + ":  " + s[0] + " - " + s[1],
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            y = y + rowH;
        }

        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        if (topIndex > 0) {
            dc.drawText(w / 2, listTop - h * 0.03, Gfx.FONT_XTINY, "^",
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        }
        if (last < sets.size()) {
            dc.drawText(w / 2, listBottom + h * 0.03, Gfx.FONT_XTINY, "v",
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        }
    }
}

class SetsHistoryDelegate extends Ui.BehaviorDelegate {

    var view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        me.view = view;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_UP) {
            view.scroll(-1);
            Ui.requestUpdate();
            return true;
        } else if (key == Ui.KEY_DOWN) {
            view.scroll(1);
            Ui.requestUpdate();
            return true;
        }
        return false;
    }
}
