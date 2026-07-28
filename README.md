# SetPoint (Garmin Connect IQ)

Standalone volleyball scoreboard watch app. Configure a session and
score point-by-point on the watch.

## Session setup

On launch you get a setup screen:

- **Sets** — number of sets to record (1–9)
- **Points per Set** — points needed to win a set (5–50)
- **Win by 2** — Yes: set ends at target only with a 2-point lead.
  No: hard cap, set ends the moment a team reaches the target.
- **START** — begin the session

Controls: UP/DOWN move between rows, ENTER edits a value or activates a
row (UP/DOWN adjust while editing, ENTER confirms), BACK exits.
Settings are remembered between sessions.

## During a match

The live match has 3 swappable data pages: **Scoreboard**, **Server
Tracking**, and **Point Progression** (the latter two are placeholders
for now). The Scoreboard page shows the current time, Home/Away scores
with each team's sets won, heart rate, and the current set number.

| Button                        | Scoreboard page        | Server Tracking / Point Progression |
|--------------------------------|-------------------------|--------------------------------------|
| UP                              | Home +1                 | Previous page (wraps, incl. Scoreboard) |
| DOWN                            | Away +1                 | Next page (wraps, incl. Scoreboard) |
| MENU (short press)              | Home +1                 | —                                    |
| MENU (long press)               | Jump to Server Tracking | —                                    |
| BACK                             | Undo last point          | same                                 |
| START/ENTER                     | Brief "Stop" popup, then Pause screen | same |

Undo works across set boundaries: undoing the point that closed a set
reopens that set at its previous score.

Pressing START/ENTER briefly shows a "Stop" popup (mirroring Garmin's
native Stop-activity confirmation) before opening the Pause screen, where
you can resume, manually end the current set, or quit the session (with
confirmation).

When the configured number of sets is complete, a summary screen shows
every set score and the winner. Press START to return to setup.

## Project layout

- `source/VolleyballScoreApp.mc` — app entry point
- `source/SetupView.mc` — session configuration screen
- `source/MatchModel.mc` — match state, scoring rules, undo stack
- `source/MatchView.mc` — live scoreboard (3 data pages) and end-of-match summary
- `source/PauseView.mc` — mid-match pause menu (Resume / End Set / Quit)
- `source/StopPopupView.mc` — brief "Stop" confirmation shown before the Pause screen

## Build

Open in VS Code with the Monkey C extension, then Run → Start Debugging
(or `monkeyc -f monkey.jungle -d fr255 -o bin/app.prg -y <developer_key>`).
Supported products are listed in `manifest.xml` (fenix7, fr255, venu2,
vivoactive4).

## Known limitation to plan around

Physical button presses only reach the app while it's in the foreground.
If the watch screen times out mid-game, the first press just wakes the
screen. Disable auto-sleep in display settings during play, or use a
"wake, then press" rhythm.
