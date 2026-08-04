using Toybox.Application as App;

class VolleyballScoreApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    // A recording session outlives the app: left open, the watch keeps
    // thinking an activity is in progress and Garmin Connect stops syncing
    // stats. The Save/Discard screen is the normal way out, but the app can
    // also be closed from elsewhere, so close any session here too.
    // Saved rather than discarded, so an unexpected exit never silently bins
    // a match that was actually played.
    function onStop(state) {
        closeActivitySession(true);
    }

    function getInitialView() {
        var view = new LandingView();
        return [ view, new LandingDelegate() ];
    }
}
