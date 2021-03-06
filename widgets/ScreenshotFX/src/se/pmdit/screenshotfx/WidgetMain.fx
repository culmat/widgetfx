/*
 * Widget.fx
 *
 * Created on 2009-jul-05, 04:56:34
 */

package se.pmdit.screenshotfx;

import org.widgetfx.Widget;


/**
 * @author pmd
 */
public class WidgetMain extends Widget, ScreenshotFX {

    override public var width on replace {
        widgetWidth = width - 2;
    };
    override public var height on replace {
        widgetHeight = height - 2;
    };

    init {
        content = mainContent;
    }
}

public function run() {
    WidgetMain {
        width: 300
        height: 64
    };
}

