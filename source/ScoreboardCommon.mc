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

// Three stacked dots (a vertical ellipsis), drawn beside the physical
// MENU/UP button as a hint that the button opens a menu -- the same
// affordance Garmin's own activity apps use.
function drawMenuGlyph(dc, cx, cy, dotR, spacing) {
    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
    for (var i = -1; i <= 1; i++) {
        dc.fillCircle(cx, cy + i * spacing, dotR);
    }
}
