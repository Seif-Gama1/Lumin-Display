#include "DriverMonitoringReceiver.h"
#include <QDebug>
#include <QtMath>
#include <mqueue.h>
#include <fcntl.h>
#include <unistd.h>
#include <cerrno>
#include <cstring>

DriverMonitoringReceiver::DriverMonitoringReceiver(QObject *parent)
    : QThread(parent) {}

DriverMonitoringReceiver::~DriverMonitoringReceiver() {
    stop();
    wait();
}

void DriverMonitoringReceiver::stop() {
    requestInterruption();
}

QString DriverMonitoringReceiver::mapCodeToString(int code) const {
    switch (code) {
    case 0: return QStringLiteral("Focused");
    case 1: return QStringLiteral("Distracted");
    case 2: return QStringLiteral("Drowsy");
    case 3: return QStringLiteral("Micro Sleep");
    case 4: return QStringLiteral("No Face");
    default: return QStringLiteral("Unknown");
    }
}

void DriverMonitoringReceiver::run() {
    mqd_t mqd = (mqd_t)-1;
    bool firstRead = true;

    struct mq_attr attr;
    attr.mq_flags = 0;
    attr.mq_maxmsg = 10;
    attr.mq_msgsize = sizeof(ClusterData);
    attr.mq_curmsgs = 0;

    // Retry loop until vsomeip or Qt creates queue
    while (!isInterruptionRequested() && mqd == (mqd_t)-1) {
        mqd = mq_open("/dms_queue", O_RDONLY | O_CREAT, 0666, &attr);
        if (mqd == (mqd_t)-1) {
            // qDebug() << "[QT MQ ERROR] mq_open failed:" << strerror(errno) << "| Retrying...";
            QThread::msleep(500);
        } else {
            // qDebug() << "[QT MQ INIT] Attached to /dev/mqueue/dms_queue";
        }
    }

    ClusterData incomingData;

    while (!isInterruptionRequested()) {
        // Read buffer must be >= attr.mq_msgsize
        ssize_t bytesRead = mq_receive(mqd, reinterpret_cast<char*>(&incomingData), sizeof(ClusterData), nullptr);

        if (bytesRead >= static_cast<ssize_t>(sizeof(ClusterData))) {
            int newCode = incomingData.state_code;
            float newRisk = incomingData.risk_percentage;
            int newAlert = incomingData.alert_status;

            // qDebug().noquote() << QString("[QT MQ READ] Code: %1 | Risk: %2 | Alert: %3")
            //                           .arg(newCode)
            //                           .arg(static_cast<double>(newRisk), 0, 'f', 4)
            //                           .arg(newAlert);

            if (firstRead || newCode != m_stateCode) {
                m_stateCode = newCode;
                emit stateCodeChanged(m_stateCode);
                emit stateStringChanged(mapCodeToString(m_stateCode));
            }

            if (firstRead || !qFuzzyCompare(newRisk, m_riskPercentage)) {
                // qDebug() << "[QT SIGNAL EMIT] riskPercentageChanged ->" << newRisk;
                m_riskPercentage = newRisk;
                emit riskPercentageChanged(m_riskPercentage);
            }

            if (firstRead || newAlert != m_alertStatus) {
                m_alertStatus = newAlert;
                emit alertStatusChanged(m_alertStatus, m_riskPercentage);            }

            firstRead = false;
        } else if (bytesRead == -1) {
            // qDebug() << "[QT MQ RECV ERROR]:" << strerror(errno);
            QThread::msleep(100);
        }
    }

    if (mqd != (mqd_t)-1) {
        mq_close(mqd);
    }
}
