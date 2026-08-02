using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

// Scrollable, 3-column (#, elapsed time, score) list of every point
// transition in the currently active (in-progress) set, opened from the
// Pause screen.
// UP/DOWN scroll the list; BACK returns to the Pause screen.
class PointsHistoryView extends Ui.View {

    var entries;
    var topIndex;
    var visibleRows = 1;

    function initialize(match) {
        View.initialize();
        entries = buildEntries(match.currentSetEvents());
        // Start scrolled to the most recent point; clamped once the
        // visible row count is known in onUpdate.
        topIndex = entries.size();
    }

    function buildEntries(events) {
        var result = [];
        var a = 0;
        var b = 0;
        for (var i = 0; i < events.size(); i++) {
            var team = events[i]["team"];
            if (team == 0) {
                a = a + 1;
            } else {
                b = b + 1;
            }
            result = result.add({
                "n" => i + 1,
                "elapsed" => formatElapsed(events[i]["elapsedMs"]),
                "score" => a + "-" + b
            });
        }
        return result;
    }

    function scroll(dir) {
        topIndex = topIndex + dir;
        clampTopIndex();
    }

    function clampTopIndex() {
        var maxTop = entries.size() - visibleRows;
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

        // Top section: the title alone, on two lines. Anchored at the centre
        // of the two-line block so neither line runs off the top bezel.
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.15, Gfx.FONT_TINY, "POINTS\nHISTORY",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        // Everything below the title is the table: #, elapsed time, score,
        // separated by vertical dividers.
        var col1X = w * 0.30;
        var col2X = w * 0.65;
        var xNum = w * 0.15;
        var xTime = (col1X + col2X) / 2;
        var xScore = (col2X + w) / 2;

        var headerY = h * 0.31;
        var listTop = h * 0.37;
        var listBottom = h * 0.88;

        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(xNum, headerY, Gfx.FONT_XTINY, "#",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.drawText(xTime, headerY, Gfx.FONT_XTINY, "Time",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.drawText(xScore, headerY, Gfx.FONT_XTINY, "Score",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(col1X, h * 0.26, col1X, listBottom);
        dc.drawLine(col2X, h * 0.26, col2X, listBottom);

        if (entries.size() == 0) {
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(w / 2, (listTop + listBottom) / 2, Gfx.FONT_SMALL, "No points yet",
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var rowH = h * 0.125;
        visibleRows = ((listBottom - listTop) / rowH).toNumber();
        if (visibleRows < 1) {
            visibleRows = 1;
        }
        clampTopIndex();

        var last = topIndex + visibleRows;
        if (last > entries.size()) {
            last = entries.size();
        }

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var y = listTop;
        for (var i = topIndex; i < last; i++) {
            var e = entries[i];
            dc.drawText(xNum, y + rowH / 2, Gfx.FONT_XTINY, e["n"],
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            dc.drawText(xTime, y + rowH / 2, Gfx.FONT_XTINY, e["elapsed"],
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            dc.drawText(xScore, y + rowH / 2, Gfx.FONT_XTINY, e["score"],
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            y = y + rowH;
        }

        // Scroll position, centred so it stays clear of the rounded corners
        // that the old right-edge arrows were pushed into.
        if (entries.size() > visibleRows) {
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 0.93, Gfx.FONT_XTINY,
                        last + "/" + entries.size(),
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        }
    }
}

class PointsHistoryDelegate extends Ui.BehaviorDelegate {

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
