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

#include "ndefmanager.h"

NdefManager::NdefManager(QObject *parent) :
    QObject(parent),
    pendingWriteNdef(false)
{
#if defined(MEEGO_EDITION_HARMATTAN)
    // Determine Harmattan FW version
    // PR 1.0 doesn't support activating read and write NDEF access at the same time,
    // so we need to switch between both modes depending on what the app intends to do.
    QSystemInfo* sysInfo = new QSystemInfo(this);
    if (sysInfo->version(QSystemInfo::Os) == "1.2" && sysInfo->version(QSystemInfo::Firmware).contains("10.2011.34")) {
        qDebug() << "Running Harmattan PR 1.0";
        m_harmattanPr10 = true;
    }
#endif
}

void NdefManager::setDeclarativeView(QDeclarativeView& view)
{
    declarativeView = &view;
}

void NdefManager::initAndStartNfc()
{
    // NdefManager (this) is the parent; will automaically delete nfcManager
    nfcManager = new QNearFieldManager(this);

    // MeeGo Harmattan PR 1.0 only allows one target access mode to be active at the same time
    if (m_harmattanPr10) {
        nfcManager->setTargetAccessModes(QNearFieldManager::NdefReadTargetAccess);
    } else {
        nfcManager->setTargetAccessModes(QNearFieldManager::NdefReadTargetAccess | QNearFieldManager::NdefWriteTargetAccess);
    }

    // Get notified when the tag gets out of range
    connect(nfcManager, SIGNAL(targetLost(QNearFieldTarget*)),
            this, SLOT(targetLost(QNearFieldTarget*)));
    connect(nfcManager, SIGNAL(targetDetected(QNearFieldTarget*)),
            this, SLOT(targetDetected(QNearFieldTarget*)));

    nfcManager->registerNdefMessageHandler(this, SLOT(targetMessageDetected(QNdefMessage,QNearFieldTarget*)));

    // Start detecting targets
    bool activationSuccessful = nfcManager->startTargetDetection();
    if (activationSuccessful) {
        emit nfcStatusUpdate("Successfully started target detection");
    } else {
        emit nfcStatusError("Error starting NFC target detection");
    }
}

void NdefManager::checkNfcStatus()
{
#ifdef Q_OS_SYMBIAN
    // Construct a new instance.
    nfcSettings = new NfcSettings(this);

    // Retrieve the NFC feature support information.
    NfcSettings::NfcFeature nfcFeature = nfcSettings->nfcFeature();

    if (nfcFeature == NfcSettings::NfcFeatureSupported) {
        // Connect signals for receiving mode change and error notifications.
        connect(nfcSettings, SIGNAL(nfcModeChanged(NfcSettings::NfcMode)), SLOT(handleNfcModeChange(NfcSettings::NfcMode)));
        connect(nfcSettings, SIGNAL(nfcErrorOccurred(NfcSettings::NfcError, int)), SLOT(handleNfcError(NfcSettings::NfcError, int)));

        // Retrieve the initial value of the NFC mode setting.
        NfcSettings::NfcMode nfcMode = nfcSettings->nfcMode();

        if (nfcMode != NfcSettings::NfcModeOn) {
            // NFC is supported but not switched on, prompt the user to enable it.
            emit nfcStatusError(tr("NFC hardware is available but currently switched off."));
        } else {
            emit nfcStatusUpdate(tr("NFC is supported and switched on."));
        }
    }
    else if (nfcFeature == NfcSettings::NfcFeatureSupportedViaFirmwareUpdate) {
        // Display message to user to update device firmware
        emit nfcStatusError(tr("Update device firmware to enable NFC support."));
        return;
    } else {
        // Display message informing the user that NFC is not supported by this device.
        emit nfcStatusError(tr("NFC not supported by this device."));
        return;
    }
#endif
}

void NdefManager::targetDetected(QNearFieldTarget *target)
{
    qDebug() << "Target detected!";
    // Handle potential errors emitted by the target
    connect(target, SIGNAL(error(QNearFieldTarget::Error,QNearFieldTarget::RequestId)),
            this, SLOT(targetError(QNearFieldTarget::Error,QNearFieldTarget::RequestId)));
    connect(target, SIGNAL(requestCompleted (const QNearFieldTarget::RequestId)),
            this, SLOT(requestCompleted(QNearFieldTarget::RequestId)));
    connect(target, SIGNAL(ndefMessagesWritten()),
            this, SLOT(ndefMessageWritten()));

    // Cache the target in any case for future writing
    // (so that we can also write on tags that are empty as of now)
    cachedTarget = target;

    if (!pendingWriteNdef)
    {
        // Check if the target has NDEF messages
        bool targetHasNdefMessage = target->hasNdefMessage();
#ifdef Q_OS_SYMBIAN
        // Bug workaround on Symbian: hasNdefMessage() always returns false
        // for a NFC Forum Tag Type 4, even if an NDEF message is present on the tag.
        // See: https://bugreports.qt.nokia.com/browse/QTMOBILITY-2018
        if (target->type() == QNearFieldTarget::NfcTagType4 && !targetHasNdefMessage) {
            targetHasNdefMessage = true;
        }
#endif
        if (targetHasNdefMessage)
        {
            // Target has NDEF messages: read them (asynchronous)
            connect(target, SIGNAL(ndefMessageRead(QNdefMessage)),
                    this, SLOT(ndefMessageRead(QNdefMessage)));
            target->readNdefMessages();
        }
    }
    else
    {
        if (m_harmattanPr10) {
            nfcManager->setTargetAccessModes(QNearFieldManager::NdefWriteTargetAccess);
        }
        // Write a cached NDEF message to the tag
        writeCachedNdefMessage();
    }
}

void NdefManager::targetMessageDetected(const QNdefMessage &message, QNearFieldTarget* /*target*/)
{
    qDebug() << "Target Message detected!";
    // Go through all records in the message
    ndefMessageRead(message);
#ifdef MEEGO_EDITION_HARMATTAN
    // MeeGo: raise the app to the foreground in case it was autostarted by touching the tag
    // AND it was already running in the background.
    // If we wouldn't do it, the app would receive the tag, but remain in the background.
    if (declarativeView) {
        declarativeView->raise();
    }
#endif
}

void NdefManager::ndefMessageRead(const QNdefMessage &message)
{
    // Go through all records in the message
    foreach (const QNdefRecord &record, message) {
        qDebug() << "Record type: " << record.type();
        // Check type again, just to make sure
        if (record.isRecordType<QNdefNfcUriRecord>()) {
            // ------------------------------------------------
            // URI
            // Convert to the specialized URI record class
            QNdefNfcUriRecord uriRecord(record);
            // Emit a signal with the URI
            emit nfcReadTagUri(uriRecord.uri());
        }
        else if (record.isRecordType<QNdefNfcTextRecord>()) {
            // ------------------------------------------------
            // Text
            // Convert to the specialized text record class
            QNdefNfcTextRecord textRecord(record);
            // Emit a signal with the text
            emit nfcReadTagText(textRecord.text());
        }
        else if (record.isRecordType<NdefNfcSpRecord>()) {
            // ------------------------------------------------
            // Smart Poster (urn:nfc:wkt:Sp)
            NdefNfcSpRecord spRecord(record);
            // Check if the Smart Poster has a title text
            QString title;
            if (spRecord.titleCount() >= 1)
                title = spRecord.title(0).text();
            // Emit a signal with the Smart Poster basic info
            emit nfcReadTagSp(spRecord.uri(), title);
        }
        else if (record.isRecordType<NdefNfcMimeVcardRecord>()) {
            // ------------------------------------------------
            // Mime type: vCard
            NdefNfcMimeVcardRecord vCardRecord(record);

            // Parse versit document to QContact(s)
            QList<QContact> contacts = vCardRecord.contacts();
            if (!contacts.isEmpty()) {
                // Get the first contact
                QContact curContact = contacts.first();

                // Retrieve name, email and phone
                QString contactName = curContact.displayLabel();
                QString contactEmail = curContact.detail<QContactEmailAddress>().emailAddress();
                QString contactPhone = curContact.detail<QContactPhoneNumber>().number();
                // Emit a signal with the vCard basic info
                emit nfcReadTagVcard(contactName, contactEmail, contactPhone);
            } else {
                // No contacts returned from parsing? -> Error
                emit nfcReadTagUnknown(record.type(), QString("Error parsing vCard\n" + vCardRecord.error()).toUtf8());
            }
        }
        else if (record.typeNameFormat() == QNdefRecord::ExternalRtd &&
                   record.type() == "nokia.com:nfccorkboard") {
            emit nfcReadTagAutostart(record.payload());
        }
        else {
            // ------------------------------------------------
            // Record type not handled by this application
            emit nfcReadTagUnknown(record.type(), record.payload());
        }
    }
}

void NdefManager::nfcWriteTag(const QString &nfcTagText)
{
    // Create a new NDEF message
    QNdefMessage message;
    bool createdMessage = false;

    // First try if the text is a Smart Poster -> it is considered so
    // when the first line is a URL and the second line(s) text.

    // To check if text is an URL: the string is converted to a QUrl
    // and checked if it's valid. This is only a rather simple conversion:
    // We additionally check if the URL contains a '.' character,
    // as otherwise a word like "hello" would be converted to
    // "http://hello". Obviously, this assumption doesn't work when
    // you want to store telephone numbers as URIs; but this example is
    // only intended for Internet URLs and plain text.

    if (nfcTagText.startsWith("Corkboards Autostart")) {
        // Create a new corkboards autostart tag
        QNdefRecord autostartRecord;
        autostartRecord.setTypeNameFormat(QNdefRecord::ExternalRtd);
        autostartRecord.setType("nokia.com:nfccorkboard");
        // Get payload
        const QString payloadText = "Payload:\n";
        const int payloadPos = nfcTagText.indexOf(payloadText);
        if (payloadPos > -1) {
            const int payloadLength = nfcTagText.length() - (payloadPos + payloadText.length());
            if (payloadLength > 0) {
                QByteArray autostartPayload;
                autostartPayload.append(nfcTagText.right(payloadLength));
                autostartRecord.setPayload(autostartPayload);
            }
        }
        message.append(autostartRecord);
        createdMessage = true;
        qDebug() << "Creating autostart message ...";
    }
    if (!createdMessage) {
        const int newLinePos = nfcTagText.indexOf("\n");
        if (newLinePos >= 1 && nfcTagText.size() > 3) {
            // Text has at least two lines, with the first line having at least one char
            // Could be a smart poster - check if the first line is a URL
            QString firstLine = nfcTagText.left(newLinePos);
            //qDebug() << "*** First line: '" << firstLine << "'";
            QUrl convertedUrl = QUrl::fromUserInput(firstLine);
            if (convertedUrl.isValid() && firstLine.contains('.')) {
                // Store this as a Smart Poster
                NdefNfcSpRecord spRecord;
                spRecord.setUri(convertedUrl);
                QNdefNfcTextRecord titleRecord;
                titleRecord.setText(nfcTagText.right(nfcTagText.size() - newLinePos - 1));

                //qDebug() << "*** Second line: '" << nfcTagText.right(nfcTagText.size() - newLinePos - 1) << "'";
                spRecord.addTitle(titleRecord);
                message.append(spRecord);
                createdMessage = true;
                qDebug() << "Creating Smart Poster message ...";
            }
        }
    }
    // No Smart Poster created?
    // Check if we should create a URI record, or otherwise a plain text record.
    if (!createdMessage) {
        QUrl convertedUrl = QUrl::fromUserInput(nfcTagText);
        if (convertedUrl.isValid() && nfcTagText.contains('.'))
        {
            // The string was a URL, so create a URL record
            QNdefNfcUriRecord uriRecord;
            uriRecord.setUri(convertedUrl);
            message.append(uriRecord);
            qDebug() << "Creating URI message ...";
            createdMessage = true;
        } else {
            // Write a text record to the tag
            QNdefNfcTextRecord textRecord;
            textRecord.setText(nfcTagText);
            // Use the English locale.
            textRecord.setLocale("en");
            message.append(textRecord);
            qDebug() << "Creating Text message ...";
            createdMessage = true;
        }
    }
    // Write the message (containing either a URL or plain text) to the target.
    if (createdMessage) {
        cachedNdefMessage = message;
        pendingWriteNdef = true;
        writeCachedNdefMessage();
    }
}

void NdefManager::writeCachedNdefMessage()
{
    if (pendingWriteNdef)
    {
        if (cachedTarget)
        {
            // Check target access mode
            QNearFieldManager::TargetAccessModes accessModes = nfcManager->targetAccessModes();
            if (accessModes.testFlag(QNearFieldManager::NdefWriteTargetAccess))
            {
                writeRequestId = cachedTarget->writeNdefMessages(QList<QNdefMessage>() << cachedNdefMessage);
                if (m_harmattanPr10) {
                    nfcManager->setTargetAccessModes(QNearFieldManager::NdefReadTargetAccess);
                }
                pendingWriteNdef = false;
            } else {
                // Device is not in writing mode
                emit nfcStatusUpdate("Please touch the tag again to write the message.");
            }
        } else {
            // Can't write - no cached target available
            emit nfcStatusUpdate("Please touch a tag to write the message.");
        }
    }
}

void NdefManager::targetLost(QNearFieldTarget *target)
{
    cachedTarget = NULL;
    target->deleteLater();
}

void NdefManager::targetError(QNearFieldTarget::Error error, const QNearFieldTarget::RequestId &/*id*/)
{
    QString errorText("Error: " + convertTargetErrorToString(error));
    qDebug() << errorText;
    nfcReadTagError(errorText);
}

QString NdefManager::convertTargetErrorToString(QNearFieldTarget::Error error)
{
    QString errorString = "Unknown";
    switch (error)
    {
    case QNearFieldTarget::NoError:
        errorString = "No error has occurred.";
        break;
    case QNearFieldTarget::UnsupportedError:
        errorString = "The requested operation is unsupported by this near field target.";
        break;
    case QNearFieldTarget::TargetOutOfRangeError:
        errorString = "The target is no longer within range.";
        break;
    case QNearFieldTarget::NoResponseError:
        errorString = "The target did not respond.";
        break;
    case QNearFieldTarget::ChecksumMismatchError:
        errorString = "The checksum has detected a corrupted response.";
        break;
    case QNearFieldTarget::InvalidParametersError:
        errorString = "Invalid parameters were passed to a tag type specific function.";
        break;
    case QNearFieldTarget::NdefReadError:
        errorString = "Failed to read NDEF messages from the target.";
        break;
    case QNearFieldTarget::NdefWriteError:
        errorString = "Failed to write NDEF messages to the target.";
        break;
    case QNearFieldTarget::UnknownError:
        errorString = "Unknown error.";
        break;
    }
    return errorString;
}

void NdefManager::requestCompleted(const QNearFieldTarget::RequestId &id)
{
    qDebug() << "Request completed";
    if (id == writeRequestId)
    {
        emit nfcStatusUpdate("Message written to the tag.");
    }
}

/*!
  \brief Slot called by Qt Mobility when an NDEF message was successfully
  written to a tag.

  Emits an nfcStatusUpdate signal to log this in the user interface.
  On MeeGo, both the requestCompleted() method and this method will be called
  when writing a tag.
  */
void NdefManager::ndefMessageWritten()
{
    emit nfcStatusUpdate("Message written to the tag.");
}



#ifdef Q_OS_SYMBIAN
void NdefManager::handleNfcModeChange(NfcSettings::NfcMode nfcMode)
{
    switch (nfcMode) {
    case NfcSettings::NfcModeNotSupported:
        // NFC is not currently supported. It is not possible to distinguish
        // whether a firmware update could enable NFC features based solely
        // on the value of the nfcMode parameter. The return value of
        // NfcSettings::nfcFeature() indicates whether a firmware update is
        // applicable to this device.
        emit nfcStatusError(tr("NFC is not currently supported."));
        break;
    case NfcSettings::NfcModeUnknown:
        // NFC is supported, but the current mode is unknown at this time.
        emit nfcStatusError(tr("NFC is supported, but the current mode is unknown at this time."));
        break;
    case NfcSettings::NfcModeOn:
        // NFC is supported and switched on.
        emit nfcStatusUpdate(tr("NFC is supported and switched on."));
        break;
    case NfcSettings::NfcModeCardOnly:
        // NFC hardware is available and currently in card emulation mode.
        emit nfcStatusError(tr("NFC hardware is available and currently in card emulation mode."));
        break;
    case NfcSettings::NfcModeOff:
        // NFC hardware is available but currently switched off.
        emit nfcStatusError(tr("NFC hardware is available but currently switched off."));
        break;
    default:
        break;
    }
}


void NdefManager::handleNfcError(NfcSettings::NfcError nfcError, int error)
{
    // The platform specific error code is ignored here.
    Q_UNUSED(error)

    switch (nfcError) {
    case NfcSettings::NfcErrorFeatureSupportQuery:
        // Unable to query NFC feature support.
        emit nfcStatusError(tr("Unable to query NFC feature support."));
        break;
    case NfcSettings::NfcErrorSoftwareVersionQuery:
        // Unable to query device software version.
        emit nfcStatusError(tr("Unable to query device software version."));
        break;
    case NfcSettings::NfcErrorModeChangeNotificationRequest:
        // Unable to request NFC mode change notifications.
        emit nfcStatusError(tr("Unable to request NFC mode change notifications."));
        break;
    case NfcSettings::NfcErrorModeChangeNotification:
        // NFC mode change notification was received, but caused an error.
        emit nfcStatusError(tr("NFC mode change notification was received, but caused an error."));
        break;
    case NfcSettings::NfcErrorModeRetrieval:
        // Unable to retrieve current NFC mode.
        emit nfcStatusError(tr("Unable to retrieve current NFC mode."));
        break;
    default:
        break;
    }
}
#endif
