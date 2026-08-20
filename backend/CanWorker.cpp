#include "CanWorker.h"
#include <QThread>
#include <QChar>
#include <QCoreApplication>
#include <unistd.h> // usleep for QNX
extern "C" {
#include "mcp2515.h"
}

CanWorker::CanWorker(unsigned int bus, unsigned int dev, QObject *parent)
    : QObject(parent), m_bus(bus), m_dev(dev) {}

CanWorker::~CanWorker(){
    stop();

    rpi_spi_cleanup_device(m_bus, m_dev);

    if (m_clientFd >= 0)
        ::close(m_clientFd);

    if (m_serverFd >= 0)
        ::close(m_serverFd);
}

void CanWorker::stop(){
    m_running.store(false, std::memory_order_relaxed);
}

void CanWorker::initSocketServer(){
    m_serverFd = ::socket(AF_INET, SOCK_STREAM, 0);

    if (m_serverFd < 0) {
        qWarning() << "[CanWorker Socket] socket() failed:"
                   << strerror(errno);
        return;
    }

    int opt = 1;

    if (::setsockopt(
            m_serverFd,
            SOL_SOCKET,
            SO_REUSEADDR,
            &opt,
            sizeof(opt)) < 0) {

        qWarning() << "[CanWorker Socket] setsockopt() failed:"
                   << strerror(errno);
    }

    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(5555);

    if (::bind(
            m_serverFd,
            reinterpret_cast<struct sockaddr*>(&address),
            sizeof(address)) < 0) {

        qWarning() << "[CanWorker Socket] bind() failed:"
                   << strerror(errno)
                   << "errno =" << errno;

        ::close(m_serverFd);
        m_serverFd = -1;
        return;
    }

    qDebug() << "[CanWorker Socket] bind() SUCCESS on port 5555";

    if (::listen(m_serverFd, 1) < 0) {

        qWarning() << "[CanWorker Socket] listen() failed:"
                   << strerror(errno)
                   << "errno =" << errno;

        ::close(m_serverFd);
        m_serverFd = -1;
        return;
    }

    int flags = fcntl(m_serverFd, F_GETFL, 0);

    if (flags < 0) {
        qWarning() << "[CanWorker Socket] fcntl(F_GETFL) failed:"
                   << strerror(errno);
    } else if (fcntl(m_serverFd, F_SETFL, flags | O_NONBLOCK) < 0) {
        qWarning() << "[CanWorker Socket] fcntl(F_SETFL) failed:"
                   << strerror(errno);
    }

    qDebug() << "[CanWorker Socket] SERVER LISTENING on 0.0.0.0:5555";
}

void CanWorker::sendDmsAlertStatus(int alertStatus, float riskPercentage) {
    uint8_t payload[8] = {0};

    // Byte 0: Alert Status (0 = OK, 1 = Warning/Alert)
    payload[0] = static_cast<uint8_t>(alertStatus);

    // Byte 1: Risk Percentage normalized to 0-100%
    payload[1] = static_cast<uint8_t>(riskPercentage * 100.0f);

    uint8_t dlc = 2;

    // 1. Transmit out over MCP2515 hardware CAN SPI
    mcp2515_send_can_msg(m_bus, m_dev, CAN_ID_DMS_TX, dlc, payload);

    // 2. Relay frame over TCP socket to Linux Guest (if connected)
    sendToLinuxGuest(CAN_ID_DMS_TX, dlc, payload);
}

void CanWorker::sendToLinuxGuest(uint32_t id, uint8_t dlc, const uint8_t *payload) {
    // Transmit raw frame over TCP socket if connected
    if (m_clientFd >= 0) {
        CanFrame frame{};
        frame.can_id = id;
        frame.can_dlc = dlc;
        std::memcpy(frame.data, payload, dlc > 8 ? 8 : dlc);

        ssize_t bytesSent = ::send(m_clientFd, &frame, sizeof(CanFrame), MSG_NOSIGNAL);
        if (bytesSent <= 0) {
            if (errno != EAGAIN && errno != EWOULDBLOCK) {
                qWarning() << "[CanWorker Socket] Linux Guest disconnected during TX";
                ::close(m_clientFd);
                m_clientFd = -1;
            }
        }
    }
}

void CanWorker::process(){
    initSocketServer();

    if (rpi_spi_configure_device(m_bus, m_dev, 0x408, 500000) != SPI_SUCCESS) {
        emit driverError("Failed to configure QNX SPI device hardware!");
        return;
    }
    if (mcp2515_init(m_bus, m_dev) != 0) {
        emit driverError("Failed to initialize MCP2515 on QNX SPI bus!");
        return;
    }

    // 0x64 = Disable filters (0x60) + Enable Rollover BUKT bit (0x04)
    mcp2515_write_reg(m_bus, m_dev, MCP_RXB0CTRL, 0x64);
    mcp2515_write_reg(m_bus, m_dev, MCP_RXB1CTRL, 0x60);

    uint32_t can_id = 0;
    uint8_t dlc = 0;
    uint8_t payload[8] = {0};


    while (m_running.load(std::memory_order_relaxed)) {
        // CRITICAL FIX: Process queued Qt events (e.g. sendDmsAlertStatus)
        QCoreApplication::processEvents();

        // 1. Accept Linux VM connections
        if (m_clientFd < 0 && m_serverFd >= 0) {
            sockaddr_in clientAddr{};
            socklen_t addrLen = sizeof(clientAddr);
            int newClient = ::accept(m_serverFd, (struct sockaddr*)&clientAddr, &addrLen);
            if (newClient >= 0) {
                m_clientFd = newClient;
                int flags = fcntl(m_clientFd, F_GETFL, 0);
                fcntl(m_clientFd, F_SETFL, flags | O_NONBLOCK);
                qDebug() << "[CanWorker Socket] Linux Guest connected!";
            }
        }

        // 2. Transmit path (Linux -> QNX -> MCP2515)
        if (m_clientFd >= 0) {
            CanFrame txFrame{};
            ssize_t bytesRead = ::recv(m_clientFd, &txFrame, sizeof(CanFrame), MSG_DONTWAIT);

            if (bytesRead == sizeof(CanFrame)) {
                mcp2515_send_can_msg(m_bus, m_dev, txFrame.can_id, txFrame.can_dlc, txFrame.data);
            } else if (bytesRead == 0 || (bytesRead < 0 && errno != EAGAIN && errno != EWOULDBLOCK)) {
                qWarning() << "[CanWorker Socket] Linux Client disconnected.";
                ::close(m_clientFd);
                m_clientFd = -1;
            }
        }

        // 3. Receive path
        int status;

        while ((status = mcp2515_read_can_msg(m_bus, m_dev, &can_id, &dlc, payload)) > 0) {

            // qDebug("[CAN RECV] ID: 0x%03X | DLC: %d", can_id, dlc);

            if (can_id == 0x0A2 && dlc >= 6) {
                uint8_t lsb = static_cast<uint8_t>(payload[0]);
                uint8_t msb = static_cast<uint8_t>(payload[1]);
                int rpm = lsb | (msb << 8);
                int speed = payload[2];
                QString gearMode = QString(QChar(payload[3]));
                int gearNum = static_cast<int8_t>(payload[4]);
                bool handsOn = (payload[5] & 0x01) != 0;

                emit vehicleDataReceived(rpm, speed, gearMode, gearNum, handsOn);
            }else if (can_id == 0x0A3 && dlc >= 3) {
                // ---------------------------------------------------------
                // Byte 0: Telltale states
                //
                // Bit 0 = High Beam
                // Bit 1 = Low Beam
                // Bit 2 = Left Indicator
                // Bit 3 = Right Indicator
                // Bits 7:4 = Reserved
                // ---------------------------------------------------------
                bool lightHighBeam  = (payload[0] & (1 << 0)) != 0;
                bool lightLowBeam   = (payload[0] & (1 << 1)) != 0;
                bool indicatorLeft  = (payload[0] & (1 << 2)) != 0;
                bool indicatorRight = (payload[0] & (1 << 3)) != 0;
                // left blinker takes place of right blinker
                // right blinker takes place of high beam

                emit statusTelltalesReceived(lightHighBeam, lightLowBeam,
                                             indicatorLeft, indicatorRight);

                // ---------------------------------------------------------
                // Byte 1: LED fault status
                //
                // Bits 1:0 = Left Indicator Fault
                // Bits 3:2 = Right Indicator Fault
                // Bits 5:4 = Low Beam Fault
                // Bits 7:6 = High Beam Fault
                //
                // 00 = OK
                // 01 = OPEN
                // 10 = SHORT
                // 11 = Reserved
                // ---------------------------------------------------------
                uint8_t indicatorLeftFault  = (payload[1] >> 0) & 0x03;
                uint8_t indicatorRightFault = (payload[1] >> 2) & 0x03;
                uint8_t lowBeamFault        = (payload[1] >> 4) & 0x03;
                uint8_t highBeamFault       = (payload[1] >> 6) & 0x03;

                bool ackBtn = (payload[2] & (1 << 0)) != 0;

                uint8_t fuelLevel = payload[3];
                uint8_t motorTemp = payload[4];

                emit ackButtonPressedReceived(ackBtn);

                emit statusFaultsReceived(indicatorLeftFault, indicatorRightFault,
                                            lowBeamFault, highBeamFault);
                emit potentiometerDataReceived(fuelLevel, motorTemp);
            }
            sendToLinuxGuest(can_id, dlc, payload);
        }

        usleep(500);
    }
}
