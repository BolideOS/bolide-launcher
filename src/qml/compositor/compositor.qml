/*
 * Copyright (C) 2015 Florent Revest <revestflo@gmail.com>
 *               2014 Aleksi Suomalainen <suomalainen.aleksi@gmail.com>
 *               2013 John Brooks <john.brooks@dereferenced.net>
 *               2013 Jolla Ltd.
 * All rights reserved.
 *
 * You may use this file under the terms of BSD license as follows:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the author nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import QtQuick 2.9
import QtQuick.Window 2.1
import org.nemomobile.lipstick 0.1
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import "desktop.js" as Desktop
import "compositor"

Item {
    id: root
    width: Dims.w(100)
    height: Dims.h(100)
    rotation: Screen.angleBetween(Screen.primaryScreen, Lipstick.compositor.screenOrientation)

    Item {
        id: homeLayer
        z: 1
        anchors.fill: parent
    }

    Item {
        property bool ready: false
        id: appLayer
        visible: comp.appActive
        z: 2

        opacity: (width-2*gestureArea.value)/width
        x: gestureArea.active &&  gestureArea.horizontal ? gestureArea.value : 0
        y: gestureArea.active && !gestureArea.horizontal ? gestureArea.value : 0

        width: parent.width
        height: parent.height

        // Let app deal with rotation themselves
        rotation: Screen.angleBetween(Lipstick.compositor.screenOrientation, Screen.primaryScreen)
    }

    Item {
        id: notificationLayer
        z: 3
        anchors.fill: parent
    }

    Item {
        id: agentLayer
        z: 4
        anchors.fill: parent
    }

    BorderGestureArea {
        id: gestureArea
        enabled: comp.appActive
        z: 5
        anchors.fill: parent
        acceptsDown: true
        acceptsRight: !comp.topmostWindowRequestsGesturesDisabled

        property real swipeThreshold: 0.15

        onGestureStarted: {
            swipeAnimation.stop()
            if (gesture == "down") {
                Desktop.desktop.aboutToClose = true
            } else if(gesture == "right") {
                Desktop.desktop.aboutToMinimize = true
            }
        }

        onGestureFinished: {
            if ((gesture == "down" || gesture == "right")) {
                if (gestureArea.progress >= swipeThreshold) {
                    swipeAnimation.valueTo = inverted ? -max : max
                    swipeAnimation.start()
                    var app = comp.topmostWindow
                    comp.topmostWindow = comp.homeWindow
                    Lipstick.compositor.closeClientForWindowId(app.window.windowId)
                } else {
                    cancelAnimation.start()
                }
            } else if (comp.homeActive) {
                cancelAnimation.start()
            }
            Desktop.desktop.aboutToClose = false
            Desktop.desktop.aboutToMinimize = false
        }

        NumberAnimation {
            id: cancelAnimation
            target: gestureArea
            property: "value"
            to: 0
            duration: 200
            easing.type: Easing.OutQuint
        }

        SequentialAnimation {
            id: swipeAnimation
            property alias valueTo: valueAnimation.to

            NumberAnimation {
                id: valueAnimation
                target: gestureArea
                property: "value"
                duration: 200
                easing.type: Easing.OutQuint
            }

            ScriptAction {
                script: comp.setCurrentWindow(comp.homeWindow)
            }
        }
    }

    Component {
        id: windowWrapper
        WindowWrapperBase { }
    }

    Timer {
        id: delayTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (comp.topmostWindow && comp.topmostWindow !== comp.homeWindow) {
                Lipstick.compositor.closeClientForWindowId(comp.topmostWindow.window.windowId)
            }
            Lipstick.compositor.setAmbientUpdatesEnabled(true)
        }
    }

    Compositor {
        id: comp

        property Item homeWindow

        // Set to the item of the current topmost window
        property Item topmostWindow

        // Only used to change blank timeout when on watchface or elsewhere
        property bool longTimeout: homeActive
        Component.onCompleted: {
            longTimeout = Qt.binding(function() { return homeActive && (Desktop.panelsGrid.currentVerticalPos == 0 && Desktop.panelsGrid.currentHorizontalPos == 0) })
            // Expose raiseApp to other QML components via desktop.js
            Desktop.raiseAppFunc = raiseApp
        }
        onLongTimeoutChanged: lipstickSettings.lockscreenVisible = longTimeout

        // True if the home window is the topmost window
        homeActive: topmostWindow == comp.homeWindow
        property bool appActive: !homeActive

        // Track display state for power management
        property bool displayOn: true

        // The application window that was most recently topmost
        property Item topmostApplicationWindow

        readonly property bool topmostWindowRequestsGesturesDisabled: topmostWindow && topmostWindow.window
                                                                      && (topmostWindow.window.windowFlags & 1)

        // Try to raise a cached (hidden) app window by title. Returns true if found.
        function raiseApp(title) {
            var w = Desktop.cachedWindows[title]
            if (w && w.window) {
                var age = Date.now() - (Desktop.cachedTimestamps[title] || 0)
                if (age > 30000) {
                    console.warn("[LAUNCH] raiseApp: cached window for '" + title + "' is stale (" + age + "ms) — killing")
                    Lipstick.compositor.closeClientForWindowId(w.window.windowId)
                    delete Desktop.cachedWindows[title]
                    delete Desktop.cachedTimestamps[title]
                    return false
                }
                console.warn("[LAUNCH] raiseApp: found cached window for '" + title + "' (age " + age + "ms)")
                delete Desktop.cachedWindows[title]
                delete Desktop.cachedTimestamps[title]
                w.opacity = 1.0
                w.visible = true
                setCurrentWindow(w, true)
                return true
            }
            return false
        }

        // Cache an app window (hide it but keep it alive)
        function cacheApp(w) {
            if (w && w !== homeWindow && w.window) {
                var title = w.window.title
                console.warn("[LAUNCH] cacheApp: caching '" + title + "'")
                w.opacity = 0
                Desktop.cachedWindows[title] = w
                Desktop.cachedTimestamps[title] = Date.now()
            }
        }

        function windowToFront(winId) {
            var o = comp.windowForId(winId)
            var window = null

            if (o) window = o.userData
            if (window == null) window = homeWindow

            setCurrentWindow(window)
        }

        function setCurrentWindow(w, skipAnimation) {
            console.warn("[LAUNCH] setCurrentWindow called, w=" + w + " skipAnimation=" + skipAnimation + " at " + Date.now())
            if (w == null)
                w = homeWindow

            topmostWindow = w;

            if (topmostWindow != homeWindow && topmostWindow != null) {
                if (topmostApplicationWindow) topmostApplicationWindow.visible = false
                topmostApplicationWindow = topmostWindow
                topmostApplicationWindow.visible = true
                if (!skipAnimation) topmostApplicationWindow.animateIn()
                w.window.takeFocus()
                console.warn("[LAUNCH] setCurrentWindow: app window shown at " + Date.now())
            }
        }

        onDisplayOff: {
            comp.displayOn = false
            // Kill cached settings to free memory before suspend
            var cachedSettings = Desktop.cachedWindows["Settings"]
            if (cachedSettings && cachedSettings.window) {
                console.warn("[LAUNCH] display off — killing cached Settings to save power")
                Lipstick.compositor.closeClientForWindowId(cachedSettings.window.windowId)
                delete Desktop.cachedWindows["Settings"]
                delete Desktop.cachedTimestamps["Settings"]
            }
            delayTimer.start()
        }
        onDisplayAboutToBeOn: {
            comp.displayOn = true
            delayTimer.stop()
            // Re-preload settings on wake so it's ready when user needs it
            preloadHelper.schedulePreload("bolide-settings", 500)
        }

        onWindowAdded: {
            var now = Date.now()
            var delta = Desktop.launchTimestamp > 0 ? (now - Desktop.launchTimestamp) : -1
            console.warn("[LAUNCH] onWindowAdded: title=" + window.title + " category=" + window.category + " isInProcess=" + window.isInProcess + " at " + now)
            if (delta >= 0) console.warn("[TIMING] " + window.title + " window added in " + delta + "ms (from button click)")
            Desktop.launchTimestamp = 0
            var isHomeWindow = window.isInProcess && comp.homeWindow == null && window.title === "Home"
            var isDialogWindow = window.category === "dialog"
            var isNotificationWindow = window.category == "notification"
            var isAgentWindow = window.category == "agent"
            var parent = null
            if (isHomeWindow) {
                parent = homeLayer
            } else if (isNotificationWindow) {
                parent = notificationLayer
            } else if (isAgentWindow) {
                parent = agentLayer
            } else {
                parent = appLayer
            }

            var w = windowWrapper.createObject(parent, { window: window })
            window.userData = w

            if (isHomeWindow) {
                parent.z = Qt.binding(function() { return w.window.rootItem.z })
                Desktop.desktop.aboutToOpen = Qt.binding(function() {return !homeActive && !appLayer.ready })
                comp.homeWindow = w
                setCurrentWindow(homeWindow)
            } else if (!isNotificationWindow && !isAgentWindow && !isDialogWindow) {
                // Clean up any old cached window with the same title
                var oldCached = Desktop.cachedWindows[window.title]
                if (oldCached && oldCached.window) {
                    console.warn("[LAUNCH] cleaning up old cached window for '" + window.title + "'")
                    Lipstick.compositor.closeClientForWindowId(oldCached.window.windowId)
                    delete Desktop.cachedWindows[window.title]
                }
                // Close previous topmost app (different app)
                if (topmostApplicationWindow != null) {
                    Lipstick.compositor.closeClientForWindowId(topmostApplicationWindow.window.windowId)
                }
                parent.ready = false
                w.smoothBorders = true

                // If this was not user-initiated (preload), hide immediately
                if (delta < 0) {
                    console.warn("[LAUNCH] preloaded window '" + window.title + "' — caching hidden")
                    comp.cacheApp(w)
                    comp.topmostApplicationWindow = null
                } else {
                    w.x = width
                    w.moveInAnim.start()
                    cancelAnimation.start()
                    setCurrentWindow(w)
                }
            }
        }

        onWindowRaised: {
            var now = Date.now()
            var delta = Desktop.launchTimestamp > 0 ? (now - Desktop.launchTimestamp) : -1
            console.warn("[LAUNCH] onWindowRaised: winId=" + window.windowId + " title=" + window.title + " at " + now)
            if (delta >= 0) console.warn("[TIMING] " + window.title + " window raised in " + delta + "ms (from button click)")
            Desktop.launchTimestamp = 0
            windowToFront(window.windowId)
        }

        onWindowRemoved: {
            var w = window.userData;
            var title = window.title
            if (comp.topmostWindow == w)
                setCurrentWindow(comp.homeWindow);

            // Remove from cache if present
            if (title && Desktop.cachedWindows[title] === w) {
                delete Desktop.cachedWindows[title]
                delete Desktop.cachedTimestamps[title]
            }

            if (window.userData)
                window.userData.destroy()

            // Re-preload settings after user-initiated kill (display on)
            // Skip re-preload on display-off kills to save battery
            if (title === "Settings" && comp.displayOn) {
                console.warn("[LAUNCH] Settings removed (display on), scheduling re-preload")
                preloadHelper.schedulePreload("bolide-settings", 0)
            } else if (title === "Settings") {
                console.warn("[LAUNCH] Settings removed (display off), skipping re-preload")
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        z: 6
        visible: DeviceSpecs.hasRoundScreen
        layer.enabled: DeviceSpecs.hasRoundScreen
        layer.effect: CircleMaskShader {
            smoothness: 0.002
            keepInner: false
        }
    }
}
