#ifndef MEEGOSIPEVENTFILTER_H
#define MEEGOSIPEVENTFILTER_H

#include <QObject>
#include <QInputContext>
#include <QApplication>

/**
  * Temporary workaround to close the software input panel when the
  * QML TextEdit element loses focus.
  * Only required on MeeGo Harmattan PR 1.0.
  */
class MeeGoSipEventFilter : public QObject
{
    Q_OBJECT
public:
    explicit MeeGoSipEventFilter(QObject *parent = 0) :
        QObject(parent)
    {
    }
protected:
    bool eventFilter(QObject *obj, QEvent *event) {
        QInputContext *ic = qApp->inputContext();
        if (ic) {
            if (ic->focusWidget() == 0 && prevFocusWidget) {
                QEvent closeSIPEvent(QEvent::CloseSoftwareInputPanel);
                ic->filterEvent(&closeSIPEvent);
            } else if (prevFocusWidget == 0 && ic->focusWidget()) {
                QEvent openSIPEvent(QEvent::RequestSoftwareInputPanel);
                ic->filterEvent(&openSIPEvent);
            }
            prevFocusWidget = ic->focusWidget();
        }
        return QObject::eventFilter(obj,event);
    }
private:
    QWidget *prevFocusWidget;


};

#endif // MEEGOSIPEVENTFILTER_H
