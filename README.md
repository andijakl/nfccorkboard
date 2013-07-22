Nfc Corkboard
=============
Extends the Qt Quick corkboards example of the Qt SDK with NFC functionality: touch a tag and its NDEF contents appear as a new note on the screen. Press the NFC flag of a note on the screen and its contents will be written to the tag. Parses URI, text, Smart Poster and vCard records and shows a generic post-it for all other tag types.

The app is auto-started when touching a tag containing a record of the type name urn:nfc:ext:nokia.com:nfccorkboard.

A C++ class encapsulates the NFC functionality and is registered at runtime with the QML file of the user interface. This allows direct and easy communication between the UI and the NFC engine using signals and slots: create an NdefManager element in QML and react to its onNfcReadTagText signal, or write to a tag using ndefManager.nfcWriteTag(text). The C++ class additionally writes debug output to the console in case of detected targets, performed actions and errors, to make development easier.

Note for Symbian: The project requires Qt 4.7.4 and Qt Mobility 1.2 to be present on your device. On the C7, Symbian Anna (or newer) is required to use this application, as it enables the NFC capabilities of the device. Please read the build & installation instructions for more details.

More information:
http://www.nfcinteractor.com/apps/nfccorkboard/

FEATURES
-------------------------------------------------------------------------------

TODO


Work-in-progress (new features, known bugs / issues):
- Test tag writing with Harmattan PR 1.0
- Check reliability of saving to DB on Symbian
  -> Commit can't be used - transaction still in progress. Try again to make sure used in a different transaction?
  -> Test if it's the fault of using a primary key, or integer columns? All examples seem to only use TEXT.
  -> If this doesn't help, create a bugreport and an example project with similar table. Only option then to use Qt C++? :(
- Update documentation
- Check Harmattan deployment files
- Create page on nfcinteractor.com

IMPORTANT FILES/CLASSES
-------------------------------------------------------------------------------

- ndefmanager.h : encapsulates NFC target detection and NDEF tag reading / writing.
- corkboards.qml : Main application QML file, defines the model containing the 
notes and the view.
- Day.qml : Delegate for showing a single corkboard including its notes.

- ndefnfcsprecord.h : Convenience class for interacting with Nfc Forum 
Smart Poster records.
- ndefnfcmimevcardrecord.h : Convenience class for interacting with Mime / vCard
records. Supports parsing the versit documents stored on a tag to Qt Mobility's
QContact class, as well as converting QContacts to versit documents for writing
them to a tag.
- ndefnfcmimeimagerecord.h : Convenience class for interacting with any image 
mime type record where encoding and decoding support is provided by Qt.


SECURITY
--------------------------------------------------------------------------------

Symbian: The application can be self-signed.

Harmattan: No special aegis manifest is required.


KNOWN ISSUES / LIMITATIONS
-------------------------------------------------------------------------------

Due to the simple content display of text on notes, this example handles
few selected details of Smart Posters or business cards. For full read / write
support for those record types, see the Nfc Info example.

Harmattan: The SIP (virtual keyboard) opened from the TextEdit element 
doesn't close when the element loses focus. The workaround applied is to
install an event filter on the declarative view (meegosipeventfilter.h).

Harmattan: Ndef autostart (starting the app when touching a tag that contains
a record with type name urn:nfc:ext:nokia.com:nfccorkboard) requires PR 1.1
firmware on the Nokia N9.


BUILD & INSTALLATION INSTRUCTIONS
-------------------------------------------------------------------------------

MeeGo Harmattan
~~~~~~~~~~~~~~~
The example will work out of the box with the Harmattan target 
of the Qt SDK 1.1.4. Make sure you have the latest firmware version (PR 1.1)
on your Nokia N9. The Nokia N950 doesn't support NFC.


Symbian
~~~~~~~
Compatible devices:
C7-00/Oro/Astound with Symbian Anna/Belle,
Nokia 603, 700 and 701 (plus all upcoming NFC capable devices).

Device Preparation:
C7-00 with Symbian Anna: additionally install Qt 4.7.4, Qt Mobility 1.2 
from the Qt SDK:
C:\QtSDK\Symbian\sis\Symbian_Anna\Qt\4.7.4\Qt-4.7.403-for-Anna.sis
C:\QtSDK\Symbian\sis\Symbian_Anna\Qt\4.7.4\QtWebKit-4.8.1-for-Anna.sis
C:\QtSDK\Symbian\sis\Symbian_Anna\QtMobility\1.2.1\QtMobility-1.2.1-for-Anna.sis

Symbian Belle: already includes Qt 4.7.4 and QtM 1.2 - you don't
need to install these.



Build & installation instructions using Qt SDK
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

1. Open nfccorkboard.pro
   File > Open File or Project, select nfccorkboard.pro.
   
2. Symbian: Select the 'Qt 4.7.4 for Symbian Anna" target
   (also when compiling for Symbian Belle).
   MeeGo Harmattan: Select the MeeGo 1.2 Harmattan release target.

3. Press the Run button to build the project and to install it on the device.

Note: if switching between Symbian and MeeGo Harmattan builds, make sure to 
clean the project inbetween. Otherwise, specific differences in the meta-objects
might not get rebuilt.


COMPATIBILITY
-------------------------------------------------------------------------------

- Qt SDK 1.1.4 / Qt Creator 2.3
- QtMobility 1.2
- Qt 4.7.4

Tested on: 
- Nokia C7-00 with Symbian Anna Firmware and QtM 1.2
- Nokia C7-00 and 701 with Symbian Belle Firmware (already includes QtM 1.2)
- Nokia N9 PR 1.1


CHANGE HISTORY
--------------------------------------------------------------------------------
1.4 New default text for notes, explaining the app and including a note to write
		autostart tags
	Tag write confirmation shown also on Symbian
	Always copies NDEF autostart file to C drive on Symbian
	Uses the invoker to launch the app on MeeGo Harmattan, as is recommended
	Small fix in correctly parsing the note to write autostart tags

1.3.1 Doesn't fail app (un)installation if NDEF autostart (un)registration fails
		(= on MeeGo Harmattan PR 1.0). Autostart only works on PR 1.1+.
	Replicate autostart tags (on-screen notes that have the 
		text "Corkboards Autostart")
	Always installs autostart XML file on C drive for Symbian. See:
		https://bugreports.qt.nokia.com/browse/QTMOBILITY-1895
		
1.3 Autostart support when touching a tag with a custom
		urn:nfc:ext:nokia.com:nfccorkboard record.
	Text edit cursor positioning working for notes on MeeGo Harmattan.

1.2 Added support for reading and writing Smart Posters (Notes that have an
        URL in the first line and plain text in the second line)
	Added support for reading vCard tags (shows name, email and phone number
	    on the note)		 
			 
1.1 Shows status and error messages on the screen
	Post-it shows the contents of unknown NFC tags
	Added MeeGo Harmattan support
    Symbian: added NFC availability check, incorporating the NFC Settings App:
	    https://projects.developer.nokia.com/NfcSettingsApplication/
	
1.0 First version


RELATED DOCUMENTATION
-------------------------------------------------------------------------------

Project page
http://www.nfcinteractor.com/apps/nfccorkboard/

NFC 
http://www.developer.nokia.com/NFC

Qt
http://www.developer.nokia.com/Qt

