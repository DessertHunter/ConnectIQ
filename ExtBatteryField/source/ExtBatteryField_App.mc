//!
//! Copyright 2016 @DessertHunter
//!
using Toybox.Application as App;
using Toybox.System as Sys;

class ExtBatteryField_App extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    //! onStart() is called on application start up
    function onStart(state) {
    }

    //! onStop() is called when your application is exiting
    function onStop(state) {
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new ExtBatteryField_View() ];
    }

    //! Called when the application settings have been changed by Garmin Connect Mobile while the app is running.
    function onSettingsChanged() {
        Sys.println("onSettingsChanged");
    }

}