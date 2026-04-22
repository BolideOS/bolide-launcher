/*
 * Copyright (C) 2026 - BolideOS
 *
 * Inspired by MoveToBeActive by Felipe Vieira (fevieira27)
 * https://github.com/fevieira27/MoveToBeActive
 * Original design inspired by Garmin Vivomove series.
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 2.1 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import QtQuick.Shapes 1.0
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import Nemo.Mce 1.0
import BolideMetrics 1.0

Item {
    anchors.fill: parent

    property string accentColor: "#55FF00"

    MetricsService {
        id: metrics
    }

    MceBatteryLevel {
        id: batteryChargePercentage
    }

    MceBatteryState {
        id: batteryChargeState
    }

    Item {
        id: root

        anchors.centerIn: parent
        height: parent.width > parent.height ? parent.height : parent.width
        width: height

        // Black background
        Rectangle {
            anchors.fill: parent
            color: "black"
            radius: width / 2
        }

        // Tick marks
        Canvas {
            id: tickMarks

            anchors.fill: parent
            smooth: true
            antialiasing: true
            renderStrategy: Canvas.Cooperative
            visible: !nightstand
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.translate(width / 2, height / 2)
                var outerRad = width / 2
                var innerRad = outerRad - (width * 0.04)

                for (var i = 0; i < 60; i++) {
                    var angle = i * Math.PI / 30 - Math.PI / 2

                    if (i % 5 === 0) {
                        // 5-minute marks: thicker
                        ctx.lineWidth = width * 0.012
                        if (i === 15 || i === 45) {
                            // 3 and 9 positions: accent color
                            ctx.strokeStyle = accentColor
                        } else {
                            ctx.strokeStyle = Qt.rgba(0.7, 0.7, 0.7, 0.9)
                        }
                        var sX = (innerRad - width * 0.03) * Math.cos(angle)
                        var sY = (innerRad - width * 0.03) * Math.sin(angle)
                        var eX = outerRad * Math.cos(angle)
                        var eY = outerRad * Math.sin(angle)
                        ctx.beginPath()
                        ctx.moveTo(sX, sY)
                        ctx.lineTo(eX, eY)
                        ctx.stroke()
                    } else {
                        // Minute marks: thinner
                        ctx.lineWidth = width * 0.005
                        ctx.strokeStyle = Qt.rgba(0.5, 0.5, 0.5, 0.7)
                        var msX = innerRad * Math.cos(angle)
                        var msY = innerRad * Math.sin(angle)
                        var meX = outerRad * Math.cos(angle)
                        var meY = outerRad * Math.sin(angle)
                        ctx.beginPath()
                        ctx.moveTo(msX, msY)
                        ctx.lineTo(meX, meY)
                        ctx.stroke()
                    }
                }
            }
        }

        // Hour labels: 12, 3, 6, 9
        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: parent.height * 0.06
            }
            font {
                pixelSize: parent.height * 0.09
                family: "Source Sans Pro"
                weight: Font.Light
            }
            color: Qt.rgba(0.8, 0.8, 0.8, 0.9)
            text: "12"
        }

        Text {
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: parent.width * 0.06
            }
            font {
                pixelSize: parent.height * 0.09
                family: "Source Sans Pro"
                weight: Font.Light
            }
            color: Qt.rgba(0.8, 0.8, 0.8, 0.9)
            text: "3"
        }

        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: parent.height * 0.06
            }
            font {
                pixelSize: parent.height * 0.09
                family: "Source Sans Pro"
                weight: Font.Light
            }
            color: Qt.rgba(0.8, 0.8, 0.8, 0.9)
            text: "6"
        }

        Text {
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: parent.width * 0.07
            }
            font {
                pixelSize: parent.height * 0.09
                family: "Source Sans Pro"
                weight: Font.Light
            }
            color: Qt.rgba(0.8, 0.8, 0.8, 0.9)
            text: "9"
        }

        // Date display
        Text {
            id: dateDisplay

            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: parent.height * 0.19
            }
            font {
                pixelSize: parent.height * 0.046
                family: "Source Sans Pro"
            }
            color: Qt.rgba(1, 1, 1, 0.85)
            horizontalAlignment: Text.AlignHCenter
            text: wallClock.time.toLocaleString(Qt.locale(), "ddd").toUpperCase() + ", " +
                  wallClock.time.toLocaleString(Qt.locale(), "MMM") + " " +
                  wallClock.time.toLocaleString(Qt.locale(), "d")
        }

        // Battery indicator
        Item {
            id: batteryIndicator

            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
                horizontalCenterOffset: parent.width * 0.22
                verticalCenterOffset: -parent.height * 0.01
            }

            property int percent: batteryChargePercentage.percent
            property color battColor: percent <= 20 ? "#FF5555" :
                                      percent <= 40 ? "#FFFF55" : "#55FF00"

            // Battery body
            Rectangle {
                id: battBody
                width: root.width * 0.10
                height: root.height * 0.045
                radius: 2
                color: "transparent"
                border.color: batteryIndicator.battColor
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                // Fill
                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                        margins: 2
                    }
                    width: (parent.width - 4) * batteryIndicator.percent / 100
                    color: batteryIndicator.battColor
                    radius: 1
                }
            }

            // Battery tip
            Rectangle {
                anchors {
                    left: battBody.right
                    verticalCenter: battBody.verticalCenter
                }
                width: root.width * 0.008
                height: root.height * 0.025
                color: batteryIndicator.battColor
                radius: 1
            }

            // Battery text
            Text {
                anchors {
                    horizontalCenter: battBody.horizontalCenter
                    top: battBody.bottom
                    topMargin: root.height * 0.01
                }
                font {
                    pixelSize: root.height * 0.036
                    family: "Source Sans Pro"
                }
                color: batteryIndicator.battColor
                text: batteryIndicator.percent + "%"
            }
        }

        // Bluetooth icon (drawn as text symbol)
        Text {
            id: bluetoothIcon

            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: -parent.height * 0.29
            }
            font {
                pixelSize: parent.height * 0.055
                family: "Source Sans Pro"
                weight: Font.Bold
            }
            color: bluetoothStatus ? "#5555FF" : Qt.rgba(0.4, 0.4, 0.4, 0.8)
            text: "ᛒ"

            property bool bluetoothStatus: false
        }

        // Steps data field (left side)
        Item {
            id: stepsField

            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
                horizontalCenterOffset: -parent.width * 0.22
            }
            visible: !displayAmbient

            // Steps icon (shoe/footprint unicode)
            Text {
                id: stepsIcon
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: stepsText.top
                    bottomMargin: root.height * 0.005
                }
                font.pixelSize: root.height * 0.05
                color: Qt.rgba(0.7, 0.7, 0.7, 0.9)
                text: "👟"
            }

            Text {
                id: stepsText
                anchors.centerIn: parent
                font {
                    pixelSize: root.height * 0.04
                    family: "Source Sans Pro"
                }
                color: Qt.rgba(1, 1, 1, 0.85)
                text: metrics.connected && metrics.dailySteps > 0
                      ? (metrics.dailySteps >= 1000
                         ? (metrics.dailySteps / 1000).toFixed(1) + "k"
                         : metrics.dailySteps.toString())
                      : "---"
            }

            // Heart rate below steps
            Text {
                id: hrText
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: stepsText.bottom
                    topMargin: root.height * 0.02
                }
                font {
                    pixelSize: root.height * 0.038
                    family: "Source Sans Pro"
                }
                color: metrics.connected && metrics.heartRate > 0
                       ? "#FF4444" : Qt.rgba(0.5, 0.5, 0.5, 0.7)
                text: metrics.connected && metrics.heartRate > 0
                      ? "♥ " + metrics.heartRate : "♥ --"
            }
        }

        // Hour hand (white, pointed, Vivomove-inspired)
        Canvas {
            id: hourHand

            property int hour: 0
            property int minute: 0

            anchors.fill: parent
            smooth: true
            antialiasing: true
            renderStrategy: Canvas.Cooperative
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.translate(width / 2, height / 2)

                var hourAngle = (hour % 12 + minute / 60) * Math.PI / 6 - Math.PI / 2
                var handLength = width * 0.25
                var tailLength = width * 0.04
                var handWidth = width * 0.028
                var tipNarrow = width * 0.008

                // Shadow
                ctx.save()
                ctx.shadowColor = Qt.rgba(0, 0, 0, 0.6)
                ctx.shadowOffsetX = 2
                ctx.shadowOffsetY = 2
                ctx.shadowBlur = 4

                // Hand body (white)
                ctx.beginPath()
                // Tail
                var tailX = -tailLength * Math.cos(hourAngle)
                var tailY = -tailLength * Math.sin(hourAngle)
                var perpX = Math.cos(hourAngle + Math.PI / 2)
                var perpY = Math.sin(hourAngle + Math.PI / 2)
                // Points: tail-left, body-left, tip, body-right, tail-right
                ctx.moveTo(tailX + perpX * handWidth * 0.4, tailY + perpY * handWidth * 0.4)
                ctx.lineTo(perpX * handWidth / 2, perpY * handWidth / 2)
                ctx.lineTo(handLength * 0.75 * Math.cos(hourAngle) + perpX * handWidth / 2,
                           handLength * 0.75 * Math.sin(hourAngle) + perpY * handWidth / 2)
                // Pointed tip
                ctx.lineTo(handLength * Math.cos(hourAngle),
                           handLength * Math.sin(hourAngle))
                ctx.lineTo(handLength * 0.75 * Math.cos(hourAngle) - perpX * handWidth / 2,
                           handLength * 0.75 * Math.sin(hourAngle) - perpY * handWidth / 2)
                ctx.lineTo(-perpX * handWidth / 2, -perpY * handWidth / 2)
                ctx.lineTo(tailX - perpX * handWidth * 0.4, tailY - perpY * handWidth * 0.4)
                ctx.closePath()
                ctx.fillStyle = Qt.rgba(1, 1, 1, 0.95)
                ctx.fill()

                ctx.restore()
            }
        }

        // Minute hand (accent color, pointed, longer)
        Canvas {
            id: minuteHand

            property int minute: 0

            anchors.fill: parent
            smooth: true
            antialiasing: true
            renderStrategy: Canvas.Cooperative
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.translate(width / 2, height / 2)

                var minuteAngle = minute * Math.PI / 30 - Math.PI / 2
                var handLength = width * 0.37
                var tailLength = width * 0.04
                var handWidth = width * 0.024
                var tipNarrow = width * 0.006

                // Shadow
                ctx.save()
                ctx.shadowColor = Qt.rgba(0, 0, 0, 0.6)
                ctx.shadowOffsetX = 3
                ctx.shadowOffsetY = 3
                ctx.shadowBlur = 5

                // Hand body (accent)
                ctx.beginPath()
                var perpX = Math.cos(minuteAngle + Math.PI / 2)
                var perpY = Math.sin(minuteAngle + Math.PI / 2)
                var tailX = -tailLength * Math.cos(minuteAngle)
                var tailY = -tailLength * Math.sin(minuteAngle)
                // Points: tail-left, body-left, tip, body-right, tail-right
                ctx.moveTo(tailX + perpX * handWidth * 0.4, tailY + perpY * handWidth * 0.4)
                ctx.lineTo(perpX * handWidth / 2, perpY * handWidth / 2)
                ctx.lineTo(handLength * 0.8 * Math.cos(minuteAngle) + perpX * handWidth / 2,
                           handLength * 0.8 * Math.sin(minuteAngle) + perpY * handWidth / 2)
                // Pointed tip
                ctx.lineTo(handLength * Math.cos(minuteAngle),
                           handLength * Math.sin(minuteAngle))
                ctx.lineTo(handLength * 0.8 * Math.cos(minuteAngle) - perpX * handWidth / 2,
                           handLength * 0.8 * Math.sin(minuteAngle) - perpY * handWidth / 2)
                ctx.lineTo(-perpX * handWidth / 2, -perpY * handWidth / 2)
                ctx.lineTo(tailX - perpX * handWidth * 0.4, tailY - perpY * handWidth * 0.4)
                ctx.closePath()
                ctx.fillStyle = accentColor
                ctx.fill()

                ctx.restore()
            }
        }

        // Center arbor (pivot dot)
        Canvas {
            id: centerArbor

            anchors.fill: parent
            smooth: true
            antialiasing: true
            renderStrategy: Canvas.Cooperative
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                // Outer dark ring
                ctx.beginPath()
                ctx.arc(width / 2, height / 2, width * 0.025, 0, 2 * Math.PI)
                ctx.fillStyle = Qt.rgba(0, 0, 0, 1)
                ctx.fill()
                // Inner light dot
                ctx.beginPath()
                ctx.arc(width / 2, height / 2, width * 0.018, 0, 2 * Math.PI)
                ctx.fillStyle = Qt.rgba(0.75, 0.75, 0.75, 1)
                ctx.fill()
            }
        }

        // Nightstand mode: battery arc
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
                property real arcStrokeWidth: .02
                property real scalefactor: .46 - (arcStrokeWidth / 2)
                property real chargecolor: Math.floor(batteryChargePercentage.percent / 33.35)
                readonly property var colorArray: ["#FF5555", "#FFFF55", "#55FF00"]

                model: segmentAmount

                Shape {
                    visible: index === 0 ? true : (index / segmentedArc.segmentAmount) < segmentedArc.inputValue

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: segmentedArc.colorArray[segmentedArc.chargecolor]
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
                    family: "Source Sans Pro"
                    weight: Font.Light
                }
                color: segmentedArc.colorArray[segmentedArc.chargecolor]
                text: batteryChargePercentage.percent + "%"
            }
        }

        Connections {
            target: wallClock
            function onTimeChanged() {
                var hour = wallClock.time.getHours()
                var minute = wallClock.time.getMinutes()
                if (hourHand.hour !== hour || hourHand.minute !== minute) {
                    hourHand.hour = hour
                    hourHand.minute = minute
                    hourHand.requestPaint()
                }
                if (minuteHand.minute !== minute) {
                    minuteHand.minute = minute
                    minuteHand.requestPaint()
                }
            }
        }

        Component.onCompleted: {
            var hour = wallClock.time.getHours()
            var minute = wallClock.time.getMinutes()
            hourHand.hour = hour
            hourHand.minute = minute
            hourHand.requestPaint()
            minuteHand.minute = minute
            minuteHand.requestPaint()
            burnInProtectionManager.widthOffset = Qt.binding(function() { return width * (nightstandMode.active ? .12 : .07) })
            burnInProtectionManager.heightOffset = Qt.binding(function() { return height * (nightstandMode.active ? .12 : .07) })
        }
    }
}
