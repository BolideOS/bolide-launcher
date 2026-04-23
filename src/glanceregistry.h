/*
 * Copyright (C) 2026 BolideOS Contributors
 * All rights reserved.
 * BSD License — see project root for full text.
 *
 * GlanceRegistry — Central D-Bus service for app glance data.
 *
 * Any app can push glance data here. The shell's glance list
 * queries this registry to display rich cards.
 *
 * D-Bus service: org.bolideos.Glances
 * D-Bus path:    /org/bolideos/Glances
 *
 * Glance data map fields:
 *   title      (string)  — Line 1: glance title
 *   value      (string)  — Primary metric value (e.g. "7h 23m")
 *   valueRight (string)  — Secondary value, right-aligned (e.g. "49:04")
 *   label      (string)  — Status label (e.g. "Fair", "Optimal")
 *   icon       (string)  — Ion-icon name (e.g. "ios-moon")
 *   color      (string)  — Accent color hex (e.g. "#9C27B0")
 *   progress   (double)  — 0.0–1.0 for range bar position
 *   sparkline  (list)    — Array of numbers for mini graph
 *   barSegments(list)    — [{color, width}] for multi-color range bars
 *   pageId     (string)  — Deep-link page ID (app-specific)
 */

#ifndef GLANCEREGISTRY_H
#define GLANCEREGISTRY_H

#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include <QHash>
#include <QTimer>

class GlanceRegistry : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.bolideos.Glances")

public:
    static GlanceRegistry *instance();

    explicit GlanceRegistry(QObject *parent = nullptr);

    /** Start D-Bus service. Call once at startup. */
    bool registerService();

    // ── QML helpers (called from glance list delegate) ──────────────

    /** Get the first/primary glance for an app (by desktop file path). */
    Q_INVOKABLE QVariantMap glanceForApp(const QString &desktopPath) const;

    /** Check if any glance exists for an app. */
    Q_INVOKABLE bool hasGlance(const QString &desktopPath) const;

public slots:
    // ── D-Bus methods (callable by any app) ─────────────────────────

    /** Register or update a glance. appId = reverse-domain app name. */
    void registerGlance(const QString &appId,
                        const QString &glanceId,
                        const QVariantMap &data);

    /** Remove a specific glance. */
    void removeGlance(const QString &appId,
                      const QString &glanceId);

    /** Remove all glances for an app. */
    void removeApp(const QString &appId);

    /** Get all glances as a flat list. */
    QVariantList allGlances() const;

signals:
    /** Emitted whenever any glance data changes. QML bindings use this. */
    Q_SCRIPTABLE void glancesChanged();

    /** Per-glance update signal (for fine-grained listeners). */
    Q_SCRIPTABLE void glanceUpdated(const QString &appId,
                                    const QString &glanceId,
                                    const QVariantMap &data);

private:
    void loadFromDisk();
    void saveToDisk();

    // Key: "appId/glanceId" → glance data
    QHash<QString, QVariantMap> m_glances;

    // Mapping: desktop file basename → appId (for QML lookups)
    // e.g. "bolide-fitness" → "org.bolide.fitness"
    QHash<QString, QString> m_desktopToAppId;

    QTimer m_saveTimer;

    static GlanceRegistry *s_instance;
};

#endif // GLANCEREGISTRY_H
