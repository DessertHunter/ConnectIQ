//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//
using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.FitContributor as Fit;


const CURR_HEMO_CONC_FIELD_ID = 0;
const LAP_HEMO_CONC_FIELD_ID = 1;
const AVG_HEMO_CONC_FIELD_ID = 2;
const CURR_HEMO_PERCENT_FIELD_ID = 3;
const LAP_HEMO_PERCENT_FIELD_ID = 4;
const AVG_HEMO_PERCENT_FIELD_ID = 5;



class FitRecording {

    // @see: http://developer.garmin.com/index.php/blog/post/connect-iq-2-the-full-circle
    hidden var mEnableFitRecording = true;
    hidden var mBatteryLevelFitField; // class Toybox::FitContributor::Field
    const BATTERY_LEVEL_FIT_FIELD_ID = 666; //type=Number; The unique Field Identifier for the Field



    // Variables for computing averages
    hidden var mHCLapAverage = 0.0;
    hidden var mHCSessionAverage = 0.0;
    hidden var mHPLapAverage = 0.0;
    hidden var mHPSessionAverage = 0.0;
    hidden var mLapRecordCount = 0;
    hidden var mSessionRecordCount = 0;
    hidden var mTimerRunning = false;

    // FIT Contributions variables
    hidden var mCurrentHCField = null;
    hidden var mLapAverageHCField = null;
    hidden var mSessionAverageHCField = null;
    hidden var mCurrentHPField = null;
    hidden var mLapAverageHPField = null;
    hidden var mSessionAverageHPField = null;

    // Constructor
    function initialize(dataField) {
        mCurrentHCField = dataField.createField("currHemoConc", CURR_HEMO_CONC_FIELD_ID, Fit.DATA_TYPE_UINT16, { :nativeNum=>54, :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"g/dl" });
        mLapAverageHCField = dataField.createField("lapHemoConc", LAP_HEMO_CONC_FIELD_ID, Fit.DATA_TYPE_UINT16, { :nativeNum=>84, :mesgType=>Fit.MESG_TYPE_LAP, :units=>"g/dl" });
        mSessionAverageHCField = dataField.createField("avgHemoConc", AVG_HEMO_CONC_FIELD_ID, Fit.DATA_TYPE_UINT16, { :nativeNum=>95, :mesgType=>Fit.MESG_TYPE_SESSION, :units=>"g/dl" });

        mCurrentHPField = dataField.createField("currHemoPerc", CURR_HEMO_PERCENT_FIELD_ID, Fit.DATA_TYPE_UINT16, { :nativeNum=>57, :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"%" });
        mLapAverageHPField = dataField.createField("lapHemoConc", LAP_HEMO_PERCENT_FIELD_ID, Fit.DATA_TYPE_UINT16, { :nativeNum=>87, :mesgType=>Fit.MESG_TYPE_LAP, :units=>"%" });
        mSessionAverageHPField = dataField.createField("avgHemoConc", AVG_HEMO_PERCENT_FIELD_ID, Fit.DATA_TYPE_UINT16, { :nativeNum=>98, :mesgType=>Fit.MESG_TYPE_SESSION, :units=>"%" });

        mCurrentHCField.setData(0);
        mLapAverageHCField.setData(0);
        mSessionAverageHCField.setData(0);

        mCurrentHPField.setData(0);
        mLapAverageHPField.setData(0);
        mSessionAverageHPField.setData(0);





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
            mBatteryLevelFitField = dataField.createField("battery_level", BATTERY_LEVEL_FIT_FIELD_ID, Fit.DATA_TYPE_FLOAT, {
                :count => 1, // The number of elements to add to the field if it is an array (Default 1)
                :mesgType => FitContributor.MESG_TYPE_RECORD, // The message type that this field should be added to. Defaults to MESG_TYPE_RECORD if not provided.
                :units => "%" // The display units as a String. This should use the current device language.
                });
        }

    }

    function compute(battery_stats) {


        if( battery_stats != null ) {

            var battery_level = battery_stats.getBatteryLevel();

            if (battery_level instanceof Toybox.Lang.Float)
            {
                //Sys.print("RecordFitData BatteryLevel="); Sys.println(battery_level);
                mBatteryLevelFitField.setData(battery_level);
            }
            else
            {
                Sys.print("RecordFitData ERROR, BatteryLevel is no Float! "); Sys.println(battery_level);
                mEnableFitRecording = false;
            }

            var HemoConc = Toybox.Math.rand();
            var HemoPerc = Toybox.Math.rand();

            // Hemoglobin Concentration is stored in 1/100ths g/dL fixed point
            mCurrentHCField.setData( toFixed(HemoConc, 100) );
            // Saturated Hemoglobin Percent is stored in 1/10ths % fixed point
            mCurrentHPField.setData( toFixed(HemoPerc, 10)  );

            if( mTimerRunning ) {
                // Update lap/session data and record counts
                mLapRecordCount++;
                mSessionRecordCount++;
                mHCLapAverage += HemoConc;
                mHCSessionAverage += HemoConc;
                mHPLapAverage += HemoPerc;
                mHPSessionAverage += HemoPerc;

                // Updatea lap/session FIT Contributions
                mLapAverageHCField.setData( toFixed(mHCLapAverage/mLapRecordCount, 100) );
                mSessionAverageHCField.setData( toFixed(mHCSessionAverage/mSessionRecordCount, 100) );

                mLapAverageHPField.setData( toFixed(mHPLapAverage/mLapRecordCount, 10) );
                mSessionAverageHPField.setData( toFixed(mHPSessionAverage/mSessionRecordCount, 10) );
            }
        }
    }

    function toFixed(value, scale) {
        return ((value * scale) + 0.5).toNumber();
    }

    function setTimerRunning(state) {
        mTimerRunning = state;
    }

    function onTimerLap() {
        mLapRecordCount = 0;
        mHCLapAverage = 0.0;
        mHPLapAverage = 0.0;
    }

    function onTimerReset() {
        mSessionRecordCount = 0;
        mHCSessionAverage = 0.0;
        mHPSessionAverage = 0.0;
    }
}