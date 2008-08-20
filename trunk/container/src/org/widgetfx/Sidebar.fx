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
import org.widgetfx.ui.*;
import org.widgetfx.install.InstallUtil;
import javafx.lang.*;
import javafx.scene.paint.*;
import javafx.application.*;
import javafx.application.Frame;
import javafx.scene.*;
import javafx.scene.geometry.*;
import javafx.scene.effect.*;
import javafx.input.*;
import javax.swing.*;
import javafx.scene.text.*;
import javafx.scene.layout.*;
import javafx.ext.swing.*;
import javafx.animation.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseMotionAdapter;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.util.Arrays;
import java.awt.Point;
import java.io.*;
import java.lang.System;

/**
 * @author Stephen Chin
 */
public class Sidebar extends Frame {
    static attribute DEFAULT_WIDTH = 180;
    static attribute MIN_WIDTH = 120;
    static attribute MAX_WIDTH = 400;
    static attribute BORDER = 5;
    static attribute DS_RADIUS = 5;
    
    private attribute mainMenu = createMainMenu();
    private attribute logo:Node;
    attribute widgetViews:Node[] = [];
    private attribute hoverPlaceholder;
    
    public attribute widgets = bind WidgetManager.getInstance().widgets on replace oldInst[lo..hi]=instances {
        var oldWidgets = for (inst in oldInst[lo..hi]) inst.widget;
        for (view in widgetViews where view instanceof WidgetView) {
            if (Sequences.indexOf(oldWidgets, (view as WidgetView).widget) != -1) {
                delete view from widgetViews;
            }
        }
        for (instance in instances) {
            updateWidth(instance.widget);
            var view = createWidgetView(instance.widget);
            insert view into widgetViews;
        }
    };
    
    private attribute currentGraphics:java.awt.GraphicsConfiguration;
    private attribute screenBounds = bind currentGraphics.getBounds() on replace {
        updateDockLocation();
    }
    private attribute dockLeft:Boolean on replace {
        dockRight = not dockLeft;
        updateDockLocation();
    };
    private attribute dockRight:Boolean on replace {
        dockLeft = not dockRight;
        updateDockLocation();
    };
    attribute resizing:Boolean;
    attribute dragging:Boolean;
    
    private function updateDockLocation() {
        height = screenBounds.height;
        x = screenBounds.x + (if (dockLeft) 0 else screenBounds.width - width);
        y = screenBounds.y;
    }
    
    public attribute preferredWidth = DEFAULT_WIDTH + BORDER * 2;
    
    private attribute transparentBG = bind if (dockLeft) leftBG else rightBG;
    private attribute bgOpacity = 0.7;
    private attribute leftBG = bind LinearGradient {
        endY: 0
        stops: [
            Stop {offset: 0.0, color: Color.color(0, 0, 0, bgOpacity)},
            Stop {offset: 1.0, color: Color.color(0, 0, 0, 0)}
        ]
    }
    private attribute rightBG = bind LinearGradient {
        endY: 0
        stops: [
            Stop {offset: 0.0, color: Color.color(0, 0, 0, 0)},
            Stop {offset: 1.0, color: Color.color(0, 0, 0, bgOpacity)}
        ]
    }
    
    // todo - add this to config file
    private attribute launchOnStartup:Boolean on replace {
        if (launchOnStartup) {
            InstallUtil.copyStartupFile();
        } else {
            InstallUtil.deleteStartupFile();
        }
    }
    
    init {
        windowStyle = WindowStyle.TRANSPARENT;
        width = preferredWidth;
        currentGraphics = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getDefaultConfiguration();
    }

    postinit {
        // todo - this should only happen on first invocation (maybe with a dialog)
        launchOnStartup = true;
        loadContent();
    }
    
    public function addWidget():Void {
        org.widgetfx.ui.AddWidgetDialog {}.showDialog();
    }
    
    public function createMainMenu():JPopupMenu {
        var menu = Menu {
            var alwaysOnTop:CheckBoxMenuItem = CheckBoxMenuItem {
                    text: "Always on Top"
                    action: function() {
                        window.setAlwaysOnTop(alwaysOnTop.selected);
                    }
            }
            items: [
                MenuItem {
                    text: "Add Widget..."
                    action: addWidget
                },
                alwaysOnTop,
                CheckBoxMenuItem {
                    text: "Launch on Startup"
                    selected: bind launchOnStartup with inverse
                },
                Menu {
                    var group = ToggleGroup {}
                    text: "Dock Sidebar"
                    items: [
                        RadioButtonMenuItem {
                            text: "Left"
                            toggleGroup: group
                            selected: bind dockLeft with inverse
                        },
                        RadioButtonMenuItem {
                            text: "Right"
                            toggleGroup: group
                            selected: bind dockRight with inverse
                        }
                    ]

                },
                MenuItem {
                    text: "Hide"
                    action: function() {
                        hide();
                    }
                },
                MenuItem {
                    text: "Exit"
                    action: function() {
                        System.exit(0);
                    }
                }
            ]
        }
        // todo - replace with javafx Separator when one exists
        menu.getJMenu().insertSeparator(1);
        menu.getJMenu().insertSeparator(4);
        // todo - create a javafx PopupMenu directly when one exists
        return menu.getJMenu().getPopupMenu();
    }
    
    public function hide() {
        (window as java.awt.Frame).setExtendedState(java.awt.Frame.ICONIFIED);
    }
    
    public function hover(widget:Widget, screenX:Integer, screenY:Integer):java.awt.Rectangle {
        return hover(widget, screenX, screenY, false);
    }
    
    public function hover(widget:Widget, screenX:Integer, screenY:Integer, immediate:Boolean):java.awt.Rectangle {
        if (screenX >= x and screenX < x + width and screenY >= y and screenY < y + height) {
            if (hoverPlaceholder == null) {
                hoverPlaceholder = Rectangle {
                    x: 0, y: 0, width: widget.stage.width + DS_RADIUS * 2 + 2, height: 1
                    fill: Color.rgb(0, 0, 0, 0.0);
                    horizontalAlignment: HorizontalAlignment.CENTER
                    translateX: bind width / 2 - BORDER + DS_RADIUS + 1
                };
                if (immediate) {
                    hoverPlaceholder.height = widget.stage.height + DS_RADIUS * 2 + 2;
                } else {
                    Timeline {
                        keyFrames: KeyFrame {time: 300ms, values: hoverPlaceholder.height => widget.stage.height + DS_RADIUS * 2 + 2 tween Interpolator.EASEBOTH}
                    }.start();
                }
            } else {
                delete hoverPlaceholder from widgetViews;
            }
            var inserted;
            var localY = screenY - y;
            for (view in widgetViews) {
                var viewY = view.getBoundsY() + view.getParent().getBoundsY();
                var viewHeight = view.getBoundsHeight();
                if (localY < viewY + viewHeight / 2) {
                    inserted = true;
                    insert hoverPlaceholder before widgetViews[indexof view];
                    break;
                }
            }
            if (not inserted) {
                insert hoverPlaceholder into widgetViews;
            }
            return new java.awt.Rectangle(x + hoverPlaceholder.getBoundsX(), y + hoverPlaceholder.getBoundsY() + hoverPlaceholder.getParent().getBoundsY(), widget.stage.width, widget.stage.height);
        } else {
            clearHover();
            return null;
        }
    }
    
    public function clearHover():Void {
        if (hoverPlaceholder != null) {
            Timeline {
                keyFrames: KeyFrame {time: 300ms, values: hoverPlaceholder.height => 1 tween Interpolator.EASEBOTH
                    action: function() {
                        delete hoverPlaceholder from widgetViews;
                        hoverPlaceholder = null;
                    }
                }
            }.start();
        }
    }
    
    public function dock(widget:Widget, screenX:Integer, screenY:Integer):Boolean {
        if (screenX >= x and screenX < x + width and screenY >= y and screenY < y + height) {
            for (view in widgetViews where view == hoverPlaceholder) {
                insert createWidgetView(widget) before widgetViews[indexof view];
            }
            updateWidth(widget);
            delete hoverPlaceholder from widgetViews;
            hoverPlaceholder = null;
            return true;
        }
        return false;
    }
    
    private function createWidgetView(widget:Widget):WidgetView {
        return WidgetView {
            sidebar: this
            widget: widget
            horizontalAlignment: HorizontalAlignment.CENTER
            translateX: bind width / 2 - BORDER + DS_RADIUS + 1
        }
    }
    
    private function updateWidth(widget:Widget):Void {
        updateWidth(widget, true);
    }
    
    private function updateWidth(widget:Widget, notifyResize:Boolean):Void {
        if (widget.resizable) {
            widget.stage.width = width - BORDER * 2;
            if (widget.aspectRatio != 0) {
                widget.stage.height = (widget.stage.width / widget.aspectRatio).intValue();
            }
            if (notifyResize and widget.onResize != null) {
                widget.onResize(widget.stage.width, widget.stage.height);
            }
        }
    }
    
    private function loadContent():Void {
        closeAction = function() {System.exit(0);};
        var rolloverOpacity = 0.01;
        var rolloverTimeline = Timeline {
            autoReverse: true, toggle: true
            keyFrames: KeyFrame {time: 1s, values: [rolloverOpacity => 0.8 tween Interpolator.EASEBOTH, bgOpacity => 0.8 tween Interpolator.EASEBOTH]}
        }
        logo = HBox { // Logo Text
            translateX: BORDER, translateY: BORDER
            content: [
                Text {
                    font: Font {style: FontStyle.BOLD_ITALIC}
                    fill: Color.WHITE
                    textOrigin: TextOrigin.TOP
                    content: "Widget"
                },
                Text {
                    font: Font {style: FontStyle.BOLD_ITALIC}
                    fill: Color.ORANGE
                    textOrigin: TextOrigin.TOP
                    content: "FX"
                }
            ]
        }
        var addWidgetButton = Group {
            var color = Color.GRAY;
            translateY: 7
            content: [
                Circle {
                    stroke: bind color
                    fill: Color.rgb(0, 0, 0, 0.0);
                    radius: 7
                },
                Line {
                    stroke: bind color
                    strokeWidth: 2
                    startX: -3, startY: 0
                    endX: 3, endY: 0
                },
                Line {
                    stroke: bind color
                    strokeWidth: 2
                    startX: 0, startY: -3
                    endX: 0, endY: 3
                }
            ]
            onMouseEntered: function(e) {
                color = Color.WHITE;
            }
            onMouseExited: function(e) {
                color = Color.GRAY;
            }
            onMouseClicked: function(e) {
                addWidget();
            }
        }
        var mainMenuButton:Group = Group {
            var color = Color.GRAY;
            translateY: 7
            content: [
                Circle {
                    stroke: bind color
                    fill: Color.rgb(0, 0, 0, 0.0);
                    radius: 7
                },
                Polygon {
                    stroke: bind color
                    fill: bind color
                    points: [
                        -3.0,-1.0, 
                        3.0,-1.0,
                        0.0,3.0
                    ]
                }
            ]
            onMouseEntered: function(e) {
                color = Color.WHITE;
            }
            onMouseExited: function(e) {
                color = Color.GRAY;
            }
            onMouseReleased: function(e:MouseEvent) {
                mainMenu.show(window, e.getStageX(), e.getStageY());
            }
        }
        var hideButton = Group {
            var color = Color.GRAY;
            translateY: 7
            content: [
                Circle {
                    stroke: bind color
                    fill: Color.rgb(0, 0, 0, 0.0);
                    radius: 7
                },
                Line {
                    stroke: bind color
                    strokeWidth: 2
                    startX: -3, startY: 2
                    endX: 3, endY: 2
                }
            ]
            onMouseEntered: function(e) {
                color = Color.WHITE;
            }
            onMouseExited: function(e) {
                color = Color.GRAY;
            }
            onMouseClicked: function(e) {
                hide();
            }
        }
        var menus = HBox { // Menu Buttons
            translateX: bind width, translateY: 4
            spacing: 4
            horizontalAlignment: HorizontalAlignment.TRAILING
            content: [
                addWidgetButton,
                mainMenuButton,
                hideButton
            ]

        }
        stage = Stage {
            content: [
                Group { // Drag Bar
                    content: [
                        Line {endY: bind height, stroke: Color.BLACK, strokeWidth: 1, opacity: bind rolloverOpacity / 4},
                        Line {endY: bind height, stroke: Color.BLACK, strokeWidth: 1, opacity: bind rolloverOpacity, translateX: 1},
                        Line {endY: bind height, stroke: Color.WHITE, strokeWidth: 1, opacity: bind rolloverOpacity / 3, translateX: 2}
                    ]
                    horizontalAlignment: bind if (dockLeft) HorizontalAlignment.TRAILING else HorizontalAlignment.LEADING
                    translateX: bind if (dockLeft) width else 0
                    cursor: Cursor.H_RESIZE
                    onMouseDragged: function(e:MouseEvent) {
                        resizing = true;
                        width = if (dockLeft) e.getScreenX().intValue() - screenBounds.x
                                else screenBounds.x + screenBounds.width - e.getScreenX().intValue();
                        width = if (width < MIN_WIDTH) MIN_WIDTH else if (width > MAX_WIDTH) MAX_WIDTH else width;
                        updateDockLocation();
                        for (instance in widgets) {
                            updateWidth(instance.widget, false);
                        }
                    }
                    onMouseReleased: function(e) {
                        for (instance in widgets where instance.widget.onResize != null) {
                            instance.widget.onResize(instance.widget.stage.width, instance.widget.stage.height);
                        }
                        resizing = false;
                    }
                },
                logo,
                menus,
                VBox { // Content Area
                    translateX: BORDER, translateY: bind BORDER * 2 + logo.getHeight();
                    spacing: BORDER
                    content: bind widgetViews
                }
            ],
            fill: bind transparentBG;
        };
        (window as RootPaneContainer).getContentPane().addMouseListener(MouseAdapter {
            public function mouseEntered(e) {
                rolloverTimeline.start();
            }
            public function mouseExited(e) {
                rolloverTimeline.start();
            }
        });
        (window as RootPaneContainer).getContentPane().addMouseMotionListener(MouseMotionAdapter {
            public function mouseDragged(e) {
                getGraphicsConfiguration(e.getLocationOnScreen());
            }
        });
    }
    
    private function getGraphicsConfiguration(location:Point) {
        if (not dragging and not resizing) {
            if (not screenBounds.contains(location)) {
                for (gd in Arrays.asList(java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getScreenDevices())) {
                    for (gc in Arrays.asList(gd.getConfigurations())) {
                        if (gc.getBounds().contains(location)) {
                            currentGraphics = gc;
                        }
                    }
                }
            }
            dockRight = not (dockLeft = location.x < screenBounds.width / 2 + screenBounds.x);
        }
    }
}
