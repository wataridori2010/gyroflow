import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC

import Gyroflow 1.0

// TODO: multiple trims

Item {
    id: root;
    property real trimStart: 0.0;
    property real trimEnd: 1.0;
    property bool trimActive: trimStart > 0.01 || trimEnd < 0.99;

    property real durationMs: 0;

    property real visibleAreaLeft: 0.0;
    property real visibleAreaRight: 1.0;
    onVisibleAreaLeftChanged: Qt.callLater(redrawChart);
    onVisibleAreaRightChanged: Qt.callLater(redrawChart);
    property alias pressed: ma.pressed;

    property real value: 0;

    function mapToVisibleArea(pos) { return (pos - visibleAreaLeft) / (visibleAreaRight - visibleAreaLeft); }
    function mapFromVisibleArea(pos) { return pos * (visibleAreaRight - visibleAreaLeft) + visibleAreaLeft; }

    function redrawChart() { chart.update(); }
    function getChart() { return chart; }

    function timeAtPosition(pos) {
        const time = Math.max(0, durationMs * pos);
        return new Date(time).toISOString().substr(11, 8);
    }

    //anchors.topMargin: 15 * dpiScale;
    //anchors.bottomMargin: 30 * dpiScale;
    //anchors.leftMargin: 30 * dpiScale;
    //anchors.rightMargin: 10 * dpiScale;

    Column {
        x: 3 * dpiScale;
        y: 50 * dpiScale;
        spacing: 3 * dpiScale;
        TimelineAxisButton { id: a0; text: "X"; onCheckedChanged: chart.setAxisVisible(0, checked); checked: chart.getAxisVisible(0); }
        TimelineAxisButton { id: a1; text: "Y"; onCheckedChanged: chart.setAxisVisible(1, checked); checked: chart.getAxisVisible(1); }
        TimelineAxisButton { id: a2; text: "Z"; onCheckedChanged: chart.setAxisVisible(2, checked); checked: chart.getAxisVisible(2); }
        TimelineAxisButton { id: a3; text: "W"; onCheckedChanged: chart.setAxisVisible(3, checked); checked: chart.getAxisVisible(3); }
    }
    Column {
        anchors.right: parent.right;
        anchors.rightMargin: 3 * dpiScale;
        y: 50 * dpiScale;
        spacing: 3 * dpiScale;
        TimelineAxisButton { id: a4; text: "X"; onCheckedChanged: chart.setAxisVisible(4, checked); checked: chart.getAxisVisible(4); }
        TimelineAxisButton { id: a5; text: "Y"; onCheckedChanged: chart.setAxisVisible(5, checked); checked: chart.getAxisVisible(5); }
        TimelineAxisButton { id: a6; text: "Z"; onCheckedChanged: chart.setAxisVisible(6, checked); checked: chart.getAxisVisible(6); }
        TimelineAxisButton { id: a7; text: "W"; onCheckedChanged: chart.setAxisVisible(7, checked); checked: chart.getAxisVisible(7); }
    }

    Item {
        x: 33 * dpiScale;
        y: 15 * dpiScale;
        width: parent.width - x - 33 * dpiScale;
        height: parent.height - y - 30 * dpiScale - parent.additionalHeight;

        Rectangle {
            x: 0;
            y: 35 * dpiScale;
            width: parent.width
            radius: 4 * dpiScale;
            color: Qt.lighter(styleButtonColor, 1.1)
            height: parent.height - 35 * dpiScale;
            opacity: root.trimActive? 0.6 : 1.0;

            TimelineGyroChart {
                id: chart;
                visibleAreaLeft: root.visibleAreaLeft;
                visibleAreaRight: root.visibleAreaRight;
                anchors.fill: parent;
                anchors.topMargin: 5 * dpiScale;
                anchors.bottomMargin: 5 * dpiScale;
                opacity: root.trimActive? 0.8 : 1.0;
                onAxisVisibleChanged: {
                    a0.checked = chart.getAxisVisible(0);
                    a1.checked = chart.getAxisVisible(1);
                    a2.checked = chart.getAxisVisible(2);
                    a3.checked = chart.getAxisVisible(3);
                    a4.checked = chart.getAxisVisible(4);
                    a5.checked = chart.getAxisVisible(5);
                    a6.checked = chart.getAxisVisible(6);
                    a7.checked = chart.getAxisVisible(7);
                }
            }
        }

        // Lines
        // TODO QQuickPaintedItem
        Column {
            width: parent.width;
            Row {
                width: parent.width;
                spacing: (100 * dpiScale) - children[0].width;
                x: -children[0].width / 2;
                //layer.enabled: true;
                Repeater {
                    model: Math.max(0, linesCanvas.bigLines + 1);
                    BasicText {
                        leftPadding: 0;
                        font.pixelSize: 10 * dpiScale;
                        opacity: 0.6;
                        text: timeAtPosition(root.mapFromVisibleArea(x / parent.width));
                    }
                }
            }

            Item {
                width: parent.width;
                height: 15 * dpiScale;
                Canvas {
                    id: linesCanvas;
                    width: parent.width*2;
                    height: parent.height*2;
                    scale: 0.5;
                    anchors.centerIn: parent;
                    transformOrigin: Item.Center;
                    contextType: "2d";
                    layer.enabled: true;
                    property int lines: width / (20 * dpiScale);
                    property int bigLines: lines / 10;

                    onPaint: {
                        let ctx = context;

                        ctx.reset();
                        for (let j = 0; j < lines; j++) {
                            const x = Math.round(j * 20 * dpiScale);
                            ctx.beginPath();
                            ctx.moveTo(x, (j % 10 == 0)? 0 : height / 2);
                            ctx.lineTo(x, height);
                            ctx.strokeStyle = "#444444";
                            ctx.lineWidth = 1;
                            ctx.closePath();
                            ctx.lineCap = "round";
                            ctx.stroke();
                        }
                    }
                }
            }
        }

        MouseArea {
            id: ma;
            anchors.fill: parent;
            onMouseXChanged: {
                root.value = Math.max(0.0, Math.min(1.0, root.mapFromVisibleArea(mouseX / parent.width)));
            }
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    addSyncPointPopup.x = mouse.x;
                    addSyncPointPopup.y = mouse.y - addSyncPointPopup.height - 5;
                    addSyncPointPopup.open();
                }
            }
            onWheel: (wheel) => {
                if (wheel.modifiers & Qt.ControlModifier) {
                    const remainingWindow = (root.visibleAreaRight - root.visibleAreaLeft);

                    const factor = (wheel.angleDelta.y / 120) / (10 / remainingWindow);
                    const xPosFactor = wheel.x / root.width;
                    root.visibleAreaLeft  = Math.min(root.visibleAreaRight, Math.max(0.0, root.visibleAreaLeft  + factor * xPosFactor));
                    root.visibleAreaRight = Math.max(root.visibleAreaLeft,  Math.min(1.0, root.visibleAreaRight - factor * (1.0 - xPosFactor)));

                    scrollbar.position = root.visibleAreaLeft;
                }
                if (wheel.modifiers & Qt.AltModifier) {
                    const factor = (wheel.angleDelta.x / 120) / 10;
                    chart.vscale += factor;
                }
            }
        }

        Popup {
            id: addSyncPointPopup;
            width: maxItemWidth + 10 * dpiScale;
            y: -height - 5 * dpiScale;
            currentIndex: -1;
            model: [qsTr("Auto sync here"), qsTr("Add manual sync point here")];
            icons: ["spinner", "plus"];
            itemHeight: 27 * dpiScale;
            font.pixelSize: 11.5 * dpiScale;
            onClicked: (index) => {
                const pos = (root.mapFromVisibleArea(addSyncPointPopup.x / ma.width));
                switch (index) {
                    case 0: controller.start_autosync(pos, window.sync.initialOffset, window.sync.syncSearchSize * 1000, window.sync.timePerSyncpoint, window.sync.everyNthFrame, window.videoArea.vid); break;
                    case 1: controller.set_offset(pos * root.durationMs * 1000, controller.offset_at_timestamp(pos * root.durationMs)); break;
                }

                addSyncPointPopup.close();
            }
        }

        Item {
            anchors.fill: parent;
            clip: true;
            TimelineRangeIndicator {
                trimStart: root.trimStart;
                trimEnd: root.trimEnd;
                visible: root.trimActive;
                onChangeTrimStart: (val) => { root.trimStart = val; if (root.trimStart >= root.trimEnd) { root.trimStart = 0; root.trimEnd = 1.0; } }
                onChangeTrimEnd:   (val) => { root.trimEnd   = val; if (root.trimStart >= root.trimEnd) { root.trimStart = 0; root.trimEnd = 1.0; } }
            }
        }

        // Handle
        Rectangle {
            x: Math.max(0, root.mapToVisibleArea(root.value) * (parent.width) - width / 2)
            y: (parent.height - height) / 2
            radius: width;
            height: parent.height;
            width: 2 * dpiScale;
            color: styleAccentColor;
            visible: x >= 0 && x <= parent.width;
            Rectangle {
                height: 15 * dpiScale;
                width: 18 * dpiScale;
                color: styleAccentColor;
                radius: 3 * dpiScale;
                y: -5 * dpiScale;
                x: -width / 2;

                Rectangle {
                    height: 12 * dpiScale;
                    width: 15 * dpiScale;
                    color: parent.color;
                    radius: 3 * dpiScale;
                    anchors.centerIn: parent;
                    anchors.verticalCenterOffset: 5 * dpiScale;
                    rotation: 45;
                }
                Rectangle {
                    width: 1.5 * dpiScale;
                    color: "#000";
                    height: 6 * dpiScale;
                    radius: width;
                    anchors.horizontalCenter: parent.horizontalCenter;
                    anchors.horizontalCenterOffset: 1 * dpiScale;
                    anchors.bottom: parent.bottom;
                    anchors.bottomMargin: -6 * dpiScale;
                }
            }
        }

        Repeater {
            model: controller.offsets_model;

            TimelineSyncPoint {
                timeline: root;
                org_timestamp_us: timestamp_us;
                position: timestamp_us / (root.durationMs * 1000.0); // TODO: Math.round?
                offsetMs: offset_ms;
                onEdit: (ts_ns, offs) => {
                    console.log("edit sync point", ts_ns, offs);
                    root.editingSyncPoint = true;
                    syncPointSlider.timestamp_us = ts_ns;
                    syncPointSlider.from = offs - Math.max(15, Math.abs(offs));
                    syncPointSlider.to = offs + Math.max(15, Math.abs(offs));
                    syncPointSlider.value = offs;
                }
                onRemove: (ts_ns) => {
                    controller.remove_offset(ts_ns);
                }
            }
        }

        QQC.ScrollBar {
            id: scrollbar;
            hoverEnabled: true;
            active: hovered || pressed;
            orientation: Qt.Horizontal;
            size: root.visibleAreaRight - root.visibleAreaLeft;
            anchors.left: parent.left;
            anchors.right: parent.right;
            anchors.bottom: parent.bottom;
            position: 0;
            onPositionChanged: {
                const diff = root.visibleAreaRight - root.visibleAreaLeft;
                root.visibleAreaLeft = position;
                root.visibleAreaRight = position + diff;
            }
        }
    }

    property bool editingSyncPoint: false;
    property real additionalHeight: editingSyncPoint? 35 : 0;
    Ease on additionalHeight { }

    Row {
        id: row;
        x: 30 * dpiScale;
        width: parent.width - x;
        spacing: 10 * dpiScale;
        height: 35 * dpiScale;
        anchors.bottom: parent.bottom;
        anchors.bottomMargin: 0 * dpiScale;
        visible: opacity > 0;
        opacity: parent.editingSyncPoint? 1 : 0;
        Ease on opacity {}
        Slider {
            id: syncPointSlider;
            property int timestamp_us: 0;
            width: parent.width - syncPointEditField.width - syncPointBtn.width - 30 * dpiScale;
            anchors.verticalCenter: parent.verticalCenter;
            property bool preventChange: false;
            onValueChanged: if (!preventChange) syncPointEditField.value = value;
            unit: qsTr("ms")
        }
        NumberField {
            id: syncPointEditField;

            width: 90 * dpiScale;
            precision: 4;
            unit: "ms";
            anchors.verticalCenter: parent.verticalCenter;
            property bool preventChange: true;
            onValueChanged: {
                if (preventChange) return;
                syncPointSlider.preventChange = true;
                syncPointSlider.value = value;
                syncPointSlider.preventChange = false;

                controller.set_offset(syncPointSlider.timestamp_us, value);
            }
            Component.onCompleted: {
                preventChange = false;
            }
            onAccepted: {
                controller.set_offset(syncPointSlider.timestamp_us, value);
            }
        }
        Button {
            id: syncPointBtn;
            text: qsTr("Save");
            accent: true;
            height: 25 * dpiScale;
            leftPadding: 8 * dpiScale;
            rightPadding: 8 * dpiScale;
            font.pixelSize: 12 * dpiScale;
            anchors.verticalCenter: parent.verticalCenter;
            onClicked: {
                root.editingSyncPoint = false;
                controller.set_offset(syncPointSlider.timestamp_us, syncPointEditField.value);
            }
        }
    }
    LoaderOverlay { anchors.topMargin: 10 * dpiScale; }

}