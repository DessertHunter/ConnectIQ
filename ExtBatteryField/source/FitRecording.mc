//!
//! Copyright 2016 @DessertHunter
//!
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.FitContributor as Fit;


//! Kapselt die Koordination der FIT-Datei Aufzeichnung
class FitRecording {

    // FIT field IDs, type=Number; The unique Field Identifier for the Field
    const BATTERY_LEVEL_FIT_FIELD_ID = 0;
    const BATTERY_LOSS_LAP_FIT_FIELD_ID = 1;
    const BATTERY_LOSS_SUM_FIT_FIELD_ID = 2;

    // @see: http://developer.garmin.com/index.php/blog/post/connect-iq-2-the-full-circle
    hidden var mEnableFitRecording = true;

    // Variables for computing averages
    hidden var mLapRecordCount = 0;
    hidden var mSessionRecordCount = 0;
    hidden var mTimerRunning = false; // Boolean

    // FIT Contributions variables (class Toybox::FitContributor::Field)
    hidden var mBatteryLevelFitField;
    hidden var mBatteryLossLapFitField;
    hidden var mBatteryLossSumFitField;

    //! Constructor
    function initialize(dataField) {
        var app = App.getApp(); // class Application

        mEnableFitRecording = app.getProperty("enableRecording");
        if (null == mEnableFitRecording)
        {
            // Einstellung noch nicht gesetzt
            mEnableFitRecording = true;
            Sys.println("Setting enableRecording to Default");
            app.setProperty("enableRecording", mEnableFitRecording);
        }

        // Used to create a new field. Field is updated in the FIT file by changing the the value of the data within the Field. This method is to allow data fields access to FIT recording without giving them access to the session.
        if (mEnableFitRecording)
        {
            // ab ConnecIQ 1.3.0

            // Create a new field in the session.
            // Current namastes provides an file internal definition of the field
            // Field id _must_ match the fitField id in resources or your data will not display!
            // The field type specifies the kind of data we are going to store. For Record data this must be numeric, for others it can also be a string.
            // The mesgType allows us to say what kind of FIT record we are writing.
            //    FitContributor.MESG_TYPE_RECORD for graph information
            //    FitContributor.MESG_TYPE_LAP for lap information
            //    FitContributor.MESG_TYPE_SESSION` for summary information.
            // Units provides a file internal units field.
            mBatteryLevelFitField = dataField.createField("battery_level", BATTERY_LEVEL_FIT_FIELD_ID, Fit.DATA_TYPE_UINT8, {
                :count => 1, // The number of elements to add to the field if it is an array (Default 1)
                :mesgType => Fit.MESG_TYPE_RECORD, // The message type that this field should be added to. Defaults to MESG_TYPE_RECORD if not provided.
                :units => Ui.loadResource(Rez.Strings.fit0_units) // The display units as a String. This should use the current device language.
                });
            mBatteryLevelFitField.setData(0); // Default-Wert

            mBatteryLossLapFitField = dataField.createField("battery_loss_lap", BATTERY_LOSS_LAP_FIT_FIELD_ID, Fit.DATA_TYPE_UINT8, {
                :count => 1, // The number of elements to add to the field if it is an array (Default 1)
                :mesgType => Fit.MESG_TYPE_LAP, // The message type that this field should be added to. Defaults to MESG_TYPE_RECORD if not provided.
                :units => Ui.loadResource(Rez.Strings.fit0_units) // The display units as a String. This should use the current device language.
                });
            mBatteryLossLapFitField.setData(0); // Default-Wert

            mBatteryLossSumFitField = dataField.createField("battery_loss_sum", BATTERY_LOSS_SUM_FIT_FIELD_ID, Fit.DATA_TYPE_UINT8, {
                :count => 1, // The number of elements to add to the field if it is an array (Default 1)
                :mesgType => Fit.MESG_TYPE_SESSION, // The message type that this field should be added to. Defaults to MESG_TYPE_RECORD if not provided.
                :units => Ui.loadResource(Rez.Strings.fit0_units) // The display units as a String. This should use the current device language.
                });
            mBatteryLossSumFitField.setData(0); // Default-Wert
        }
        else
        {
            mBatteryLevelFitField = null;
            mBatteryLossLapFitField = null;
            mBatteryLossSumFitField = null;
        }
    }

    function compute(battery_stats) {

        if( battery_stats != null ) {

            var battery_level = toFixed( battery_stats.getBatteryLevel(), 1 );
            mBatteryLevelFitField.setData(battery_level);


            if( mTimerRunning ) {
                // Update lap/session data and record counts
                var battery_loss = toFixed( battery_stats.getBatteryLoss(), 1 );

                mLapRecordCount++;
                mSessionRecordCount++;

                // Updatea lap/session FIT Contributions
                mBatteryLossLapFitField.setData(battery_loss);
                mBatteryLossSumFitField.setData(battery_loss);
            }
        }
    }

    hidden function toFixed(value, scale) {

        if (value instanceof Toybox.Lang.Float)
        {
            return ((value * scale) + 0.5).toNumber();
        }
        else
        {
            Sys.print("RecordFitData ERROR, value is no Float! value was "); Sys.println(value);
            mEnableFitRecording = false;
            return 0;
        }
    }

    function setTimerRunning(state) {
        mTimerRunning = state;
    }

    function onTimerLap() {
        mLapRecordCount = 0;
    }

    function onTimerReset() {
        mSessionRecordCount = 0;
    }
}