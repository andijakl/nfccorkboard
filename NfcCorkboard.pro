# When compiling for publishing the app, activate this
# to change to the 0x2... UID and the right UID for the
# Smart Installer. Using those UIDs requires a development
# certificate.
# For self signed versions, remove / comment the following line.
#DEFINES += DEPLOY_VERSION

TARGET = nfccorkboard
VERSION = 1.90.00

QT += sql
# If your application uses the Qt Mobility libraries, uncomment
# the following lines and add the respective components to the 
# MOBILITY variable. 
CONFIG += mobility
MOBILITY += sensors connectivity systeminfo versit contacts

# Define QMLJSDEBUGGER to allow debugging of QML in debug builds
# (This might significantly increase build time)
# DEFINES += QMLJSDEBUGGER

# Define for detecting Harmattan in .cpp files.
# Only needed for experimental / beta Harmattan SDKs.
# Will be defined by default in the final SDK.
exists($$QMAKE_INCDIR_QT"/../qmsystem2/qmkeys.h"):!contains(MEEGO_EDITION,harmattan): {
  MEEGO_VERSION_MAJOR     = 1
  MEEGO_VERSION_MINOR     = 2
  MEEGO_VERSION_PATCH     = 0
  MEEGO_EDITION           = harmattan
  DEFINES += MEEGO_EDITION_HARMATTAN
}

# Additional import path used to resolve QML modules in Creator's code model
QML_IMPORT_PATH =

# The .cpp file which was generated for your project. Feel free to hack it.
SOURCES += main.cpp \
    ndefmanager.cpp \
    ndefnfcsprecord.cpp \
    ndefnfcmimevcardrecord.cpp \
    ndefnfcmimeimagerecord.cpp

HEADERS += \
    ndefmanager.h \
    meegosipeventfilter.h \
    ndefnfcsprecord.h \
    ndefnfcmimevcardrecord.h \
    ndefnfcmimeimagerecord.h

OTHER_FILES += \
    qml/nfccorkboard/corkboards.qml \
    qml/nfccorkboard/Day.qml \
    qml/nfccorkboard/Info.qml \
    qml/nfccorkboard/CustomButton.qml \
    qml/nfccorkboard/NoteStorage.js \
    qml/nfccorkboard/NfcFlag.png \
    qml/nfccorkboard/note-yellow.png \
    qml/nfccorkboard/infobg.png \
    qml/nfccorkboard/icon.png \
    qml/nfccorkboard/info.png \
    qml/nfccorkboard/close.png \
    qml/nfccorkboard/trash.png

# Add more folders to ship with the application here
qmlFolder.source = qml/nfccorkboard
qmlFolder.target = qml
DEPLOYMENTFOLDERS = qmlFolder

symbian {
    DEPLOYMENT.display_name = "NfcCorkboard"
    contains(DEFINES,DEPLOY_VERSION) {
        TARGET.UID3 = 0x2005CE05
    } else {
        TARGET.UID3 = 0xEAFA7D84
    }

    # Allow network access on Symbian
    TARGET.CAPABILITY += NetworkServices LocalServices

    # Smart Installer package's UID
    # This UID is from the protected range and therefore the package will
    # fail to install if self-signed. By default qmake uses the unprotected
    # range value if unprotected UID is defined for the application and
    # 0x2002CCCF value if protected UID is given to the application
    contains(DEFINES,DEPLOY_VERSION) {
        DEPLOYMENT.installer_header = 0x2002CCCF
    }

    # add NfcSettings support
    include(nfcsettings/nfcsettings.pri)

    # Autostart
    ndefhandler.sources = ndefhandler_nfccorkboard.xml
    ndefhandler.path = c:/private/2002AC7F/import/
    DEPLOYMENT += ndefhandler

    # Localisation support.
    CODECFORTR = UTF-8
    TRANSLATIONS += loc/$${TARGET}_en.ts \
                    loc/$${TARGET}_ar.ts \
                    loc/$${TARGET}_zh_HK.ts \
                    loc/$${TARGET}_zh_CN.ts \
                    loc/$${TARGET}_zh_TW.ts \
                    loc/$${TARGET}_cs.ts \
                    loc/$${TARGET}_da.ts \
                    loc/$${TARGET}_nl.ts \
                    loc/$${TARGET}_en_US.ts \
                    loc/$${TARGET}_fi.ts \
                    loc/$${TARGET}_fr.ts \
                    loc/$${TARGET}_fr_CA.ts \
                    loc/$${TARGET}_de.ts \
                    loc/$${TARGET}_el.ts \
                    loc/$${TARGET}_he.ts \
                    loc/$${TARGET}_hi.ts \
                    loc/$${TARGET}_hu.ts \
                    loc/$${TARGET}_id.ts \
                    loc/$${TARGET}_it.ts \
                    loc/$${TARGET}_ms.ts \
                    loc/$${TARGET}_no.ts \
                    loc/$${TARGET}_pl.ts \
                    loc/$${TARGET}_pt.ts \
                    loc/$${TARGET}_pt_BR.ts \
                    loc/$${TARGET}_ro.ts \
                    loc/$${TARGET}_ru.ts \
                    loc/$${TARGET}_sk.ts \
                    loc/$${TARGET}_es.ts \
                    loc/$${TARGET}_es_419.ts \
                    loc/$${TARGET}_sv.ts \
                    loc/$${TARGET}_th.ts \
                    loc/$${TARGET}_tr.ts \
                    loc/$${TARGET}_uk.ts \
                    loc/$${TARGET}_vi.ts

    translationfiles.source = loc/*.qm
    DEPLOYMENTFOLDERS += translationfiles

    vendorName = "Andreas Jakl"
    vendorinfo = \
        "; Localised Vendor name" \
        "%{$$addLanguageDependentPkgItem(vendorName)}" \
        " " \
        "; Unique Vendor name" \
        ":\"$$vendorName\"" \
        " "

    deployment_vendor.pkg_prerules += vendorinfo
    DEPLOYMENT += deployment_vendor
}

contains(MEEGO_EDITION,harmattan) {
    # Temp
    DEFINES += MEEGO_EDITION_HARMATTAN

    OTHER_FILES += qtc_packaging/debian_harmattan/*

    # Don't use nfccorkboard_harmattan.desktop. Otherwise,
    # the NDEF Autostart handler won't find the desktop file and
    # will not be able to auto-launch this app on tag-touch.
    # See: https://bugreports.qt.nokia.com/browse/QTMOBILITY-1848
    harmattandesktopfile.files = nfccorkboard.desktop
    harmattandesktopfile.path = /usr/share/applications
    INSTALLS += harmattandesktopfile

    # Make sure this file gets deployed to the session.d directory,
    # and not the system dbus.
    ndefhandler_conf.files = nfccorkboard.conf
    ndefhandler_conf.path = /etc/dbus-1/session.d/

    # To avoid conflicts, recommended to name this file according to the
    # full service name instead of just the app name.
    # See: https://bugreports.qt.nokia.com/browse/QTMOBILITY-1848
    ndefhandler_service.files = com.nokia.qtmobility.nfc.nfccorkboard.service
    ndefhandler_service.path = /usr/share/dbus-1/services/

    launchericon.files = nfccorkboard80.png splash-nfccorkboard-l.png splash-nfccorkboard-p.png
    launchericon.path = /opt/$${TARGET}/

    INSTALLS += ndefhandler_conf ndefhandler_service launchericon
}

# Please do not modify the following lines. Required for deployment.
include(qmlapplicationviewer/qmlapplicationviewer.pri)
qtcAddDeployment()






