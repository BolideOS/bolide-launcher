/*
 * Copyright (C) 2026 - BolideOS
 *
 * MS-DOS dir listing watchface — retro command prompt aesthetic.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 2.1 of the
 * License, or (at your option) any later version.
 */

import QtQuick 2.12
import QtQuick.Shapes 1.0
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import Nemo.Mce 1.0

Item {
    anchors.fill: parent

    readonly property string monoFont: "Source Code Pro"
    readonly property color  txtColor: "#CCCCCC"
    readonly property color  dimColor: "#888888"
    readonly property color  hiColor:  "#FFFFFF"

    MceBatteryLevel {
        id: batteryChargePercentage
    }

    Item {
        id: root

        anchors.centerIn: parent
        height: parent.width > parent.height ? parent.height : parent.width
        width: height

        Rectangle {
            anchors.fill: parent
            color: "black"
            radius: width / 2
        }

        // Clipping mask for round display
        Item {
            anchors.fill: parent
            clip: true

            Column {
                id: dirListing

                anchors {
                    left: parent.left
                    leftMargin: parent.width * 0.14
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: -parent.height * 0.01
                }
                width: parent.width * 0.74
                spacing: root.height * 0.006

                property real fontSize: root.height * 0.050
                property real tagWidth: root.width * 0.30

                // ── Prompt: C:\Watch>dir ─────────────────────────
                Text {
                    font { pixelSize: dirListing.fontSize; family: monoFont }
                    color: txtColor
                    text: "C:\\Watch>dir"
                    visible: !displayAmbient
                }

                // Blank spacer
                Item { width: 1; height: root.height * 0.010; visible: !displayAmbient }

                // ── <time>  H:MM:SS ──────────────────────────────
                Row {
                    spacing: root.width * 0.02
                    Text {
                        width: dirListing.tagWidth
                        font { pixelSize: dirListing.fontSize; family: monoFont }
                        color: dimColor
                        text: "<time>"
                    }
                    Text {
                        font { pixelSize: dirListing.fontSize; family: monoFont; weight: Font.Bold }
                        color: hiColor
                        text: {
                            var h = wallClock.time.getHours()
                            var m = wallClock.time.getMinutes()
                            var s = wallClock.time.getSeconds()
                            return h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
                        }
                    }
                }

                // ── <date>  MM/DD/YY ─────────────────────────────
                Row {
                    spacing: root.width * 0.02
                    Text {
                        width: dirListing.tagWidth
                        font { pixelSize: dirListing.fontSize; family: monoFont }
                        color: dimColor
                        text: "<date>"
                    }
                    Text {
                        font { pixelSize: dirListing.fontSize; family: monoFont }
                        color: txtColor
                        text: {
                            var d = wallClock.time
                            var mo = d.getMonth() + 1
                            var day = d.getDate()
                            var yr = d.getFullYear() % 100
                            return (mo < 10 ? "0" : "") + mo + "/" +
                                   (day < 10 ? "0" : "") + day + "/" +
                                   (yr < 10 ? "0" : "") + yr
                        }
                    }
                }

                // ── <w_ba>  watch battery ────────────────────────
                Row {
                    spacing: root.width * 0.02
                    Text {
                        width: dirListing.tagWidth
                        font { pixelSize: dirListing.fontSize; family: monoFont }
                        color: dimColor
                        text: "<w_ba>"
                    }
                    Text {
                        font { pixelSize: dirListing.fontSize; family: monoFont }
                        color: batteryChargePercentage.percent <= 20 ? "#FF5555" : txtColor
                        text: batteryChargePercentage.percent + "%"
                    }
                }

                // ── <day>  day of week ───────────────────────────
                Row {
                    spacing: root.width * 0.02
                    visible: !displayAmbient
                    Text {
                        width: dirListing.tagWidth
                        font { pixelSize: dirListing.fontSize; family: monoFont }
                        color: dimColor
                        text: "<day>"
                    }
                    Text {
                        font { pixelSize: dirListing.fontSize; family: monoFont }
                        color: txtColor
                        text: {
                            var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                            return days[wallClock.time.getDay()]
                        }
                    }
                }

                // ── <ampm>  AM/PM indicator ──────────────────────
                Row {
                    spacing: root.width * 0.02
                    visible: !displayAmbient
                    Text {
                        width: dirListing.tagWidth
                        font { pixelSize: dirListing.fontSize; family: monoFont }
                        color: dimColor
                        text: "<ampm>"
                    }
                    Text {
                        font { pixelSize: dirListing.fontSize; family: monoFont }
                        color: txtColor
                        text: wallClock.time.getHours() < 12 ? "AM" : "PM"
                    }
                }

                // ── <uptime> ─────────────────────────────────────
                Row {
                    spacing: root.width * 0.02
                    visible: !displayAmbient
                    Text {
                        width: dirListing.tagWidth
                        font { pixelSize: dirListing.fontSize; family: monoFont }
                        color: dimColor
                        text: "<uptm>"
                    }
                    Text {
                        font { pixelSize: dirListing.fontSize; family: monoFont }
                        color: txtColor
                        text: {
                            var h = wallClock.time.getHours()
                            var m = wallClock.time.getMinutes()
                            var totalMin = h * 60 + m
                            return totalMin + " min"
                        }
                    }
                }

                // Blank spacer
                Item { width: 1; height: root.height * 0.005; visible: !displayAmbient }

                // ── Byte count line ──────────────────────────────
                Text {
                    anchors.right: parent.right
                    font { pixelSize: dirListing.fontSize * 0.85; family: monoFont }
                    color: dimColor
                    visible: !displayAmbient
                    text: {
                        // Fun fake byte count based on time
                        var h = wallClock.time.getHours()
                        var m = wallClock.time.getMinutes()
                        var s = wallClock.time.getSeconds()
                        var bytes = 1024 + h * 100 + m * 17 + s
                        return bytes + " bytes"
                    }
                }

                // Blank spacer
                Item { width: 1; height: root.height * 0.005 }

                // ── Bottom prompt with blinking cursor ───────────
                Row {
                    spacing: 0

                    Text {
                        font { pixelSize: dirListing.fontSize; family: monoFont }
                        color: txtColor
                        text: "C:\\Watch>"
                    }

                    Rectangle {
                        id: cursor
                        width: dirListing.fontSize * 0.6
                        height: dirListing.fontSize
                        anchors.verticalCenter: parent.verticalCenter
                        color: hiColor
                        visible: !displayAmbient

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 1; duration: 530 }
                            NumberAnimation { to: 0; duration: 530 }
                        }
                    }
                }
            }
        }

        // ── Nightstand mode ──────────────────────────────────────
        Item {
            id: nightstandMode

            readonly property bool active: nightstand
            anchors.fill: parent
            visible: nightstandMode.active

            Repeater {
                id: segmentedArc

                property real inputValue: batteryChargePercentage.percent / 100
                property int segmentAmount: 12
                property int start: 0
                property int gap: 6
                property int endFromStart: 360
                property bool clockwise: true
                property real arcStrokeWidth: .024
                property real scalefactor: .46 - (arcStrokeWidth / 2)
                property color arcColor: "#CCCCCC"

                model: segmentAmount

                Shape {
                    visible: index === 0 ? true : (index / segmentedArc.segmentAmount) < segmentedArc.inputValue

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: segmentedArc.arcColor
                        strokeWidth: root.height * segmentedArc.arcStrokeWidth
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.MiterJoin
                        startX: root.width / 2
                        startY: root.height * (.5 - segmentedArc.scalefactor)

                        PathAngleArc {
                            centerX: root.width / 2
                            centerY: root.height / 2
                            radiusX: segmentedArc.scalefactor * root.width
                            radiusY: segmentedArc.scalefactor * root.height
                            startAngle: -90 + index * (sweepAngle + (segmentedArc.clockwise ? +segmentedArc.gap : -segmentedArc.gap)) + segmentedArc.start
                            sweepAngle: segmentedArc.clockwise ? (segmentedArc.endFromStart / segmentedArc.segmentAmount) - segmentedArc.gap :
                                                                 -(segmentedArc.endFromStart / segmentedArc.segmentAmount) + segmentedArc.gap
                            moveToStart: true
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                font {
                    pixelSize: root.width * 0.14
                    family: monoFont
                    weight: Font.Bold
                }
                color: hiColor
                text: batteryChargePercentage.percent + "%"
            }
        }

        Component.onCompleted: {
            burnInProtectionManager.widthOffset = Qt.binding(function() { return width * (nightstandMode.active ? .12 : .07) })
            burnInProtectionManager.heightOffset = Qt.binding(function() { return height * (nightstandMode.active ? .12 : .07) })
        }
    }
}
