cmake_minimum_required(VERSION 3.16)
project(SimpleQmlApp)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 查找Qt5
find_package(Qt5 REQUIRED COMPONENTS Core Quick Widgets)

# 设置Qt自动处理
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# 源文件
set(SOURCES
    src/main.cpp
)

# 资源文件
set(RESOURCES
    qml.qrc
)

# Windows 资源文件（包含图标）
if(WIN32)
    set(WIN_RESOURCES
        app.rc
    )
else()
    set(WIN_RESOURCES "")
endif()

# 创建可执行文件
add_executable(${PROJECT_NAME} ${SOURCES} ${RESOURCES} ${WIN_RESOURCES})

# 链接库
target_link_libraries(${PROJECT_NAME} 
    Qt5::Core 
    Qt5::Quick
    Qt5::Widgets
)

# Windows平台特定设置
if(WIN32)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
endif()