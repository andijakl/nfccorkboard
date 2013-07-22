/****************************************************************************
**
** Copyright (C) 2012-2013 Andreas Jakl.
** All rights reserved.
** Contact: Andreas Jakl (andreas.jakl@mopius.com)
**
** This file may be used under the terms of the GNU General
** Public License version 3.0 as published by the Free Software Foundation
** and appearing in the file LICENSE included in the packaging of this
** file. Please review the following information to ensure the GNU General
** Public License version 3.0 requirements will be met:
** http://www.gnu.org/copyleft/gpl.html.
**
****************************************************************************/

#ifndef NDEFMANAGER_H
#define NDEFMANAGER_H

#include <QObject>
#include <QDebug>
#include <QUrl>
#include <QDeclarativeView>
#include <QSystemInfo>

#include <qnearfieldmanager.h>
#include <qndeffilter.h>
#include <qnearfieldtarget.h>
#include <qndefmessage.h>
#include <qndefrecord.h>
#include <qndefnfcurirecord.h>
#include <qndefnfctextrecord.h>
#include "ndefnfcmimeimagerecord.h"
#include "ndefnfcsprecord.h"
#include "ndefnfcmimevcardrecord.h"

#include <QContact>
#include <QContactDisplayLabel>
#include <QContactEmailAddress>
#include <QContactPhoneNumber>

QTM_USE_NAMESPACE

#ifdef Q_OS_SYMBIAN
#include "nfcsettings.h"
#endif

class NdefManager : public QObject
{
    Q_OBJECT
public:
    explicit NdefManager(QObject *parent = 0);

    void setDeclarativeView(QDeclarativeView& view);

signals:
    void nfcStatusUpdate(const QString& nfcStatusText);
    void nfcStatusError(const QString& nfcStatusErrorText);
    void nfcReadTagUri(const QUrl& nfcTagUri);
    void nfcReadTagText(const QString& nfcTagText);
    void nfcReadTagSp(const QUrl& nfcTagUri, const QString& nfcTagTitle);
    void nfcReadTagVcard(const QString& nfcTagName, const QString& nfcTagEmail, const QUrl& nfcTagPhone);
    void nfcReadTagAutostart(const QByteArray& nfcTagPayload);
    void nfcReadTagUnknown(const QByteArray& nfcTagType, const QByteArray& nfcTagPayload);
    void nfcReadTagError(const QString& nfcTagError);

public slots:
    void checkNfcStatus();
    void initAndStartNfc();
    void nfcWriteTag(const QString& nfcTagText);


private slots:
    void targetMessageDetected(const QNdefMessage &message, QNearFieldTarget *target);
    void targetDetected(QNearFieldTarget *target);
    void ndefMessageRead(const QNdefMessage &message);
    void requestCompleted(const QNearFieldTarget::RequestId & id);
    void ndefMessageWritten();
    void targetError(QNearFieldTarget::Error error, const QNearFieldTarget::RequestId &id);
    void targetLost(QNearFieldTarget *target);

private:
    void writeCachedNdefMessage();
    QString convertTargetErrorToString(QNearFieldTarget::Error error);

#ifdef Q_OS_SYMBIAN
private slots:
    // Check for NFC Support
    void handleNfcError(NfcSettings::NfcError nfcError, int error);
    void handleNfcModeChange(NfcSettings::NfcMode nfcMode);
private:
    NfcSettings* nfcSettings;
#endif

private:
    QNearFieldManager *nfcManager;
    QNearFieldTarget *cachedTarget;
    bool pendingWriteNdef;
    QNdefMessage cachedNdefMessage;
    QNearFieldTarget::RequestId writeRequestId;
    QDeclarativeView* declarativeView;
    /*! Running on Harmattan PR 1.0? Then, need to switch between reading
      and writng NDEF messages from/to tags, as this FW can't have both
      modes activated at the same time. This has been improved in PR 1.1+. */
    bool m_harmattanPr10;
};

#endif // NDEFMANAGER_H
