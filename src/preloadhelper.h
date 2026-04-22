#ifndef PRELOADHELPER_H
#define PRELOADHELPER_H

#include <QObject>
#include <QProcess>
#include <QTimer>

class PreloadHelper : public QObject
{
    Q_OBJECT
public:
    explicit PreloadHelper(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE void schedulePreload(const QString &appName, int delayMs = 1000) {
        QTimer::singleShot(delayMs, this, [appName]{
            QString soPath = QStringLiteral("/usr/lib/%1.so").arg(appName);
            qWarning("[LAUNCH] Re-preloading %s via invoker", qPrintable(appName));
            QProcess::startDetached(QStringLiteral("invoker"),
                QStringList() << "--single-instance" << "--type=qt5" << soPath);
        });
    }
};

#endif // PRELOADHELPER_H
