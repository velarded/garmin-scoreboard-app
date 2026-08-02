# SetPoint (Garmin Connect IQ)

Standalone volleyball scoreboard watch app. Score point-by-point on the
watch and track serve rotations.

## Data pages

The app opens on **Landing** and cycles through three pages with UP/MENU:

```
not recording:   Landing  ->  Primary  ->  Secondary  ->  Landing  (loop)
recording:                    Primary  <->  Secondary            (Landing hidden)
```

Once a session starts, Landing drops out of the cycle so a live match can't
be navigated away from by accident.

- **Landing** — "Volleyball" title, a green-dot **Ready** status, and the
  current time in the bottom half.
- **Primary scoreboard** — current time with elapsed set time underneath,
  Home/Away scores with each team's sets won, heart rate, and set number.
- **Secondary scoreboard** — serve and rotation: each side's label, score,
  sets won and current rotation position, with a volleyball icon on
  whichever side is serving. Current time along the bottom.

## Buttons

On **Landing**:

| Button | Action |
|---|---|
| MENU/UP | open Setup |
| DOWN | browse the scoreboards (not recording) |
| START | "Start" popup, then begin recording on the Primary scoreboard |
| BACK | exit the app |

On **either scoreboard** (identical on both):

| Button | Action |
|---|---|
| UP / MENU | cycle data pages |
| DOWN | **Home** +1 point |
| BACK (quick) | **Away** +1 point |
| BACK (hold) | undo last point |
| START | not recording → begin recording; recording → "Stop" popup, then Pause |

Scoring and undo are inert until a session is actually recording; page
cycling always works. Undo works across set boundaries — undoing the point
that closed a set reopens that set at its previous score, and restores the
serve and rotation state with it.

## Serve rotation

Official side-out rules: the serving team keeps serving and does **not**
rotate when it scores; a team that wins a point while receiving takes serve
and rotates `1 → 2 → 3 → 4 → 5 → 6 → 1`.

The app can't know who served first, so it asks once per set:

1. Set opens 0–0 — both sides show "Position 1", no serve icon.
2. First point of the set (either team) — that team gets the volleyball icon;
   both stay at Position 1.
3. The **other** team's first point of the set → prompt **"Stay 1 on serve?"**
   — Yes keeps them at Position 1, No moves them to Position 2.
4. Every later side-out rotates normally.

## Setup

Opened with MENU from Landing. Settings are remembered between sessions.

- **Sets** — number of sets to record (1–9)
- **Points per Set** — points needed to win a set (5–50)
- **Win by 2** — Yes: set ends at target only with a 2-point lead.
  No: hard cap, set ends the moment a team reaches the target.

UP/DOWN move between rows, ENTER edits a value (UP/DOWN adjust while
editing, ENTER confirms), BACK returns to Landing.

## Pause screen

START during a session shows a "Stop" popup with the device's native stop
tone, then opens the Pause menu: Resume, **Undo Last Point**, End Set,
Points History, Sets History, Quit.

- **Points History** — a scrollable, 3-column table (#, elapsed set time,
  score) of every point in the current set, e.g. row 3 at 05:01 showing
  "2-1", newest entries at the bottom.
- **Sets History** — a scrollable list of the final score of every completed
  set so far, e.g. "Set 1:  25 - 20".

Both scroll with UP/DOWN; BACK returns to Pause. Quitting returns to Landing.

When the configured number of sets is complete, a summary screen shows every
set score and the winner. Press START to return to Landing.

## Project layout

- `source/VolleyballScoreApp.mc` — app entry point
- `source/LandingView.mc` — home screen
- `source/SetupView.mc` — session configuration
- `source/MatchModel.mc` — match state, scoring, serve/rotation, undo stack
- `source/ScoreboardCommon.mc` — shared drawing/formatting helpers
- `source/ScoreboardPrimaryView.mc` — primary scoreboard, shared scoreboard
  button handling, end-of-match summary
- `source/ScoreboardSecondaryView.mc` — serve and rotation display
- `source/StartPopupView.mc` / `source/StopPopupView.mc` — brief start/stop confirmations
- `source/PauseView.mc` — mid-match pause menu
- `source/PointsHistoryView.mc` — point-by-point history for the active set
- `source/SetsHistoryView.mc` — completed sets' final scores

## Build

Open in VS Code with the Monkey C extension, then Run → Start Debugging
(or `monkeyc -f monkey.jungle -d fr255 -o bin/app.prg -y <developer_key>`).
Supported products are listed in `manifest.xml` (fenix7, fr165, fr255, venu2,
vivoactive4).

## Known limitations to plan around

**Button hold detection is unreliable on real hardware.** Detecting a long
press needs the raw `onKeyPressed`/`onKeyReleased` pair, which is a
documented, longstanding Connect IQ gap — it works in the simulator but is
unreliable or silently absent on much real hardware, the fr255 included.
BACK-hold-to-undo is therefore expected **not to work on the fr255**; use
Pause → **Undo Last Point** instead, which uses only the reliable `onKey()`
path. BACK is wired so that on those devices the quick press still scores the
Away point via the `onBack()` behavior callback. Every other control in the
app uses plain `onKey()` or a behavior callback.

**Foreground-only input.** Physical button presses only reach the app while
it's in the foreground. If the watch screen times out mid-game, the first
press just wakes the screen. Disable auto-sleep in display settings during
play, or use a "wake, then press" rhythm.
