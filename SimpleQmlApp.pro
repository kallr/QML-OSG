QT += core quick widgets
CONFIG += c++17

TARGET = SimpleQmlApp
TEMPLATE = app

SOURCES += src/main.cpp

RESOURCES += qml.qrc

win32 {
    RC_FILE = app.rc
    CONFIG += windows
}

# 设置输出目录
DESTDIR = $$PWD/build
OBJECTS_DIR = $$PWD/build/obj
MOC_DIR = $$PWD/build/moc
RCC_DIR = $$PWD/build/rcc