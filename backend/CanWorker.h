#ifndef CANWORKER_H
#define CANWORKER_H


#include <QObject>
#include <QString>
#include "CanFrame.h"

// Qt Logging
#include <QDebug>

// POSIX & BSD Sockets (QNX / Linux target)
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <atomic>

class CanWorker : public QObject {
    Q_OBJECT
public:
    explicit CanWorker(unsigned int bus, unsigned int dev, QObject *parent = nullptr);
    ~CanWorker();

    void stop();

public slots:
    void process();
    void sendDmsAlertStatus(int alertStatus, float riskPercentage);

signals:
    void vehicleDataReceived(int rpm, int speed, QString gearMode, int gearNum, bool handsOn);
    void statusTelltalesReceived(bool highBeam, bool lowBeam, bool leftInd, bool rightInd);

    void statusFaultsReceived(uint8_t indicatorLeftFault, uint8_t indicatorRightFault,
                              uint8_t lowBeamFault, uint8_t highBeamFault);
    void driverError(const QString &msg);
    void ackButtonPressedReceived(bool pressed);
    void potentiometerDataReceived(uint8_t fuelLevel, uint8_t motorTemp);

private:
    void initSocketServer();
    void sendToLinuxGuest(uint32_t id, uint8_t dlc, const uint8_t *payload);

    unsigned int m_bus;
    unsigned int m_dev;
    std::atomic<bool> m_running{true};

    // Socket server descriptors
    int m_serverFd = -1;
    int m_clientFd = -1;
    static constexpr uint32_t CAN_ID_DMS_TX = 0x0A5;

};

#endif // CANWORKER_H
