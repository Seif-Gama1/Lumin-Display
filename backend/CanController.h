#ifndef CANCONTROLLER_H
#define CANCONTROLLER_H

#include <QObject>
#include <QString>
#include <QThread>

class CanWorker; // Forward declaration

class CanController : public QObject {
    Q_OBJECT

    Q_PROPERTY(double rpm READ rpm NOTIFY vehicleDataChanged)
    Q_PROPERTY(double speed READ speed NOTIFY vehicleDataChanged)
    Q_PROPERTY(QString transmission READ transmission NOTIFY vehicleDataChanged)
    Q_PROPERTY(int gear READ gear NOTIFY vehicleDataChanged)
    Q_PROPERTY(bool handsOn READ handsOn NOTIFY vehicleDataChanged)
    Q_PROPERTY(bool lightLowBeam READ lightLowBeam NOTIFY lightLowBeamChanged)
    Q_PROPERTY(bool lightHighBeam READ lightHighBeam NOTIFY lightHighBeamChanged)
    Q_PROPERTY(bool leftSignal READ leftSignal NOTIFY leftSignalChanged)
    Q_PROPERTY(bool rightSignal READ rightSignal NOTIFY rightSignalChanged)

    // --- NEW: Lighting Fault Properties ---
    Q_PROPERTY(bool lightLowBeamFault READ lightLowBeamFault NOTIFY lightLowBeamFaultChanged)
    Q_PROPERTY(bool lightHighBeamFault READ lightHighBeamFault NOTIFY lightHighBeamFaultChanged)
    Q_PROPERTY(bool lightDirectionLeftFault READ lightDirectionLeftFault NOTIFY lightDirectionLeftFaultChanged)
    Q_PROPERTY(bool lightDirectionRightFault READ lightDirectionRightFault NOTIFY lightDirectionRightFaultChanged)

    Q_PROPERTY(bool ackButtonPressed READ ackButtonPressed NOTIFY ackButtonPressedChanged)

    // Potentiometers
    // Change properties to match QML expected types:
    Q_PROPERTY(int fuelLevel READ fuelLevel NOTIFY potentiometerDataChanged)
    Q_PROPERTY(int motorTemperature READ motorTemperature NOTIFY potentiometerDataChanged)

public:
    explicit CanController(QObject *parent = nullptr);
    ~CanController();

    double rpm() const { return m_rpm; }
    double speed() const { return m_speed; }
    QString transmission() const { return m_gearMode; }
    int gear() const { return m_gearNum; }
    bool handsOn() const { return m_handsOn; }
    bool lightLowBeam() const { return m_lightLowBeam; }
    bool lightHighBeam() const { return m_lightHighBeam; }
    bool leftSignal() const { return m_leftSignal; }
    bool rightSignal() const { return m_rightSignal; }

    // Fault Getters
    bool lightLowBeamFault() const { return m_lightLowBeamFault; }
    bool lightHighBeamFault() const { return m_lightHighBeamFault; }
    bool lightDirectionLeftFault() const { return m_lightDirectionLeftFault; }
    bool lightDirectionRightFault() const { return m_lightDirectionRightFault; }
    // Acknowledge button for faults Getter
    bool ackButtonPressed() const { return m_ackButtonPressed; }

    int fuelLevel() const { return m_fuelLevelPercentage; }
    int motorTemperature() const { return m_motorTemperature; }

    // Fault Setters
    void setLightLowBeamFault(bool fault);
    void setLightHighBeamFault(bool fault);
    void setLightDirectionLeftFault(bool fault);
    void setLightDirectionRightFault(bool fault);
    Q_INVOKABLE void sendDmsAlert(int alertStatus, float riskPercentage);

public slots:
    void handleVehicleData(int rpm, int speed, QString gearMode, int gearNum, bool handsOn);
    void onStatusTelltalesReceived(bool highBeam, bool lowBeam, bool leftInd, bool rightInd);
    void handleStatusFaultsReceived(uint8_t leftInd, uint8_t rightInd, uint8_t lowBeam, uint8_t highBeam);
    void handleAckButtonPressed(bool pressed); // 3. Slot to receive from CanWorker
    void handlePotentiometerData(uint8_t fuelLevel, uint8_t motorTemp);
signals:
    void vehicleDataChanged();
    void lightLowBeamChanged();
    void lightHighBeamChanged();
    void leftSignalChanged();
    void rightSignalChanged();

    // Fault Change Signals
    void lightLowBeamFaultChanged();
    void lightHighBeamFaultChanged();
    void lightDirectionLeftFaultChanged();
    void lightDirectionRightFaultChanged();

    void ackButtonPressedChanged(); // 4. Signal for QML bindings
    void potentiometerDataChanged();

    void sendDmsAlertToWorker(int alertStatus, float riskPercentage);

private:
    QThread m_workerThread;
    CanWorker *m_worker{nullptr}; // <-- CHANGE: Store pointer for clean shutdown

    // Telemetry State
    int m_rpm{0};
    int m_speed{0};
    QString m_gearMode{"P"};
    int m_gearNum{0};
    bool m_handsOn{false};

    // Light State
    bool m_lightLowBeam{false};
    bool m_lightHighBeam{false};
    bool m_leftSignal{false};
    bool m_rightSignal{false};

    // Fault State
    bool m_lightLowBeamFault{false};
    bool m_lightHighBeamFault{false};
    bool m_lightDirectionLeftFault{false};
    bool m_lightDirectionRightFault{false};

    bool m_ackButtonPressed{false};

    int m_motorTemperature {0};
    int m_fuelLevelPercentage {0};
};

#endif // CANCONTROLLER_H
