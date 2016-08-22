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


    enum {
        eModeCurrentBatteryLevel = 1,
        eModeBatteryLossSinceStart,
        eModeBatteryLossPerTime,
        eModeRemainingBatteryTime
    }

    hidden var mCurrentMode = eModeCurrentBatteryLevel;
    hidden var mAutoSwitchDelay_Setting;
    hidden var mAutoSwitchDelay_Current;
    hidden var mLabel = "";
    hidden var mValue = 0.0;
    hidden var mBatteryStats; // class BatteryModule.Stats

    //! Constructor
    function initialize() {
        DataField.initialize();

        mBatteryStats = new BatteryModule.Stats();

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

        mFitRecording = new FitRecording(self);
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
            labelView.locY = labelView.locY - 16;
            var valueView = View.findDrawableById("value");
            valueView.locY = valueView.locY + 7;
        }

        View.findDrawableById("label").setText(Rez.Strings.label);
        return true;
    }

    //! The given info object contains all the current workout
    //! information. Calculate a value and save it locally in this method.
    function compute(info) {
        // See Activity.Info in the documentation for available information.

        mBatteryStats.doUpdate();

        mFitRecording.compute(mBatteryStats);

        // Wert je nach aktuellem Modus anzeigen
        if (mCurrentMode == eModeCurrentBatteryLevel)
        {
            mValue = mBatteryStats.getBatteryLevel().format("%.1f");
        }
        else if (mCurrentMode == eModeBatteryLossSinceStart)
        {
            mValue = mBatteryStats.getBatteryLoss().format("%.1f");
        }
        else if (mCurrentMode == eModeBatteryLossPerTime)
        {
            mValue = mBatteryStats.getBatteryLossPerTime(Time.Gregorian.SECONDS_PER_HOUR).format("%.3f");
        }
        else if (mCurrentMode == eModeRemainingBatteryTime)
        {
            mValue = mBatteryStats.getRemainingBatteryTime().format("%.1f");
        }
        else
        {
            // DEBUG
            mValue = 0.00;
        }

        // Modus automatisch weiterschalten?
        if (mAutoSwitchDelay_Current >= 1)
        {
            mAutoSwitchDelay_Current = mAutoSwitchDelay_Current - 1;
        }
        else
        {
            // Ablauf der Verzögerung, nächsen Modi anzeigen
            mAutoSwitchDelay_Current = mAutoSwitchDelay_Setting;

            if (mCurrentMode == eModeCurrentBatteryLevel)
            {
                mLabel = Rez.Strings.label_CurrentBatteryLevel; // "B% current"
                mCurrentMode = eModeBatteryLossSinceStart;
            }
            else if (mCurrentMode == eModeBatteryLossSinceStart)
            {
                mLabel = Rez.Strings.label_BatteryLossSinceStart; // "B% dLoss"
                mCurrentMode = eModeBatteryLossPerTime;
            }
            else if (mCurrentMode == eModeBatteryLossPerTime)
            {
                mLabel = Rez.Strings.label_BatteryLossPerTime; // "B% Loss/h"
                mCurrentMode = eModeRemainingBatteryTime;
            }
            else if (mCurrentMode == eModeRemainingBatteryTime)
            {
                mLabel = Rez.Strings.label_RemainingBatteryTime; // "tB Remaining"
                mCurrentMode = eModeCurrentBatteryLevel;
            }
            else
            {
                // DEBUG
                Sys.println("Unknown Mode=" + mCurentMode);
                mLabel = "Mode? null";
                mCurrentMode = eModeCurrentBatteryLevel;
            }
        }
    }

    //! Display the value you computed here. This will be called
    //! once a second when the data field is visible.
    function onUpdate(dc) {
        // Set the background color
        View.findDrawableById("Background").setColor(getBackgroundColor());

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
