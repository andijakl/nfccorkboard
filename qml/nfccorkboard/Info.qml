/****************************************************************************
**
** Copyright (C) 2012-2013 Andreas Jakl.
** All rights reserved.
** Part of the NFC Corkboard demo app.
** Contact: Andreas Jakl (andreas.jakl@mopius.com)
** 
** Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
** All rights reserved.
** Contact: Nokia Corporation (qt-info@nokia.com)
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of Nokia Corporation and its Subsidiary(-ies) nor
**     the names of its contributors may be used to endorse or promote
**     products derived from this software without specific prior written
**     permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 1.1
import "NoteStorage.js" as NoteStorage

Item {
    id: infoTxt
    state: "hidden"
    visible: false
    opacity: 0.0;

    function show() {
        infoTxt.state = "shown";
    }
    function hide() {
        infoTxt.state = "hidden";
    }

    MouseArea {
        anchors.fill: parent
        onClicked: hide();
    }

    Rectangle {
        id: darken
        anchors.fill: parent
        color: "#000000"
        opacity: 0.3
    }
    Image {
        id: background
        anchors.centerIn: parent
        width: (parent.width / 5) * 4
        height: (parent.height / 5) * 4
        smooth: true
        source: "infobg.png"

        Item {
            id: instructionsItem
            anchors.fill: parent
            anchors.topMargin: 5
            anchors.leftMargin: 7
            anchors.rightMargin: 10
            anchors.bottomMargin: 10

            Flickable {
                id: instructionsFlickable
                width: parent.width
                height: parent.height
                clip: true
                anchors { left: parent.left; top: parent.top }
                contentHeight: instructionsContentItem.height
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: instructionsContentItem
                    width: parent.width

                    spacing: 10

                    Text {
                        id: instructionsText1
                        text: qsTr("<strong>Nfc Corkboard</strong>")
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                        wrapMode: Text.WordWrap
                        color: "black";
                        font.pixelSize: 22
                    }

                    Image {
                        id: instructionsImage
                        anchors.horizontalCenter: parent.horizontalCenter
                        fillMode: Image.PreserveAspectFit
                        source: "icon.png"
                        asynchronous: true
                    }

                    Text {
                        id: instructionsText2
                        text: qsTr("v2.0.0\n2011 - 2012 Andreas Jakl\nBased on the Corkboards example of the Qt SDK")
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                        wrapMode: Text.WordWrap
                        color: "black"
                        font.pixelSize: 20
                    }

                    CustomButton {
                        label: "nfcinteractor.com"
                        img: "info.png"
                        imgHeight: 20
                        onClicked: Qt.openUrlExternally("http://www.nfcinteractor.com/nfccorkboard/")
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        id: instructionsText3
                        text: qsTr("Touch NFC tags (containing an NDEF message), and their contents will appear as a new sticky note. Press the red flag to write the note contents to a tag. Swipe the screen to switch between different corkboards. Drag a note on the trash can to delete it.")
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                        wrapMode: Text.WordWrap
                        color: "black"
                        font.pixelSize: 20
                    }

                    CustomButton {
                        label: "Reset notes to default"
                        img: "reset.svg"
                        imgHeight: 20
                        onClicked: NoteStorage.resetToDefaults()
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    states: [
        State {
            name: "shown"
            PropertyChanges { target:infoTxt; visible: true; opacity: 1.0 }

        },
        State {
            name: "hidden"
            PropertyChanges { target:infoTxt; visible: true; opacity: 0.0 }
        }
    ]
    transitions: [
        Transition {
            from: "hidden"; to: "shown"
            SequentialAnimation {
                PropertyAction { target: infoTxt; property: "visible"; value: true }
                NumberAnimation { target: infoTxt; property: "opacity"; duration: 200 }
            }
        },
        Transition {
            from: "shown"; to: "hidden"
            SequentialAnimation {
                NumberAnimation { target: infoTxt; property: "opacity"; duration: 200 }
                PropertyAction { target: infoTxt; property: "visible"; value: false }
            }
        }
    ]
}
