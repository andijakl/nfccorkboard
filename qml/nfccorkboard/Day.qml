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

Component {
    Item {
        id: page
        width: ListView.view.width+40;
        height: ListView.view.height

        Image { 
            source: "cork.jpg"
            width: page.ListView.view.width
            height: page.ListView.view.height
            fillMode: Image.PreserveAspectCrop
            clip: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                page.forceActiveFocus();
            }
        }

        Text {
            anchors { left: parent.left; top: parent.top; right: parent.right; margins: 5 }
            text: name;
            font.pixelSize: 18; font.bold: true; color: "white"
            style: Text.Outline; styleColor: "black"
        }

        Image {
            id: trash
            source: "trash.png"
            opacity: 0.0
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.bottomMargin: 30
            anchors.leftMargin: 80
            z: 9
            Behavior on opacity {
                NumberAnimation { properties:"opacity"; duration: 200 }
            }
        }

        Repeater {
            model: notes
            Item {
                id: stickyPage

                property int randomX: Math.random() * (page.ListView.view.width-0.5*stickyImage.width) +100
                property int randomY: Math.random() * (page.ListView.view.height-0.5*stickyImage.height) +50

                x: randomX; y: randomY

                rotation: -flickable.horizontalVelocity / 100;
                Behavior on rotation {
                    SpringAnimation { spring: 2.0; damping: 0.15 }
                }

                Item {
                    id: sticky
                    scale: 0.7

                    Image {
                        id: stickyImage
                        x: 8 + -width * 0.6 / 2; y: -20
                        source: "note-yellow.png"
                        scale: 0.6; transformOrigin: Item.TopLeft
                        smooth: true
                    }

                    TextEdit {
                        id: myText
                        text: noteText
                        x: -104; y: 36; width: 215; height: 200
                        smooth: true
                        font.pixelSize: 24
                        readOnly: false
                        rotation: -8
                        wrapMode: TextEdit.Wrap
                    }

                    Item {
                        id: interactionItem
                        x: stickyImage.x; y: -20
                        width: stickyImage.width * stickyImage.scale
                        height: stickyImage.height * stickyImage.scale

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            drag.target: stickyPage
                            drag.axis: Drag.XandYAxis
                            drag.minimumY: 0
                            drag.maximumY: page.height - 80
                            drag.minimumX: 100
                            drag.maximumX: page.width - 140
                            hoverEnabled: true
                            onClicked: {
                                myText.forceActiveFocus();
                                myText.openSoftwareInputPanel();
                                var mappedPos = interactionItem.mapToItem(myText, mouse.x, mouse.y);
                                myText.cursorPosition = myText.positionAt(mappedPos.x, mappedPos.y)
                            }
                            drag.onActiveChanged: {
                                trash.opacity = drag.active ? 0.5 : 0.0;
//                                if (!drag.active) {
//                                }
                            }
                            onPositionChanged: {
                                if (drag.active) {
                                    trash.opacity = (checkIfOnTrash(mouse.x, mouse.y) ? 1.0 : 0.5);
                                }
                            }
                            onReleased: {
                                // Only check if trash was hit when dragging beforehand.
                                // This is to prevent that clicking on the note would delete
                                // it, in case it's placed below the trash can.
                                // Note that drag is still active in onReleased (whereas
                                // in drag.onActiveChanged -> false, the mouse coordinates
                                // would already be missing)
                                if (drag.active && checkIfOnTrash(mouse.x, mouse.y)) {
                                    trash.opacity = 0.0;
                                    // User dragged item to trash bin -> delete note!
                                    NoteStorage.removeNote(noteId, notePage, index);
                                }
                            }

                            function checkIfOnTrash(posX, posY) {
                                var posInPage = page.mapFromItem(interactionItem, posX, posY)
                                //console.log("x: " + posX + ", y: " + posY + ", p.x: " + posInPage.x + ", p.y: " + posInPage.y + ", t.x: " + trash.x + ", t.y: " + trash.y)
                                return (posInPage.x >= trash.x && posInPage.x <= trash.x + trash.width &&
                                        posInPage.y >= trash.y && posInPage.y <= trash.y + trash.height);
                            }
                        }
                        Image {
                            id: writeButton
                            source: "NfcFlag.png"
                            rotation: -8    // Note image itself is rotated
                            anchors { bottom: parent.bottom; right:parent.right }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { ndefManager.nfcWriteTag(myText.text); }
                            }
                        }
                    }
                }

                Image {
                    x: -width / 2; y: -height * 0.5 / 2
                    source: "tack.png"
                    scale: 0.7; transformOrigin: Item.TopLeft
                }

                states: State {
                    name: "pressed"
                    when: mouse.pressed
                    PropertyChanges { target: sticky; rotation: 8; scale: 1 }
                    PropertyChanges { target: page; z: 8 }
                }

                transitions: Transition {
                    NumberAnimation { properties: "rotation,scale"; duration: 200 }
                }
            }
        }
    }
}








