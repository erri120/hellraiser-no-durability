-- NoDurability: removes the melee weapon durability/decay and break system
-- from Hellraiser.
--
-- Mechanism: per-hit durability loss funnels through the reflected
-- DurabilityItemInfoInterface:UpdateDurability(delta) which GA_Melee applies
-- on ItemInfoMeleeWeapon. The pre-exec hook zeroes delta; the game honours
-- the zeroed param (verified in-game). Weapon init/repair (SetDurability)
-- stays untouched.
--
-- Same principle forces the HUD durability bar off: it reads the persisted
-- EHUDToggleBehavior Durabilitybar in UInfernoUserSettings, which the options
-- menu can set to On/Off/Dynamic/Minimalistic. Every write is clamped to
-- EHUDToggleBehavior.Off (0) in the pre-hook, and a stale saved value is
-- overwritten once on possession.

local TAG = "[NoDurability] "
local MODULE = "/Script/Project"
local EHUD_OFF = 0 -- EHUDToggleBehavior.Off

local function onUpdateDurability(_, delta)
    if delta then
        pcall(function() delta:set(0) end)
    end
end

local function onSetToggleDurabilityBar(_, behavior)
    if behavior then
        pcall(function() behavior:set(EHUD_OFF) end)
    end
end

-- The game module is not yet loaded when UE4SS starts this script.
local hookedDurability = false
local function installDurabilityHook()
    if hookedDurability then return true end
    local ok, err = pcall(RegisterHook,
        MODULE .. ".DurabilityItemInfoInterface:UpdateDurability", onUpdateDurability)
    if ok then
        hookedDurability = true
        print(TAG .. "hooked " .. MODULE .. ".DurabilityItemInfoInterface:UpdateDurability")
    else
        print(TAG .. "could not hook durability: " .. tostring(err))
    end
    return hookedDurability
end

local hookedBarSetting = false
local function installBarHook()
    if hookedBarSetting then return true end
    local ok, err = pcall(RegisterHook,
        MODULE .. ".InfernoUserSettings:SetToggleDurabilityBar", onSetToggleDurabilityBar)
    if ok then
        hookedBarSetting = true
        print(TAG .. "hooked " .. MODULE .. ".InfernoUserSettings:SetToggleDurabilityBar")
    else
        print(TAG .. "could not hook durability bar setting: " .. tostring(err))
    end
    return hookedBarSetting
end

-- Profiles saved before this mod may carry On/Dynamic; overwrite once.
local function forceOffDurabilityBar()
    local ok, settings = pcall(FindFirstOf, "InfernoUserSettings")
    if ok and settings and settings:IsValid() then
        local okSet, err = pcall(settings.SetToggleDurabilityBar, settings, EHUD_OFF)
        print(okSet and (TAG .. "durability bar forced Off")
            or (TAG .. "could not set durability bar: " .. tostring(err)))
    end
end

-- ClientRestart is the first engine event where the player is possessed;
-- combat-driven UpdateDurability calls and HUD construction happen after it,
-- so the bar setting is clamped before the HUD reads it.
RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
    forceOffDurabilityBar()
    installBarHook()
    installDurabilityHook()
end)
