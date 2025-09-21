-- this is the client with speaker

-- CONFIG ==============
local SIDES = {
    MODEM = "front"
}
local PROTOCOL = "siren_server_protocol"
local SERVER_NAME = "siren_server"

local speaker = peripheral.find("speaker")
local server_id
local client = {}

rednet.open(SIDES.MODEM)

for i = 1, 20 do
    server_id = rednet.lookup(PROTOCOL, SERVER_NAME)
    if server_id then
        print("found server")
        break
    end
    sleep(10)
end
if not server_id then
    print("no server found after 20 retries")
    return
end
function client:new()
    local instance = {
        protocol = PROTOCOL,
        meltdown = false,
        speaker = speaker
    }
    setmetatable(instance, {__index = self})
    rednet.send(server_id, "sub", PROTOCOL)
    return instance
end

function client:handle_signals()
    while true do
        local _, message = rednet.receive(self.protocol)
        if message == "meltdown" then
            print("received meltdown")
            self.meltdown = true
        end
        if message == "abort" then
            print("aborting meltdown")
            self.meltdown = false
        end
        sleep(0.1)
    end
end

function client:siren_sound()
    while true do
        while self.meltdown do
            self.speaker.playSound("pneumaticcraft:elevator_rising", 3.0, 1.5)
            sleep(0.3)
            self.speaker.playSound("pneumaticcraft:elevator_rising", 3.0, 1.0)
            sleep(0.3)
        end
        sleep(1)
    end
end

-- MAIN =================
local myClient = client:new()
print("client started")
myClient.speaker.playNote("harp", 1, 1)

parallel.waitForAll(
    function() myClient:handle_signals() end,
    function() myClient:siren_sound() end
)