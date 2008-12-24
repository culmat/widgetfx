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

 * This particular file is subject to the "Classpath" exception as provided
 * in the LICENSE file that accompanied this code.

 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package org.widgetfx;

import org.jfxtras.scene.*;
import org.widgetfx.toolbar.WidgetToolbar;
import org.widgetfx.ui.*;
import java.awt.Point;
import java.lang.*;
import javafx.animation.*;
import javafx.geometry.*;
import javafx.lang.*;
import javafx.scene.*;
import javafx.scene.effect.*;
import javafx.scene.input.*;
import javafx.scene.shape.*;
import javafx.scene.layout.*;
import javafx.scene.paint.*;
import javafx.scene.transform.*;
import javafx.stage.*;
import javax.swing.JPanel;
import javax.swing.RootPaneContainer;

/**
 * @author Stephen Chin
 */
public var TOP_BORDER = 13;
public var BOTTOM_BORDER = 7;

public class WidgetView extends CacheSafeGroup, Constrained, DragContainer {
    public-init var container:WidgetContainer;
    
    var resizing = false;
    
    var dockedParent:Group;
    
    var scale:Number = bind calculateScale();
    
    bound function calculateScale():Number {
        return if (not widget.resizable) {
            var widthScale = if (maxWidth == Constrained.UNBOUNDED) 1.0 else maxWidth / widget.width;
            var heightScale = if (maxHeight == Constrained.UNBOUNDED) 1.0 else maxHeight / widget.height;
            var scale = Math.min(widthScale, heightScale);
            if (scale > 1) 1.0 else scale;
        } else {
            1.0;
        }
    }

    var toolbar:WidgetToolbar;
    
    public var widgetHover = false;

    var flashHover = bind if (widget instanceof FlashWidget) then (widget as FlashWidget).widgetHovering else false;
    
    var hovering = bind widgetHover or flashHover on replace {
        FX.deferAction(
            function():Void {
                var newRate = if (hovering) 1 else -1;
                if (rolloverTimeline.rate != newRate) {
                    rolloverTimeline.rate = newRate;
                    rolloverTimeline.play();
                }
            }
        )
    }
    
    var rolloverOpacity = 0.0;
    var rolloverTimeline = Timeline {
        keyFrames: at (500ms) {rolloverOpacity => 1.0 tween Interpolator.EASEIN}
    }
    
    function resize(oldMaxWidth:Number, oldMaxHeight:Number) {
        if (instance.widget.resizable) {
            var widthMaximized = oldMaxWidth == instance.widget.width;
            var heightMaximized = oldMaxHeight == instance.widget.height;
            if (maxWidth != Constrained.UNBOUNDED) {
                instance.setWidth(maxWidth);
            }
            if (maxHeight != Constrained.UNBOUNDED) {
                instance.setHeight(maxHeight);
            }
            if (instance.widget.aspectRatio != 0) {
                var currentRatio = (instance.widget.width as Number) / instance.widget.height;
                if (widthMaximized and maxHeight == Constrained.UNBOUNDED) {
                    // unbounded height, keep the width maximized
                    instance.setHeight(instance.widget.width / instance.widget.aspectRatio);
                } else if (heightMaximized and maxWidth == Constrained.UNBOUNDED) {
                    // unbounded width, keep the height maximized
                    instance.setWidth(instance.widget.aspectRatio * instance.widget.height);
                } else {
                    // bounded, fit proportionally
                    if (currentRatio > instance.widget.aspectRatio) {
                        instance.setWidth(instance.widget.aspectRatio * instance.widget.height);
                    } else {
                        instance.setHeight(instance.widget.width / instance.widget.aspectRatio);
                    }
                }
            }
        }
    }
    
    override var translateX on replace {
        updateFlashBounds();
    }
    
    override var translateY on replace {
        updateFlashBounds();
    }
    
    override var impl_layoutX on replace {
        updateFlashBounds();
    }
    
    override var impl_layoutY on replace {
        updateFlashBounds();
    }
    
    override var maxWidth on replace oldMaxWidth {
        resize(oldMaxWidth as Number, maxHeight);
        updateFlashBounds();
    }
    
    override var maxHeight on replace oldMaxHeight {
        resize(maxWidth, oldMaxHeight as Number);
        updateFlashBounds();
    }
    
    override var cache = true;
    
    init {
        content = [
            Rectangle { // Invisible Spacer
                height: bind widget.height * scale + TOP_BORDER + BOTTOM_BORDER
                width: bind maxWidth
                fill: Color.rgb(0, 0, 0, 0.0)
            },
            CacheSafeGroup { // Widget with DropShadow
                translateY: TOP_BORDER
                translateX: bind (maxWidth - widget.width * scale) / 2
                cache: true
                content: Group { // Alert
                    effect: bind if (widget.alert) DropShadow {color: Color.RED, radius: 12} else null
                    content: Group { // Drop Shadow
                        effect: bind if (resizing or not container.drawShadows) null else DropShadow {offsetX: 2, offsetY: 2, radius: Dock.DS_RADIUS}
                        content: Group { // Clip Group
                            content: widget
                            clip: Rectangle {width: bind widget.width, height: bind widget.height, smooth: false}
                            transforms: bind Transform.scale(scale, scale)
                        }
                    }
                }
            },
            toolbar = WidgetToolbar {
                blocksMouse: true
                translateX: bind (maxWidth + widget.width * scale) / 2 - toolbar.boundsInLocal.maxX
                opacity: bind rolloverOpacity
                instance: instance
                onClose: function() {
                    removeFlash();
                    WidgetManager.getInstance().removeWidget(instance);
                }
            },
            Group { // Drag Bar
                blocksMouse: true
                translateX: -2
                translateY: bind widget.height * scale + TOP_BORDER + BOTTOM_BORDER - 3
                content: [
                    Line {endX: bind maxWidth + 4, stroke: Color.BLACK, strokeWidth: 1, opacity: bind container.rolloverOpacity * .175 / 4},
                    Line {endX: bind maxWidth + 4, stroke: Color.BLACK, strokeWidth: 1, opacity: bind container.rolloverOpacity * .7, translateY: 1},
                    Line {endX: bind maxWidth + 4, stroke: Color.WHITE, strokeWidth: 1, opacity: bind container.rolloverOpacity * .23, translateY: 2}
                ]
                cursor: Cursor.V_RESIZE
                var initialHeight;
                var initialY;
                onMousePressed: function(e:MouseEvent) {
                    if (widget.resizable) {
                        resizing = true;
                        initialHeight = widget.height * scale;
                        initialY = e.sceneY.intValue();
                    }
                }
                onMouseDragged: function(e:MouseEvent) {
                    if (resizing) {
                        instance.setHeight(initialHeight + (e.sceneY.intValue() - initialY) / scale);
                        if (widget.height < WidgetInstance.MIN_HEIGHT) {
                            instance.setHeight(WidgetInstance.MIN_HEIGHT);
                        }
                        if (widget.aspectRatio != 0) {
                            instance.setWidth(widget.height * widget.aspectRatio);
                            if (widget.width > maxWidth) {
                                instance.setWidth(maxWidth);
                                instance.setHeight(widget.width / widget.aspectRatio);
                            }
                        }
                        updateFlashBounds();
                        container.layout.doLayout();
                    }
                }
                onMouseReleased: function(e) {
                    if (resizing) {
                        if (widget.onResize != null) {
                            widget.onResize(widget.width, widget.height);
                        }
                        instance.saveWithoutNotification();
                        resizing = false;
                    }
                }
            }
        ];
        addFlash();
    };
    
    override var onMousePressed = function(e:MouseEvent):Void {
        if (e.button == MouseButton.PRIMARY) {
            prepareDrag(e.x, e.y, e.screenX, e.screenY);
        }
    }

    override var onMouseDragged = function(e:MouseEvent):Void {
        if (not docking) {
        	doDrag(e.screenX, e.screenY);
		}
    };
    
    override var onMouseReleased = function(e:MouseEvent):Void {
        if (e.button == MouseButton.PRIMARY) {
            finishDrag(e.screenX, e.screenY);
        }
    }

    override var hoverContainer on replace {
        if (instance.frame != null) {
            instance.frame.hoverContainer = hoverContainer;
        }
    }
    
    override function doDrag(screenX:Number, screenY:Number) {
        if (not docking and dragging) {
            container.dragging = true;
            if (instance.docked) {
                flashPanel.setVisible(false);
                var bounds = container.layout.getScreenBounds(this);
                var xPos = (bounds.minX + (bounds.width - widget.width * scale) / 2 - WidgetFrame.BORDER).intValue();
                var toolbarHeight = if (instance.widget.configuration == null) WidgetFrame.NONRESIZABLE_TOOLBAR_HEIGHT else WidgetFrame.RESIZABLE_TOOLBAR_HEIGHT;
                var yPos = bounds.minY + TOP_BORDER - (WidgetFrame.BORDER + toolbarHeight);
                instance.frame = WidgetFrame {
                    instance: instance
                    x: xPos, y: yPos
                    style: if (WidgetFXConfiguration.TRANSPARENT and not (widget instanceof FlashWidget)) StageStyle.TRANSPARENT else StageStyle.UNDECORATED
                }
                if (widget instanceof FlashWidget) {
                    var flash = widget as FlashWidget;
                    flash.dragContainer = this;
                }
                instance.docked = false;
            }
            DragContainer.doDrag(screenX, screenY);
        }
    }
    
    override function dragComplete(dragListener:WidgetDragListener, targetBounds:Rectangle2D):Void {
        container.dragging = false;
        removeFlash();
        if (targetBounds != null) {
            docking = true;
            instance.frame.dock(dragListener as WidgetContainer, targetBounds.minX + (targetBounds.width - widget.width) / 2, targetBounds.minY);
        } else {
            // todo - don't call this block multiple times
            if (instance.widget.onResize != null) {
                instance.widget.onResize(instance.widget.width, instance.widget.height);
            }
            if (widget instanceof FlashWidget) {
                var flash = widget as FlashWidget;
                flash.dragContainer = instance.frame;
            }
            if (instance.widget.onUndock != null) {
                instance.widget.onUndock();
            }
        }
    }
    
    var flashPanel:JPanel;
    
    function addFlash() {
        if (widget instanceof FlashWidget) {
            var flash = widget as FlashWidget;
            flashPanel = flash.createPlayer();
            var layeredPane = (container.window as RootPaneContainer).getLayeredPane();
            layeredPane.add(flashPanel, new java.lang.Integer(1000));
            updateFlashBounds();
            flash.dragContainer = this;
        }
    }
    
    function removeFlash() {
        if (flashPanel != null) {
            var layeredPane = (container.window as RootPaneContainer).getLayeredPane();
            layeredPane.remove(flashPanel);
            flashPanel = null;
        }
    }
    
    function updateFlashBounds() {
        if (flashPanel != null) {
            var location = localToScene(0, 0);
            flashPanel.setBounds(location.x, location.y + TOP_BORDER, widget.width, widget.height);
        }
    }
}
