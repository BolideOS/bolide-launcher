/*
 * Copyright (C) 2026 BolideOS Contributors
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

import QtQuick 2.9
import QtGraphicalEffects 1.0

Item {
    id: root
    anchors.fill: parent

    property color centerColor: typeof bgCenterColor !== "undefined" ? bgCenterColor : "#0044A6"
    property color outerColor: typeof bgOuterColor !== "undefined" ? bgOuterColor : "#00010C"

    // Multiple independent phases at irrational-ratio durations
    // so the motion never visibly repeats
    property real t1: 0.0
    property real t2: 0.0
    property real t3: 0.0
    property real t4: 0.0

    NumberAnimation on t1 {
        from: 0; to: Math.PI * 2; duration: 37000
        loops: Animation.Infinite
    }
    NumberAnimation on t2 {
        from: 0; to: Math.PI * 2; duration: 53000
        loops: Animation.Infinite
    }
    NumberAnimation on t3 {
        from: 0; to: Math.PI * 2; duration: 43000
        loops: Animation.Infinite
    }
    NumberAnimation on t4 {
        from: 0; to: Math.PI * 2; duration: 61000
        loops: Animation.Infinite
    }

    RadialGradient {
        anchors.fill: parent
        horizontalOffset: Math.sin(root.t1) * parent.width * 0.08
                        + Math.sin(root.t3 * 0.7) * parent.width * 0.04
        verticalOffset: Math.cos(root.t2) * parent.height * 0.08
                      + Math.cos(root.t4 * 0.6) * parent.height * 0.04
        horizontalRadius: parent.width * (0.55 + 0.08 * Math.sin(root.t3))
        verticalRadius: parent.height * (0.55 + 0.08 * Math.cos(root.t1 * 0.8))

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.lighter(root.centerColor, 1.0 + 0.12 * Math.sin(root.t4))
            }
            GradientStop {
                position: 0.5
                color: root.centerColor
            }
            GradientStop {
                position: 1.0
                color: root.outerColor
            }
        }
    }

    RadialGradient {
        anchors.fill: parent
        opacity: 0.2 + 0.08 * Math.sin(root.t2 + 1.0)
        horizontalOffset: Math.cos(root.t4) * parent.width * 0.1
        verticalOffset: Math.sin(root.t1 + 2.0) * parent.height * 0.1
        horizontalRadius: parent.width * 0.35
        verticalRadius: parent.height * 0.35

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.lighter(root.centerColor, 1.25)
            }
            GradientStop {
                position: 1.0
                color: "transparent"
            }
        }
    }
}
