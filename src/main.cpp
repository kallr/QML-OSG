#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>

int main(int argc, char *argv[])
{
    // 启用高分辨率显示支持
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
    
    QGuiApplication app(argc, argv);
    
    app.setApplicationName("绘图");
    app.setApplicationDisplayName("绘图");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("示例组织");
    
    // 设置应用程序图标（可选）
    // app.setWindowIcon(QIcon(":/icons/app_icon.ico"));

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}