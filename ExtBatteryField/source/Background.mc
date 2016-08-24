using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;

class Background extends Ui.Drawable {

    hidden var mColor;
    hidden var mShowRecIndicator; // boolean
    const BORDER_REC = 2; // Rand links und rechts vom roten Punkt

    function initialize() {
        var dictionary = {
            :identifier => "Background"
        };

        Drawable.initialize(dictionary);

        mShowRecIndicator = false;
    }

    function setColor(color) {
        mColor = color;
    }

    function setRecording(state) {
        mShowRecIndicator = state;
    }

    function draw(dc) {
        dc.setColor(Gfx.COLOR_TRANSPARENT, mColor);
        dc.clear();
        if (mShowRecIndicator)
        {
            // Links oben erst einen roten kleinen Kreis und daneben den Text "REC" anzeigen
            var radius = 3; // TODO: dc.getFontHeight(Gfx.FONT_XTINY) / 2
            var x = BORDER_REC + radius;
            var y = 4 + radius; // TODO: dc.getFontHeight(Gfx.FONT_XTINY) / 2
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, radius);
            x = x + radius + BORDER_REC;
            y = 0;
            dc.drawText(x, y, Gfx.FONT_XTINY, "REC", Gfx.TEXT_JUSTIFY_LEFT);
        }
    }
}
