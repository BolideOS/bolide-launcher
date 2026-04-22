#include "applauncher.h"
#include <QDebug>
#include <QElapsedTimer>

AppLauncher::AppLauncher(QObject *parent) : QObject(parent)
{
}

bool AppLauncher::launchApp(const QString &appName)
{
    QElapsedTimer t;
    t.start();
    qWarning() << "[LAUNCH] AppLauncher::launchApp() called for" << appName;

    // Skip the shell script wrapper — call invoker directly.
    // This avoids fork+exec of /bin/sh and the script overhead.
    QString soPath = QStringLiteral("/usr/lib/%1.so").arg(appName);
    QStringList args;
    args << QStringLiteral("--single-instance")
         << QStringLiteral("--type=qt5")
         << soPath;

    // Set env vars that the shell script would normally set
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("QT_WAYLAND_DISABLE_WINDOWDECORATION"), QStringLiteral("1"));

    QProcess proc;
    proc.setProcessEnvironment(env);
    bool ok = proc.startDetached(QStringLiteral("invoker"), args);
    qWarning() << "[LAUNCH] invoker startDetached returned" << ok << "in" << t.elapsed() << "ms";
    return ok;
}

bool AppLauncher::launchDesktopFile(const QString &desktopFile) {
    QString appName = desktopFile;
    if (appName.endsWith(".desktop")) {
        appName.chop(strlen(".desktop"));
    }
    return launchApp(appName);
}
