/*
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T

EmptyPage {
    id: root

    property real preferredSideBarWidth: Math.max(footer.tabBar.implicitWidth, applicationsPage.implicitSideBarWidth)

    contentItem: HorizontalStackView {
        id: stackView
        focus: true
        reverseTransitions: footer.currentRootRow === -1
        initialItem: applicationsPage

        ApplicationsPage {
            id: applicationsPage
            preferredSideBarWidth: root.preferredSideBarWidth + kickoff.backgroundMetrics.leftPadding
            hideSidebar: true
        }

        Component {
            id: placesPage
            PlacesPage {
                preferredSideBarWidth: root.preferredSideBarWidth + kickoff.backgroundMetrics.leftPadding
                preferredSideBarHeight: applicationsPage.implicitSideBarHeight
            }
        }

        function activateFooterTab(index: int): void {
            const item = footer.footerModelItem(index);
            if (!item) {
                return;
            }

            if (item.kind === "places") {
                stackView.replace(placesPage);
                return;
            }

            // The sidebar is visually hidden, but its model-backed ListView
            // remains the source of the selected category. Set it explicitly
            // when a footer icon is clicked instead of relying on TabBar's
            // contentModel to discover Repeater-created buttons.
            if (applicationsPage.sideBarItem) {
                applicationsPage.sideBarItem.currentIndex = item.rootRow;
            }
            stackView.replace(applicationsPage);
        }

        Connections {
            target: footer.tabBar
            function onCurrentIndexChanged() {
                stackView.activateFooterTab(footer.tabBar.currentIndex);
            }
        }

        Component.onCompleted: {
            if (applicationsPage.sideBarItem) {
                applicationsPage.sideBarItem.currentIndex = 0;
            }
        }
    }

    footer: Footer {
        id: footer

        preferredTabBarWidth: root.preferredSideBarWidth

        // Expose the backing ListModel without exposing it as a public alias.
        function footerModelItem(index: int): var {
            return footer.footerItemsModel.get(index);
        }

        function activateTab(index: int): void {
            stackView.activateFooterTab(index);
        }

        readonly property int currentRootRow: {
            const item = footerModelItem(tabBar.currentIndex);
            return item ? item.rootRow : 0;
        }

        Binding {
            target: kickoff
            property: "footer"
            value: footer
            restoreMode: Binding.RestoreBinding
        }

        Keys.onDownPressed: event => {}
    }
}
