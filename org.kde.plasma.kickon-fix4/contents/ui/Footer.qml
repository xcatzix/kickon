/*
 *    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
 *    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 *
 *    SPDX-License-Identifier: GPL-2.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.ksvg as KSvg
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels

PlasmaExtras.PlasmoidHeading {
    id: root

    readonly property alias tabBar: tabBar
    property real preferredTabBarWidth: 0
    readonly property alias leaveButtons: leaveButtons

    // The footer now contains the application categories themselves.
    // - row 0: Favorites
    // - Places replaces the old "All Applications" position
    // - category rows follow
    // - All Applications is moved after "Lost & Found"
    ListModel {
        id: footerModel
    }

    readonly property alias footerItemsModel: footerModel
    readonly property int displayRole: KItemModels.KRoleNames.role("display")
    readonly property int decorationRole: KItemModels.KRoleNames.role("decoration")

    contentWidth: tabBar.implicitWidth + spacing
    contentHeight: leaveButtons.implicitHeight

    leftPadding: kickoff.backgroundMetrics.leftPadding
    rightPadding: kickoff.backgroundMetrics.rightPadding
    topPadding: Kirigami.Units.smallSpacing * 2
    bottomPadding: Kirigami.Units.smallSpacing * 2

    topInset: 0
    leftInset: 0
    rightInset: 0
    bottomInset: 0

    spacing: kickoff.backgroundMetrics.spacing
    position: PC3.ToolBar.Footer

    function roleData(row: int, role: int): var {
        const index = kickoff.rootModel.index(row, 0);
        return index.valid ? kickoff.rootModel.data(index, role) : "";
    }

    function isLostAndFound(row: int): bool {
        const text = String(roleData(row, displayRole)).toLowerCase();
        return text === "lost & found" || text === "lost and found" || text.includes("lost & found");
    }

    function rebuildFooterModel(): void {
        footerModel.clear();

        if (!kickoff.rootModel || kickoff.rootModel.rowCount() < 1) {
            return;
        }

        // Keep Favorites first.
        footerModel.append({
            kind: "root",
            rootRow: 0,
            label: String(roleData(0, displayRole)),
            iconName: String(roleData(0, decorationRole) || "favorite")
        });

        // Places occupies the old All Applications position.
        footerModel.append({
            kind: "places",
            rootRow: -1,
            label: i18nc("@title:tab kickoff footer tab", "Places"),
            iconName: "compass"
        });

        // Show every application category as an icon-only footer tab.
        // The old All Applications row (1) is deliberately held back until
        // after Lost & Found.
        let lostAndFoundRow = -1;
        for (let row = 2; row < kickoff.rootModel.rowCount(); ++row) {
            if (isLostAndFound(row)) {
                lostAndFoundRow = row;
                break;
            }
        }

        const appendCategory = (row) => {
            footerModel.append({
                kind: "root",
                rootRow: row,
                label: String(roleData(row, displayRole)),
                iconName: String(roleData(row, decorationRole) || "applications-all")
            });
        };

        for (let row = 2; row < kickoff.rootModel.rowCount(); ++row) {
            appendCategory(row);
            if (row === lostAndFoundRow) {
                appendCategory(1); // All Applications
            }
        }

        // Defensive fallback for models without a Lost & Found row.
        if (lostAndFoundRow < 0 && kickoff.rootModel.rowCount() > 1) {
            appendCategory(1);
        }

        if (footerModel.count > 0) {
            tabBar.currentIndex = Math.min(tabBar.currentIndex, footerModel.count - 1);
        }
    }

    PC3.TabBar {
        id: tabBar

        property real tabWidth: Kirigami.Units.iconSizes.medium + Kirigami.Units.smallSpacing * 2

        focus: true

        width: root.preferredTabBarWidth > 0 ? root.preferredTabBarWidth : implicitWidth
        implicitWidth: contentWidth + leftPadding + rightPadding
        implicitHeight: contentHeight + topPadding + bottomPadding

        leftPadding: mirrored ? root.spacing : 0
        rightPadding: !mirrored ? root.spacing : 0

        anchors {
            top: parent.top
            left: parent.left
            bottom: parent.bottom
        }

        position: PC3.TabBar.Footer

        contentItem: ListView {
            id: tabBarListView
            focus: true
            model: tabBar.contentModel
            currentIndex: tabBar.currentIndex

            spacing: 0
            orientation: ListView.Horizontal
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.AutoFlickIfNeeded
            snapMode: ListView.SnapToItem

            highlightMoveDuration: Kirigami.Units.longDuration
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: tabBar.tabWidth
            preferredHighlightEnd: width - tabBar.tabWidth
            highlight: KSvg.FrameSvgItem {
                anchors.top: tabBarListView.contentItem.top
                anchors.bottom: tabBarListView.contentItem.bottom
                anchors.topMargin: -root.topPadding
                anchors.bottomMargin: -root.bottomPadding
                imagePath: "widgets/tabbar"
                prefix: tabBar.position === PC3.TabBar.Header ? "north-active-tab" : "south-active-tab"
            }
            keyNavigationEnabled: false
        }

        Repeater {
            model: footerModel

            delegate: PC3.TabButton {
                required property string kind
                required property int rootRow
                required property string label
                required property string iconName
                required property int index

                width: tabBar.tabWidth
                anchors.top: tabBarListView.contentItem.top
                anchors.bottom: tabBarListView.contentItem.bottom
                anchors.topMargin: -root.topPadding
                anchors.bottomMargin: -root.bottomPadding

                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                icon.name: iconName
                display: PC3.AbstractButton.IconOnly

                PC3.ToolTip.text: label
                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                PC3.ToolTip.visible: hovered

                onClicked: {
                    tabBar.currentIndex = index;
                    // Repeater-created TabButtons are not always reflected in
                    // TabBar.contentModel on all Plasma 6 builds, so dispatch
                    // activation directly as well as updating the highlight.
                    if (kickoff.footer && kickoff.footer.activateTab) {
                        kickoff.footer.activateTab(index);
                    }
                }

                Keys.onTabPressed: event => {
                    if (index === tabBar.count - 1) {
                        leaveButtons.nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason);
                    } else {
                        event.accepted = false;
                    }
                }
            }
        }

        Connections {
            target: kickoff
            function onExpandedChanged() {
                if (!kickoff.expanded) {
                    tabBar.currentIndex = 0;
                }
            }
        }

        Keys.onPressed: event => {
            const Key_Next = Application.layoutDirection === Qt.RightToLeft ? Qt.Key_Left : Qt.Key_Right
            const Key_Prev = Application.layoutDirection === Qt.RightToLeft ? Qt.Key_Right : Qt.Key_Left
            if (event.key === Key_Next) {
                if (currentIndex === count - 1) {
                    leaveButtons.nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
                } else {
                    incrementCurrentIndex()
                    currentItem.forceActiveFocus(Qt.TabFocusReason)
                }
                event.accepted = true
            } else if (event.key === Key_Prev && currentIndex > 0) {
                decrementCurrentIndex()
                currentItem.forceActiveFocus(Qt.BacktabFocusReason)
                event.accepted = true
            }
        }

        Keys.onUpPressed: event => {
            kickoff.firstCentralPane.forceActiveFocus(Qt.BacktabFocusReason);
        }
    }

    LeaveButtons {
        id: leaveButtons

        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }

        maximumWidth: root.availableWidth - tabBar.width - root.spacing

        Keys.onUpPressed: event => {
            kickoff.lastCentralPane.forceActiveFocus(Qt.BacktabFocusReason);
        }
    }

    Behavior on height {
        enabled: kickoff.expanded
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InQuad
        }
    }

    Item {
        id: mouseItem
        parent: root
        anchors.left: parent.left
        height: root.height
        width: tabBar.width
        z: 1
        WheelHandler {
            id: tabScrollHandler
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: {
                const shouldDec = rotation >= 15
                const shouldInc = rotation <= -15
                const shouldReset = (rotation > 0 && tabBar.currentIndex === 0) || (rotation < 0 && tabBar.currentIndex === tabBar.count - 1)
                if (shouldDec) {
                    tabBar.decrementCurrentIndex();
                    rotation = 0
                } else if (shouldInc) {
                    tabBar.incrementCurrentIndex();
                    rotation = 0
                } else if (shouldReset) {
                    rotation = 0
                }
            }
        }
    }

    Shortcut {
        sequences: ["Ctrl+Tab", "Ctrl+Shift+Tab", StandardKey.NextChild, StandardKey.PreviousChild]
        onActivated: {
            tabBar.currentIndex = (tabBar.currentIndex + 1) % Math.max(tabBar.count, 1);
        }
    }

    Component.onCompleted: rebuildFooterModel()

    Connections {
        target: kickoff.rootModel
        function onModelReset() {
            rebuildFooterModel();
        }
        function onRowsInserted() {
            rebuildFooterModel();
        }
        function onRowsRemoved() {
            rebuildFooterModel();
        }
        function onRefreshed() {
            rebuildFooterModel();
        }
    }
}
