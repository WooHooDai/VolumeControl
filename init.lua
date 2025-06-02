--- === VolumeControl ===
---
--- macos菜单栏音量控制
--- 基于Hammerspoon, 为macos提供Windows系统一样的音量调节体验。
--- 在菜单栏显示当前音量，支持鼠标中键滚动调节音量、左键单击切换静音状态、右键单击选择输出设备
--- === END ===


local obj = {}
obj.__index = obj

-- 元数据
obj.name = "VolumeControl"
obj.version = "0.3"
obj.author = "静声 <woohoodai>"
obj.homepage = "https://github.com/WooHooDai/VolumeControl"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- 内部属性
obj._volumeIcon = nil
obj._scrollWatcher = nil
obj._audioDevice = nil
obj._deviceWatcher = nil
obj._showDeviceName = false  -- 是否显示设备名称
-- 内部属性：音量图标
obj._volMute = "静音"
obj._volPercent = false
obj._percent = ""
obj._font = {  -- 字体设置
    name = "Arial",
    size = fontSize or 14  -- 默认字体大小为12
}

function obj:updateVolumeIcon()
    -- 获取当前默认输出设备
    local device = hs.audiodevice.defaultOutputDevice()
    self._audioDevice = device
    
    if device and self._volumeIcon then
        local volume = device:volume()
        local muted = device:muted()
        local deviceName = device:name()
        
        local titleText = ""
        if muted then
            titleText = self._volMute
        elseif volume ~= nil then
            titleText = math.floor(volume).. (obj._volPercent and "%" or "")
        else
            -- 音量为nil时，不显示
            titleText = "--"
        end
        
        -- 添加设备名称
        if self._showDeviceName and deviceName then
            titleText = titleText .. " | " .. deviceName
        end
        
        -- 应用字体设置
        if self._font then
            -- 使用hs.styledtext创建带样式的文本
            local styledTitle = hs.styledtext.new(titleText, {
                font = {
                    name = self._font.name,
                    size = self._font.size
                }
            })
            self._volumeIcon:setTitle(styledTitle)
        else
            self._volumeIcon:setTitle(titleText)
        end
    end
end

function obj:init()
    self._volumeIcon = hs.menubar.new(true, "volumeControl")    -- 创建音量图标
    self._audioDevice = hs.audiodevice.defaultOutputDevice()     -- 获取默认音频设备

    -- 创建音量图标右键菜单
    self._volumeIcon:setMenu(function()
        local menu = {}
        local currentDevice = hs.audiodevice.defaultOutputDevice()
        
        -- 添加所有输出设备到菜单
        local outputDevices = hs.audiodevice.allOutputDevices()
        for _, device in ipairs(outputDevices) do
            local deviceName = device:name()
            local checked = (currentDevice and deviceName == currentDevice:name())
            
            table.insert(menu, {
                title = deviceName,
                checked = checked,
                fn = function()
                    device:setDefaultOutputDevice()
                    -- 更新后立即刷新图标
                    hs.timer.doAfter(0.1, function() self:updateVolumeIcon() end)
                end
            })
        end
        
        -- 添加显示设备名称选项
        table.insert(menu, { title = "-" })  -- 分隔线
        table.insert(menu, {
            title = "显示设备名称",
            checked = self._showDeviceName,
            fn = function()
                self._showDeviceName = not self._showDeviceName
                self:updateVolumeIcon()
            end
        })
        
        return menu
    end)

    -- 监听鼠标事件
    self._mouseWatcher = hs.eventtap.new({
        hs.eventtap.event.types.leftMouseDown,
        hs.eventtap.event.types.scrollWheel
    }, function(event)
        local mousePos = hs.mouse.absolutePosition()
        local iconPos = self._volumeIcon:frame()

        if iconPos and mousePos.x >= iconPos.x and mousePos.x <= iconPos.x + iconPos.w and
           mousePos.y >= iconPos.y and mousePos.y <= iconPos.y + iconPos.h then

            local eventType = event:getType()

            -- 鼠标左键，切换静音状态
            if eventType == hs.eventtap.event.types.leftMouseDown then
                -- 关闭菜单
                hs.eventtap.keyStroke({}, "escape")
                
                if self._audioDevice then
                    self._audioDevice:setMuted(not self._audioDevice:muted())
                    self:updateVolumeIcon()
                end
                return true  -- 返回true阻止事件继续传播（避免触发菜单）

            -- 鼠标滚轮，调整音量
            elseif eventType == hs.eventtap.event.types.scrollWheel then
                local device = hs.audiodevice.defaultOutputDevice()
                if device then
                    local currentVolume = device:volume()
                    local scrollDelta = event:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis1)
                    local newVolume = currentVolume + (scrollDelta > 0 and 1 or -1)
                    newVolume = math.min(100, math.max(0, newVolume))
                    
                    if newVolume == 0 then
                        device:setMuted(true)
                    else
                        device:setMuted(false)
                    end

                    device:setVolume(newVolume)
                    self:updateVolumeIcon()
                    return true
                end
            end
        end
        return false
    end)

    -- 设置音频设备监听
    if self._audioDevice then
        self._audioDevice:watcherCallback(function(dev_uid, event_name, scope, element)
            if event_name == "vmvc" then
                self:updateVolumeIcon()
            end
        end)
    end
    
    -- 设置系统级音频设备变更监听
    hs.audiodevice.watcher.setCallback(function(event)
        -- 当默认输出设备改变时更新图标
        if event == "dOut" then
            -- 短暂延迟以确保设备已完全切换
            hs.timer.doAfter(0.1, function() 
                self:updateVolumeIcon() 
            end)
        end
    end)
    self._deviceWatcher = hs.audiodevice.watcher
    
    return self
end

function obj:start()
    if self._volumeIcon then
        self:updateVolumeIcon()     -- 初始化音量图标
        
        if self._mouseWatcher then   -- 启动鼠标事件监听
            self._mouseWatcher:start()
        end
        
        if self._audioDevice then -- 启动当前音频设备监听
            self._audioDevice:watcherStart()
        end
        
        if self._deviceWatcher then -- 启动系统级音频设备变更监听
            self._deviceWatcher.start()
        end
    end
    return self
end

function obj:stop()
    if self._mouseWatcher then
        self._mouseWatcher:stop()
    end
    
    if self._audioDevice then
        self._audioDevice:watcherStop()
    end
    
    if self._deviceWatcher then
        self._deviceWatcher.stop()
    end
    
    if self._volumeIcon then
        self._volumeIcon:delete()
        self._volumeIcon = nil
    end
    return self
end

-- ======API======
function obj:setMuteStr(str)
    self._volMute = str
    return self
end

function obj:visiblePercent(boolean)
    self._volPercent = boolean
    return self
end

-- 设置是否显示设备名称
function obj:showDeviceName(boolean)
    self._showDeviceName = boolean
    return self
end

-- 设置字体（可自行指定等宽字体，避免音量调整时的抖动）
function obj:setFont(fontName, fontSize)
    if fontName then
        self._font = {
            name = fontName,
            size = fontSize or 14
        }
        -- 如果图标已经创建，立即更新图标
        if self._volumeIcon then
            self:updateVolumeIcon()
        end
    end
    return self
end

return obj