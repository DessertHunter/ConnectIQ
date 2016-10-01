//!
//! Copyright 2016 @DessertHunter
//!
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Time as Time;

class ExtBatteryField_View extends Ui.DataField {

    hidden var mFitRecording; // class FitRecording;

    const NUM_MODI = 4;
    enum {
        eModeCurrentBatteryLevel = 0,
        eModeBatteryLossSinceStart,
        eModeBatteryLossPerTime,
        eModeRemainingBatteryTime
    }
    hidden var mNextModeLookup = new [NUM_MODI];

    hidden var mCurrentMode = eModeCurrentBatteryLevel;
    hidden var mAutoSwitchDelay_Setting;
    hidden var mAutoSwitchDelay_Current;
    hidden var mShowCurrentBatteryLevel_Setting;
    hidden var mShowBatteryLossSinceStart_Setting;
    hidden var mShowBatteryLossPerTime_Setting;
    hidden var mShowRemainingBatteryTime_Setting;

    hidden var mLabel; // class Object oder String
    hidden var mValue; // class String oder Number
    hidden var mBatteryStats; // class BatteryModule.Stats

    //! Constructor
    function initialize() {
        DataField.initialize();

        mBatteryStats = new BatteryModule.Stats();
        mFitRecording = new FitRecording(self);

        reloadSettings();
    }

    //! L�dt die Einstellungen neu
    function reloadSettings() {
        var app = App.getApp(); // class Application

        mAutoSwitchDelay_Setting = app.getProperty("autoSwitchDelay");
        if (null == mAutoSwitchDelay_Setting)
        {
            // Einstellung noch nicht gesetzt
            mAutoSwitchDelay_Setting = 2;
            Sys.println("Setting autoSwitchDelay to Default");
            app.setProperty("autoSwitchDelay", mAutoSwitchDelay_Setting);
        }
        mAutoSwitchDelay_Current = mAutoSwitchDelay_Setting;

        // Reihenfolge: 1->2->3->4->1-> ...
        for (var i = 0; i < NUM_MODI; i += 1) {
            mNextModeLookup[i] = evaluateNextMode(i);
        }
    }

    //! Ermittelt rekursiv den n�chsten Modus, anhand der Applikationseinstellungen
    hidden function evaluateNextMode(mode) {
        var app = App.getApp(); // class Application
        var next_mode = eModeCurrentBatteryLevel; // Fallback

        if (mode == eModeCurrentBatteryLevel) // 1: "B% current"
        {
            next_mode = eModeBatteryLossSinceStart; // 1->2
            if (false == app.getProperty("showBatteryLossSinceStart")) {
                next_mode = evaluateNextMode(next_mode); // Feld ist ausgeblendet, n�chstes anzuzeigendes Feld suchen
            }
        }
        else if (mode == eModeBatteryLossSinceStart) // 2: "B% dLoss"
        {
            next_mode = eModeBatteryLossPerTime; // 2->3
            if (false == app.getProperty("showBatteryLossPerTime")) {
                next_mode = evaluateNextMode(next_mode); // Feld ist ausgeblendet, n�chstes anzuzeigendes Feld suchen
            }
        }
        else if (mode == eModeBatteryLossPerTime) // 3: "B% Loss/h"
        {
            next_mode = eModeRemainingBatteryTime; // 3->4
            if (false == app.getProperty("showRemainingBatteryTime")) {
                next_mode = evaluateNextMode(next_mode); // Feld ist ausgeblendet, n�chstes anzuzeigendes Feld suchen
            }
        }
        else if (mode == eModeRemainingBatteryTime) // 4: "tB Remaining"
        {
            next_mode = eModeCurrentBatteryLevel; // 4->1 (neue Runde)
            if (false == app.getProperty("showCurrentBatteryLevel")) {
                // DEBUG
                Sys.println("Property showCurrentBatteryLevel is not FALSE!");
            }
        }
        else
        {
            // DEBUG
            Sys.print("evaluateNextMode Unknown Mode "); Sys.println(mode);
        }
        return next_mode;
    }

    //! Set your layout here. Anytime the size of obscurity of
    //! the draw context is changed this will be called.
    function onLayout(dc) {
        var obscurityFlags = DataField.getObscurityFlags();

        // Top left quadrant so we'll use the top left layout
        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.TopLeftLayout(dc));

        // Top right quadrant so we'll use the top right layout
        } else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.TopRightLayout(dc));

        // Bottom left quadrant so we'll use the bottom left layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.BottomLeftLayout(dc));

        // Bottom right quadrant so we'll use the bottom right layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.BottomRightLayout(dc));

        // Use the generic, centered layout
        } else {
            View.setLayout(Rez.Layouts.MainLayout(dc));
            var labelView = View.findDrawableById("label");
            labelView.locY = labelView.locY - 20; // vom 'center' bisschen nach oben verschieben
            var valueView = View.findDrawableById("value");
            valueView.locY = valueView.locY + 12; // vom 'center' bisschen nach unten verschieben
        }

        return true;
    }

    //! The given info object contains all the current workout
    //! information. Calculate a value and save it locally in this method.
    function compute(info) {
        // See Activity.Info in the documentation for available information.

        // Zuerst neue Statistiken erstellen
        mBatteryStats.doUpdate();

        // Aufzeichnungswerte aktualisieren
        mFitRecording.compute(mBatteryStats);

        // Modus automatisch weiterschalten?
        if (mAutoSwitchDelay_Current >= 1)
        {
            mAutoSwitchDelay_Current = mAutoSwitchDelay_Current - 1;
        }
        else
        {
            // Ablauf der Verz�gerung, n�chsen Modi anzeigen
            mAutoSwitchDelay_Current = mAutoSwitchDelay_Setting;
            mCurrentMode = mNextModeLookup[mCurrentMode];
        }

        // GUI-Wert je nach aktuellem Modus anzeigen
        if (mCurrentMode == eModeCurrentBatteryLevel)
        {
            mLabel = Rez.Strings.label_CurrentBatteryLevel; // "B% current"
            mValue = mBatteryStats.getBatteryLevel().format("%u") + "%";
        }
        else if (mCurrentMode == eModeBatteryLossSinceStart)
        {
            mLabel = Rez.Strings.label_BatteryLossSinceStart; // "B% dLoss"
            mValue = mBatteryStats.getBatteryLoss().format("%+d") + "%";
        }
        else if (mCurrentMode == eModeBatteryLossPerTime)
        {
            mLabel = Rez.Strings.label_BatteryLossPerTime; // "B% Loss/h"
            mValue = mBatteryStats.getBatteryLossPerTime(Time.Gregorian.SECONDS_PER_HOUR).format("%.1f"); // Eine Nachkommstelle anzeigen
        }
        else if (mCurrentMode == eModeRemainingBatteryTime)
        {
            mLabel = Rez.Strings.label_RemainingBatteryTime; // "tB Remaining"

            var remaining_seconds = mBatteryStats.getRemainingBatteryTime(); // [s]
            if (remaining_seconds != BatteryModule.Stats.INVALID_REMAINING_BATTERY_TIME) {
                var remaining_mins = remaining_seconds / Time.Gregorian.SECONDS_PER_MINUTE;
                var remaining_hours = remaining_mins / 60;
                remaining_mins = remaining_mins % 60;
                remaining_seconds = remaining_seconds % 60;
                mValue = remaining_hours.format("%u") + ":" + remaining_mins.format("%02u") + ":" + remaining_seconds.format("%02u");
            } else {
                mValue = Rez.Strings.no_value;
            }
        }
        else
        {
            // DEBUG
            mValue = "? MODE ?";
        }
    }

    //! Display the value you computed here. This will be called
    //! once a second when the data field is visible.
    function onUpdate(dc) {
        // Set the background color
        var bg_drawable = View.findDrawableById("Background");
        if (bg_drawable instanceof Background)
        {
            bg_drawable.setColor(getBackgroundColor());
            bg_drawable.setRecording(mFitRecording.getIsRecording());
        }

        // Set the foreground color and value
        var value = View.findDrawableById("value");
        if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            value.setColor(Gfx.COLOR_WHITE);
        } else {
            value.setColor(Gfx.COLOR_BLACK);
        }

        if (mValue instanceof Toybox.Lang.Number) {
            value.setText(mValue.format("%.2f"));
        } else if (mValue instanceof Toybox.Lang.String) {
            value.setText(mValue);
        } else {
            value.setText(Rez.Strings.no_value);
        }

        var label = View.findDrawableById("label");
        if ((mLabel instanceof Toybox.Lang.Object) || (mLabel instanceof Toybox.Lang.String)) {
            label.setText(mLabel);
        } else {
            label.setText(Rez.Strings.no_value);
        }

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

    //! The timer was started, so set the state to running.
    function onTimerStart() {
        mFitRecording.setTimerRunning(true);
    }

    //! The timer was stopped, so set the state to stopped.
    function onTimerStop() {
        mFitRecording.setTimerRunning(false);
    }

    //! The timer was started, so set the state to running.
    function onTimerPause() {
        mFitRecording.setTimerRunning(false);
    }

    //! The timer was stopped, so set the state to stopped.
    function onTimerResume() {
        mFitRecording.setTimerRunning(true);
    }

    //! This is called each time a lap is created, so increment the lap number.
    function onTimerLap() {
        mFitRecording.onTimerLap();
    }

    //! The timer was reeset, so reset all our tracking variables
    function onTimerReset() {
        mFitRecording.onTimerReset();
    }
}
