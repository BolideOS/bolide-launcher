/*
 * Copyright (C) 2026 BolideOS Contributors
 * All rights reserved.
 * BSD License — see project root for full text.
 */

#include "glanceregistry.h"

#include <QDBusConnection>
#include <QDBusError>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QStandardPaths>

GlanceRegistry *GlanceRegistry::s_instance = nullptr;

GlanceRegistry *GlanceRegistry::instance()
{
    if (!s_instance)
        s_instance = new GlanceRegistry();
    return s_instance;
}

GlanceRegistry::GlanceRegistry(QObject *parent)
    : QObject(parent)
{
    s_instance = this;

    // Deferred save — coalesce rapid updates into one disk write
    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(2000);
    connect(&m_saveTimer, &QTimer::timeout, this, &GlanceRegistry::saveToDisk);

    loadFromDisk();
}

bool GlanceRegistry::registerService()
{
    QDBusConnection bus = QDBusConnection::sessionBus();

    if (!bus.registerObject(QStringLiteral("/org/bolideos/Glances"),
                            this,
                            QDBusConnection::ExportAllSlots
                            | QDBusConnection::ExportAllSignals)) {
        qWarning("GlanceRegistry: failed to register D-Bus object: %s",
                 qPrintable(bus.lastError().message()));
        return false;
    }

    if (!bus.registerService(QStringLiteral("org.bolideos.Glances"))) {
        qWarning("GlanceRegistry: failed to register D-Bus service: %s",
                 qPrintable(bus.lastError().message()));
        return false;
    }

    return true;
}

// ── D-Bus methods ──────────────────────────────────────────────────

void GlanceRegistry::registerGlance(const QString &appId,
                                    const QString &glanceId,
                                    const QVariantMap &data)
{
    QString key = appId + "/" + glanceId;

    QVariantMap g = data;
    g[QStringLiteral("appId")] = appId;
    g[QStringLiteral("glanceId")] = glanceId;

    // Extract desktop file mapping if provided
    QString desktop = data.value("desktopFile").toString();
    if (!desktop.isEmpty()) {
        // Store mapping: basename without extension → appId
        // e.g. "bolide-fitness.desktop" → "org.bolide.fitness"
        QString base = QFileInfo(desktop).completeBaseName();
        m_desktopToAppId[base] = appId;
    }

    m_glances[key] = g;
    m_saveTimer.start();

    emit glanceUpdated(appId, glanceId, g);
    emit glancesChanged();
}

void GlanceRegistry::removeGlance(const QString &appId,
                                  const QString &glanceId)
{
    QString key = appId + "/" + glanceId;
    if (m_glances.remove(key)) {
        m_saveTimer.start();
        emit glancesChanged();
    }
}

void GlanceRegistry::removeApp(const QString &appId)
{
    bool changed = false;
    auto it = m_glances.begin();
    while (it != m_glances.end()) {
        if (it.key().startsWith(appId + "/")) {
            it = m_glances.erase(it);
            changed = true;
        } else {
            ++it;
        }
    }
    if (changed) {
        m_saveTimer.start();
        emit glancesChanged();
    }
}

QVariantList GlanceRegistry::allGlances() const
{
    QVariantList list;
    for (auto it = m_glances.constBegin(); it != m_glances.constEnd(); ++it)
        list.append(it.value());
    return list;
}

// ── QML helpers ────────────────────────────────────────────────────

QVariantMap GlanceRegistry::glanceForApp(const QString &desktopPath) const
{
    // desktopPath looks like:
    //   "/usr/share/applications/bolide-fitness.desktop"
    // Extract basename without extension
    QString base = QFileInfo(desktopPath).completeBaseName();
    QString appId = m_desktopToAppId.value(base);
    if (appId.isEmpty())
        return QVariantMap();

    // Return the first glance for this app
    for (auto it = m_glances.constBegin(); it != m_glances.constEnd(); ++it) {
        if (it.key().startsWith(appId + "/"))
            return it.value();
    }
    return QVariantMap();
}

bool GlanceRegistry::hasGlance(const QString &desktopPath) const
{
    QString base = QFileInfo(desktopPath).completeBaseName();
    return m_desktopToAppId.contains(base);
}

// ── Persistence ────────────────────────────────────────────────────

static QString glanceFilePath()
{
    QString dir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
                  + "/bolide-shell";
    QDir().mkpath(dir);
    return dir + "/glances.json";
}

void GlanceRegistry::loadFromDisk()
{
    QFile f(glanceFilePath());
    if (!f.open(QIODevice::ReadOnly))
        return;

    QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject())
        return;

    QJsonObject root = doc.object();

    // Load desktop→appId mapping
    QJsonObject mapping = root.value("desktopMapping").toObject();
    for (auto it = mapping.constBegin(); it != mapping.constEnd(); ++it)
        m_desktopToAppId[it.key()] = it.value().toString();

    // Load glance data
    QJsonArray glances = root.value("glances").toArray();
    for (const QJsonValue &v : glances) {
        QJsonObject obj = v.toObject();
        QString key = obj.value("appId").toString() + "/"
                    + obj.value("glanceId").toString();
        m_glances[key] = obj.toVariantMap();
    }
}

void GlanceRegistry::saveToDisk()
{
    QJsonObject root;

    // Save desktop→appId mapping
    QJsonObject mapping;
    for (auto it = m_desktopToAppId.constBegin();
         it != m_desktopToAppId.constEnd(); ++it)
        mapping[it.key()] = it.value();
    root["desktopMapping"] = mapping;

    // Save glance data
    QJsonArray glances;
    for (auto it = m_glances.constBegin(); it != m_glances.constEnd(); ++it)
        glances.append(QJsonObject::fromVariantMap(it.value()));
    root["glances"] = glances;

    QFile f(glanceFilePath());
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        f.write(QJsonDocument(root).toJson(QJsonDocument::Compact));
}
