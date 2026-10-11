-- NoDurability: removes the melee weapon durability/decay and break system
-- from Hellraiser.
--
-- Mechanism: per-hit durability loss funnels through the reflected
-- DurabilityItemInfoInterface:UpdateDurability(delta) which GA_Melee applies
-- on ItemInfoMeleeWeapon. The pre-exec hook zeroes delta; the game honours
-- the zeroed param (verified in-game). Weapon init/repair (SetDurability)
-- stays untouched.

local TAG = "[NoDurability] "
local MODULE = "/Script/Project"

local function onUpdateDurability(_, delta)
    if delta then
        pcall(function() delta:set(0) end)
    end
end

local installed = false
local function install()
    if installed then return true end
    local ok, err = pcall(RegisterHook,
        MODULE .. ".DurabilityItemInfoInterface:UpdateDurability", onUpdateDurability)
    if ok then
        installed = true
        print(TAG .. "hooked " .. MODULE .. ".DurabilityItemInfoInterface:UpdateDurability")
    else
        print(TAG .. "could not hook yet: " .. tostring(err))
    end
    return installed
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
    install()
end)
