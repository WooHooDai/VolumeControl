--- === VolumeControl ===
---
--- macos菜单栏音量控制
--- 基于Hammerspoon, 为macos提供Windows系统一样的音量调节体验。
--- 在菜单栏显示当前音量，支持鼠标中键滚动调节音量，和点击切换静音状态
--- === END ===


local obj = {}
obj.__index = obj

-- 元数据
obj.name = "VolumeControl"
obj.version = "0.1"
obj.author = "静声 <woohoodai>"
obj.homepage = "https://github.com/your_username/VolumeControl.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- 内部属性
obj._volumeIcon = nil
obj._scrollWatcher = nil
obj._audioDevice = nil

-- 内部属性：音量图标
obj._volMute = "静音"
obj._volPercent = false
obj._percent = ""
obj._font = {  -- 字体设置
    name = "Arial",
    size = fontSize or 14  -- 默认字体大小为12
}

function obj:updateVolumeIcon()
    local device = self._audioDevice
    if device and self._volumeIcon then
        local volume = device:volume()
        local muted = device:muted()
        
        local titleText = ""
        if muted then
            titleText = self._volMute
        elseif volume ~= nil then
            titleText = math.floor(volume).. (obj._volPercent and "%" or "")
        else
            -- 连接电视为显示器时，音量为nil，粗暴处理一下
            -- TODO： 音量输出源不为nil或者切换时，重启脚本以显示音量
            titleText = "--"
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
        
        self._volumeIcon:autosaveName("volumeControl")
    end
end

function obj:init()
    self._volumeIcon = hs.menubar.new(true, "volumeControl")    -- 创建音量图标
    obj._audioDevice = hs.audiodevice.defaultOutputDevice()     -- 获取默认音频设备
    -- 设置音量图标点击事件
    self._volumeIcon:setClickCallback(function()
        if self._audioDevice then
            self._audioDevice:setMuted(not self._audioDevice:muted())
            self:updateVolumeIcon()
        end
    end)

    -- 设置鼠标滚轮监听
    self._scrollWatcher = hs.eventtap.new({hs.eventtap.event.types.scrollWheel}, function(event)
        local mousePos = hs.mouse.absolutePosition()
        local iconPos = self._volumeIcon:frame()
        
        if mousePos.x >= iconPos.x and mousePos.x <= iconPos.x + iconPos.w and
            mousePos.y >= iconPos.y and mousePos.y <= iconPos.y + iconPos.h then
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

    return self
end

function obj:start()
    if self._volumeIcon and self._audioDevice and self._scrollWatcher then
        self:updateVolumeIcon()     -- 初始化音量图标
        self._scrollWatcher:start() -- 启动鼠标滚轮监听
        self._audioDevice:watcherStart() -- 启动音频设备监听
    end
    return self
end

function obj:stop()
    if self._scrollWatcher then
        self._scrollWatcher:stop()
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