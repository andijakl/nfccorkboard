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


// ------------------------------------------------------------------------------------
// Database handling
function db() {
    return openDatabaseSync("NfcCorkboard", "1.0", "Notes with NFC tag data", 50000);
}

function ensureTables(resetWithDefaults) {
    // Somehow, executing this block to check if the DB already exists
    // reduces the stability of the SQL statements on Symbian.
    // If this is executed, removing & adding notes from the DB
    // is successful and it modifies the DB, but when restarting the app,
    // it's like these statements have not been executed.
//    db().transaction(
//        function(tx) {
//            try {
//                // DEBUG ONLY: uncomment to re-create the table
//                //tx.executeSql('DROP TABLE NfcNotesData');

//                // Checking for tables in sqlite_master doesn't return anything
//                // on Symbian, and the "CREATE TABLE IF NOT EXISTS" return value
//                // is the same, no matter if it created the table or not.
//                // -> Go the hardcore way and select data from the table,
//                // catching the error if it doesn't exist yet.
//                tx.executeSql("SELECT * FROM NfcNotesData");
//            } catch (err) {
//                // Table didn't exist before - fill it with data
//                resetWithDefaults = true;
//            }
//        }
//    )
    db().transaction(
        function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS NfcNotesData(noteId INTEGER PRIMARY KEY, notePage INTEGER, noteText TEXT)');
        }
    )
    if (resetWithDefaults) {
        setupDefaultTableContents();
    }
}

function resetToDefaults() {
    // First, delete all stored notes
    db().transaction(
        function(tx) {
            try {
                var rs = tx.executeSql("DELETE FROM NfcNotesData");
            } catch (err) {
                // Error shouldn't be important, most likely only when
                // table didn't exist beforehand
                console.log("Error deleting contents from table " + err);
            }
        }
    )
    // Now, recreate the table and fill it with the default values.
    // This also clears all notes from the UI, to get it in sync with
    // the DB model.
    fillModelFromDb(true);
}

function setupDefaultTableContents() {
    console.log("Fill SQL table with default data.")
    db().transaction(
        function(tx) {
            addNoteToPageTx(0, "Near Field Communication", tx, false);
            addNoteToPageTx(0, "Touch a tag and its contents will appear as a new note", tx, false);
            addNoteToPageTx(0, "Swipe screen to switch to the next corkboard", tx, false);
            addNoteToPageTx(1, "To write a tag, click the red flag of a note and then touch a tag", tx, false);
            addNoteToPageTx(1, "http://nfcinteractor.com", tx, false);
            addNoteToPageTx(2, "Corkboards Autostart\nPayload:\nNokia", tx, false);
            addNoteToPageTx(2, "Write the other note on this board to a tag to create an autostart tag for this app", tx, false);
            addNoteToPageTx(3, "Smart Poster: URL, [linefeed], title", tx, false);
            addNoteToPageTx(3, "https://projects.developer.nokia.com/nfccorkboards\nNfc Corkboard Project", tx, false);
            addNoteToPageTx(4, "This app reads these records: Smart Poster, URI, Text and vCard", tx, false);
            addNoteToPageTx(4, "This app writes these records: Smart Poster, URI, Text", tx, false);
            addNoteToPageTx(4, "http://www.nfc-forum.org", tx, false);
            addNoteToPageTx(5, "http://www.developer.nokia.com/Develop/NFC/Code_examples/\nMore NFC code examples", tx, false);
            addNoteToPageTx(5, "http://developer.nokia.com/NFC", tx, false);
            addNoteToPageTx(6, "Play with NFC", tx, false);
            addNoteToPageTx(6, "http://nokia.com/NFC", tx, false);
            addNoteToPageTx(6, "http://nfcinteractor.com", tx, false);
        }
    )
    commit();
}

function fillModelFromDb(resetWithDefaults) {
    console.log("Filling model data from SQL database");
    // Reset the model
    list.clear();

    // Setup days
    var days = new Array("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday");
    for (var i = 0; i < days.length; i++) {
        list.append({"name":days[i],"notes":(new Array())});
    }

    // Get data from DB
    ensureTables(resetWithDefaults);
    db().transaction(
        function(tx) {
            var rs = tx.executeSql("SELECT * FROM NfcNotesData");
            console.log("Number of items in the table: " + rs.rows.length);

            // Apply data from DB to model
            if (rs.rows.length > 0) {
                for (var i=0; i<rs.rows.length; ++i) {
                    var curNoteId = rs.rows.item(i).noteId;
                    var curNotePage = rs.rows.item(i).notePage;
                    var curNoteText = rs.rows.item(i).noteText;
                    list.get(curNotePage).notes.append({"noteId":curNoteId,"notePage":curNotePage,"noteText":curNoteText});
                    console.log("Added to model: noteId = " + curNoteId + ", notePage = " + curNotePage + ", noteText = " + curNoteText);
                }
            }
        }
    )
}

function addNoteToCurrentPage(newNoteText) {
    addNoteToPage(flickable.currentIndex, newNoteText);
}

function addNoteToPage(newNotePage, newNoteText) {
    db().transaction(
        function(tx) {
            addNoteToPageTx(newNotePage, newNoteText, tx, true);
        }
    )
    commit();
}

function addNoteToPageTx(newNotePage, newNoteText, tx, addToUi) {

    // Escaping characters are not needed when using placeholders like here.
    var rs = tx.executeSql("INSERT INTO NfcNotesData(notePage,noteText) VALUES(?,?)", [newNotePage,newNoteText]);
    if (rs.rowsAffected === 1) {
        console.log("Inserted to SQL: noteId = " + rs.insertId + ", notePage = " + newNotePage + ", noteText = " + newNoteText);
    } else {
        console.log("Failed to insert into SQL");
    }

    if (addToUi) {
        list.get(newNotePage).notes.append({"noteId":rs.insertId,"notePage":newNotePage,"noteText":newNoteText});
    }
}

function removeNote(removeNoteId, removeNotePage, removeNoteIndex) {
    db().transaction(
        function(tx) {
            // Delete note from DB
            var rs = tx.executeSql("DELETE FROM NfcNotesData WHERE noteId=?", [removeNoteId]);
            if (rs.rowsAffected === 1) {
                console.log("Deleted note from DB: " + removeNoteId);
            } else {
                console.log("Failed to delete from SQL SQL");
            }
            // Delete note from UI
            list.get(removeNotePage).notes.remove(removeNoteIndex);
        }
    )
    commit();
    // TODO: Debug only

    db().transaction(
        function(tx) {
            var rs = tx.executeSql("SELECT * FROM NfcNotesData");
            //console.log("Number of items in the table: " + rs.rows.length);
        }
    )

}

// Shouldn't really be needed, but Symbian seems to be unreliable with
// saving data, and calling commit doesn't really hurt either.
function commit()
{
    db().transaction(
        function(tx) {
            var rs = tx.executeSql("COMMIT");
        }
    )
}

/**
 * Function : dump()
 * Arguments: The data - array,hash(associative array),object
 *    The level - OPTIONAL
 * Returns  : The textual representation of the array.
 * This function was inspired by the print_r function of PHP.
 * This will accept some data as the argument and return a
 * text that will be a more readable version of the
 * array/hash/object that is given.
 * Docs: http://www.openjs.com/scripts/others/dump_function_php_print_r.php
 */
function dump(arr,level) {
    var dumped_text = "";
    if(!level) level = 0;

    //The padding given at the beginning of the line.
    var level_padding = "";
    for(var j=0;j<level+1;j++) level_padding += "    ";

    if(typeof(arr) == 'object') { //Array/Hashes/Objects
        for(var item in arr) {
            var value = arr[item];

            if(typeof(value) == 'object') { //If it is an array,
                dumped_text += level_padding + "'" + item + "' ...\n";
                dumped_text += dump(value,level+1);
            } else {
                dumped_text += level_padding + "'" + item + "' => \"" + value + "\"\n";
            }
        }
    } else { //Stings/Chars/Numbers etc.
        dumped_text = "===>"+arr+"<===("+typeof(arr)+")";
    }
    return dumped_text;
}
