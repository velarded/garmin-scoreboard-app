using Toybox.Application as App;

class VolleyballScoreApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        var view = new LandingView();
        return [ view, new LandingDelegate() ];
    }
}
