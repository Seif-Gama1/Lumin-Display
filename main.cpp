#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QScreen>
#include <QWindow>
#include <QDebug>
#include "CanController.h"
#include "DriverMonitoringReceiver.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    CanController canController;
    engine.rootContext()->setContextProperty("canController", &canController);

    // 2. Initialize & start Driver Monitoring Shared Memory Receiver
    DriverMonitoringReceiver dmsReceiver;

    QObject::connect(&dmsReceiver, &DriverMonitoringReceiver::alertStatusChanged,
                     &canController, &CanController::sendDmsAlert);

    dmsReceiver.start();
    engine.rootContext()->setContextProperty("dmsReceiver", &dmsReceiver);

    engine.loadFromModule("DigitalCluster", "Main");

    // Check detected screens
    auto screens = QGuiApplication::screens();
    qDebug() << "[QNX Screen] Total screens detected by Qt:" << screens.count();
    for (int i = 0; i < screens.count(); ++i) {
        qDebug() << "[QNX Screen] Index" << i << "Name:" << screens[i]->name();
    }

    // Force root QML Window onto Display 2 (Index 1)
    if (!engine.rootObjects().isEmpty()) {
        QWindow *rootWindow = qobject_cast<QWindow*>(engine.rootObjects().first());
        if (rootWindow) {
            if (screens.count() > 1) {
                qDebug() << "[QNX Screen] Assigning DigitalCluster window to Display 2 (screens[1])...";
                rootWindow->setScreen(screens[1]);
            } else {
                qWarning() << "[QNX Screen] Warning: Only 1 screen detected by Qt. Defaulting to primary display.";
            }
            rootWindow->setFlags(Qt::Window | Qt::FramelessWindowHint);
            rootWindow->showFullScreen();
        }
    }

    return app.exec();
}
