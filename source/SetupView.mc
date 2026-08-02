using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.Timer as Timer;

// Row indices for the setup screen.
const ROW_SETS = 0;
const ROW_TARGET = 1;
const ROW_WINBY2 = 2;
const NUM_ROWS = 3;

// A label wider than this fraction of the screen auto-scrolls instead of
// being drawn (and potentially clipped/overlapping) in place.
const LABEL_SCROLL_WIDTH_RATIO = 0.4;
const LABEL_SCROLL_INTERVAL_MS = 50;
const LABEL_SCROLL_STEP = 2;
const LABEL_SCROLL_GAP_RATIO = 0.15;

// Pre-match configuration screen, opened with MENU from LandingView.
// UP/DOWN move between rows; ENTER edits a value (UP/DOWN adjust,
// ENTER confirms) or toggles Win by 2.
// BACK exits edit mode, then returns to LandingView.
// Starting a session lives on LandingView, not here.
class SetupView extends Ui.View {

    var sel = 0;
    var editing = false;

    var numSets = 3;
    var target = 25;
    var winBy2 = true;

    var scrollOffset = 0;
    var anyLabelScrolling = false;
    var scrollTimer;

    function initialize() {
        View.initialize();
        var s = loadMatchSettings();
        numSets = s["sets"];
        target = s["target"];
        winBy2 = s["winby2"];
    }

    function saveSettings() {
        App.Storage.setValue("settings", {
            "sets" => numSets,
            "target" => target,
            "winby2" => winBy2
        });
    }

    function onShow() {
        scrollTimer = new Timer.Timer();
        scrollTimer.start(method(:onScrollTick), LABEL_SCROLL_INTERVAL_MS, true);
    }

    function onHide() {
        if (scrollTimer != null) {
            scrollTimer.stop();
            scrollTimer = null;
        }
    }

    function onScrollTick() as Void {
        scrollOffset = (scrollOffset + LABEL_SCROLL_STEP) % 100000;
        if (anyLabelScrolling) {
            Ui.requestUpdate();
        }
    }

    // Draws `text` at `anchorX`, always confined to LABEL_SCROLL_WIDTH_RATIO
    // of the screen width. Text that fits is drawn normally; text that
    // doesn't is cut off at that boundary, unless it's the selected row,
    // in which case it auto-scrolls horizontally instead of being cut off.
    // Returns true if it's scrolling (so the caller knows to keep the
    // scroll timer animating).
    function drawLabel(dc, text, anchorX, justify, y, rowH, w, selected) {
        var font = Gfx.FONT_SMALL;
        var textW = dc.getTextWidthInPixels(text, font);
        var maxW = (w * LABEL_SCROLL_WIDTH_RATIO).toNumber();

        if (textW <= maxW) {
            dc.drawText(anchorX, y + rowH / 2, font, text,
                        justify | Gfx.TEXT_JUSTIFY_VCENTER);
            return false;
        }

        var clipLeft = (justify == Gfx.TEXT_JUSTIFY_CENTER) ? anchorX - maxW / 2 : anchorX;
        dc.setClip(clipLeft, y, maxW, rowH);

        if (!selected) {
            dc.drawText(anchorX, y + rowH / 2, font, text,
                        justify | Gfx.TEXT_JUSTIFY_VCENTER);
            dc.clearClip();
            return false;
        }

        var gap = (w * LABEL_SCROLL_GAP_RATIO).toNumber();
        var total = textW + gap;
        var x = clipLeft - (scrollOffset % total);

        dc.drawText(x, y + rowH / 2, font, text,
                    Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x + total, y + rowH / 2, font, text,
                    Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);

        dc.clearClip();
        return true;
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.14, Gfx.FONT_SMALL, "SetPoint",
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

        var labels = ["Sets", "Points per Set", "Win by 2"];
        var values = [
            numSets.toString(),
            target.toString(),
            winBy2 ? "Yes" : "No"
        ];

        var rowH = h * 0.13;
        var startY = h * 0.26;
        var scrolling = false;

        for (var i = 0; i < NUM_ROWS; i++) {
            var y = startY + i * rowH;

            if (i == sel) {
                dc.setColor(editing ? Gfx.COLOR_DK_BLUE : Gfx.COLOR_DK_GRAY,
                            Gfx.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(w * 0.12, y, w * 0.76, rowH - 2, 6);
            }

            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            if (values[i].equals("")) {
                if (drawLabel(dc, labels[i], w / 2, Gfx.TEXT_JUSTIFY_CENTER,
                              y, rowH, w, i == sel)) {
                    scrolling = true;
                }
            } else {
                if (drawLabel(dc, labels[i], w * 0.17, Gfx.TEXT_JUSTIFY_LEFT,
                              y, rowH, w, i == sel)) {
                    scrolling = true;
                }
                var v = (editing && i == sel) ? "< " + values[i] + " >" : values[i];
                dc.drawText(w * 0.83, y + rowH / 2, Gfx.FONT_SMALL, v,
                            Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER);
            }
        }

        anyLabelScrolling = scrolling;
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
        return false; // pops back to LandingView
    }
}
