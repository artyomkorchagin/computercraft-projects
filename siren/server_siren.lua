-- i need to create a server with pub/sub architecture
-- this is the computer that will read redstone signal from the sensors
-- and send signals to computers with speakers that are subscribed to this server

-- CONFIG =================
local SIGNALS = {
    MELTDOWN = "meltdown",
    ABORT = "abort"
}
local STATES = {
    NORMAL = 0,
    MELTDOWN = 1,
    ABORT = 2
}
local SIDES = {
    MODEM = "right",
    REDSTONE = "left"
}
local PROTOCOL = "siren_server_protocol"

rednet.open(SIDES.MODEM)

local server = {}

function server:new()
    server = {
        protocol = PROTOCOL,
        hostname = "siren_server",
        meltdown = false,
        state = STATES.NORMAL,
        clients = {}
    }
    setmetatable(server, self)
    self.__index = self
    rednet.host(server.protocol, server.hostname)
    return server
end


local function tableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

local function fetch_redstone()
    while true do
        server.meltdown = redstone.getInput(SIDES.REDSTONE)
        sleep(1)
    end
end

local function handle_states()
    while true do
        if server.meltdown and server.state == STATES.NORMAL then
            server.state = STATES.MELTDOWN
            server:send_signal(SIGNALS.MELTDOWN)
        end
        if not server.meltdown and server.state == STATES.MELTDOWN then
            server.state = STATES.ABORT
        end
        if server.state == STATES.ABORT then
            server.state = STATES.NORMAL
            server:send_signal(SIGNALS.ABORT)
        end
        sleep(1)
    end
end

local function handle_subscriptions()
    while true do
        local id, message = rednet.receive(PROTOCOL)
        if message == "sub" then
            server:subscribe(id)
            if server.meltdown then
                rednet.send(id, SIGNALS.MELTDOWN, server.protocol)
            end
            print("client subscribed with id" ..id)
        end
        sleep(0.1)
    end
end

function server:send_signal(signal) -- signal = "abort" or "meltdown"
    for _, client in pairs(server.clients) do
        rednet.send(client, signal, server.protocol)
    end
end

function server:subscribe(client)
    if tableContains(server.clients, client) then
        return
    end
    table.insert(server.clients, client)
end

-- MAIN ================
server:new()

print("started server on host: " ..server.hostname)

parallel.waitForAll(fetch_redstone, handle_states, handle_subscriptions)