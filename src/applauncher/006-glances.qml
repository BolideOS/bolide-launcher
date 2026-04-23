/*
 * Copyright (C) 2026 BolideOS Contributors
 * All rights reserved.
 *
 * Garmin-style vertical glance list.
 *
 * Each app from launcherModel gets an entry. If the app has registered
 * glance data via GlanceRegistry (D-Bus), a rich card is shown:
 *   Line 1: Title (white, bold)
 *   Line 2: Range bar / sparkline (optional, based on data)
 *   Line 3: Label (left, dimmer)    Value (right, white)
 *
 * Apps without glance data show: icon + title (simple row).
 * Thin colored accent bar on the left edge per item.
 *
 * BSD License — see project root for full text.
 */

import QtQuick 2.9
import QtGraphicalEffects 1.0
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0

ListView {
    id: glanceList

    property bool fakePressed: false

    // Re-read glance data when registry signals changes
    property int glanceRevision: 0
    Connections {
        target: glanceRegistry
        function onGlancesChanged() { glanceRevision++ }
    }

    anchors.fill: parent
    orientation: ListView.Vertical
    snapMode: ListView.SnapToItem
    clip: true
    cacheBuffer: height * 2

    // ~3 items visible at once, like Garmin
    property real cardHeight: Math.round(height / 3)

    property int currentPos: 0

    onCurrentPosChanged: {
        rightIndicator.animate()
        leftIndicator.animate()
        topIndicator.animate()
        bottomIndicator.animate()
    }

    Connections {
        target: grid
        function onCurrentVerticalPosChanged() {
            if (grid.currentVerticalPos === 0) {
                glanceList.highlightMoveDuration = 0
                glanceList.currentIndex = 0
            } else if (grid.currentVerticalPos === 1) {
                glanceList.highlightMoveDuration = 300
                forbidTop = false
                grid.changeAllowedDirections()
            }
        }
    }

    onAtYBeginningChanged: {
        if ((grid.currentHorizontalPos === 0) && (grid.currentVerticalPos === 1)) {
            forbidTop = !atYBeginning
            grid.changeAllowedDirections()
        }
    }

    model: launcherModel

    delegate: MouseArea {
        id: cardDelegate
        width: glanceList.width
        height: glanceList.cardHeight
        enabled: !glanceList.dragging

        // Query glance data for this app (re-evaluated on glanceRevision change)
        property var glance: {
            glanceList.glanceRevision  // dependency trigger
            return glanceRegistry.glanceForApp(model.object.filePath)
        }
        property bool hasGlance: glance && glance.title !== undefined

        onClicked: model.object.launchApplication()

        // Press feedback
        Rectangle {
            anchors.fill: parent
            color: cardDelegate.pressed ? "#18FFFFFF" : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        // Thin colored accent bar on the left
        Rectangle {
            id: accentBar
            anchors {
                left: parent.left
                leftMargin: Dims.l(5)
                top: parent.top
                topMargin: Dims.l(2)
                bottom: parent.bottom
                bottomMargin: Dims.l(2)
            }
            width: Dims.l(0.8)
            radius: width / 2
            color: hasGlance && glance.color ? glance.color
                                             : alb.centerColor(launcherModel.get(index).filePath)
        }

        // ── Rich glance card (has D-Bus data) ──────────────────────
        Item {
            id: richCard
            visible: hasGlance
            anchors {
                left: accentBar.right
                leftMargin: Dims.l(3)
                right: parent.right
                rightMargin: Dims.l(5)
                top: parent.top
                topMargin: Dims.l(2)
                bottom: parent.bottom
                bottomMargin: Dims.l(2)
            }

            // Optional small icon next to title
            Icon {
                id: glanceIcon
                visible: hasGlance && glance.icon && glance.icon !== ""
                anchors {
                    top: parent.top
                    topMargin: Dims.l(1)
                    left: parent.left
                }
                width: visible ? Dims.l(6) : 0
                height: width
                name: (hasGlance && glance.icon) ? glance.icon : ""
                color: accentBar.color
            }

            // Line 1: Title
            Label {
                id: richTitle
                anchors {
                    top: parent.top
                    topMargin: Dims.l(1)
                    left: glanceIcon.visible ? glanceIcon.right : parent.left
                    leftMargin: glanceIcon.visible ? Dims.l(1.5) : 0
                    right: parent.right
                }
                text: hasGlance && glance.title ? glance.title : ""
                font {
                    pixelSize: Dims.l(8)
                    family: "Roboto Condensed"
                    styleName: "Bold"
                }
                color: "white"
                elide: Text.ElideRight
            }

            // Line 2: Range bar (visible if progress is defined)
            Rectangle {
                id: rangeBar
                visible: hasGlance && glance.progress !== undefined && glance.progress >= 0
                anchors {
                    top: richTitle.bottom
                    topMargin: Dims.l(1.5)
                    left: parent.left
                    right: parent.right
                }
                height: visible ? Dims.l(1.2) : 0
                radius: height / 2
                color: "#30FFFFFF"

                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: parent.width * Math.min(1.0, hasGlance ? (glance.progress || 0) : 0)
                    radius: parent.radius
                    color: accentBar.color
                }

                Rectangle {
                    visible: hasGlance && glance.progress > 0
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width * Math.min(1.0, hasGlance ? (glance.progress || 0) : 0) - width / 2
                    width: Dims.l(1.8)
                    height: width
                    radius: width / 2
                    color: "white"
                }
            }

            // Line 2 alt: Multi-segment color bar (like Garmin Training Readiness)
            Row {
                id: segmentBar
                visible: hasGlance && glance.barSegments !== undefined && glance.barSegments.length > 0
                anchors {
                    top: richTitle.bottom
                    topMargin: Dims.l(1.5)
                    left: parent.left
                    right: parent.right
                }
                height: visible ? Dims.l(1.2) : 0
                spacing: 1

                Repeater {
                    model: (hasGlance && glance.barSegments) ? glance.barSegments : []
                    Rectangle {
                        width: (segmentBar.width - (segmentBar.spacing * ((hasGlance && glance.barSegments) ? glance.barSegments.length - 1 : 0)))
                               * (modelData.width || (1.0 / ((hasGlance && glance.barSegments) ? glance.barSegments.length : 1)))
                        height: segmentBar.height
                        radius: height / 2
                        color: modelData.color || "#666"
                    }
                }
            }

            // Line 3: Label (left) + Value (right)
            Item {
                anchors {
                    top: rangeBar.visible ? rangeBar.bottom
                       : segmentBar.visible ? segmentBar.bottom
                       : richTitle.bottom
                    topMargin: Dims.l(1.5)
                    left: parent.left
                    right: parent.right
                }
                height: glanceLabel.height

                Label {
                    id: glanceLabel
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    text: hasGlance && glance.label ? glance.label : ""
                    font {
                        pixelSize: Dims.l(7)
                        family: "Roboto Condensed"
                    }
                    color: "#A0FFFFFF"
                }

                Label {
                    id: glanceValue
                    visible: hasGlance && glance.value && glance.value !== ""
                    anchors {
                        left: glanceLabel.right
                        leftMargin: Dims.l(2)
                        verticalCenter: parent.verticalCenter
                    }
                    text: hasGlance && glance.value ? glance.value : ""
                    font {
                        pixelSize: Dims.l(7)
                        family: "Roboto Condensed"
                        styleName: "Bold"
                    }
                    color: "white"
                }

                Label {
                    id: glanceValueRight
                    visible: hasGlance && glance.valueRight && glance.valueRight !== ""
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    text: hasGlance && glance.valueRight ? glance.valueRight : ""
                    font {
                        pixelSize: Dims.l(7)
                        family: "Roboto Condensed"
                        styleName: "Bold"
                    }
                    color: "white"
                }
            }
        }

        // ── Simple row (no glance data) ────────────────────────────
        Item {
            id: simpleRow
            visible: !hasGlance
            anchors {
                left: accentBar.right
                leftMargin: Dims.l(3)
                right: parent.right
                rightMargin: Dims.l(5)
                verticalCenter: parent.verticalCenter
            }
            height: simpleTitle.height

            Icon {
                id: simpleIcon
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                width: Dims.l(8)
                height: width
                name: model.object.iconId === "" ? "ios-help" : model.object.iconId
                color: accentBar.color
            }

            Label {
                id: simpleTitle
                anchors {
                    left: simpleIcon.right
                    leftMargin: Dims.l(2)
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                text: model.object.title + localeManager.changesObserver
                font {
                    pixelSize: Dims.l(8)
                    family: "Roboto Condensed"
                    styleName: "Bold"
                }
                color: "white"
                elide: Text.ElideRight
            }
        }

        // Bottom separator line
        Rectangle {
            anchors {
                bottom: parent.bottom
                left: parent.left
                leftMargin: Dims.l(5)
                right: parent.right
                rightMargin: Dims.l(5)
            }
            height: 1
            color: "#15FFFFFF"
        }
    }

    Component.onCompleted: {
        toLeftAllowed = false
        toRightAllowed = false
        toBottomAllowed = Qt.binding(function() { return !atYBeginning })
        toTopAllowed = Qt.binding(function() { return !atYEnd })
        forbidTop = Qt.binding(function() { return !atYBeginning })
        forbidBottom = false
        forbidLeft = false
        forbidRight = false
        launcherColorOverride = true
    }

    onContentYChanged: {
        var itemH = glanceList.cardHeight
        if (itemH > 0) {
            var lowerStop = Math.floor(contentY / itemH)
            var ratio = (contentY % itemH) / itemH
            currentPos = Math.round(lowerStop + ratio)
        }
    }
}
