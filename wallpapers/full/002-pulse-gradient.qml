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

    property real pulse: 0.0

    NumberAnimation on pulse {
        from: 0.0
        to: 1.0
        duration: 8000
        loops: Animation.Infinite
        easing.type: Easing.InOutSine
    }

    // Slowly shifting radial gradient
    RadialGradient {
        id: gradient
        anchors.fill: parent
        horizontalOffset: Math.sin(root.pulse * Math.PI * 2) * parent.width * 0.15
        verticalOffset: Math.cos(root.pulse * Math.PI * 2) * parent.height * 0.15
        horizontalRadius: parent.width * (0.5 + 0.2 * Math.sin(root.pulse * Math.PI * 2))
        verticalRadius: parent.height * (0.5 + 0.2 * Math.cos(root.pulse * Math.PI * 2 + 1.0))

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.lighter(root.centerColor, 1.0 + 0.3 * Math.sin(root.pulse * Math.PI * 2))
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

    // Second subtle gradient layer for depth
    RadialGradient {
        anchors.fill: parent
        opacity: 0.3 + 0.15 * Math.sin(root.pulse * Math.PI * 2 + 2.0)
        horizontalOffset: Math.cos(root.pulse * Math.PI * 2 + 1.5) * parent.width * 0.2
        verticalOffset: Math.sin(root.pulse * Math.PI * 2 + 1.5) * parent.height * 0.2
        horizontalRadius: parent.width * 0.4
        verticalRadius: parent.height * 0.4

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.lighter(root.centerColor, 1.4)
            }
            GradientStop {
                position: 1.0
                color: "transparent"
            }
        }
    }
}
