//!
//! Copyright 2016 @DessertHunter
//!
using Toybox.System as Sys;
using Toybox.Time as Time;

module BatteryModule
{
    class Stats
    {
        const MIN_DURATION_BEFORE_CALC = 30; // Mindestzeitspanne vor der Ermittlung einer Hochrechnung
        const MAX_REMAINING_SECONDS_TILL_EMPTY = 20 * Time.Gregorian.SECONDS_PER_HOUR; // Maximal errechnete Restlaufzeit in Sekunden

        enum {
            eUnitPerSecond = 1, // keine Umrechnung nötig
            eUnitPerMinute = 60, // entspricht Time.Gregorian.SECONDS_PER_MINUTE
            eUnitPerHour = 3600 // entspricht Time.Gregorian.SECONDS_PER_HOUR
        }

        hidden var mStartMoment;
        hidden var mStartBatteryLevel, mLastBatteryLevel;
        hidden var mBatteryLoss; // Float in % verbrauchte Battery seit Start
        hidden var mLossInSeconds; // Dauer in Sekunden seit Start

        //! Konstruktor
        function initialize() {
            mStartMoment = Time.now();
            mStartBatteryLevel = getBatteryLevel();
            mBatteryLoss = 0.0; // Float
            mLossInSeconds = 0; // Number
        }

        function doUpdate() {
            //var seconds = 0;
            //var duration = new Time.Duration(seconds);
            //var differnce = duration.subtract(rest);

            var newBatteryLevel = getBatteryLevel();
            if (mLastBatteryLevel != newBatteryLevel) {
                // Abweichelnder Batteriestand (egal ob größer oder kleiner)
                mLastBatteryLevel = newBatteryLevel;

                var rest = Time.now().subtract(mStartMoment); // Moment - Moment = Duration
                mLossInSeconds = rest.value();

                calcBatteryLoss();
            }
        }

        hidden function calcBatteryLoss() {
            mBatteryLoss = mLastBatteryLevel - mStartBatteryLevel;

            // DEBUG
            Sys.println("Neuer Bat_Loss=" + mBatteryLoss.format("%.2f") + "; Duration=" + mLossInSeconds);
        }

        //! Zeigt den Verbrauch in Prozent seit dem Beginn der Aktivität an
        //! Liefert positive Werte falls der Akku geladen wird, sonst negative in 0.0-100.0%
        function getBatteryLoss() {
            return mBatteryLoss; // [B% dLoss]
        }

        //! Zeigt die geschätzte Restlaufzeit an bevor die Batterie alle ist
        function getRemainingBatteryTime() {
            // Der Startbatteriestand wird geteilt durch die aktuelle Verbrauchsrate
            var secondsTillEmpty = 0.0;

            if ((MIN_DURATION_BEFORE_CALC < mLossInSeconds) && (mLossInSeconds > 0)) {
                if (mBatteryLoss < 0.0) {
                    secondsTillEmpty = mStartBatteryLevel / (-1.0 * mBatteryLoss / mLossInSeconds);
                }
                else if (mBatteryLoss > 0.0) {
                    // Batterie wird geladen, daher keine Hochrechnung möglich!
                    secondsTillEmpty = MAX_REMAINING_SECONDS_TILL_EMPTY;
                }
                else {
                    // Fehler mBatteryLoss==0, noch kein Abfall detektiert, daher keine Hochrechnung möglich!
                    secondsTillEmpty = MAX_REMAINING_SECONDS_TILL_EMPTY;
                }
            }
            else {
                // Fehler, noch nicht genügend Zeit verstrichen oder noch kein neuer Batterylevel, daher keine Hochrechnung möglich!
                secondsTillEmpty = -1.0;
            }

            return mLossInSeconds; // [min]
        }

        //! Zeigt den aktuellen Verbrauch in "Ladestand in Prozent" pro Zeit an
        function getBatteryLossPerTime(eUnit) {
            if ((eUnit == eUnitPerSecond) || (eUnit == eUnitPerMinute) || (eUnit == eUnitPerHour)) {
                if ((MIN_DURATION_BEFORE_CALC < mLossInSeconds) && (mLossInSeconds > 0)) {
                    return (mBatteryLoss / mLossInSeconds) * eUnit.toFloat(); // [B% Loss/s], [B% Loss/h] oder [B% Loss/min]
                }
                else {
                    // Noch kein Akkuverlust detektiert
                    return 0.0; // Float
                }
            }
            else {
                // DEBUG
                Sys.println("Unknown eUnit=" + eUnit);

                return -1.0; // Float
            }
        }

        //! Ermittelt den aktuellen Batteriestand in %
        static function getBatteryLevel() {
            var batt = 0.0;
            batt = Sys.getSystemStats().battery.toFloat(); // Battery life remaining in percent (Float between 0.0 and 100.0).
            //BATT_STATUS_GOOD
            return batt;
        }

    }

    var moduleVariable;
}

//function usageSample() {
//    BatteryModule.moduleVariable = new BatteryModule.Stats();
//}