-- this is the client with speaker

-- CONFIG ==============
local SIDES = {
    REDSTONE = "left"
}

local speaker = peripheral.find("speaker")
local client = {}

function client:new()
    local instance = {
        meltdown = false,
        speaker = speaker
    }
    setmetatable(instance, {__index = self})
    return instance
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

function client:fetch_redstone()
    while true do
        self.meltdown = redstone.getInput(SIDES.REDSTONE)
        sleep(5)
    end
end
-- MAIN =================

local myClient = client:new()
print("client started")
myClient.speaker.playNote("harp", 1, 1)

parallel.waitForAll(
    function() myClient:siren_sound() end,
    function() myClient:fetch_redstone() end
)