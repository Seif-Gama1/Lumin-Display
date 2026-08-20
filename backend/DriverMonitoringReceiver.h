#ifndef DRIVERMONITORINGRECEIVER_H
#define DRIVERMONITORINGRECEIVER_H

#include <QThread>
#include <QString>
#include <atomic>
#include <mqueue.h>
#include <fcntl.h>
#include <unistd.h>

// Matching layout written by the vsomeip client over /dms_queue
struct ClusterData {
    int state_code;         // Offset 0 (4 bytes)
    float risk_percentage;  // Offset 4 (4 bytes)
    int alert_status;       // Offset 8 (4 bytes)
};

class DriverMonitoringReceiver : public QThread {
    Q_OBJECT
    Q_PROPERTY(int stateCode READ stateCode NOTIFY stateCodeChanged)
    Q_PROPERTY(QString stateString READ stateString NOTIFY stateStringChanged)
    Q_PROPERTY(float riskPercentage READ riskPercentage NOTIFY riskPercentageChanged)
    Q_PROPERTY(int alertStatus READ alertStatus NOTIFY alertStatusChanged)

public:
    explicit DriverMonitoringReceiver(QObject *parent = nullptr);
    ~DriverMonitoringReceiver();

    int stateCode() const { return m_stateCode; }
    QString stateString() const { return mapCodeToString(m_stateCode); }
    float riskPercentage() const { return m_riskPercentage; }
    int alertStatus() const { return m_alertStatus; }

    void stop();

signals:
    void stateCodeChanged(int stateCode);
    void stateStringChanged(const QString &stateString);
    void riskPercentageChanged(float riskPercentage);
    void alertStatusChanged(int alertStatus, float riskPercentage);

protected:
    void run() override;

private:
    int m_stateCode{0};
    float m_riskPercentage{0.0f};
    int m_alertStatus{0};

    QString mapCodeToString(int code) const;
};

#endif
