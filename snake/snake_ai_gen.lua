-- ==================================================
-- SNAKE GAME — Dual Screen Edition
-- Renders on MONITOR (main) + TERMINAL (mirror)
-- Game bounds based on MONITOR size
-- Terminal clips if smaller — no crashes!
-- ==================================================

-- ===== CONFIG =====
local MONITOR_SIDE = "right"
local GAME_SPEED = 0.2
local INITIAL_SNAKE_LENGTH = 5
local INITIAL_SNAKE_X, INITIAL_SNAKE_Y = 10, 8

-- ===== GLOBAL STATE =====
local monitor = peripheral.wrap(MONITOR_SIDE)
if not monitor then
    print("Attach monitor to side: " .. MONITOR_SIDE)
    return
end

local screen = {
    monitor = monitor,
    terminal = term,
    width = 0,
    height = 0,
    gameWidth = 0,
    gameHeight = 0,
    snake_color = colors.lime,
    bounds_color = colors.gray
}

local snake = {
    head = nil,
    dx = 1,
    dy = 0,
    length = 0
}

local foodX, foodY = 0, 0
local gameOver = false

-- ===== SNAKE CELL CLASS =====
local snake_cell = {}
function snake_cell:new(x, y)
    local cell = {
        x = x or 1,
        y = y or 1,
        next = nil
    }
    setmetatable(cell, self)
    self.__index = self
    return cell
end

-- ===== SCREEN RENDERING =====
local function drawToBoth(drawFunc)
    if screen.monitor then
        drawFunc(screen.monitor)
    end
    if screen.terminal then
        local termW, termH = term.getSize()
        local safeTarget = {
            setCursorPos = function(x, y)
                if x >= 1 and x <= termW and y >= 1 and y <= termH then
                    term.setCursorPos(x, y)
                end
            end,
            setTextColor = function(col) term.setTextColor(col) end,
            setBackgroundColor = function(col) term.setBackgroundColor(col) end,
            write = function(str) term.write(str) end,
            clear = function() term.clear() end
        }
        drawFunc(safeTarget)
    end
end

function screen:init()
    if self.monitor then
        self.width, self.height = self.monitor.getSize()
        print("Monitor: " .. self.width .. "x" .. self.height)
    else
        print("No monitor — defaulting to 51x19")
        self.width, self.height = 51, 19
    end

    -- Game logic bounds = monitor size
    self.gameWidth = self.width
    self.gameHeight = self.height

    -- Terminal info (for display only)
    local termW, termH = term.getSize()
    print("Terminal: " .. termW .. "x" .. termH)
end

function screen:clear()
    drawToBoth(function(target)
        target.clear()
        target.setBackgroundColor(colors.black)
    end)
end

function screen:draw_border()
    local left, right = 3, self.gameWidth - 2
    local top, bottom = 3, self.gameHeight - 2

    self:draw_horizontal_line(top, left, right)
    self:draw_horizontal_line(bottom, left, right)
    self:draw_vertical_line(left, top, bottom)
    self:draw_vertical_line(right, top, bottom)
end

function screen:draw_vertical_line(x, start_y, end_y)
    local y1, y2 = math.min(start_y, end_y), math.max(start_y, end_y)
    drawToBoth(function(target)
        for y = y1, y2 do
            target.setCursorPos(x, y)
            target.setTextColor(self.bounds_color)
            target.write("|")
        end
    end)
end

function screen:draw_horizontal_line(y, start_x, end_x)
    local x1, x2 = math.min(start_x, end_x), math.max(start_x, end_x)
    drawToBoth(function(target)
        for x = x1, x2 do
            target.setCursorPos(x, y)
            target.setTextColor(self.bounds_color)
            target.write("-")
        end
    end)
end

function screen:draw_snake(head)
    local function draw_cell(cell, target)
        if not cell then return end
        target.setCursorPos(cell.x, cell.y)
        target.setTextColor(self.snake_color)
        target.write("O")
        if cell.next then draw_cell(cell.next, target) end
    end

    drawToBoth(function(target)
        draw_cell(head, target)
    end)
end

function screen:draw_food(x, y)
    drawToBoth(function(target)
        target.setCursorPos(x, y)
        target.setTextColor(colors.red)
        target.write("F")
    end)
end

-- ===== SNAKE LOGIC =====
function snake:new(x, y, length)
    local head = snake_cell:new(x, y)
    local current = head
    for i = 1, length - 1 do
        current.next = snake_cell:new(x - i, y)
        current = current.next
    end
    self.head = head
    self.length = length
    self.dx, self.dy = 1, 0
end

function snake:move()
    local oldX, oldY = self.head.x, self.head.y
    self.head.x = self.head.x + self.dx
    self.head.y = self.head.y + self.dy

    local current = self.head.next
    while current do
        local tempX, tempY = current.x, current.y
        current.x, current.y = oldX, oldY
        oldX, oldY = tempX, tempY
        current = current.next
    end
end

function snake:grow()
    local tail = self.head
    while tail.next do tail = tail.next end
    tail.next = snake_cell:new(tail.x, tail.y)
    self.length = self.length + 1
end

function snake:checkSelfCollision()
    local current = self.head.next 
    while current do
        if self.head.x == current.x and self.head.y == current.y then
            return true 
        end
        current = current.next
    end
    return false
end

-- ===== GAME INIT =====
screen:init()
snake:new(INITIAL_SNAKE_X, INITIAL_SNAKE_Y, INITIAL_SNAKE_LENGTH)

math.randomseed(os.time())
foodX = math.random(5, screen.gameWidth - 4)
foodY = math.random(5, screen.gameHeight - 4)

local directions = {
    w = {dx=0, dy=-1}, s = {dx=0, dy=1},
    a = {dx=-1, dy=0}, d = {dx=1, dy=0},
    up = {dx=0, dy=-1}, down = {dx=0, dy=1},
    left = {dx=-1, dy=0}, right = {dx=1, dy=0}
}
local function setDirection(dir)
    if not dir then return end

    local currentDx, currentDy = snake.dx, snake.dy
    local newDx, newDy = dir.dx, dir.dy

    -- If new direction is exact opposite, ignore it
    if currentDx == -newDx or currentDy == -newDy then
        return
    end

    snake.dx, snake.dy = newDx, newDy
end

-- ===== GAME THREADS =====

local function HandleControls()
    while not gameOver do
        local event, key = os.pullEvent("key")
        local keyName = keys.getName(key)
        local dir = directions[keyName]
        setDirection(dir)
    end
end

-- Game Over Condition (wall collision)
local function GameOverCondition()
    while not gameOver do
        if snake.head.x < 3 or snake.head.x > screen.gameWidth - 2 or
           snake.head.y < 3 or snake.head.y > screen.gameHeight - 2 then

            gameOver = true
            screen:clear()
            drawToBoth(function(target)
                target.setCursorPos(1, 1)
                target.setTextColor(colors.red)
                target.write("GAME OVER")
                target.setCursorPos(1, 3)
                target.write("Length: " .. snake.length)
            end)
            os.sleep(3)
        end
        os.sleep(0.05)
    end
end

-- Self Collision Checker (runs in parallel)
local function SelfCollisionChecker()
    while not gameOver do
        if snake:checkSelfCollision() then
            gameOver = true
            screen:clear()
            drawToBoth(function(target)
                target.setCursorPos(1, 1)
                target.setTextColor(colors.red)
                target.write("SELF COLLISION!")
                target.setCursorPos(1, 3)
                target.write("Length: " .. snake.length)
            end)
            os.sleep(3)
        end
        os.sleep(0.05) 
    end
end

-- Main Game Loop
local function GameLoop()
    while not gameOver do
        -- RENDER
        screen:clear()
        screen:draw_border()
        screen:draw_food(foodX, foodY)
        screen:draw_snake(snake.head)

        -- UPDATE
        snake:move()

        -- FOOD
        if snake.head.x == foodX and snake.head.y == foodY then
            snake:grow()
            foodX = math.random(5, screen.gameWidth - 4)
            foodY = math.random(5, screen.gameHeight - 4)
        end

        os.sleep(GAME_SPEED)
    end
end

-- ===== START GAME =====
-- Run all 3 coroutines in parallel
parallel.waitForAll(HandleControls, GameOverCondition, GameLoop, SelfCollisionChecker)