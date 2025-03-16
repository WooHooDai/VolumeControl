# VolumeControl

基于Hammerspoon, 提供了和Windows系统一样的音量调节体验。

## 功能

- 菜单栏图标显示当前音量/静音
- 鼠标悬浮在菜单栏图标上，滚动中键调节音量
- 点击图标切换静音状态
- 可定制静音文字

## 安装

1. 下载此仓库
2. 将 VolumeControl.spoon 文件夹复制到 `~/.hammerspoon/Spoons/` 目录下

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

spoon.VolumeControl:start()
```

### 完整API
`start()`: 启动插件
`stop()`: 停止插件
`visiblePercent(visible)`: 隐藏/显示音量百分号
`setMuteStr(str)`: 设置静音文字

## 版本记录
- 2025-03-11: fix 静音状态下，调整音量不生效；音量到0时，未显示静音
- 2025-03-07: init 初始功能