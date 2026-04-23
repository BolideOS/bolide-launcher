/*
 * Copyright (C) 2017 Florent Revest <revestflo@gmail.com>
 * All rights reserved.
 *
 * You may use this file under the terms of BSD license as follows:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the author nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "gesturefilterarea.h"

#include <QQuickWindow>
#include <QScreen>

GestureFilterArea::GestureFilterArea(QQuickItem *parent) : QQuickItem(parent)
{
    setFiltersChildMouseEvents(true);
    setAcceptedMouseButtons(Qt::LeftButton);
    m_toLeftAllowed = true;
    m_toRightAllowed = true;
    m_toBottomAllowed = true;
    m_toTopAllowed = true;

    m_threshold = width()*0.01;
}

void GestureFilterArea::geometryChanged(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    m_threshold = newGeometry.width()*0.01;
    QQuickItem::geometryChanged(newGeometry, oldGeometry);
}

bool GestureFilterArea::childMouseEventFilter(QQuickItem *i, QEvent *e)
{
    if (!isVisible() || !isEnabled())
        return QQuickItem::childMouseEventFilter(i, e);

    switch (e->type()) {
    case QEvent::MouseButtonPress:
    case QEvent::MouseMove:
    case QEvent::MouseButtonRelease:
        return filterMouseEvent(i, static_cast<QMouseEvent *>(e));
    case QEvent::UngrabMouse:
        break;
    default:
        break;
    }

    return QQuickItem::childMouseEventFilter(i, e);
}

void GestureFilterArea::mousePressEvent(QMouseEvent *event) {
    if (!isEnabled() || !(event->button() & acceptedMouseButtons())) {
        QQuickItem::mousePressEvent(event);
    } else {
        m_pressed = true;
        m_velocityX = 0;
        m_velocityY = 0;
        m_tracing = true;
        m_horizontal = false;
        m_prevPos = event->localPos();
        m_startPos = event->localPos();
        m_prevTimestamp = event->timestamp();
        m_counter = 0;
    }
}

void GestureFilterArea::mouseMoveEvent(QMouseEvent *event) {
    if (!isEnabled() || !m_pressed) {
        QQuickItem::mouseMoveEvent(event);
        return;
    }
    m_counter++;

    qreal deltaX = event->localPos().x() - m_prevPos.x();
    qreal deltaY = event->localPos().y() - m_prevPos.y();

    // Use time-based velocity (px per ~16ms frame) to normalize across
    // different event frequencies (QEMU USB tablet ~1000Hz vs real touch ~60-120Hz)
    ulong ts = event->timestamp();
    qreal dt = (ts > m_prevTimestamp) ? (qreal)(ts - m_prevTimestamp) : 1.0;
    if (dt < 0.001) dt = 1.0;  // guard against zero/negative
    qreal instantVx = deltaX / dt * 16.0;
    qreal instantVy = deltaY / dt * 16.0;

    const qreal alpha = 0.4;
    if (m_counter == 1) {
        m_velocityX = instantVx;
        m_velocityY = instantVy;
    } else {
        m_velocityX = alpha * instantVx + (1.0 - alpha) * m_velocityX;
        m_velocityY = alpha * instantVy + (1.0 - alpha) * m_velocityY;
    }
    m_prevTimestamp = ts;

    if(m_tracing && m_counter >= 3) {
        // Use total displacement from start for swipe direction detection,
        // not per-event velocity (which is too small with high-frequency events)
        qreal totalDx = event->localPos().x() - m_startPos.x();
        qreal totalDy = event->localPos().y() - m_startPos.y();
        qreal dispThreshold = m_threshold * 5;  // ~16px on 320px

        if (abs(totalDx) > abs(totalDy)) {
            if(totalDx > dispThreshold) {
                m_tracing = false;
                if(m_toRightAllowed) {
                    m_horizontal = true;
                    grabMouse();
                }
                else
                    m_pressed = false;
            } else if(totalDx < -dispThreshold) {
                m_tracing = false;
                if(m_toLeftAllowed) {
                    m_horizontal = true;
                    grabMouse();
                }
                else
                    m_pressed = false;
            }
        } else {
            if(totalDy > dispThreshold) {
                m_tracing = false;
                if(m_toBottomAllowed) {
                    m_horizontal = false;
                    grabMouse();
                }
                else
                    m_pressed = false;
            } else if(totalDy < -dispThreshold) {
                m_tracing = false;
                if(m_toTopAllowed) {
                    m_horizontal = false;
                    grabMouse();
                }
                else
                    m_pressed = false;
            }
        }
    } else if(m_pressed && !m_tracing) {
        // Only emit movement AFTER direction is committed — prevents cross-axis jitter
        qreal delta;
        if(m_horizontal)
            delta = event->localPos().x() - m_prevPos.x();
        else
            delta = event->localPos().y() - m_prevPos.y();

        emit swipeMoved(m_horizontal, delta);
    }
    m_prevPos = event->localPos();
}

void GestureFilterArea::mouseReleaseEvent(QMouseEvent *event) {
    if (!isEnabled() || !m_pressed) {
        QQuickItem::mouseReleaseEvent(event);
    } else {
        // If still tracing (direction not committed), determine direction
        // from total displacement so PanelsGrid can still snap
        if (m_tracing) {
            qreal totalDx = event->localPos().x() - m_startPos.x();
            qreal totalDy = event->localPos().y() - m_startPos.y();
            m_horizontal = qAbs(totalDx) > qAbs(totalDy);
        }
        qreal currVel;
        if(m_horizontal)
            currVel = m_velocityX;
        else
            currVel = m_velocityY;
        emit swipeReleased(m_horizontal, currVel, m_tracing);
        m_pressed = false;
        if (window() && window()->mouseGrabberItem() == this)
            ungrabMouse();
    }
}

bool GestureFilterArea::filterMouseEvent(QQuickItem *item, QMouseEvent *event) {
    QPointF localPos = mapFromScene(event->windowPos());
    QQuickWindow *c = window();
    QQuickItem *grabber = c ? c->mouseGrabberItem() : 0;

    // Process events when: no dominant grabber, OR we're actively tracking a gesture
    if (contains(localPos) && (m_pressed || !grabber || !grabber->keepMouseGrab())) {
        QMouseEvent mouseEvent(event->type(), localPos, event->windowPos(), event->screenPos(),
                               event->button(), event->buttons(), event->modifiers());
        mouseEvent.setAccepted(false);

        switch (event->type()) {
        case QEvent::MouseMove:
            mouseMoveEvent(&mouseEvent);
            break;
        case QEvent::MouseButtonPress:
            mousePressEvent(&mouseEvent);
            break;
        case QEvent::MouseButtonRelease:
            mouseReleaseEvent(&mouseEvent);
            break;
        default:
            break;
        }
    }
    return false;
}

void GestureFilterArea::mouseUngrabEvent() {
    if (m_pressed && !m_tracing) {
        // Grab was stolen during an active panel swipe — still snap
        qreal currVel = m_horizontal ? m_velocityX : m_velocityY;
        emit swipeReleased(m_horizontal, currVel, false);
    }
    m_pressed = false;
}
