--- === VolumeControl ===
---
--- 菜单栏音量控制
--- 在菜单栏显示当前音量，支持鼠标中键滚动调节音量，和点击切换静音状态
--- init: 3月7日
--- fix: 3月11日 静音状态下，调整音量不生效；音量到0时，未显示静音
--- Download: [https://github.com/your_username/VolumeControl.spoon](.)

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

function obj:updateVolumeIcon()
    local device = self._audioDevice
    if device and self._volumeIcon then
        local volume = math.floor(device:volume())
        local muted = device:muted()
        if muted then
            self._volumeIcon:setTitle(self._volMute)
        else
            self._volumeIcon:setTitle(volume.. (obj._volPercent and "%" or ""))
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


return obj