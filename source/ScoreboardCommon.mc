using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;

// Current time of day, honouring the device's 12/24-hour setting.
function formatClockTime() {
    var now = Sys.getClockTime();
    var settings = Sys.getDeviceSettings();
    if (settings.is24Hour) {
        return now.hour.format("%02d") + ":" + now.min.format("%02d");
    }
    var hour = now.hour % 12;
    if (hour == 0) {
        hour = 12;
    }
    var suffix = now.hour < 12 ? "AM" : "PM";
    return hour + ":" + now.min.format("%02d") + " " + suffix;
}

// Milliseconds as MM:SS.
function formatElapsed(ms) {
    var totalSec = ms / 1000;
    var mm = totalSec / 60;
    var ss = totalSec % 60;
    return mm.format("%02d") + ":" + ss.format("%02d");
}

// Small vector heart: two circle lobes plus a triangular point, centred at
// (cx, cy) with an overall half-width/height of about r.
function drawHeartIcon(dc, cx, cy, r) {
    dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
    var lobeR = r * 0.55;
    dc.fillCircle(cx - lobeR, cy - lobeR * 0.4, lobeR);
    dc.fillCircle(cx + lobeR, cy - lobeR * 0.4, lobeR);
    // fillPolygon takes Graphics.Point2D, which is Array[Numeric, Numeric] --
    // the cast has to name that type, not a hand-rolled Array<Number>.
    var pts = [
        [cx - r, cy - r * 0.1],
        [cx + r, cy - r * 0.1],
        [cx, cy + r]
    ] as Lang.Array<Gfx.Point2D>;
    dc.fillPolygon(pts);
}

// Volleyball: light ball with darker seams, marking the serving side.
function drawVolleyballIcon(dc, cx, cy, r) {
    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    dc.fillCircle(cx, cy, r);
    dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
    dc.setPenWidth(1);
    dc.drawCircle(cx, cy, r);
    dc.drawLine(cx - r, cy, cx + r, cy);
    dc.drawLine(cx, cy - r, cx, cy + r);
}

// Between-sets review: the set is over but the scoreboard stays on it so the
// final score can be checked before committing to the next set. Shown by both
// scoreboard pages while match.setAwaitingReview is true.
function drawSetComplete(dc, w, h, match) {
    var s = match.sets[match.cur];
    var lastSet = (match.cur + 1 >= match.numSets);

    dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
    dc.drawText(w / 2, h * 0.13, Gfx.FONT_SMALL,
                "SET " + (match.cur + 1) + "\nCOMPLETE",
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

    dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
    dc.setPenWidth(1);
    dc.drawLine(w / 2, h * 0.24, w / 2, h * 0.55);

    dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
    dc.drawText(w * 0.28, h * 0.29, Gfx.FONT_XTINY, "Home",
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
    dc.drawText(w * 0.72, h * 0.29, Gfx.FONT_XTINY, "Away",
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    dc.drawText(w * 0.28, h * 0.44, Gfx.FONT_NUMBER_MEDIUM, s[0].toString(),
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    dc.drawText(w * 0.72, h * 0.44, Gfx.FONT_NUMBER_MEDIUM, s[1].toString(),
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
    dc.drawText(w / 2, h * 0.62, Gfx.FONT_XTINY,
                "Sets " + match.setsWon(0) + " - " + match.setsWon(1),
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    dc.drawText(w / 2, h * 0.71, Gfx.FONT_XTINY, formatElapsed(match.elapsedMs()),
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

    dc.drawText(w / 2, h * 0.82, Gfx.FONT_XTINY,
                lastSet ? "START: finish" : "START: next set",
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    dc.drawText(w / 2, h * 0.90, Gfx.FONT_XTINY, "BACK: undo",
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
}

// End-of-match summary: the result and every set score. Shown by both
// scoreboard pages once match.done is set, so finishing on either one lands
// on the same screen.
function drawMatchSummary(dc, w, h, match) {
    var homeWon = match.setsWon(0);
    var awayWon = match.setsWon(1);

    dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
    dc.drawText(w / 2, h * 0.13, Gfx.FONT_SMALL, "MATCH DONE",
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    var result;
    if (homeWon > awayWon) {
        result = "Home wins " + homeWon + "-" + awayWon;
    } else if (awayWon > homeWon) {
        result = "Away wins " + awayWon + "-" + homeWon;
    } else {
        result = "Tied " + homeWon + "-" + awayWon;
    }
    dc.drawText(w / 2, h * 0.25, Gfx.FONT_MEDIUM, result,
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);

    var y = h * 0.38;
    for (var i = 0; i < match.sets.size(); i++) {
        dc.drawText(w / 2, y, Gfx.FONT_TINY,
                    "Set " + (i + 1) + ":  " + match.sets[i][0] + " - " + match.sets[i][1],
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        y = y + h * 0.09;
    }

    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
    dc.drawText(w / 2, h * 0.87, Gfx.FONT_XTINY, "START: exit",
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
}

// Three stacked dots (a vertical ellipsis), drawn beside the physical
// MENU/UP button as a hint that the button opens a menu -- the same
// affordance Garmin's own activity apps use.
function drawMenuGlyph(dc, cx, cy, dotR, spacing) {
    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
    for (var i = -1; i <= 1; i++) {
        dc.fillCircle(cx, cy + i * spacing, dotR);
    }
}
