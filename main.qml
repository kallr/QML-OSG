import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    width: 1200
    height: 800
    visible: true
    title: qsTr("同豪绘图")
    
    // 优化窗口标志设置，确保标题栏简洁
    flags: Qt.Window
    
    // 现代化明亮主题
    color: "#f8fafc"

    // 明亮主题颜色定义
    property color primaryColor: "#2563eb"      // 主蓝色（保持）
    property color secondaryColor: "#64748b"    // 灰蓝色
    property color accentColor: "#3b82f6"       // 亮蓝色（保持）
    property color successColor: "#10b981"      // 绿色
    property color surfaceColor: "#ffffff"      // 白色表面
    property color textColor: "#1e293b"         // 深色文字
    property color borderColor: "#e2e8f0"       // 浅灰色边框
    property string currentPage: "analytics"
    
    // 树节点数据模型
    property var treeModel: [
        {
            id: "root",
            text: "📁 项目根目录",
            expanded: true,
            depth: 0,
            type: "folder",
            children: [
                {
                    id: "src",
                    text: "📂 src",
                    expanded: true,
                    depth: 1,
                    type: "folder",
                    children: [
                        { id: "main_cpp", text: "📄 main.cpp", depth: 2, type: "file" },
                        { id: "mainwindow_h", text: "📄 mainwindow.h", depth: 2, type: "file" },
                        { id: "mainwindow_cpp", text: "📄 mainwindow.cpp", depth: 2, type: "file" }
                    ]
                },
                {
                    id: "resources",
                    text: "📂 resources",
                    expanded: false,
                    depth: 1,
                    type: "folder",
                    children: []
                },
                {
                    id: "qml",
                    text: "📂 qml",
                    expanded: true,
                    depth: 1,
                    type: "folder",
                    children: [
                        { id: "main_qml", text: "📄 main.qml", depth: 2, type: "file" },
                        { id: "components", text: "📂 components", depth: 2, type: "folder", children: [] }
                    ]
                },
                { id: "cmake", text: "⚙️ CMakeLists.txt", depth: 1, type: "file" },
                { id: "readme", text: "📄 README.md", depth: 1, type: "file" }
            ]
        }
    ]
    
    property string selectedNodeId: ""
    property bool showDetailView: false  // 控制是否显示详细视图（上下分栏）
    property real topPanelRatio: 0.4  // 上栏高度比例，默认40%
    
    // 全局右键菜单
    Menu {
        id: globalContextMenu
        property string nodeId: ""
        property string nodeText: ""
        property string currentNodeType: ""
        
        width: 140
        
        background: Rectangle {
            color: surfaceColor
            border.color: borderColor
            border.width: 1
            radius: 8
        }
        
        MenuItem {
            text: "🗑️ 删除"
            enabled: globalContextMenu.nodeId !== "root"
            
            background: Rectangle {
                color: parent.hovered ? "#fee2e2" : "transparent"
                radius: 6
            }
            
            contentItem: Text {
                text: parent.text
                color: parent.enabled ? (parent.hovered ? "#dc2626" : textColor) : "#9ca3af"
                font.pixelSize: 13
            }
            
            onTriggered: {
                if (globalContextMenu.nodeId && globalContextMenu.nodeId !== "root") {
                    deleteTreeNode(globalContextMenu.nodeId)
                    statusText.text = "已删除: " + globalContextMenu.nodeText
                }
            }
        }
        
        MenuSeparator {
            visible: globalContextMenu.nodeId !== "root"
            
            background: Rectangle {
                color: borderColor
                height: 1
                width: parent.width - 16
                anchors.centerIn: parent
            }
        }
        
        MenuItem {
            text: "📄 添加文件"
            enabled: globalContextMenu.currentNodeType === "folder"
            
            background: Rectangle {
                color: parent.hovered ? "#eff6ff" : "transparent"
                radius: 6
            }
            
            contentItem: Text {
                text: parent.text
                color: parent.enabled ? (parent.hovered ? primaryColor : textColor) : "#9ca3af"
                font.pixelSize: 13
            }
            
            onTriggered: {
                if (globalContextMenu.currentNodeType === "folder") {
                    var timestamp = Date.now()
                    var nodeText = "新文件_" + timestamp
                    addTreeNode(globalContextMenu.nodeId, nodeText, "file")
                }
            }
        }
        
        MenuItem {
            text: "📂 添加文件夹"
            enabled: globalContextMenu.currentNodeType === "folder"
            
            background: Rectangle {
                color: parent.hovered ? "#eff6ff" : "transparent"
                radius: 6
            }
            
            contentItem: Text {
                text: parent.text
                color: parent.enabled ? (parent.hovered ? primaryColor : textColor) : "#9ca3af"
                font.pixelSize: 13
            }
            
            onTriggered: {
                if (globalContextMenu.currentNodeType === "folder") {
                    var timestamp = Date.now()
                    var nodeText = "新文件夹_" + timestamp
                    addTreeNode(globalContextMenu.nodeId, nodeText, "folder")
                }
            }
        }
    }
    
    // 树节点操作函数
    function flattenTree(nodes, result) {
        if (!result) result = []
        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i]
            result.push(node)
            if (node.expanded && node.children && node.children.length > 0) {
                flattenTree(node.children, result)
            }
        }
        return result
    }
    
    function findNodeById(nodeId, nodes) {
        if (!nodes) nodes = treeModel
        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i]
            if (node.id === nodeId) {
                return node
            }
            if (node.children && node.children.length > 0) {
                var found = findNodeById(nodeId, node.children)
                if (found) return found
            }
        }
        return null
    }
    
    function addTreeNode(parentId, nodeText, nodeType) {
        var parentNode = findNodeById(parentId)
        if (parentNode && parentNode.type === "folder") {
            if (!parentNode.children) {
                parentNode.children = []
            }
            var newId = "node_" + Date.now()
            var icon = nodeType === "folder" ? "📂" : "📄"
            var newNode = {
                id: newId,
                text: icon + " " + nodeText,
                depth: parentNode.depth + 1,
                type: nodeType,
                children: nodeType === "folder" ? [] : undefined
            }
            parentNode.children.push(newNode)
            parentNode.expanded = true
            
            // 触发界面更新
            updateTreeDisplay()
            statusText.text = "已添加节点: " + nodeText
        }
    }
    
    function deleteTreeNode(nodeId) {
        if (nodeId === "root") {
            statusText.text = "无法删除根节点"
            return
        }
        
        function removeFromParent(nodes) {
            for (var i = 0; i < nodes.length; i++) {
                var node = nodes[i]
                if (node.children) {
                    for (var j = 0; j < node.children.length; j++) {
                        if (node.children[j].id === nodeId) {
                            var removedNode = node.children.splice(j, 1)[0]
                            statusText.text = "已删除节点: " + removedNode.text
                            return true
                        }
                    }
                    if (removeFromParent(node.children)) {
                        return true
                    }
                }
            }
            return false
        }
        
        if (removeFromParent(treeModel)) {
            selectedNodeId = ""
            updateTreeDisplay()
        }
    }
    
    function toggleNodeExpansion(nodeId) {
        var node = findNodeById(nodeId)
        if (node && node.type === "folder") {
            node.expanded = !node.expanded
            updateTreeDisplay()
        }
    }
    
    function updateTreeDisplay() {
        // 更新所有树控件的显示
        var flatModel = flattenTree(treeModel)
        if (typeof treeRepeater !== 'undefined') {
            treeRepeater.model = flatModel
        }
        if (typeof projectTreeRepeater !== 'undefined') {
            projectTreeRepeater.model = flatModel
        }
    }




    // 主内容区域 - 使用RowLayout实现左侧导航+中间内容的布局
    RowLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // 左侧导航栏
        Rectangle {
            id: navigationPanel
            Layout.preferredWidth: 80  // 从180缩小到80，仅显示图标
            Layout.fillHeight: true
            color: surfaceColor
            radius: 12
            border.color: borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                // 导航标题（用户头像）
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 32
                    height: 32
                    radius: 16
                    color: accentColor

                    Text {
                        anchors.centerIn: parent
                        text: "👤"
                        font.pixelSize: 16
                        color: "white"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: primaryColor
                    radius: 1
                }

                // 导航按钮组
                Column {
                    Layout.fillWidth: true
                    spacing: 8

                    NavigationButton {
                        width: parent.width
                        text: "📋"
                        isActive: currentPage === "projects"
                        onClicked: {
                            currentPage = "projects"
                            statusText.text = "已切换到项目管理"
                        }
                    }
                    
                    NavigationButton {
                        width: parent.width
                        text: "📈"
                        isActive: currentPage === "analytics"
                        onClicked: {
                            currentPage = "analytics"
                            statusText.text = "已切换到数据分析"
                        }
                    }


                    NavigationButton {
                        width: parent.width
                        text: "⚙️"
                        isActive: currentPage === "settings"
                        onClicked: {
                            currentPage = "settings"
                            statusText.text = "已切换到设置页面"
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }

        // 中间内容区域（非项目管理页面）
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: surfaceColor
            radius: 12
            border.color: borderColor
            border.width: 1
            visible: currentPage !== "projects"

            StackLayout {
                id: contentStack
                anchors.fill: parent
                anchors.margins: 20
                currentIndex: {
                    switch(currentPage) {
                        case "analytics": return 0
                        case "settings": return 1
                        default: return 0
                    }
                }

                // 数据分析页面
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 20

                        Text {
                            text: qsTr("📊 数据分析仪表板")
                            font.pixelSize: 28
                            font.bold: true
                            color: textColor
                            Layout.alignment: Qt.AlignHCenter
                        }

                        GridLayout {
                            columns: 2
                            rowSpacing: 16
                            columnSpacing: 16
                            Layout.fillWidth: true

                            StatCard {
                                title: "总用户数"
                                value: "12,345"
                                icon: "👥"
                                cardColor: primaryColor
                            }

                            StatCard {
                                title: "活跃用户"
                                value: "8,765"
                                icon: "🔥"
                                cardColor: accentColor
                            }

                            StatCard {
                                title: "收入"
                                value: "￥89,012"
                                icon: "💰"
                                cardColor: successColor
                            }

                            StatCard {
                                title: "订单数"
                                value: "1,234"
                                icon: "📦"
                                cardColor: secondaryColor
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // 设置页面
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 20

                        Text {
                            text: qsTr("⚙️ 应用设置")
                            font.pixelSize: 28
                            font.bold: true
                            color: textColor
                            Layout.alignment: Qt.AlignHCenter
                        }

                        GroupBox {
                            title: qsTr("常规设置")
                            Layout.fillWidth: true
                            Layout.preferredHeight: 200
                            
                            background: Rectangle {
                                color: "transparent"
                                border.color: borderColor
                                radius: 8
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 16

                                Text {
                                    text: qsTr("这里可以配置应用的各种设置选项")
                                    color: textColor
                                    font.pixelSize: 14
                                    opacity: 0.8
                                }

                                Button {
                                    text: qsTr("保存设置")
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#1d4ed8" : (parent.hovered ? "#2563eb" : primaryColor)
                                        radius: 6
                                        
                                        Behavior on color {
                                            ColorAnimation { duration: 150 }
                                        }
                                    }
                                    
                                    contentItem: Text {
                                        text: parent.text
                                        font.pixelSize: 14
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    onClicked: {
                                        statusText.text = qsTr("设置已保存")
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }

        // 右侧树控件区域（非项目管理页面时隐藏）
        Rectangle {
            id: treePanel
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            color: surfaceColor
            radius: 12
            border.color: borderColor
            border.width: 1
            visible: false  // 默认隐藏，不再显示

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // 树控件操作按钮（顶部）
                Row {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6
                    
                    Button {
                        text: "📄"
                        width: 28
                        height: 28
                        
                        ToolTip.visible: hovered
                        ToolTip.text: "添加文件"
                        
                        background: Rectangle {
                            color: parent.pressed ? "#1d4ed8" : (parent.hovered ? "#2563eb" : primaryColor)
                            radius: 6
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 12
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: {
                            // 添加文件节点
                            var parentId = selectedNodeId || "root"
                            var parentNode = findNodeById(parentId)
                            if (parentNode && parentNode.type === "folder") {
                                var timestamp = Date.now()
                                var nodeText = "新文件_" + timestamp
                                addTreeNode(parentId, nodeText, "file")
                            } else {
                                statusText.text = "请选中一个文件夹来添加子项"
                            }
                        }
                    }
                    
                    Button {
                        text: "📂"
                        width: 28
                        height: 28
                        
                        ToolTip.visible: hovered
                        ToolTip.text: "添加目录"
                        
                        background: Rectangle {
                            color: parent.pressed ? "#1d4ed8" : (parent.hovered ? "#2563eb" : primaryColor)
                            radius: 6
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 12
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: {
                            // 添加文件夹节点
                            var parentId = selectedNodeId || "root"
                            var parentNode = findNodeById(parentId)
                            if (parentNode && parentNode.type === "folder") {
                                var timestamp = Date.now()
                                var nodeText = "新文件夹_" + timestamp
                                addTreeNode(parentId, nodeText, "folder")
                            } else {
                                statusText.text = "请选中一个文件夹来添加子项"
                            }
                        }
                    }
                    
                    Button {
                        text: "🗑️"
                        width: 32
                        height: 32
                        
                        background: Rectangle {
                            color: parent.pressed ? "#dc2626" : (parent.hovered ? "#ef4444" : "#f87171")
                            radius: 6
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 14
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: {
                            if (selectedNodeId && selectedNodeId !== "root") {
                                deleteTreeNode(selectedNodeId)
                            } else {
                                statusText.text = "请先选中要删除的节点"
                            }
                        }
                    }
                    
                    Button {
                        text: "🔄"
                        width: 32
                        height: 32
                        
                        background: Rectangle {
                            color: parent.pressed ? "#059669" : (parent.hovered ? "#10b981" : "#34d399")
                            radius: 6
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 14
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: {
                            updateTreeDisplay()
                            statusText.text = "已刷新项目树"
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: primaryColor
                    radius: 1
                }

                // 树控件容器
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#f1f5f9"
                    radius: 8
                    border.color: borderColor
                    border.width: 1

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 8
                        clip: true

                        Column {
                            width: parent.width
                            spacing: 4

                            Repeater {
                                id: treeRepeater
                                model: flattenTree(treeModel)
                                
                                Component.onCompleted: {
                                    model = flattenTree(treeModel)
                                }
                                
                                TreeItem {
                                    width: parent.width
                                    itemText: modelData.text
                                    isExpanded: modelData.expanded || false
                                    depth: modelData.depth
                                    nodeId: modelData.id
                                    nodeType: modelData.type
                                    isSelected: selectedNodeId === modelData.id
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 项目管理页面的三栏布局（导航 + 树控件 + 内容）
    RowLayout {
        id: projectLayout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        visible: currentPage === "projects"

        // 复用左侧导航栏
        Rectangle {
            id: projectNavigationPanel
            Layout.preferredWidth: 80  // 与主导航栏保持一致
            Layout.fillHeight: true
            color: surfaceColor
            radius: 12
            border.color: borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                // 导航标题（用户头像）
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 32
                    height: 32
                    radius: 16
                    color: accentColor

                    Text {
                        anchors.centerIn: parent
                        text: "👤"
                        font.pixelSize: 16
                        color: "white"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: primaryColor
                    radius: 1
                }

                // 导航按钮组
                Column {
                    Layout.fillWidth: true
                    spacing: 8

                    NavigationButton {
                        width: parent.width
                        text: "📈"
                        isActive: currentPage === "analytics"
                        onClicked: {
                            currentPage = "analytics"
                            statusText.text = "已切换到数据分析"
                        }
                    }

                    NavigationButton {
                        width: parent.width
                        text: "📋"
                        isActive: currentPage === "projects"
                        onClicked: {
                            currentPage = "projects"
                            statusText.text = "已切换到项目管理"
                        }
                    }

                    NavigationButton {
                        width: parent.width
                        text: "⚙️"
                        isActive: currentPage === "settings"
                        onClicked: {
                            currentPage = "settings"
                            statusText.text = "已切换到设置页面"
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }

        // 中间树控件区域（仅项目管理页面）
        Rectangle {
            id: projectTreePanel
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            color: surfaceColor
            radius: 12
            border.color: borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // 树控件操作按钮（顶部）
                Row {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6
                    
                    Button {
                        text: "📄"
                        width: 28
                        height: 28
                        
                        ToolTip.visible: hovered
                        ToolTip.text: "添加文件"
                        
                        background: Rectangle {
                            color: parent.pressed ? "#1d4ed8" : (parent.hovered ? "#2563eb" : primaryColor)
                            radius: 6
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 12
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: {
                            // 添加文件节点
                            var parentId = selectedNodeId || "root"
                            var parentNode = findNodeById(parentId)
                            if (parentNode && parentNode.type === "folder") {
                                var timestamp = Date.now()
                                var nodeText = "新文件_" + timestamp
                                addTreeNode(parentId, nodeText, "file")
                            } else {
                                statusText.text = "请选中一个文件夹来添加子项"
                            }
                        }
                    }
                    
                    Button {
                        text: "📂"
                        width: 28
                        height: 28
                        
                        ToolTip.visible: hovered
                        ToolTip.text: "添加目录"
                        
                        background: Rectangle {
                            color: parent.pressed ? "#1d4ed8" : (parent.hovered ? "#2563eb" : primaryColor)
                            radius: 6
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 12
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: {
                            // 添加文件夹节点
                            var parentId = selectedNodeId || "root"
                            var parentNode = findNodeById(parentId)
                            if (parentNode && parentNode.type === "folder") {
                                var timestamp = Date.now()
                                var nodeText = "新文件夹_" + timestamp
                                addTreeNode(parentId, nodeText, "folder")
                            } else {
                                statusText.text = "请选中一个文件夹来添加子项"
                            }
                        }
                    }
                    
                    Button {
                        text: "🗑️"
                        width: 32
                        height: 32
                        
                        background: Rectangle {
                            color: parent.pressed ? "#dc2626" : (parent.hovered ? "#ef4444" : "#f87171")
                            radius: 6
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 14
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: {
                            if (selectedNodeId && selectedNodeId !== "root") {
                                deleteTreeNode(selectedNodeId)
                            } else {
                                statusText.text = "请先选中要删除的节点"
                            }
                        }
                    }
                    
                    Button {
                        text: "🔄"
                        width: 32
                        height: 32
                        
                        background: Rectangle {
                            color: parent.pressed ? "#059669" : (parent.hovered ? "#10b981" : "#34d399")
                            radius: 6
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 14
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: {
                            updateTreeDisplay()
                            statusText.text = "已刷新项目树"
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: primaryColor
                    radius: 1
                }

                // 树控件容器
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#f1f5f9"
                    radius: 8
                    border.color: borderColor
                    border.width: 1

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 8
                        clip: true

                        Column {
                            width: parent.width
                            spacing: 4

                            Repeater {
                                id: projectTreeRepeater
                                model: flattenTree(treeModel)
                                
                                Component.onCompleted: {
                                    model = flattenTree(treeModel)
                                }
                                
                                TreeItem {
                                    width: parent.width
                                    itemText: modelData.text
                                    isExpanded: modelData.expanded || false
                                    depth: modelData.depth
                                    nodeId: modelData.id
                                    nodeType: modelData.type
                                    isSelected: selectedNodeId === modelData.id
                                }
                            }
                        }
                    }
                }
            }
        }

        // 右侧内容区域（项目管理页面）
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: surfaceColor
            radius: 12
            border.color: borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                // 标题和关闭按钮区域
                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        text: showDetailView ? qsTr("📝 文件编辑器") : qsTr("📋 项目介绍")
                        font.pixelSize: 28
                        font.bold: true
                        color: textColor
                        Layout.fillWidth: true
                    }
                    
                    // 返回按钮
                    Button {
                        visible: showDetailView
                        text: "←"
                        width: 32
                        height: 32
                        
                        ToolTip.visible: hovered
                        ToolTip.text: "返回项目管理"
                        
                        background: Rectangle {
                            color: parent.pressed ? "#1d4ed8" : (parent.hovered ? "#2563eb" : primaryColor)
                            radius: 6
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: {
                            showDetailView = false
                            statusText.text = "已返回项目管理"
                        }
                    }
                }

                // 条件显示：详细视图或默认视图
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    // 默认项目管理视图
                    Rectangle {
                        anchors.fill: parent
                        color: "#f1f5f9"
                        radius: 8
                        border.color: borderColor
                        border.width: 1
                        visible: !showDetailView

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 16

                            Text {
                                text: qsTr("这是一个测试项目，请勿用于实际开发。")
                                color: textColor
                                font.pixelSize: 14
                                opacity: 0.8
                             //   wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
/*
                            Rectangle {
                                Layout.fillWidth: true
                                height: 200
                                color: surfaceColor
                                radius: 8
                                border.color: borderColor
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: qsTr("📝\n\n文件编辑区域\n\n双击文件节点打开编辑器")
                                    color: textColor
                                    font.pixelSize: 16
                                    horizontalAlignment: Text.AlignHCenter
                                    opacity: 0.6
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }
*/                            
                        }
                    }
                    
                    // 详细视图（上下分栏）
                    Item {
                        anchors.fill: parent
                        visible: showDetailView
                        
                        // 上栏：表单输入界面
                        Rectangle {
                            id: topPanel
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height * topPanelRatio
                            color: surfaceColor
                            radius: 8
                            border.color: borderColor
                            border.width: 1
                            
                            ScrollView {
                                anchors.fill: parent
                                anchors.margins: 16
                                clip: true
                                
                                ColumnLayout {
                                    width: parent.width
                                    spacing: 16
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        
                                        Text {
                                            text: qsTr("⚙️ 属性设置")
                                            font.pixelSize: 16
                                            font.bold: true
                                            color: textColor
                                            Layout.fillWidth: true
                                        }
                                        
                                        // 面板比例指示器
                                        Text {
                                            text: Math.round(topPanelRatio * 100) + "%"
                                            color: secondaryColor
                                            font.pixelSize: 12
                                            font.family: "Monospace"
                                            
                                            Rectangle {
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                color: "transparent"
                                                border.color: borderColor
                                                border.width: 1
                                                radius: 4
                                            }
                                        }
                                    }
                                    
                                    // 文件名输入
                                    RowLayout {
                                        Layout.fillWidth: true
                                        
                                        Text {
                                            text: "文件名:"
                                            color: textColor
                                            font.pixelSize: 14
                                            Layout.preferredWidth: 80
                                        }
                                        
                                        TextField {
                                            id: fileNameField
                                            Layout.fillWidth: true
                                            placeholderText: "请输入文件名"
                                            
                                            background: Rectangle {
                                                color: surfaceColor
                                                border.color: borderColor
                                                border.width: 1
                                                radius: 6
                                            }
                                        }
                                    }
                                    
                                    // 文件类型
                                    RowLayout {
                                        Layout.fillWidth: true
                                        
                                        Text {
                                            text: "文件类型:"
                                            color: textColor
                                            font.pixelSize: 14
                                            Layout.preferredWidth: 80
                                        }
                                        
                                        ComboBox {
                                            id: fileTypeCombo
                                            Layout.fillWidth: true
                                            model: ["CAD模型", "3D模型", "文本文件", "图片文件"]
                                            
                                            background: Rectangle {
                                                color: surfaceColor
                                                border.color: borderColor
                                                border.width: 1
                                                radius: 6
                                            }
                                        }
                                    }
                                    
                                    // 描述信息
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignTop
                                        
                                        Text {
                                            text: "描述:"
                                            color: textColor
                                            font.pixelSize: 14
                                            Layout.preferredWidth: 80
                                            Layout.alignment: Qt.AlignTop
                                        }
                                        
                                        ScrollView {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 80
                                            clip: true
                                            
                                            TextArea {
                                                id: descriptionArea
                                                placeholderText: "请输入文件描述..."
                                                wrapMode: TextArea.Wrap
                                                
                                                background: Rectangle {
                                                    color: surfaceColor
                                                    border.color: borderColor
                                                    border.width: 1
                                                    radius: 6
                                                }
                                            }
                                        }
                                    }
                                    
                                    // 操作按钮
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 12
                                        
                                        Button {
                                            text: "💾 保存"
                                            
                                            background: Rectangle {
                                                color: parent.pressed ? "#1d4ed8" : (parent.hovered ? "#2563eb" : primaryColor)
                                                radius: 6
                                            }
                                            
                                            contentItem: Text {
                                                text: parent.text
                                                font.pixelSize: 14
                                                color: "white"
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            
                                            onClicked: {
                                                statusText.text = "已保存文件属性: " + fileNameField.text
                                            }
                                        }
                                        
                                        Button {
                                            text: "🔄 重置"
                                            
                                            background: Rectangle {
                                                color: parent.pressed ? "#6b7280" : (parent.hovered ? "#9ca3af" : secondaryColor)
                                                radius: 6
                                            }
                                            
                                            contentItem: Text {
                                                text: parent.text
                                                font.pixelSize: 14
                                                color: "white"
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            
                                            onClicked: {
                                                fileNameField.text = ""
                                                fileTypeCombo.currentIndex = 0
                                                descriptionArea.text = ""
                                                statusText.text = "已重置表单"
                                            }
                                        }
                                        
                                        Item {
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 可拖动的分隔条
                        Rectangle {
                            id: splitter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: topPanel.bottom
                            height: 12  // 增大拖拽区域
                            color: "transparent"
                            
                            // 背景阴影效果
                            Rectangle {
                                anchors.fill: parent
                                color: dragArea.containsMouse || dragArea.pressed ? Qt.rgba(0, 0, 0, 0.05) : "transparent"
                                radius: 6
                                
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }
                            
                            // 主分隔条视觉指示器
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.9
                                height: 3
                                color: dragArea.containsMouse || dragArea.pressed ? primaryColor : borderColor
                                radius: 2
                                
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                                
                                // 中间手柄（拖拽点图标）
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 60
                                    height: 8
                                    color: dragArea.containsMouse || dragArea.pressed ? primaryColor : secondaryColor
                                    radius: 4
                                    
                                    // 拖拽点指示器
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 3
                                        
                                        Repeater {
                                            model: 3
                                            Rectangle {
                                                width: 2
                                                height: 6
                                                color: "white"
                                                radius: 1
                                                opacity: 0.8
                                            }
                                        }
                                    }
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: 200 }
                                    }
                                    
                                    // 添加轻微的阴影效果
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.topMargin: 1
                                        color: "transparent"
                                        border.color: Qt.rgba(0, 0, 0, 0.1)
                                        border.width: 1
                                        radius: parent.radius
                                        visible: dragArea.containsMouse || dragArea.pressed
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.SizeVerCursor
                                
                                property real startY: 0
                                property real startRatio: 0
                                property bool isDragging: false
                                
                                onPressed: {
                                    startY = mouseY
                                    startRatio = topPanelRatio
                                    isDragging = true
                                    statusText.text = "开始调整面板大小..."
                                }
                                
                                onPositionChanged: {
                                    if (isDragging && pressed) {
                                        var deltaY = mouseY - startY
                                        var containerHeight = parent.parent.height
                                        var newRatio = startRatio + (deltaY / containerHeight)
                                        
                                        // 限制最小和最大比例（保持在20%-80%之间）
                                        newRatio = Math.max(0.2, Math.min(0.8, newRatio))
                                        topPanelRatio = newRatio
                                        
                                        // 实时反馈当前比例
                                        statusText.text = "调整面板大小: " + Math.round(newRatio * 100) + "% (上栏) / " + Math.round((1-newRatio) * 100) + "% (下栏)"
                                    }
                                }
                                
                                onReleased: {
                                    isDragging = false
                                    statusText.text = "面板大小调整完成 - 上栏: " + Math.round(topPanelRatio * 100) + "%"
                                }
                                
                                onCanceled: {
                                    isDragging = false
                                    statusText.text = "面板大小调整已取消"
                                }
                                
                                // 双击重置为默认比例
                                onDoubleClicked: {
                                    var defaultRatio = 0.4  // 40%
                                    topPanelRatio = defaultRatio
                                    statusText.text = "已重置为默认比例: " + Math.round(defaultRatio * 100) + "%"
                                }
                                
                                // 鼠标悬停提示
                                ToolTip.visible: containsMouse && !pressed
                                ToolTip.text: "拖动调整上下面板大小，双击重置为默认比例"
                                ToolTip.delay: 500
                            }
                        }
                        
                        // 下栏：OSG/CAD显示窗口
                        Rectangle {
                            id: bottomPanel
                            anchors.top: splitter.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            color: "#2d3748"
                            radius: 8
                            border.color: borderColor
                            border.width: 1
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12
                                
                                // 3D显示区域标题
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Text {
                                        text: qsTr("🎆 3D 显示窗口")
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "white"
                                        Layout.fillWidth: true
                                    }
                                    
                                    // 面板比例指示器
                                    Text {
                                        text: Math.round((1-topPanelRatio) * 100) + "%"
                                        color: "#a0aec0"
                                        font.pixelSize: 12
                                        font.family: "Monospace"
                                        
                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            color: "transparent"
                                            border.color: "#4a5568"
                                            border.width: 1
                                            radius: 4
                                        }
                                    }
                                    
                                    // 视图控制按钮
                                    Row {
                                        spacing: 8
                                        
                                        Button {
                                            text: "🔄"
                                            width: 28
                                            height: 28
                                            
                                            background: Rectangle {
                                                color: parent.pressed ? "#374151" : (parent.hovered ? "#4b5563" : "#6b7280")
                                                radius: 4
                                            }
                                            
                                            contentItem: Text {
                                                text: parent.text
                                                font.pixelSize: 12
                                                color: "white"
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            
                                            onClicked: {
                                                statusText.text = "已重置3D视图"
                                            }
                                        }
                                        
                                        Button {
                                            text: "🔍"
                                            width: 28
                                            height: 28
                                            
                                            background: Rectangle {
                                                color: parent.pressed ? "#374151" : (parent.hovered ? "#4b5563" : "#6b7280")
                                                radius: 4
                                            }
                                            
                                            contentItem: Text {
                                                text: parent.text
                                                font.pixelSize: 12
                                                color: "white"
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            
                                            onClicked: {
                                                statusText.text = "缩放适应视图"
                                            }
                                        }
                                    }
                                }
                                
                                // 3D渲染区域
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: "#1a202c"
                                    radius: 6
                                    border.color: "#4a5568"
                                    border.width: 1
                                    
                                    // 模拟3D内容
                                    Item {
                                        anchors.fill: parent
                                        
                                        // 中心显示区域
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: Math.min(parent.width * 0.8, parent.height * 0.8)
                                            height: width
                                            color: "transparent"
                                            border.color: "#4a5568"
                                            border.width: 2
                                            radius: 8
                                            
                                            // 立方体模拟
                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 60
                                                height: 60
                                                color: "#3182ce"
                                                radius: 4
                                                
                                                // 旋转动画
                                                RotationAnimation {
                                                    target: parent
                                                    property: "rotation"
                                                    from: 0
                                                    to: 360
                                                    duration: 8000
                                                    loops: Animation.Infinite
                                                    running: true
                                                }
                                            }
                                            
                                            // 信息文本
                                            Text {
                                                anchors.bottom: parent.bottom
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.bottomMargin: 16
                                                text: "OSG/CAD 模型显示区域"
                                                color: "#a0aec0"
                                                font.pixelSize: 12
                                            }
                                        }
                                        
                                        // 左上角信息
                                        Text {
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.margins: 12
                                            text: "模型: " + (selectedNodeId ? (function() {
                                                var node = findNodeById(selectedNodeId);
                                                return node ? node.text : "";
                                            })() : "未选中")
                                            color: "#e2e8f0"
                                            font.pixelSize: 11
                                        }
                                        
                                        // 右上角控制信息
                                        Text {
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: 12
                                            text: "右键拖动旋转 | 滚轮缩放"
                                            color: "#a0aec0"
                                            font.pixelSize: 10
                                        }
                                    }
                                    
                                    // 鼠标交互区域
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        
                                        onPressed: {
                                            statusText.text = "开始3D操作..."
                                        }
                                        
                                        onReleased: {
                                            statusText.text = "3D操作完成"
                                        }
                                        
                                        onWheel: {
                                            var delta = wheel.angleDelta.y
                                            statusText.text = delta > 0 ? "放大视图" : "缩小视图"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 底部状态栏
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 32
        color: surfaceColor
        border.color: borderColor
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Text {
                id: statusText
                text: qsTr("欢迎使用现代化QML应用")
                color: textColor
                font.pixelSize: 11
                Layout.fillWidth: true
            }

            Text {
                text: qsTr("当前页面: ") + currentPage
                color: primaryColor
                font.pixelSize: 11
            }
        }
    }

    // 导航按钮组件
    component NavigationButton: Button {
        id: navButton
        property bool isActive: false
        
        background: Rectangle {
            color: {
                if (navButton.isActive) return primaryColor
                return navButton.pressed ? "#e2e8f0" : (navButton.hovered ? "#f1f5f9" : "transparent")
            }
            radius: 8
            border.color: navButton.isActive ? primaryColor : "transparent"
            border.width: 1
            
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
        
        contentItem: Text {
            text: navButton.text
            font.pixelSize: 20  // 增大图标尺寸
            color: navButton.isActive ? "white" : textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // 统计卡片组件
    component StatCard: Rectangle {
        property string title: ""
        property string value: ""
        property string icon: ""
        property color cardColor: primaryColor
        
        width: 200
        height: 120
        color: surfaceColor
        radius: 12
        border.color: borderColor
        border.width: 1
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            
            Text {
                text: icon
                font.pixelSize: 32
                Layout.alignment: Qt.AlignVCenter
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4
                
                Text {
                    text: title
                    color: textColor
                    font.pixelSize: 12
                    opacity: 0.8
                }
                
                Text {
                    text: value
                    color: cardColor
                    font.pixelSize: 18
                    font.bold: true
                }
            }
        }
        
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 3
            color: cardColor
            radius: 2
        }
    }

    // 树节点组件
    component TreeItem: Rectangle {
        property string itemText: ""
        property bool isExpanded: false
        property int depth: 0
        property bool isSelected: false
        property string nodeId: ""
        property string nodeType: ""
        
        height: 28
        color: {
            if (isSelected) return accentColor
            if (mouseArea.containsMouse) return Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.1)
            return "transparent"
        }
        radius: 4
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
        
        Row {
            anchors.left: parent.left
            anchors.leftMargin: depth * 16 + 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            
            Text {
                text: isExpanded ? "▼" : "▶"
                color: textColor
                font.pixelSize: 10
                visible: nodeType === "folder"
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
                text: itemText
                color: isSelected ? "white" : textColor
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
                font.weight: isSelected ? Font.Medium : Font.Normal
            }
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            
            onClicked: {
                if (mouse.button === Qt.LeftButton) {
                    selectedNodeId = nodeId
                    statusText.text = "选中项目: " + itemText
                } else if (mouse.button === Qt.RightButton) {
                    selectedNodeId = nodeId
                    globalContextMenu.nodeId = nodeId
                    globalContextMenu.nodeText = itemText
                    globalContextMenu.currentNodeType = nodeType
                    statusText.text = "右键菜单: " + itemText  // 调试信息
                    globalContextMenu.popup(mouseArea, mouse.x, mouse.y)
                }
            }
            
            onDoubleClicked: {
                if (nodeType === "folder") {
                    toggleNodeExpansion(nodeId)
                } else if (nodeType === "file") {
                    // 双击文件节点，显示详细视图
                    showDetailView = true
                    selectedNodeId = nodeId
                    statusText.text = "打开文件: " + itemText
                }
            }
        }
    }
}