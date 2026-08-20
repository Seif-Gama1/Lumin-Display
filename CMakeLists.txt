cmake_minimum_required(VERSION 3.16)

project(DigitalCluster VERSION 0.1 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Quick3D Quick3DAssetUtils)

qt_standard_project_setup(REQUIRES 6.5)

qt_policy(SET QTP0004 NEW)

qt_add_executable(appDigitalCluster
    main.cpp
    backend/CanController.cpp
    backend/CanController.h
    backend/CanWorker.cpp
    backend/CanWorker.h
    backend/driver/mcp2515.c
    backend/driver/mcp2515.h
    backend/driver/rpi_spi.h
)

# 3. Add include directories so #include "mcp2515.h" resolves cleanly in C++
target_include_directories(appDigitalCluster PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/backend
    ${CMAKE_CURRENT_SOURCE_DIR}/backend/driver
)

target_link_directories(appDigitalCluster PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/backend/driver/lib
)

qt_add_qml_module(appDigitalCluster
    URI DigitalCluster
    VERSION 1.0
    QML_FILES
        Main.qml
        ClusterScreen.qml
        components/CircularGauge.qml
        components/InfoTile.qml
        components/MiniGauge.qml
        components/IconInfoTile.qml
        components/Background.qml
        components/WarningIcon.qml
        components/LightIcon.qml
        components/TPMSIcon.qml
        components/CarOnRoadNew.qml
        components/LampFailurePopup.qml
        components/FuelIcon.qml
        components/TempIcon.qml
        components/RangeIcon.qml
        components/TripIcon.qml
        components/OutsideTempIcon.qml
        components/ClockIcon.qml
    SOURCES
        backend/driver/rpi_spi.h
        backend/CanFrame.h
        backend/CanController.cpp
        backend/CanController.h
        backend/CanWorker.cpp
        backend/CanWorker.h
        backend/driver/mcp2515.c
        backend/driver/mcp2515.h
        backend/DriverMonitoringReceiver.h
        backend/DriverMonitoringReceiver.cpp
        backend/mapstreamitem.h
        backend/mapstreamitem.cpp
    RESOURCES
        assets/tesla_model_s.png
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appDigitalCluster PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appDigitalCluster
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appDigitalCluster
    PRIVATE Qt6::Quick
            Qt6::Quick3D
            Qt6::Quick3DAssetUtils
            rpi_spi
)

include(GNUInstallDirs)
install(TARGETS appDigitalCluster
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
