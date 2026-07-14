using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.Lang as Lang;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;

// Saved sessions, one per page, newest first.
// UP/DOWN flip between sessions, BACK returns to setup.
class HistoryView extends Ui.View {

    var history;
    var index = 0;

    function initialize() {
        View.initialize();
        var stored = App.Storage.getValue("history");
        if (stored instanceof Lang.Array) {
            history = stored as Lang.Array;
        } else {
            history = [];
        }
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.11, Gfx.FONT_TINY, "HISTORY",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        if (history.size() == 0) {
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h / 2, Gfx.FONT_SMALL, "No sessions yet",
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var entry = history[index] as Lang.Dictionary;

        dc.drawText(w / 2, h * 0.21, Gfx.FONT_XTINY,
                    (index + 1) + " of " + history.size(),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.31, Gfx.FONT_SMALL, formatDate(entry.get("ts")),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        var scores = entry.get("scores") as Lang.Array;
        var y = h * 0.43;
        for (var i = 0; i < scores.size(); i++) {
            var sc = scores[i] as Lang.Array;
            dc.drawText(w / 2, y, Gfx.FONT_TINY,
                        "Set " + (i + 1) + ":  " + sc[0] + " - " + sc[1],
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            y = y + h * 0.09;
        }

        if (history.size() > 1) {
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 0.88, Gfx.FONT_XTINY, "UP/DOWN: browse",
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        }
    }

    function formatDate(ts) {
        if (ts == null) {
            return "";
        }
        var info = Gregorian.info(new Time.Moment(ts), Time.FORMAT_MEDIUM);
        return info.month + " " + info.day + "  " + info.hour.format("%02d") + ":" + info.min.format("%02d");
    }
}

class HistoryDelegate extends Ui.BehaviorDelegate {

    var view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        me.view = view;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        var n = view.history.size();
        if (n > 0) {
            if (key == Ui.KEY_UP) {
                view.index = (view.index - 1 + n) % n;
                Ui.requestUpdate();
                return true;
            } else if (key == Ui.KEY_DOWN) {
                view.index = (view.index + 1) % n;
                Ui.requestUpdate();
                return true;
            }
        }
        return false; // BACK pops back to setup
    }
}
