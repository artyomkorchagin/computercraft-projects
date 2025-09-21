-- ===== CONFIG =====
local MONITOR_SIDE = "right"

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

function screen:draw_border()
    self:draw_horizontal_line(self.height/3)
    self:draw_horizontal_line(self.height/3*2)
    self:draw_vertical_line(self.width/3)
    self:draw_vertical_line(self.width/3*2)
end

function screen:draw_vertical_line(x)
    for y = 1, self.height do
        self.monitor.setCursorPos(x, y)
        self.monitor.setTextColor(self.bounds_color)
        self.monitor.write("◘")
    end
end

function screen:draw_horizontal_line(y)
    for x = 1, self.width do
        self.monitor.setCursorPos(x, y)
        self.monitor.setTextColor(self.bounds_color)
        self.monitor.write("◘")
    end
end
local myScreen = screen:new()
return myScreen