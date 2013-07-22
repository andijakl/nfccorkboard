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

Item {
    id: customButton
    signal clicked
    property string img
    property alias label: btnText.text
    property int imgHeight

    anchors.margins: 5

    width: btnImage.paintedWidth + btnText.paintedWidth + 18
    height: Math.max(btnImage.paintedHeight + 6, btnText.paintedHeight + 6)

    Image {
        id: btnImage
        source: img
        height: imgHeight
        fillMode: Image.PreserveAspectFit
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.top: parent.top
        anchors.topMargin: 6
        smooth: true
        asynchronous: true
        opacity: 0.5
        Behavior on opacity {
            NumberAnimation { properties:"opacity"; duration: 200 }
        }
        z: 2
    }

    Text {
        id: btnText
        visible: !(text.length === 0)
        anchors.left: btnImage.right
        anchors.leftMargin: 6
        anchors.verticalCenter: btnImage.verticalCenter
        color: "black"
        font.pixelSize: 20
        z: 1
    }

    Rectangle {
        color: "#222222"
        anchors.fill: parent
        opacity: 0.7
        z: 0
    }
    Rectangle {
        id: innerFill
        color: "#fffeb1"
        anchors.fill: parent
        anchors.margins: 1
        opacity: 0.7
        z: 0
        Behavior on opacity {
            NumberAnimation { properties:"opacity"; duration: 200 }
        }
    }

    MouseArea {
        id: btnMouse
        anchors.fill: parent
        anchors.margins: -5 // Make MouseArea bigger than the parent itself
        onClicked: customButton.clicked()
        onPressed: buttonPressed();
        onReleased: buttonReleased();
        onActiveFocusChanged: {console.log("focuschagne") }
        onContainsMouseChanged: {
            if (!btnMouse.containsMouse) {
                onReleased: buttonReleased();
            }
        }
    }

    function buttonPressed () {
        btnImage.opacity = 1.0;
        innerFill.opacity = 0.9;
    }
    function buttonReleased () {
        btnImage.opacity = 0.5;
        innerFill.opacity = 0.7;
    }
}

