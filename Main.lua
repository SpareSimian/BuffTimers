local addonName, addon = ...
LibStub('AceAddon-3.0'):NewAddon(addon, addonName, 'AceConsole-3.0')

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
local minimapButtonCreated = false

local function createMinimapButton(iconPath)
   if minimapButtonCreated then return end
   local prettyName = "Buff Timers"
   local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
      type = "data source",
      text = prettyName,
      icon = iconPath,
      OnClick = function(self, btn)
         mslcDisplayMissing()
      end,
      OnTooltipShow = function(tooltip)
         if not tooltip or not tooltip.AddLine then return end
         tooltip:AddLine(prettyName)
      end,
   })
   local icon = LibStub("LibDBIcon-1.0", true)
   icon:Register(addonName, miniButton, mslcDB)
   minimapButtonCreated = true
end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- deepcopy from http://lua-users.org/wiki/CopyTable

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


-- https://stackoverflow.com/questions/15706270/sort-a-table-in-lua
local function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- initialize can be called at any event

local playerNameKey -- "name - realm" used as key in persistent data

local function initialize()
   -- init all our data structures
   if not playerNameKey then
      local name, realm = UnitFullName("player")
      playerNameKey = name .. " - " .. realm
   end
   if not buffTimersDB then
      buffTimersDB = {}
   end
   if not buffTimersDB[playerNameKey] then
      buffTimersDB[playerNameKey] = {}
   end
   createMinimapButton("Interface\\Icons\\spell_misc_emotionhappy")
   return true -- success
end

local function displayBuffTimers()
   AuraUtil.ForEachAura("player", "HELPFUL", nil, function(name, icon, ...)
      addon:Print(name, icon, ...)
   end)
end

local function saveBuffs()
   -- iterate over buffs and save them to our persistent DB
end

local function eventHandler(self, event, ...)
   saveBuffs()
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", eventHandler)
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD") -- just before LOGOUT

SLASH_BUFFTIMERS1="/bufftimers"
SlashCmdList["BUFFTIMERS"] = function(msg)
   displayBuffTimers()
end

function addon:OnEnable()
   initialize()
   local version = C_AddOns.GetAddOnMetadata(addonName, "Version") -- from TOC file
   addon:Print("Version " .. version)
   saveBuffs()
end

function buffTimers_OnAddonCompartmentClick(addonName, mouseButton, button)
   displayBuffTimers()
end
