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
package org.widgetfx.widget.slideshow;

import org.widgetfx.*;
import org.widgetfx.config.*;
import org.widgetfx.util.*;
import javafx.application.*;
import javafx.ext.swing.*;
import javafx.scene.*;
import javafx.scene.geometry.*;
import javafx.scene.paint.*;
import javafx.scene.image.*;
import javafx.scene.text.*;
import javafx.util.*;
import javafx.animation.*;
import javafx.lang.*;
import javax.imageio.*;
import java.io.*;
import java.util.*;
import java.lang.*;
import javax.swing.*;

/**
 * @author Stephen Chin
 * @author Keith Combs
 */
var home = System.getProperty("user.home");
var defaultDirectories:File[] = [
    new File(home, "Pictures"),
    new File(home, "My Documents\\My Pictures"),
    new File(home)
][d|d.exists()];
var directoryName = (defaultDirectories[0]).getAbsolutePath();
var directory:File;
var status = "Loading Images...";
var imageFiles:File[];
var random = true;
var keywords : String;
var width = 150;
var height = 100;
var imageIndex = 0;
var imageHeight:Integer;
var currentFile:File;
var currentImage:Image;
var worker:JavaFXWorker;
var timeline = Timeline {
    repeatCount: Timeline.INDEFINITE
    keyFrames: [
        KeyFrame {time: 0s,
            action: function() {
                currentFile = imageFiles[imageIndex++ mod imageFiles.size()];
                updateImage();
            }
        },
        KeyFrame {time: 10s}
    ]
}

private function updateImage():Void {
    if (not currentFile.exists()) {
        currentImage = null;
        status = "Missing File: {currentFile}";
        return;
    }
    if (worker != null) {
        worker.cancel();
    }
    worker = JavaFXWorker {
        inBackground: function() {
            return Image {url: currentFile.toURL().toString(), height: imageHeight};
        }
        onDone: function(result) {
            currentImage = result as Image;
            status = null;
        }
    }
}

private function loadDirectory(directoryName:String):File {
    var directory = new File(directoryName);
    if (not directory.exists()) {
        status = "Directory Doesn't Exist";
    } else {
        timeline.stop();
        if (worker != null) {
            worker.cancel();
        }
        currentImage = null;
        status = "Loading Images...";
        imageFiles = getImageFiles(directory);
        if (imageFiles.size() > 0) {
            if (random) {
                imageFiles = Sequences.shuffle(imageFiles) as File[];
            }
            timeline.start();
        } else {
            status = "No Images Found"
        }
    }
    return directory;
}

private function excludesFile(name:String):Boolean {
    if (keywords != null and keywords.length() > 0) {
        if (name.toLowerCase().contains(keywords.toLowerCase())) {
            return true;
        }
    }
    return false;
}

private function getImageFiles(directory:File):File[] {
    var emptyFile:File[] = [];
    var files = Arrays.asList(directory.listFiles());
    return for (file in files) {
        var name = file.getName();
        if (excludesFile(name)) {
            emptyFile;
        } else {
            var index = name.lastIndexOf('.');
            var extension = if (index == -1) null else name.substring(index + 1);
            if (file.isDirectory()) {
                getImageFiles(file);
            } else if (extension != null and ImageIO.getImageReadersBySuffix(extension).hasNext()) {
                file;
            } else {
                emptyFile;
            }
        }
    }
}

var browseButton:Button = Button {
    text: "Browse...";
    action: function() {
        var chooser:JFileChooser = new JFileChooser(directoryName);
        chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
        var returnVal = chooser.showOpenDialog(browseButton.getJButton());
        if (returnVal == JFileChooser.APPROVE_OPTION) {
            directoryName = chooser.getSelectedFile().getAbsolutePath();
        }
    }
}

var keywordLabel = Label {text: "Filter:"};
var keywordEdit = TextField {text: bind keywords with inverse, hpref: 300};
var directoryLabel = Label {text: "Directory:"};
var directoryEdit = TextField {text: bind directoryName with inverse, hpref: 300};

var shuffleCheckBox = CheckBox {text: "Shuffle"};
var durationLabel = Label {text: "Duration"};

// todo - replace with javafx spinner when one exists
var durationSpinner = new JSpinner();
var durationSpinnerComponent = Component.fromJComponent(durationSpinner);
durationSpinnerComponent.hmax = 52;

var displayTab = ClusterPanel {
    hcluster: ParallelCluster {
        content: [
            shuffleCheckBox,
            SequentialCluster {
                content: [
                    durationLabel,
                    durationSpinnerComponent
                ]
            }
        ]
    }
    vcluster: SequentialCluster {
        content: [
            shuffleCheckBox,
            ParallelCluster {
                content: [
                    durationLabel,
                    durationSpinnerComponent
                ]
            }
        ]
    }
}

var contentTab = ClusterPanel {
    vcluster: ParallelCluster {
        content: [
            directoryLabel,
            directoryEdit,
            browseButton,
        ]
    },
    hcluster: SequentialCluster {
        content: [
            ParallelCluster {
                content:[
                    directoryLabel,
                    keywordLabel,
                ]
            },
            ParallelCluster {
                content:[
                    SequentialCluster {
                        content:[
                            directoryEdit,
                            browseButton
                        ]
                    },
                    keywordEdit
                ]
            }
        ]
    }
    vcluster : SequentialCluster {
        content:[
            ParallelCluster{
                content: [
                    directoryLabel,
                    directoryEdit,
                    browseButton
                ]
            },
            ParallelCluster {
                content : [
                    keywordLabel,
                    keywordEdit
                ]
            }
        ]
    }
}

// todo - replace with a javafx component when one is available
var tabbedPane = new JTabbedPane();
tabbedPane.add("display", displayTab.getJPanel());
tabbedPane.add("content", contentTab.getJPanel());

Widget {
    name: "Slide Show"
    resizable: true
    aspectRatio: 4.0/3.0
    configuration: Configuration {
        properties: [
            StringProperty {
                name: "directoryName"
                value: bind directoryName with inverse
            },
            BooleanProperty {
                name: "random"
                value: bind random with inverse
            },
            StringProperty {
                name : "keywords"
                value : bind keywords with inverse
            }
        ]

        component: Component.fromJComponent(tabbedPane)

        onLoad: function() {
            imageHeight = height;
            loadDirectory(directoryName);
        }
        onSave: function() {
            loadDirectory(directoryName);
        }
    }
    stage: Stage {
        width: bind width with inverse
        height: bind height with inverse
        content: [
            Group {
                content: [
                    Rectangle {
                        width: bind width
                        height: bind height
                        fill: Color.BLACK
                        arcWidth: 8, arcHeight: 8
                    },
                    Text {
                        translateY: bind height / 2
                        translateX: bind width / 2
                        horizontalAlignment: HorizontalAlignment.CENTER
                        content: bind status
                        fill: Color.WHITE
                    }
                ]
                opacity: bind if (status == null) 0 else 1;
            },
            ImageView {
                image: bind currentImage
            }
        ]
    }
    onResize: function(width:Integer, height:Integer) {
        if (imageHeight != height) {
            imageHeight = height;
            if (status == null) {
                updateImage();
            }
        }
    }
}