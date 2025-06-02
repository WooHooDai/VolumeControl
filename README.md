# VolumeControl

基于Hammerspoon, 为macos提供Windows系统一样的音量调节体验。

## 功能

- 菜单栏图标显示当前音量/静音/当前输出设备名称
- 鼠标中键滚动调节音量（鼠标需悬浮在状态栏图标上）
- 鼠标左键单击图标切换静音状态（可定制静音文字）
- 鼠标右键单击菜单，可切换输出设备
- 鼠标右键单击菜单，可显示/隐藏输出设备名称

![image](https://github.com/user-attachments/assets/a84121ac-c89f-4ed0-aa9a-b7527affd8e4)

## 安装

1. 下载此仓库
2. 将 `init.lua` 文件复制到 `~/.hammerspoon/Spoons/VolumeControl.spoon` 目录下

## 使用方法
在你的 Hammerspoon 配置文件 (`~/.hammerspoon/init.lua`) 中添加:

### 基本功能

```lua
hs.loadSpoon("VolumeControl")
spoon.VolumeControl:start()
```

### 可选功能
```lua
hs.loadSpoon("VolumeControl")

-- 隐藏音量百分比，只显示数字
spoon.VolumeControl:visiblePercent(false)

-- 静音/音量为0时，显示内容
spoon.VolumeControl:setMuteStr("静音")

-- 设置字体
spoon.VolumeControl:setFont("Arial", 14)

-- 启动
spoon.VolumeControl:start()
```

### 完整API
`start()`: 启动插件
`stop()`: 停止插件
`visiblePercent(visible)`: 隐藏/显示音量百分号
`setMuteStr(str)`: 设置静音文字
`setFont(fontName, fontSize)`: 设置字体

## 版本记录
- 2025-06-02: feat 增加右键菜单，可切换输出设备；增加右键菜单，可显示/隐藏输出设备名称
- 2025-05-16: feat 增加设置字体API（默认为Arial、14号，避免调整音量时抖动）
- 2025-05-04: fix 音量输出源为电视时，音量为nil
- 2025-03-11: fix 静音状态下，调整音量不生效；音量到0时，未显示静音
- 2025-03-07: init 初始功能
