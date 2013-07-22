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

import QtQuick 1.0
import "NoteStorage.js" as NoteStorage

Rectangle {
    id: window
    width: 800; height: 480
    color: "#464646"
    state: "hidden"

    Connections {
        target: ndefManager

        onNfcReadTagUri:
            NoteStorage.addNoteToCurrentPage(nfcTagUri);
        onNfcReadTagText:
            NoteStorage.addNoteToCurrentPage(nfcTagText);
        onNfcReadTagSp:
            NoteStorage.addNoteToCurrentPage(nfcTagUri + "\n" + nfcTagTitle);
        onNfcReadTagVcard:
            NoteStorage.addNoteToCurrentPage(nfcTagName + "\n" + nfcTagEmail + "\n" + nfcTagPhone);
        onNfcReadTagAutostart:
            NoteStorage.addNoteToCurrentPage("Corkboards Autostart\nPayload:\n" + nfcTagPayload);
        onNfcReadTagUnknown:
            NoteStorage.addNoteToCurrentPage("Unknown tag type:\n" + nfcTagType + "\nPayload:\n" + nfcTagPayload);
        onNfcReadTagError:
            infoText.newError(nfcTagError, false)
        onNfcStatusError:
            infoText.newError(nfcStatusErrorText, true)
        onNfcStatusUpdate:
            infoText.newStatus(nfcStatusText)
    }

    Component.onCompleted: initNfc();

    function initNfc()
    {
        ndefManager.checkNfcStatus();
        ndefManager.initAndStartNfc();
    }

    ListModel {
        id: list

        ListElement {
            name: "Initializing..."
            notes: []
        }

        Component.onCompleted: NoteStorage.fillModelFromDb(firstStart);
    }


    ListView {
        id: flickable

        anchors.fill: parent
        focus: true
        highlightRangeMode: ListView.StrictlyEnforceRange
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        model: list
        delegate: Day { }
    }

    Text {
        id: infoText;
        anchors { left: parent.left; bottom: parent.bottom; right: parent.right; margins: 5 }

        font.pixelSize: 18; font.bold: true; color: "lightcoral"
        style: Text.Outline; styleColor: "black"
        wrapMode: Text.Wrap

        PropertyAnimation { id: fadeOutAnimation; target: infoText; property: "opacity"; easing.type: Easing.InQuad; from: 1; to: 0; duration: 5000 }

        function newError(text, permanent) {
            infoText.color = "lightcoral"
            changeText(text, permanent)
        }
        function newStatus(text) {
            infoText.color = "lightgreen"
            changeText(text, false)
        }
        function changeText(text, permanent) {
            infoText.text = text
            if (!permanent)
            {
                fadeOutAnimation.complete()
                fadeOutAnimation.start()
            } else {
                infoText.opacity = 1
            }
        }
    }

    Image {
        id: closeButton
        source: "close.png"
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 15
        anchors.rightMargin: 25
        opacity: 0.5
        Behavior on opacity {
            NumberAnimation { properties:"opacity"; duration: 200 }
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -5 // Make MouseArea bigger than the rectangle, itself
            onClicked: Qt.quit();
            onPressed: closeButton.opacity = 1.0
            onReleased: closeButton.opacity = 0.5
        }
    }
    Image {
        id: infoButton
        source: "info.png"
        anchors.top: parent.top
        anchors.right: closeButton.left
        anchors.topMargin: 15
        anchors.rightMargin: 30
        opacity: 0.5
        Behavior on opacity {
            NumberAnimation { properties:"opacity"; duration: 200 }
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -5 // Make MouseArea bigger than the rectangle, itself
            onClicked: {
                infoTxt.show();
            }
            onPressed: infoButton.opacity = 1.0
            onReleased: infoButton.opacity = 0.5
        }
    }
    Info {
        id: infoTxt
        anchors.fill: parent
    }
}
