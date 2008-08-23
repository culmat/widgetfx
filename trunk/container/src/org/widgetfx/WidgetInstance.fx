/*
 * WidgetFX - JavaFX Desktop Widget Platform
 * Copyright (C) 2008  Stephen Chin
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package org.widgetfx;

import java.lang.Class;
import org.widgetfx.config.*;
import com.sun.javafx.runtime.sequence.Sequence;
import com.sun.javafx.runtime.sequence.Sequences;
import com.sun.javafx.runtime.Entry;
import java.io.File;
import java.lang.System;
import javafx.application.Dialog;
import javafx.application.Stage;
import javafx.ext.swing.ComponentView;
import javafx.ext.swing.BorderPanel;
import javafx.ext.swing.Button;
import javafx.scene.HorizontalAlignment;
import javafx.ext.swing.FlowPanel;

/**
 * @author Stephen Chin
 * @author Keith Combs
 */
public class WidgetInstance {
    public attribute mainClass:String on replace {
        try {
            var widgetClass:Class = Class.forName(mainClass);
            var name = Entry.entryMethodName();
            var args = Sequences.make(java.lang.String.<<class>>) as java.lang.Object;
            widget = widgetClass.getMethod(name, Sequence.<<class>>).invoke(null, args) as Widget;
        } catch (e:java.lang.RuntimeException) {
            e.printStackTrace();
        }
    };

    public attribute id:Integer;
    public attribute opacity:Number;
    public attribute docked:Boolean;
    public attribute dockedWidth:Integer;
    public attribute dockedHeight:Integer;
    public attribute undockedX:Integer;
    public attribute undockedY:Integer;
    public attribute undockedWidth:Integer;
    public attribute undockedHeight:Integer;
    public attribute widget:Widget;
    
    // todo - possibly prevent widgets from loading if they define user properties that start with "widget."
    private attribute properties = [
        StringProperty {
            name: "widget.mainClass"
            value: bind mainClass with inverse;
        },
        NumberProperty {
            name: "widget.opacity"
            value: bind opacity with inverse;
        },
        BooleanProperty {
            name: "widget.docked"
            value: bind docked with inverse;
        },
        IntegerProperty {
            name: "widget.dockedWidth"
            value: bind dockedWidth with inverse;
        },
        IntegerProperty {
            name: "widget.dockedHeight"
            value: bind dockedHeight with inverse;
        },
        IntegerProperty {
            name: "widget.undockedX"
            value: bind undockedX with inverse;
        },
        IntegerProperty {
            name: "widget.undockedY"
            value: bind undockedY with inverse;
        },
        IntegerProperty {
            name: "widget.undockedWidth"
            value: bind undockedWidth with inverse;
        },
        IntegerProperty {
            name: "widget.undockedHeight"
            value: bind undockedHeight with inverse;
        }
    ];
    
    private attribute persister = ConfigPersister {properties: bind [properties, widget.configuration.properties], file: bind getPropertyFile()}
    
    private bound function getPropertyFile():File {
        var home = System.getProperty("user.home");
        return new File(home, ".WidgetFX/widgets/{id}.config");
    }
    
    public function load() {
        if (widget.onStart != null) widget.onStart();
        if (widget.configuration != null) {
            persister.load();
            if (widget.configuration.onLoad != null) {
                widget.configuration.onLoad();
            }
        }
    }
    
    public function save() {
        if (widget.configuration != null) {
            persister.save();
            if (widget.configuration.onSave != null) {
                widget.configuration.onSave();
            }
        }
    }
    
    public function cancel() {
        if (widget.configuration != null) {
            if (widget.configuration.onCancel != null) {
                widget.configuration.onCancel();
            }
        }
    }
    
    public function showConfigDialog():Void {
        if (widget.configuration != null) {
            var configDialog:Dialog = Dialog {
                title: "{widget.name} Configuration"
                stage: Stage {
                    content: [
                        ComponentView {
                            component: BorderPanel {
                                center: widget.configuration.component
                                bottom: FlowPanel {
                                    alignment: HorizontalAlignment.RIGHT
                                    content: [
                                        Button {
                                            text: "Save"
                                            action: function() {
                                                save();
                                                configDialog.close();
                                            }
                                        },
                                        Button {
                                            text: "Cancel"
                                            action: function() {
                                                cancel();
                                                configDialog.close();
                                            }
                                        }
                                    ]
                                }
                            }
                        }
                    ]
                }
                visible: true
            }
        }
    }
}