#include "CanController.h"
#include "CanWorker.h"

CanController::CanController(QObject *parent) : QObject(parent) {
    // CHANGE: Store in member variable
    m_worker = new CanWorker(0, 0);
    m_worker->moveToThread(&m_workerThread);

    connect(&m_workerThread, &QThread::started, m_worker, &CanWorker::process);
    connect(m_worker, &CanWorker::vehicleDataReceived, this, &CanController::handleVehicleData);
    connect(&m_workerThread, &QThread::finished, m_worker, &QObject::deleteLater);

    connect(m_worker, &CanWorker::statusTelltalesReceived,
            this, &CanController::onStatusTelltalesReceived);

    connect(m_worker, &CanWorker::statusFaultsReceived,
            this, &CanController::handleStatusFaultsReceived);
    connect(m_worker, &CanWorker::ackButtonPressedReceived,
            this, &CanController::handleAckButtonPressed);

    connect(m_worker, &CanWorker::potentiometerDataReceived,
            this, &CanController::handlePotentiometerData);

    connect(this, &CanController::sendDmsAlertToWorker,
            m_worker, &CanWorker::sendDmsAlertStatus);

    m_workerThread.start();
}

CanController::~CanController() {
    // CHANGE: Tell worker loop to exit before closing thread
    if (m_worker) {
        m_worker->stop();
    }
    m_workerThread.quit();
    m_workerThread.wait();
}

void CanController::handleVehicleData(int rpm, int speed, QString gearMode, int gearNum, bool handsOn) {
    if (m_rpm != rpm || m_speed != speed || m_gearMode != gearMode ||
        m_gearNum != gearNum || m_handsOn != handsOn) {

        m_rpm = rpm;
        m_speed = speed;
        m_gearMode = gearMode;
        m_gearNum = gearNum;
        m_handsOn = handsOn;

        emit vehicleDataChanged(); // Triggers QML update
    }
}

// Slot Implementation:
void CanController::onStatusTelltalesReceived(bool highBeam, bool lowBeam, bool leftInd, bool rightInd)
{
    if (m_lightHighBeam != highBeam) {
        m_lightHighBeam = highBeam;
        emit lightHighBeamChanged();
    }
    if (m_lightLowBeam != lowBeam) {
        m_lightLowBeam = lowBeam;
        emit lightLowBeamChanged();
    }
    if (m_leftSignal != leftInd) {
        m_leftSignal = leftInd;
        emit leftSignalChanged();
    }
    if (m_rightSignal != rightInd) {
        m_rightSignal = rightInd;
        emit rightSignalChanged();
    }
}

void CanController::handleStatusFaultsReceived(uint8_t leftInd, uint8_t rightInd, uint8_t lowBeam, uint8_t highBeam) {
    // 01 = OPEN, 10 = SHORT
    setLightDirectionLeftFault(leftInd == 1 || leftInd == 2);
    setLightDirectionRightFault(rightInd == 1 || rightInd == 2);
    setLightLowBeamFault(lowBeam == 1 || lowBeam == 2);
    setLightHighBeamFault(highBeam == 1 || highBeam == 2);
}

void CanController::handleAckButtonPressed(bool pressed) {
    if (m_ackButtonPressed != pressed) {
        m_ackButtonPressed = pressed;
        emit ackButtonPressedChanged(); // Triggers QML property update
    }
}

void CanController::handlePotentiometerData(uint8_t fuelLevelRaw, uint8_t motorTempRaw) {
    // Map raw fuel (0-255) to percentage (0.0 - 100.0)
    int scaledFuel = static_cast<double>(fuelLevelRaw);
    int scaledTemp = static_cast<int>(motorTempRaw);

    if (m_fuelLevelPercentage != scaledFuel || m_motorTemperature != scaledTemp) {
        m_fuelLevelPercentage = scaledFuel;
        m_motorTemperature = scaledTemp;

        emit potentiometerDataChanged(); // Notify QML binding
    }
}

// --- Fault Setters ---

void CanController::setLightLowBeamFault(bool fault) {
    if (m_lightLowBeamFault != fault) {
        m_lightLowBeamFault = fault;
        emit lightLowBeamFaultChanged();
    }
}

void CanController::setLightHighBeamFault(bool fault) {
    if (m_lightHighBeamFault != fault) {
        m_lightHighBeamFault = fault;
        emit lightHighBeamFaultChanged();
    }
}

void CanController::setLightDirectionLeftFault(bool fault) {
    if (m_lightDirectionLeftFault != fault) {
        m_lightDirectionLeftFault = fault;
        emit lightDirectionLeftFaultChanged();
    }
}

void CanController::setLightDirectionRightFault(bool fault) {
    if (m_lightDirectionRightFault != fault) {
        m_lightDirectionRightFault = fault;
        emit lightDirectionRightFaultChanged();
    }
}

void CanController::sendDmsAlert(int alertStatus, float riskPercentage) {
    // Emit signal to m_worker; Qt automatically queues this safely across threads
    qDebug() << "[CanController] sendDmsAlert called with status:" << alertStatus;
    emit sendDmsAlertToWorker(alertStatus, riskPercentage);
}
