using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class BackToHomeDataFieldApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }
    
    function onStart(state) {
    }

    function onStop(state) {
    }
    
    function getInitialView(){
        return [new BackToHomeDataFieldView()];
    }
    
    function onSettingsChanged(){
        Ui.requestUpdate();
    }
}