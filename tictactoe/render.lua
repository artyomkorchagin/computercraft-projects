-- ===== CONFIG =====
local MONITOR_SIDE = "right"
local BORDER_SYMBOL = "◘"
-- ===== GLOBAL STATE =====
local monitor = peripheral.wrap(MONITOR_SIDE)
if not monitor then
    print("Attach monitor to side: " .. MONITOR_SIDE)
    return
end

local screen = {}

function screen:new()
    local instance = {
        monitor = monitor,
        width = 0,
        height = 0,
        color = {
            background = colors.black,
            bounds = colors.white,
            x = colors.red,
            o = colors.blue
        }
    }
    setmetatable(instance, {__index = self})
    return instance
end

function screen:init()
    if self.monitor then
        self.width, self.height = self.monitor.getSize()
    end
end

function screen:draw_border()
    self.monitor.setBackgroundColor(self.color.background)
    self.monitor.clear()
    self:draw_horizontal_line(math.floor(self.height/3))
    self:draw_horizontal_line(math.floor(self.height/3*2))
    self:draw_vertical_line(math.floor(self.width/3))
    self:draw_vertical_line(math.floor(self.width/3*2))
end

function screen:draw_vertical_line(x)
    for y = 1, self.height do
        self.monitor.setCursorPos(x, y)
        self.monitor.setTextColor(self.color.bounds)
        self.monitor.write(BORDER_SYMBOL)
    end
end

function screen:draw_horizontal_line(y)
    for x = 1, self.width do
        self.monitor.setCursorPos(x, y)
        self.monitor.setTextColor(self.color.bounds)
        self.monitor.write(BORDER_SYMBOL)
    end
end
local myScreen = screen:new()
myScreen:init()
myScreen:draw_border()
