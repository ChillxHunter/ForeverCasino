-- Forever Casino v1.4.1: keep the career scoreboard inside the game window
-- and improve accessibility of the movable minimap launcher.
-- Loaded after UI.lua, before PLAYER_LOGIN builds the UI.
local addonName, ns = ...
local UI = ns.UI
local Core = ns.Core
if not UI or not Core then return end

local function reposition(frame, parent, x, y, width, height)
    if not frame then return end
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width and height then frame:SetSize(width, height) end
end

local function updateVersion(frame)
    if not frame or not frame.GetRegions then return end
    -- The UI's original version label is local to UI.lua.
    local n = select("#", frame:GetRegions())
    for i = 1, n do
        local region = select(i, frame:GetRegions())
        if region and region.IsObjectType and region:IsObjectType("FontString")
            and region.GetText and region:GetText() == "V 1.4.0" then
            region:SetText("V 1.4.1")
        end
    end
end

function UI:ApplyCompactLayout()
    if not self.built or not self.pvpStats or not self.coinArt then return end
    local board = self.pvpStats:GetParent()
    local right = board:GetParent()
    local hero = self.coinArt:GetParent()
    local log = self.results:GetParent()
    if not (board and right and hero and log) then return end

    -- The old scoreboard started at -482 and ended at -576 *inside* a
    -- 485px-high right panel. The following layout ends at -477 instead.
    reposition(hero, right, 17, -100, 590, 173)
    reposition(self.coinArt, hero, 14, -11, 144, 144)
    reposition(self.dice, hero, 14, -11, 144, 144)
    reposition(self.symbolHelp, hero, 15, -154, 147, 18)
    reposition(self.turnFlag, hero, 181, -10, 383, 23)
    reposition(self.symbol, hero, 181, -37, 372, 41)
    reposition(self.own, hero, 181, -107, 385, 28)
    reposition(self.theirs, hero, 181, -136, 389, 33)

    reposition(self.main, right, 17, -282, 386, 39)
    reposition(self.secondary, right, 414, -282, 193, 39)

    reposition(log, right, 17, -328, 590, 77)
    reposition(self.results, log, 14, -26, 564, 48)

    reposition(board, right, 17, -412, 590, 65)
    reposition(self.pvpStats, board, 13, -23, 562, 20)
    reposition(self.soloStats, board, 13, -43, 562, 20)
    -- Move the career heading if present so it does not collide with the stats.
    if board.GetRegions then
        local n=select("#", board:GetRegions())
        for i=1,n do
            local region=select(i,board:GetRegions())
            if region and region.IsObjectType and region:IsObjectType("FontString")
                and region.GetText and type(region:GetText())=="string"
                and region:GetText():find("CAREER SCOREBOARD",1,true) then
                reposition(region,board,12,-3,565,18)
            end
        end
    end
    updateVersion(self.frame)
end

function UI:EnsureMinimapButton()
    if not self.built or not Minimap then return end
    if not self.minimap then self:BuildMinimap() end
    local m=self.minimap
    if not m then return end
    -- The stock icon is available without any extra image files.
    m:SetSize(34,34)
    m:SetFrameStrata("HIGH")
    if m.SetFrameLevel and Minimap.GetFrameLevel then
        m:SetFrameLevel(Minimap:GetFrameLevel()+6)
    end
    if m.RegisterForClicks then m:RegisterForClicks("LeftButtonUp") end
    self:UpdateMinimap()
end

local originalBuild = UI.Build
function UI:Build(...)
    if self.built then return end
    originalBuild(self,...)
    self:ApplyCompactLayout()
    self:EnsureMinimapButton()
end

-- On some customised UIs the minimap object only appears after PLAYER_LOGIN.
-- Retry once after the world has been entered.
local retry = CreateFrame("Frame")
retry:RegisterEvent("PLAYER_ENTERING_WORLD")
retry:SetScript("OnEvent", function()
    if UI.built then UI:EnsureMinimapButton() end
end)

-- `/casino showicon` is unambiguous, unlike `/casino icon`, which toggles.
local previousSlash = SlashCmdList and SlashCmdList.FOREVERCASINO
if previousSlash then
    SlashCmdList.FOREVERCASINO=function(message)
        local input=tostring(message or ""):lower():match("^%s*(.-)%s*$")
        if input=="showicon" or input=="map" or input=="minimap" then
            if type(ForeverCasinoDB)~="table" then ForeverCasinoDB={} end
            ForeverCasinoDB.hideMinimap=false
            if UI.built then UI:EnsureMinimapButton() end
            Core:Print("Minimap button shown. Left-click to open; drag around the minimap.")
        elseif input=="reseticon" then
            if type(ForeverCasinoDB)~="table" then ForeverCasinoDB={} end
            ForeverCasinoDB.hideMinimap=false
            ForeverCasinoDB.minimapAngle=225
            if UI.built then UI:EnsureMinimapButton() end
            Core:Print("Minimap button position reset.")
        else
            previousSlash(message)
        end
    end
end
