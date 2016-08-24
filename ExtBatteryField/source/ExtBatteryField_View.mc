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

    hidden var mLabel = "";
    hidden var mValue = 0.0;
    hidden var mBatteryStats; // class BatteryModule.Stats

    //! Constructor
    function initialize() {
        DataField.initialize();

        mBatteryStats = new BatteryModule.Stats();
        mFitRecording = new FitRecording(self);

        reloadSettings();
    }

    //! Lädt die Einstellungen neu
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

        // "B% current"
        if (app.getProperty("showCurrentBatteryLevel")){
            mNextModeLookup[eModeCurrentBatteryLevel] = eModeBatteryLossSinceStart;
        } else {
            mNextModeLookup[eModeCurrentBatteryLevel] = eModeCurrentBatteryLevel;
        }

        // "B% dLoss"
        if (app.getProperty("showBatteryLossSinceStart")) {
            mNextModeLookup[eModeBatteryLossSinceStart] = eModeBatteryLossPerTime;
        } else {
            mNextModeLookup[eModeCurrentBatteryLevel] = eModeCurrentBatteryLevel;
        }

        // "B% Loss/h"
        if (app.getProperty("showBatteryLossPerTime")) {
            mNextModeLookup[eModeBatteryLossPerTime] = eModeRemainingBatteryTime;
        } else {
            mNextModeLookup[eModeCurrentBatteryLevel] = eModeCurrentBatteryLevel;
        }

        // "tB Remaining"
        if (app.getProperty("showRemainingBatteryTime")) {
            mNextModeLookup[eModeRemainingBatteryTime] = eModeCurrentBatteryLevel;
        } else {
            mNextModeLookup[eModeCurrentBatteryLevel] = eModeCurrentBatteryLevel;
        }
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
            labelView.locY = labelView.locY - 22;
            var valueView = View.findDrawableById("value");
            valueView.locY = valueView.locY + 12;
        }

        View.findDrawableById("label").setText(Rez.Strings.label);
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
            // Ablauf der Verzögerung, nächsen Modi anzeigen
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
            mValue = mBatteryStats.getBatteryLossPerTime(Time.Gregorian.SECONDS_PER_HOUR).format("%.2f");
        }
        else if (mCurrentMode == eModeRemainingBatteryTime)
        {
            mLabel = Rez.Strings.label_RemainingBatteryTime; // "tB Remaining"

            var remaining_mins = mBatteryStats.getRemainingBatteryTime().toNumber();
            var remaining_hours = remaining_mins / 60;
            remaining_mins = remaining_mins % 60;
            mValue = remaining_hours.format("%02u") + ":" + remaining_mins.format("%02u");
        }
        else
        {
            // DEBUG
            mValue = "?";
        }
    }

    //! Display the value you computed here. This will be called
    //! once a second when the data field is visible.
    function onUpdate(dc) {
        // Set the background color
        var bg_drawable = View.findDrawableById("Background");
        if (null != bg_drawable)
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

        if (mValue instanceof Toybox.Lang.Number)
        {
            value.setText(mValue.format("%.2f"));
        }
        else if (mValue instanceof Toybox.Lang.String)
        {
            value.setText(mValue);
        }
        else
        {
            value.setText("---");

            // DEBUG
            // System.println("Value is not a number or string!");
        }

        var label = View.findDrawableById("label");
        label.setText(mLabel);

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

    function onTimerStart() {
        mFitRecording.setTimerRunning(true);
    }

    function onTimerStop() {
        mFitRecording.setTimerRunning(false);
    }

    function onTimerPause() {
        mFitRecording.setTimerRunning(false);
    }

    function onTimerResume() {
        mFitRecording.setTimerRunning(true);
    }

    function onTimerLap() {
        mFitRecording.onTimerLap();
    }

    function onTimerReset() {
        mFitRecording.onTimerReset();
    }
}
