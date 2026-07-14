using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.Lang as Lang;

// Row indices for the setup screen.
const ROW_SETS = 0;
const ROW_TARGET = 1;
const ROW_WINBY2 = 2;
const ROW_START = 3;
const ROW_HISTORY = 4;
const NUM_ROWS = 5;

// Pre-match configuration screen.
// UP/DOWN move between rows; ENTER edits a value (UP/DOWN adjust,
// ENTER confirms), toggles Win by 2, starts the match, or opens history.
// BACK exits edit mode, or exits the app.
class SetupView extends Ui.View {

    var sel = 0;
    var editing = false;

    var numSets = 3;
    var target = 25;
    var winBy2 = true;

    function initialize() {
        View.initialize();
        var stored = App.Storage.getValue("settings");
        if (stored instanceof Lang.Dictionary) {
            var d = stored as Lang.Dictionary;
            if (d.get("sets") != null) {
                numSets = d.get("sets");
            }
            if (d.get("target") != null) {
                target = d.get("target");
            }
            if (d.get("winby2") != null) {
                winBy2 = d.get("winby2");
            }
        }
    }

    function saveSettings() {
        App.Storage.setValue("settings", {
            "sets" => numSets,
            "target" => target,
            "winby2" => winBy2
        });
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.14, Gfx.FONT_SMALL, "Volleyball",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        var labels = ["Sets", "Target", "Win by 2", "START", "History"];
        var values = [
            numSets.toString(),
            target.toString(),
            winBy2 ? "Yes" : "No",
            "",
            ""
        ];

        var rowH = h * 0.13;
        var startY = h * 0.26;

        for (var i = 0; i < NUM_ROWS; i++) {
            var y = startY + i * rowH;

            if (i == sel) {
                dc.setColor(editing ? Gfx.COLOR_DK_BLUE : Gfx.COLOR_DK_GRAY,
                            Gfx.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(w * 0.12, y, w * 0.76, rowH - 2, 6);
            }

            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            if (values[i].equals("")) {
                dc.drawText(w / 2, y + rowH / 2, Gfx.FONT_SMALL, labels[i],
                            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.drawText(w * 0.17, y + rowH / 2, Gfx.FONT_SMALL, labels[i],
                            Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
                var v = (editing && i == sel) ? "< " + values[i] + " >" : values[i];
                dc.drawText(w * 0.83, y + rowH / 2, Gfx.FONT_SMALL, v,
                            Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER);
            }
        }
    }
}

class SetupDelegate extends Ui.BehaviorDelegate {

    var view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        me.view = view;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_UP) {
            handleUpDown(-1);
            return true;
        } else if (key == Ui.KEY_DOWN) {
            handleUpDown(1);
            return true;
        } else if (key == Ui.KEY_ENTER) {
            return onSelect();
        }
        return false;
    }

    function handleUpDown(dir) {
        if (view.editing) {
            if (view.sel == ROW_SETS) {
                view.numSets = clamp(view.numSets - dir, 1, 9);
            } else if (view.sel == ROW_TARGET) {
                view.target = clamp(view.target - dir, 5, 50);
            }
        } else {
            view.sel = (view.sel + dir + NUM_ROWS) % NUM_ROWS;
        }
        Ui.requestUpdate();
    }

    function clamp(v, lo, hi) {
        if (v < lo) {
            return lo;
        }
        if (v > hi) {
            return hi;
        }
        return v;
    }

    function onSelect() {
        var sel = view.sel;
        if (sel == ROW_SETS || sel == ROW_TARGET) {
            view.editing = !view.editing;
            if (!view.editing) {
                view.saveSettings();
            }
        } else if (sel == ROW_WINBY2) {
            view.winBy2 = !view.winBy2;
            view.saveSettings();
        } else if (sel == ROW_START) {
            view.saveSettings();
            var match = new Match(view.numSets, view.target, view.winBy2);
            var mv = new MatchView(match);
            Ui.pushView(mv, new MatchDelegate(match, mv), Ui.SLIDE_LEFT);
        } else if (sel == ROW_HISTORY) {
            var hv = new HistoryView();
            Ui.pushView(hv, new HistoryDelegate(hv), Ui.SLIDE_LEFT);
        }
        Ui.requestUpdate();
        return true;
    }

    function onBack() {
        if (view.editing) {
            view.editing = false;
            view.saveSettings();
            Ui.requestUpdate();
            return true;
        }
        return false; // exit app
    }
}
