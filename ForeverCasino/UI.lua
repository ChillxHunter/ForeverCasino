-- Forever Casino 1.4 -- native World of Warcraft interface
-- All buttons and decorative elements are created from standard WoW API frames.
local addonName, ns = ...
local A = ns.Core
local UI = { mode="COIN", best=3, playMode="SOLO", built=false }
ns.UI = UI

local C = {
    bg={0.028,0.036,0.063}, card={0.066,0.079,0.118}, cardDeep={0.044,0.053,0.088},
    gold={1.00,0.76,0.31}, goldDim={0.55,0.39,0.21}, white={0.96,0.96,0.98},
    muted={0.64,0.71,0.82}, green={0.42,0.98,0.69}, red={1.0,0.47,0.52},
    blue={0.34,0.62,0.99}, purple={0.57,0.43,0.87}
}
local texture = "Interface\\Buttons\\WHITE8X8"
local function unpack3(c) return c[1],c[2],c[3] end
local function place(frame,parent,x,y,w,h)
    frame:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    frame:SetSize(w,h)
    return frame
end
local function skin(f,fill,border,alpha)
    f:SetBackdrop({bgFile=texture,edgeFile=texture,edgeSize=1,
        insets={left=1,right=1,top=1,bottom=1}})
    f:SetBackdropColor(fill[1],fill[2],fill[3],alpha or 0.98)
    f:SetBackdropBorderColor(border[1],border[2],border[3],0.88)
end
local function panel(parent,x,y,w,h,fill,border)
    local f=place(CreateFrame("Frame",nil,parent,"BackdropTemplate"),parent,x,y,w,h)
    skin(f,fill or C.card,border or C.goldDim)
    return f
end
local function strip(parent,x,y,w,h,color,alpha)
    local t=parent:CreateTexture(nil,"ARTWORK")
    t:SetTexture(texture)
    t:SetVertexColor(color[1],color[2],color[3],alpha or 1)
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    t:SetSize(w,h)
    return t
end
local function txt(parent,s,x,y,w,h,font,color,align)
    local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    t:SetSize(w,h)
    t:SetJustifyH(align or "LEFT")
    t:SetJustifyV("MIDDLE")
    t:SetWordWrap(true)
    t:SetText(s or "")
    if color then t:SetTextColor(unpack3(color)) end
    return t
end
local function paintButton(b)
    local on=b:IsEnabled()
    local selected=b.selected
    local variant=b.variant
    local base,border,fg
    if variant=="primary" then
        base={0.55,0.29,0.09};border=C.gold;fg=C.white
    elseif variant=="danger" then
        base={0.27,0.10,0.17};border={0.67,0.25,0.35};fg={1,.72,.74}
    elseif variant=="blue" then
        base={0.13,0.23,0.41};border=C.blue;fg=C.white
    elseif selected then
        base={0.22,0.18,0.19};border=C.gold;fg=C.gold
    else
        base={0.085,0.111,0.166};border={0.21,0.28,0.36};fg=C.muted
    end
    if b.hovered and on then base={math.min(1,base[1]+0.07),math.min(1,base[2]+0.07),math.min(1,base[3]+0.075)} end
    b:SetBackdropColor(base[1],base[2],base[3],on and 1 or 0.47)
    b:SetBackdropBorderColor(border[1],border[2],border[3],on and 1 or 0.42)
    if b.label then b.label:SetTextColor(fg[1],fg[2],fg[3],on and 1 or 0.48) end
end
local function button(parent,s,x,y,w,h,action,variant)
    local b=place(CreateFrame("Button",nil,parent,"BackdropTemplate"),parent,x,y,w,h)
    b.variant=variant or "normal"
    b.selected=false
    b.hovered=false
    b.action=action
    skin(b,C.card,C.goldDim)
    local t=txt(b,s,5,-2,w-10,h-4,"GameFontNormal",C.white,"CENTER")
    b.label=t
    b:SetScript("OnClick",function(self) if self:IsEnabled() and self.action then self.action() end end)
    b:SetScript("OnEnter",function(self) self.hovered=true;paintButton(self) end)
    b:SetScript("OnLeave",function(self) self.hovered=false;paintButton(self) end)
    b:SetScript("OnEnable",paintButton)
    b:SetScript("OnDisable",paintButton)
    paintButton(b)
    return b
end
local function entry(parent,x,y,w,h,maxLetters)
    local back=panel(parent,x,y,w,h,C.cardDeep,{0.21,0.29,0.39})
    local e=CreateFrame("EditBox",nil,back)
    e:SetPoint("TOPLEFT",back,"TOPLEFT",12,-6)
    e:SetPoint("BOTTOMRIGHT",back,"BOTTOMRIGHT",-10,6)
    e:SetAutoFocus(false)
    e:SetFontObject("ChatFontNormal")
    e:SetMaxLetters(maxLetters or 70)
    e:SetTextColor(unpack3(C.white))
    e:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    e:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    e.back=back
    return e
end
local function picture(parent,x,y,icon)
    local back=place(CreateFrame("Button",nil,parent,"BackdropTemplate"),parent,x,y,144,144)
    skin(back,{0.102,0.117,0.158},C.gold)
    strip(back,9,-9,126,2,C.gold,0.55)
    strip(back,9,-133,126,2,C.gold,0.40)
    local t=back:CreateTexture(nil,"ARTWORK")
    t:SetTexture(icon)
    t:SetPoint("CENTER",back,"CENTER",0,0)
    t:SetSize(112,112)
    back.art=t
    back:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    back:SetScript("OnClick",function() if A:CanRoll() then A:Roll() end end)
    return back
end
function UI:Show(flag)
    if not self.built then return end
    if flag==false then self.frame:Hide() return end
    self.frame:Show()
    self:Refresh()
    self:UpdateAgeGate()
end
function UI:Toggle()
    if not self.built then return end
    if self.frame:IsShown() then self.frame:Hide() else self:Show(true) end
end
function UI:UpdateAgeGate()
    if not self.ageGate then return end
    if A.ageConfirmed then self.ageGate:Hide() else
        self.ageCheck:SetChecked(false)
        self.ageProceed:SetEnabled(false)
        self.ageGate:Show()
    end
end
function UI:AgeDecline()
    if A.session and A.session.stage=="incoming" then A:Decline() end
    self.frame:Hide()
end
function UI:SetButton(b,show,text,action)
    if not show then b:Hide(); b.action=nil; return end
    b:Show(); b.label:SetText(text or ""); b.action=action
    b:SetEnabled(true)
end
local function recent(s,count)
    if not s or #s.history==0 then return "No rolls yet. Your match history appears here." end
    local lines={}
    for i=math.max(1,#s.history-(count or 4)+1),#s.history do
        lines[#lines+1]="|cffdda85e"..tostring(i)..".|r  "..s.history[i]
    end
    return table.concat(lines,"\n")
end
function UI:Refresh()
    if not self.built then return end
    local s=A.session
    if s then self.mode=s.kind;self.best=s.best;self.playMode=s.solo and "SOLO" or "PVP" end
    local active=s and s.stage~="done"
    self.coin.selected=(self.mode=="COIN")
    self.death.selected=(self.mode=="DEATH")
    self.pvp.selected=(self.playMode=="PVP")
    self.solo.selected=(self.playMode=="SOLO")
    for n,b in pairs(self.bestBtns) do b.selected=(self.best==n);paintButton(b) end
    for _,b in ipairs({self.coin,self.death,self.pvp,self.solo}) do b:SetEnabled(not active);paintButton(b) end
    self.bestTitle:SetText(self.mode=="COIN" and "MATCH LENGTH  |  BEST OF" or "DEATHROLL  |  STARTING DIE: 1,000")
    for _,b in pairs(self.bestBtns) do b:SetShown(self.mode=="COIN");b:SetEnabled(not active) end
    self.playerTitle:SetShown(self.playMode=="PVP")
    self.playerEdit.back:SetShown(self.playMode=="PVP")
    self.targetBtn:SetShown(self.playMode=="PVP")
    self.start.label:SetText(self.playMode=="SOLO" and "START SOLO GAME" or "SEND CHALLENGE")
    self.start:SetEnabled(not active)
    self.notice:SetText(A.status or "")
    local rec=A:GetStats()
    self.pvpStats:SetText(string.format("2 PLAYERS     |cff65efa2W %d|r     |cffffd47eD %d|r     |cffff667bL %d|r",rec.pvp.wins,rec.pvp.draws,rec.pvp.losses))
    self.soloStats:SetText(string.format("SOLO (SIDE A)  |cff65efa2W %d|r     |cffffd47eD %d|r     |cffff667bL %d|r",rec.solo.wins,rec.solo.draws,rec.solo.losses))
    self.badge:SetText(self.playMode=="SOLO" and "SOLO PRACTICE" or "2 PLAYERS")
    self.headline:SetText(self.mode=="COIN" and "COIN TOSS" or "DEATHROLL")
    self.subline:SetText(self.mode=="COIN" and ("Best of "..self.best.."  |  Heads vs Tails") or "Alternate rolls  |  First to roll 1 loses")
    self.own:SetText("")
    self.theirs:SetText("")
    self.results:SetText("")
    self.turnFlag:SetText("CHOOSE A GAME")
    self.symbol:SetText(self.mode=="COIN" and "50 / 50" or "d1000")
    self.symbolHelp:SetText("CLICK TO ROLL")
    self.coinArt:SetShown(self.mode=="COIN")
    self.dice:SetShown(self.mode=="DEATH")
    self:SetButton(self.main,false)
    self:SetButton(self.secondary,false)
    self:SetButton(self.endBtn,false)
    self.results:SetText(recent(s,4))
    if not s then
        self.turnFlag:SetText("READY WHEN YOU ARE")
        self.own:SetText(self.playMode=="SOLO" and "A private practice table.\nYou control both sides." or "CHALLENGE A FRIEND\nBoth players must install the addon.")
        self.theirs:SetText(self.mode=="COIN" and "Pick best of 1, 3 or 5.\nFlip to decide each round." or "Begin at d1000. Each roll\nsets the next die's maximum.")
        self.symbolHelp:SetText("CHOOSE AND START")
        return
    end
    self:SetButton(self.endBtn,true,s.stage=="done" and "CLOSE TABLE" or "LEAVE TABLE",function() A:Decline() end)
    self.badge:SetText(s.solo and "SOLO PRACTICE" or ("VS "..s.other))
    self.headline:SetText(s.kind=="COIN" and "COIN TOSS" or "DEATHROLL")
    self.subline:SetText(s.kind=="COIN" and ("Best of "..s.best.."  |  "..(s.solo and "Practice" or s.other))
        or ("d1000 start  |  "..(s.solo and "Practice" or s.other)))
    if s.kind=="COIN" then
        self.symbol:SetText(s.scoreHost.." : "..s.scoreGuest)
    else
        self.symbol:SetText("d"..tostring(s.limit or 1000))
    end
    if s.stage=="invite" then
        self.turnFlag:SetText("CHALLENGE SENT")
        self.own:SetText("Waiting for "..s.other.." to accept.")
        self.theirs:SetText("Both players must press Ready after acceptance.")
        self.symbolHelp:SetText("WAITING FOR PLAYER")
    elseif s.stage=="incoming" then
        self.turnFlag:SetText("INCOMING CHALLENGE")
        self.own:SetText(s.other.." invited you to play.")
        self.theirs:SetText("Accept the invitation, then both players press Ready.")
        self:SetButton(self.main,true,"ACCEPT CHALLENGE",function() A:Accept() end)
        self:SetButton(self.secondary,true,"DECLINE",function() A:Decline() end)
        self.symbolHelp:SetText("YOUR CHOICE")
    elseif s.stage=="ready" then
        self.turnFlag:SetText("READY CHECK")
        self.own:SetText("YOU        "..(s.localReady and "|cff65f3a3READY|r" or "|cffff6976NOT READY|r"))
        self.theirs:SetText(s.other.."        "..(s.remoteReady and "|cff65f3a3READY|r" or "|cffff6976NOT READY|r"))
        self:SetButton(self.main,true,s.localReady and "WAITING FOR OPPONENT" or "I'M READY",function() A:Ready() end)
        self.main:SetEnabled(not s.localReady)
        self:SetButton(self.secondary,true,"CANCEL READY",function() A:Unready() end)
        self.secondary:SetEnabled(s.localReady)
        self.symbolHelp:SetText("BOTH MUST CONFIRM")
    elseif s.stage=="play" then
        self.turnFlag:SetText("LOCAL RANDOM / CASUAL PLAY")
        if s.kind=="COIN" then
            self.own:SetText("|cffffd47eHEADS (A)|r      "..s.scoreHost.." wins\n|cff9bc9ffTAILS (B)|r        "..s.scoreGuest.." wins")
            self.theirs:SetText("Flip "..math.min(s.seq,s.best).." of "..s.best.."  |  "..(s.solo and "You control both sides" or "Host flips"))
            if s.solo or s.host then
                self:SetButton(self.main,true,"FLIP COIN",function() A:Roll() end)
            else
                self:SetButton(self.main,true,"WAITING FOR HOST",nil)
                self.main:SetEnabled(false)
            end
        else
            local turnName=s.solo and (s.turn=="host" and "SIDE A" or "SIDE B") or
                ((s.turn==(s.host and "host" or "guest")) and "YOU" or s.other)
            self.own:SetText("CURRENT DIE     |cffffd47ed"..s.limit.."|r\nNEXT ROLLER      "..turnName)
            self.theirs:SetText("The last result becomes the next die.\nFirst to roll 1 loses.")
            if A:CanRoll() then
                self:SetButton(self.main,true,"ROLL d"..s.limit,function() A:Roll() end)
            else
                self:SetButton(self.main,true,"WAITING FOR TURN",nil)
                self.main:SetEnabled(false)
            end
        end
        self.symbolHelp:SetText("CLICK ART TO ROLL")
        if not s.solo then
            if s.drawIncoming then
                self.turnFlag:SetText("DRAW OFFER RECEIVED")
                self:SetButton(self.main,true,"DECLINE DRAW",function() A:AnswerDraw(false) end)
                self:SetButton(self.secondary,true,"ACCEPT DRAW",function() A:AnswerDraw(true) end)
            elseif s.drawOutgoing then
                self.turnFlag:SetText("DRAW OFFER PENDING")
                self:SetButton(self.secondary,true,"DRAW OFFER SENT",nil)
                self.secondary:SetEnabled(false)
                self.main:SetEnabled(false)
            else
                self:SetButton(self.secondary,true,"OFFER DRAW",function() A:OfferDraw() end)
            end
        end
    elseif s.stage=="done" then
        self.turnFlag:SetText("MATCH COMPLETE")
        local who=s.winner and (s.winner=="host" and "SIDE A" or "SIDE B") or "NO RESULT"
        local mine=s.winner and (s.winner==(s.host and "host" or "guest"))
        self.own:SetText(s.winner=="draw" and "|cffffd47eDRAW — BOTH PLAYERS AGREE|r" or
            (s.solo and ("|cff64f0a2"..who.." WINS|r") or
            (mine and "|cff64f0a2YOU WIN!|r" or "|cffff6576YOU LOSE|r")))
        self.theirs:SetText("The table is finished. Play another round whenever you're ready.")
        self.symbolHelp:SetText("FINAL RESULT")
        self:SetButton(self.main,true,"NEW GAME",function() A:Decline() end)
    end
    self.results:SetText(recent(s,4))
end
function UI:UpdateMinimap()
    if not self.minimap then return end
    local db=ForeverCasinoDB or {}
    self.minimap:SetShown(not db.hideMinimap)
    local a=math.rad(db.minimapAngle or 225)
    self.minimap:ClearAllPoints()
    self.minimap:SetPoint("CENTER",Minimap,"CENTER",math.cos(a)*81,math.sin(a)*81)
end
function UI:BuildMinimap()
    if not Minimap then return end
    local m=CreateFrame("Button","ForeverCasinoMinimapButton",Minimap)
    m:SetSize(32,32)
    m:SetFrameStrata("MEDIUM")
    local icon=m:CreateTexture(nil,"ARTWORK")
    icon:SetPoint("CENTER")
    icon:SetSize(22,22)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_02")
    local border=m:CreateTexture(nil,"OVERLAY")
    border:SetAllPoints()
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    m:RegisterForDrag("LeftButton")
    m:SetScript("OnClick",function() UI:Toggle() end)
    m:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_LEFT")
        GameTooltip:AddLine("Forever Casino",1,0.80,0.35)
        GameTooltip:AddLine("Click: open / close",1,1,1)
        GameTooltip:AddLine("Drag: reposition",0.78,0.82,0.9)
        GameTooltip:Show()
    end)
    m:SetScript("OnLeave",function() GameTooltip:Hide() end)
    m:SetScript("OnDragStart",function(self)
        self:SetScript("OnUpdate",function()
            local scale=Minimap:GetEffectiveScale()
            local cx,cy=Minimap:GetCenter()
            local mx,my=GetCursorPosition()
            local dx,dy=mx/scale-cx,my/scale-cy
            local a=(math.atan2 and math.atan2(dy,dx)) or math.atan(dy/dx)
            if not math.atan2 and dx<0 then a=a+math.pi end
            ForeverCasinoDB.minimapAngle=math.deg(a)
            UI:UpdateMinimap()
        end)
    end)
    m:SetScript("OnDragStop",function(self) self:SetScript("OnUpdate",nil) end)
    self.minimap=m
    self:UpdateMinimap()
end
function UI:Build()
    if self.built then return end
    local f=CreateFrame("Frame","ForeverCasinoWindow",UIParent,"BackdropTemplate")
    f:SetSize(940,650)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    skin(f,C.bg,C.goldDim,0.99)
    f:SetBackdropBorderColor(0.72,0.50,0.25,1)
    self.frame=f
    -- Drag handle exists only in the header so clicking game controls never moves the window.
    local drag=CreateFrame("Frame",nil,f)
    drag:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
    drag:SetSize(890,79)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart",function() f:StartMoving() end)
    drag:SetScript("OnDragStop",function() f:StopMovingOrSizing() end)
    strip(f,1,-1,938,5,C.gold,0.88)
    strip(f,1,-80,938,2,C.goldDim,0.45)
    strip(f,16,-10,4,61,C.gold,0.65)
    txt(f,"FOREVER",35,-15,175,31,"GameFontNormalLarge",C.gold)
    txt(f,"CASINO",189,-15,155,31,"GameFontNormalLarge",C.white)
    txt(f,"COIN TOSS   /   DEATHROLL   /   SOLO PRACTICE",35,-47,710,22,"GameFontHighlightSmall",C.muted)
    txt(f,"V 1.4.0",740,-29,105,22,"GameFontHighlightSmall",C.muted,"RIGHT")
    button(f,"X",890,-22,28,28,function() f:Hide() end,"danger")

    local left=panel(f,17,-95,270,485,C.cardDeep,{0.22,0.28,0.39})
    local right=panel(f,298,-95,624,485,C.card,{0.30,0.35,0.43})
    strip(left,1,-1,268,3,C.gold,0.85)
    strip(right,1,-1,622,3,C.gold,0.75)
    txt(left,"01  CHOOSE YOUR GAME",16,-12,244,25,"GameFontNormal",C.gold)
    self.coin=button(left,"COIN TOSS",14,-45,242,65,function() UI.mode="COIN";UI:Refresh() end)
    txt(self.coin,"HEADS  vs  TAILS",10,-38,218,17,"GameFontHighlightSmall",C.muted,"CENTER")
    self.death=button(left,"DEATHROLL",14,-118,242,65,function() UI.mode="DEATH";UI:Refresh() end)
    txt(self.death,"THE DICE KEEP SHRINKING",10,-38,218,17,"GameFontHighlightSmall",C.muted,"CENTER")
    txt(left,"02  PLAY MODE",16,-196,238,23,"GameFontNormal",C.gold)
    self.solo=button(left,"SOLO",14,-223,117,35,function() UI.playMode="SOLO";UI:Refresh() end)
    self.pvp=button(left,"2 PLAYERS",139,-223,117,35,function() UI.playMode="PVP";UI:Refresh() end)
    self.bestTitle=txt(left,"03  MATCH LENGTH",16,-273,239,23,"GameFontNormal",C.gold)
    self.bestBtns={}
    for i,n in ipairs({1,3,5}) do
        self.bestBtns[n]=button(left,"BO"..n,14+(i-1)*83,-301,76,34,function() UI.best=n;UI:Refresh() end)
    end
    self.playerTitle=txt(left,"04  OPPONENT CHARACTER",16,-348,240,22,"GameFontNormal",C.gold)
    self.playerEdit=entry(left,14,-376,175,36,70)
    self.targetBtn=button(left,"TARGET",195,-376,61,36,function()
        if UnitExists and UnitExists("target") then
            UI.playerEdit:SetText((GetUnitName and GetUnitName("target",true)) or UnitName("target") or "")
        else A:Update("Target another player first.") end
    end,"blue")
    self.start=button(left,"START SOLO GAME",14,-429,242,43,function()
        if UI.playMode=="SOLO" then A:StartSolo(UI.mode,UI.best)
        else A:Challenge(UI.playerEdit:GetText(),UI.mode,UI.best) end
    end,"primary")

    txt(right,"GAME TABLE",19,-13,225,22,"GameFontNormal",C.gold)
    self.badge=txt(right,"SOLO PRACTICE",374,-13,223,22,"GameFontHighlightSmall",C.green,"RIGHT")
    self.headline=txt(right,"COIN TOSS",20,-41,385,32,"GameFontNormalLarge",C.white)
    self.subline=txt(right,"",20,-72,565,19,"GameFontHighlightSmall",C.muted)
    local hero=panel(right,17,-105,590,217,C.cardDeep,{0.25,0.30,0.40})
    strip(hero,1,-1,588,2,C.goldDim,0.47)
    self.coinArt=picture(hero,16,-19,"Interface\\Icons\\INV_Misc_Coin_02")
    self.dice=picture(hero,16,-19,"Interface\\Icons\\INV_Misc_Dice_01")
    self.symbolHelp=txt(hero,"CLICK TO ROLL",15,-170,147,25,"GameFontHighlightSmall",C.muted,"CENTER")
    self.turnFlag=txt(hero,"",181,-17,383,23,"GameFontNormal",C.gold)
    self.symbol=txt(hero,"",181,-46,372,46,"GameFontNormalLarge",C.white)
    strip(hero,181,-102,381,2,C.goldDim,0.34)
    self.own=txt(hero,"",181,-114,385,48,"GameFontHighlight",C.white)
    self.theirs=txt(hero,"",181,-162,389,43,"GameFontHighlightSmall",C.muted)
    self.main=button(right,"ACTION",17,-333,386,51,function() end,"primary")
    self.secondary=button(right,"CANCEL",414,-333,193,51,function() end,"danger")
    local log=panel(right,17,-398,590,75,C.cardDeep,{0.21,0.26,0.34})
    strip(log,1,-1,588,2,C.blue,0.54)
    txt(log,"MATCH HISTORY",12,-8,210,19,"GameFontNormal",C.blue)
    self.results=txt(log,"",14,-26,564,45,"GameFontHighlightSmall",C.muted)
    local board=panel(right,17,-482,590,94,C.cardDeep,{0.30,0.35,0.43})
    strip(board,1,-1,588,2,C.gold,0.85)
    txt(board,"CAREER SCOREBOARD   •   SAVED PER CHARACTER",12,-5,565,22,"GameFontNormal",C.gold)
    self.pvpStats=txt(board,"",13,-27,562,26,"GameFontHighlight",C.white)
    self.soloStats=txt(board,"",13,-57,562,26,"GameFontHighlight",C.muted)

    strip(f,20,-590,900,2,C.goldDim,0.33)
    self.notice=txt(f,"",24,-598,740,43,"GameFontHighlightSmall",C.green)
    self.endBtn=button(f,"LEAVE TABLE",781,-604,139,32,function() A:Decline() end,"danger")
    -- Blocking age self-confirmation overlay. Not stored between login sessions.
    local gate=CreateFrame("Frame","ForeverCasinoAgeGate",f,"BackdropTemplate")
    gate:SetAllPoints(f)
    gate:SetFrameLevel(f:GetFrameLevel()+30)
    gate:EnableMouse(true)
    skin(gate,{0.012,0.019,0.032},C.goldDim,0.99)
    self.ageGate=gate
    local modal=panel(gate,190,-155,560,337,C.cardDeep,C.gold)
    strip(modal,1,-1,558,5,C.gold,0.9)
    txt(modal,"FOREVER CASINO",27,-27,504,40,"GameFontNormalLarge",C.gold,"CENTER")
    txt(modal,"18+ CONFIRMATION",27,-71,504,31,"GameFontNormalLarge",C.white,"CENTER")
    txt(modal,"Play Coin Toss and Deathroll against a friend or in Solo Practice. Please confirm your age before accessing the games.",37,-118,486,75,"GameFontHighlight",C.muted,"CENTER")
    local check=CreateFrame("CheckButton",nil,modal,"UICheckButtonTemplate")
    check:SetPoint("TOPLEFT",modal,"TOPLEFT",48,-205)
    check:SetSize(30,30)
    check:SetChecked(false)
    self.ageCheck=check
    txt(modal,"I confirm I am 18 years or older",88,-207,412,33,"GameFontNormal",C.white)
    self.ageProceed=button(modal,"CONFIRM & ENTER",34,-274,304,43,function()
        if UI.ageCheck:GetChecked() then A:ConfirmAge() end
    end,"primary")
    self.ageProceed:SetEnabled(false)
    check:SetScript("OnClick",function() UI.ageProceed:SetEnabled(check:GetChecked()==true) end)
    button(modal,"EXIT",350,-274,175,43,function() UI:AgeDecline() end,"danger")

    self.built=true
    self:BuildMinimap()
    self:Refresh()
    self:UpdateAgeGate()
    f:Hide()
end
