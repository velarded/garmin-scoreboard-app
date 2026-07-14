# Volleyball Scoreboard (Garmin Connect IQ)

Standalone volleyball scoreboard watch app. Configure a session, score
point-by-point on the watch, and review past sessions from storage.

## Session setup

On launch you get a setup screen:

- **Sets** — number of sets to record (1–9)
- **Target** — points needed to win a set (5–50)
- **Win by 2** — Yes: set ends at target only with a 2-point lead.
  No: hard cap, set ends the moment a team reaches the target.
- **START** — begin the session
- **History** — browse saved sessions

Controls: UP/DOWN move between rows, ENTER edits a value or activates a
row (UP/DOWN adjust while editing, ENTER confirms), BACK exits.
Settings are remembered between sessions.

## During a match

| Button        | Action                          |
|---------------|---------------------------------|
| UP            | Team A +1                       |
| DOWN          | Team B +1                       |
| BACK (press)  | Undo last point / set end       |
| BACK (hold)   | End the current set manually    |
| MENU          | Quit session (with confirmation)|

Undo works across set boundaries: undoing the point that closed a set
reopens that set at its previous score.

When the configured number of sets is complete, a summary screen shows
every set score and the winner. Press START to save the session to
watch storage and return to setup.

## History

Saved sessions (up to 20, newest first) are browsable from the setup
screen: date, time, and every set score. UP/DOWN flips between sessions,
BACK returns.

## Project layout

- `source/VolleyballScoreApp.mc` — app entry point
- `source/SetupView.mc` — session configuration screen
- `source/MatchModel.mc` — match state, scoring rules, undo stack, storage
- `source/MatchView.mc` — live scoreboard and end-of-match summary
- `source/HistoryView.mc` — saved session browser

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
