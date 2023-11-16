// Copyright (C) 2023 JiDe Zhang <zccrs@live.com>.
// SPDX-License-Identifier: Apache-2.0 OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Waylib.Server
import Tinywl

Item {
    id :root

    WaylandServer {
        id: server

        WaylandBackend {
            id: backend

            onOutputAdded: function(output) {
                output.forceSoftwareCursor = true // Test

                if (QmlHelper.outputManager.count > 0)
                    output.scale = 2

                Helper.allowNonDrmOutputAutoChangeMode(output)
                QmlHelper.outputManager.add({waylandOutput: output})
            }
            onOutputRemoved: function(output) {
                QmlHelper.outputManager.removeIf(function(prop) {
                    return prop.waylandOutput === output
                })
            }
            onInputAdded: function(inputDevice) {
                seat0.addDevice(inputDevice)
            }
            onInputRemoved: function(inputDevice) {
                seat0.removeDevice(inputDevice)
            }
        }

        WaylandCompositor {
            id: compositor

            backend: backend
        }

        XdgShell {
            id: shell

            onSurfaceAdded: function(surface) {
                let type = surface.isPopup ? "popup" : "toplevel"
                QmlHelper.xdgSurfaceManager.add({type: type, waylandSurface: surface})
            }
            onSurfaceRemoved: function(surface) {
                QmlHelper.xdgSurfaceManager.removeIf(function(prop) {
                    return prop.waylandSurface === surface
                })
            }
        }

        LayerShell {
            id: layerShell

            onSurfaceAdded: function(surface) {
                QmlHelper.layerSurfaceManager.add({waylandSurface: surface})
            }
            onSurfaceRemoved: function(surface) {
                QmlHelper.layerSurfaceManager.removeIf(function(prop) {
                    return prop.waylandSurface === surface
                })
            }
        }

        Seat {
            id: seat0
            name: "seat0"
            cursor: Cursor {
                id: cursor1

                layout: QmlHelper.layout
            }

            eventFilter: Helper
            keyboardFocus: Helper.getFocusSurfaceFrom(renderWindow.activeFocusItem)
        }

        CursorShapeManager { }

        WaylandSocket {
            id: masterSocket

            freezeClientWhenDisable: false

            Component.onCompleted: {
                console.info("Listing on:", socketFile)
                Helper.startDemoClient(socketFile)
            }
        }

        // TODO: add attached property for XdgSurface
        XdgDecorationManager {
            id: decorationManager
        }

        InputMethodManagerV2 {
            id: inputMethodManagerV2
        }

        TextInputManagerV1 {
            id: textInputManagerV1
        }

        TextInputManagerV3 {
            id: textInputManagerV3
        }

        VirtualKeyboardManagerV1 {
            id: virtualKeyboardManagerV1
        }

        XWayland {
            compositor: compositor.compositor
            seat: seat0.seat
            lazy: false

            onReady: masterSocket.addClient(client())

            onSurfaceAdded: function(surface) {
                QmlHelper.xwaylandSurfaceManager.add({waylandSurface: surface})
            }
            onSurfaceRemoved: function(surface) {
                QmlHelper.xwaylandSurfaceManager.removeIf(function(prop) {
                    return prop.waylandSurface === surface
                })
            }
        }
    }

    InputMethodHelper {
        id: inputMethodHelperSeat0
        seat: seat0
        textInputManagerV1: textInputManagerV1
        textInputManagerV3: textInputManagerV3
        inputMethodManagerV2: inputMethodManagerV2
        virtualKeyboardManagerV1: virtualKeyboardManagerV1
        onInputPopupSurfaceV2Added: function (surface) {
            QmlHelper.inputPopupSurfaceManager.add({ waylandSurface: surface })
        }
        onInputPopupSurfaceV2Removed: function (surface) {
            QmlHelper.inputPopupSurfaceManager.removeIf(function (prop) {
                return prop.waylandSurface === surface
            })
        }
    }

    OutputRenderWindow {
        id: renderWindow

        compositor: compositor
        width: outputRowLayout.implicitWidth + outputRowLayout.x
        height: outputRowLayout.implicitHeight + outputRowLayout.y

        EventJunkman {
            anchors.fill: parent
        }

        Row {
            id: outputRowLayout

            DynamicCreatorComponent {
                creator: QmlHelper.outputManager

                OutputDelegate {
                    property real topMargin: topbar.height
                    waylandCursor: cursor1
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent

            TabBar {
                id: topbar

                Layout.fillWidth: true

                TabButton {
                    text: qsTr("Stack Layout")
                    onClicked: {
                        decorationManager.mode = XdgDecorationManager.PreferClientSide
                    }
                }
                TabButton {
                    text: qsTr("Tiled Layout")
                    onClicked: {
                        decorationManager.mode = XdgDecorationManager.PreferServerSide
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                StackWorkspace {
                    visible: topbar.currentIndex === 0
                    anchors.fill: parent
                    activeFocusItem: renderWindow.activeFocusItem
                }

                TiledWorkspace {
                    visible: topbar.currentIndex === 1
                    anchors.fill: parent
                    activeFocusItem: renderWindow.activeFocusItem
                }
            }
        }
    }
}
