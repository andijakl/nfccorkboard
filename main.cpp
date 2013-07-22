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

#include <QtGui/QApplication>
#include "qmlapplicationviewer.h"
#include <QtDeclarative>
#include "ndefmanager.h"
#ifdef Q_OS_SYMBIAN
//#include <QSystemScreenSaver>
#endif
#if defined(MEEGO_EDITION_HARMATTAN)
#include "meegosipeventfilter.h"
#endif

// Used for the QSettings file
#define SETTINGS_ORG "Nokia"
#define SETTINGS_APP "NfcCorkboard"
#define SETTINGS_FILE "/NfcCorkboard.conf"

int main(int argc, char *argv[])
{
    QScopedPointer<QApplication> app(createApplication(argc, argv));

#ifdef Q_OS_SYMBIAN
    // Translation for NFC Status messages
    QString locale = QLocale::system().name();

    QTranslator translator;
    translator.load(QString("NfcCorkboard_") + locale);
    app->installTranslator(&translator);

    QTextCodec::setCodecForTr(QTextCodec::codecForName("utf8"));
#endif

    // Check if the app has been started for the first time.
    // If yes -> fill the corkboards with default notes from QML.
    // Use the private application dir path, so that the settings
    // are automatically removed during uninstallation.
#ifdef Q_OS_SYMBIAN
    QSettings* settings = new QSettings(QApplication::applicationDirPath() + SETTINGS_FILE, QSettings::NativeFormat);
#else
    QSettings* settings = new QSettings(SETTINGS_ORG, SETTINGS_APP);
#endif
    bool firstStart = settings->value("firstStart", true).toBool();

    // Setup QML Viewer
    QmlApplicationViewer viewer;
    viewer.setOrientation(QmlApplicationViewer::ScreenOrientationLockLandscape);

    QScopedPointer<NdefManager> ndefManager(new NdefManager());
    ndefManager->setDeclarativeView(viewer);
    viewer.rootContext()->setContextProperty("ndefManager", ndefManager.data());
    viewer.rootContext()->setContextProperty("firstStart", firstStart);

    viewer.setMainQmlFile(QLatin1String("qml/nfccorkboard/corkboards.qml"));

#if defined(MEEGO_EDITION_HARMATTAN)
    // Harmattan PR 1.0 doesn't close the SIP (virtual keyboard) when the
    // text edit loses focus or the SIP is closed from JavaScript.
    // This workaround closes the SIP as expected.
    MeeGoSipEventFilter* sipEventFilter = new MeeGoSipEventFilter(&viewer);
    viewer.installEventFilter(sipEventFilter);
#endif

    viewer.showExpanded();

    // First start done, set setting to false
    settings->setValue("firstStart", QVariant(false));
    delete settings;

//#ifdef Q_OS_SYMBIAN
//    // Prevent screensaver from kicking in
//    QSystemScreenSaver *screensaver = new QSystemScreenSaver ( &viewer );
//    screensaver->setScreenSaverInhibit();
//#endif

    return app->exec();
}
