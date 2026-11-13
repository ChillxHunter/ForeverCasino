-- Forever Casino 1.4.0 -- WoW Forever (Interface 16001)
-- Purely recreational Coin Toss and Deathroll games.
-- Results use a private client-side pseudorandom generator. Not server-verified.
local addonName, ns = ...
local A = CreateFrame("Frame")
ns.Core = A
A.version = "1.4.0"
A.prefix = "FCasino4"
A.session = nil
A.status = "Choose a game and challenge a player who has this addon."
A.myName = nil
A.nextRollAt = 0
-- Self-attested age confirmation is required once per login session.
-- This cannot verify someone's identity or actual age.
A.ageConfirmed = false

local floor, tonumber, tostring, tconcat = math.floor, tonumber, tostring, table.concat
local function trim(s) return (tostring(s or ""):match("^%s*(.-)%s*$")) end
local function nameKey(s)
    return trim(s):lower():gsub("%s+", " ")
end
local function shortKey(s)
    return nameKey(s):match("^([^-]+)") or nameKey(s)
end
local function samePlayer(a,b)
    if nameKey(a) == nameKey(b) then return true end
    -- The game sometimes displays rolls with the short name rather than Name-Realm.
    return shortKey(a) == shortKey(b)
end
local function parseParts(message)
    local parts = {}
    for v in (message .. "|"):gmatch("(.-)|") do
        parts[#parts+1] = v
        if #parts > 10 then return {} end
    end
    return parts
end
local function getSelfName()
    local n, realm
    if UnitFullName then n, realm = UnitFullName("player") end
    if not n or n == "" then n = UnitName("player") end
    if realm and realm ~= "" then return n .. "-" .. realm end
    return n or ""
end
-- Own Park-Miller PRNG avoids changing other addons' global math.random sequence.
-- This is for casual gameplay, not a cryptographically secure or server-audited roll.
function A:InitRandom()
    local seed = ((time and time() or 1) % 2147483646) + 1
    local clock = (GetTime and GetTime() or 0)
    seed = (seed + math.floor(clock * 1000000)) % 2147483646 + 1
    local salt = (UnitGUID and UnitGUID("player")) or getSelfName() or "casino"
    for i = 1, #salt do
        seed = (seed * 33 + salt:byte(i)) % 2147483646 + 1
    end
    self.rngSeed = seed
end
function A:LocalRandom(upper)
    upper = math.floor(tonumber(upper) or 0)
    if upper < 1 or upper > 1000 then return nil end
    if not self.rngSeed then self:InitRandom() end
    self.rngSeed = (self.rngSeed * 48271) % 2147483647
    return math.floor(((self.rngSeed - 1) / 2147483646) * upper) + 1
end

-- Personal, per-character SavedVariables. Completed matches count once.
function A:GetStats()
    if type(ForeverCasinoDB) ~= "table" then ForeverCasinoDB = {} end
    local db=ForeverCasinoDB
    if type(db.records) ~= "table" then db.records={} end
    local key=self.myName or getSelfName()
    if key=="" then key="player" end
    if type(db.records[key])~="table" then db.records[key]={} end
    local record=db.records[key]
    for _,mode in ipairs({"pvp","solo"}) do
        if type(record[mode])~="table" then record[mode]={} end
        for _,kind in ipairs({"wins","draws","losses"}) do
            if type(record[mode][kind])~="number" then record[mode][kind]=0 end
        end
    end
    return record
end
function A:RecordResult(s,winner)
    if s.resultRecorded then return end
    s.resultRecorded=true
    local stats=self:GetStats()
    local which=s.solo and stats.solo or stats.pvp
    if winner=="draw" then
        which.draws=which.draws+1
    elseif s.solo then
        -- Solo uses Side A as the reference; Side B winning is a Side A loss.
        if winner=="host" then which.wins=which.wins+1 else which.losses=which.losses+1 end
    else
        if winner==self:LocalRole() then which.wins=which.wins+1 else which.losses=which.losses+1 end
    end
end

function A:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffc566Forever Casino:|r " .. tostring(msg))
    end
end
function A:Update(message)
    if message then self.status = message end
    if ns.UI and ns.UI.Refresh then ns.UI:Refresh() end
end
function A:Open()
    if ns.UI and ns.UI.Show then ns.UI:Show(true) end
end
function A:ConfirmAge()
    -- Only call from the visible checkbox's explicit confirmation button.
    self.ageConfirmed = true
    self:Update("Age confirmation accepted. Select Solo Practice or challenge another player.")
    if ns.UI and ns.UI.UpdateAgeGate then ns.UI:UpdateAgeGate() end
end
function A:RequireAge()
    if self.ageConfirmed then return true end
    self:Open()
    self:Update("You must explicitly confirm that you are 18 or older to use this addon.")
    return false
end
function A:Transmit(target, data)
    if not target or target == "" then self:Update("No player selected."); return false end
    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
        self:Update("Addon messages are not available on this client.")
        return false
    end
    if #data > 255 then return false end
    local ok, result = pcall(C_ChatInfo.SendAddonMessage, self.prefix, data, "WHISPER", target)
    if not ok or result == false or (type(result) == "number" and result ~= 0) then
        self:Update("Unable to send addon whisper. Try again outside instances; both players need the addon.")
        return false
    end
    return true
end
function A:Send(action, rest)
    local s = self.session
    if not s then return false end
    return self:Transmit(s.other, action .. "|" .. s.id .. (rest and ("|" .. rest) or ""))
end
function A:Challenge(opponent, kind, best)
    if not self:RequireAge() then return false end
    if self.session and self.session.stage ~= "done" then
        self:Update("Finish or cancel your current game first.")
        return false
    end
    opponent = trim(opponent)
    if opponent == "" or #opponent > 70 or opponent:find("|",1,true) or opponent:find("/",1,true) then
        self:Update("Enter a valid character name, or use Target.")
        return false
    end
    if samePlayer(opponent, self.myName or getSelfName()) then
        self:Update("Choose another player.")
        return false
    end
    if kind ~= "COIN" and kind ~= "DEATH" then return false end
    best = tonumber(best)
    if kind == "COIN" and best ~= 1 and best ~= 3 and best ~= 5 then return false end
    if kind == "DEATH" then best = 1 end
    local id = tostring(time()) .. tostring(floor(GetTime()*1000) % 1000000)
    local s = {
        id=id, other=opponent, host=true, kind=kind, best=best,
        stage="invite", localReady=false, remoteReady=false, history={},
        scoreHost=0, scoreGuest=0
    }
    self.session = s
    if not self:Send("CHAL", kind .. "|" .. best) then self.session = nil; return false end
    self:Update("Challenge sent to " .. opponent .. ". Both players need Forever Casino installed.")
    return true
end
function A:Accept()
    if not self:RequireAge() then return end
    local s=self.session
    if not s or s.stage ~= "incoming" then return end
    if not self:Send("ACCEPT") then return end
    s.stage="ready"
    self:Update("Challenge accepted. Both players must click Ready to begin.")
end
function A:Decline()
    local s=self.session
    if not s then return end
    if s.solo then
        self.session=nil
        self:Update("Solo practice closed.")
        return
    end
    self:Send(s.stage == "incoming" and "DECLINE" or "END")
    self.session=nil
    self:Update("Challenge closed.")
end
function A:Ready()
    if not self:RequireAge() then return end
    local s=self.session
    if not s or s.stage ~= "ready" then return end
    if s.localReady then self:Update("You are already ready."); return end
    if not self:Send("READY") then return end
    s.localReady=true
    self:Update("You are ready. Waiting for the other player.")
    self:MaybeBegin()
end
function A:Unready()
    local s=self.session
    if not s or s.stage ~= "ready" then return end
    if not self:Send("UNREADY") then return end
    s.localReady=false
    self:Update("You are no longer ready.")
end
function A:MaybeBegin()
    local s=self.session
    if not s or s.stage ~= "ready" or not s.host then return end
    if not (s.localReady and s.remoteReady) then return end
    if not self:Send("START") then return end
    self:StartGame()
end
function A:StartSolo(kind,best)
    if not self:RequireAge() then return false end
    if self.session and self.session.stage ~= "done" then
        self:Update("Finish or cancel your current game first.")
        return false
    end
    if kind ~= "COIN" and kind ~= "DEATH" then return false end
    best=tonumber(best)
    if kind == "COIN" and best ~= 1 and best ~= 3 and best ~= 5 then return false end
    if kind == "DEATH" then best = 1 end
    self.session={id="solo", other="Solo Practice", host=true, solo=true,
        kind=kind, best=best, stage="play",
        localReady=true, remoteReady=true, seq=1, limit=1000, turn="host",
        scoreHost=0, scoreGuest=0, history={}}
    if kind=="COIN" then
        self:Update("Solo Coin Toss: you play both HEADS and TAILS. Flip to see who wins.")
    else
        self:Update("Solo Deathroll: control Side A and Side B alternately. First side to roll 1 loses.")
    end
    return true
end
function A:StartGame()
    local s=self.session
    if not s or s.stage ~= "ready" then return end
    if not (s.localReady and s.remoteReady) then return end
    s.stage="play"
    s.limit=1000
    s.seq=1
    s.turn="host"
    s.scoreHost=0
    s.scoreGuest=0
    s.history={}
    s.winner=nil
    if s.kind == "COIN" then
        self:Update("Both players are ready. Host flips the coin: heads = host, tails = guest.")
    else
        self:Update("Both players are ready. The challenger rolls d1000 first. Take turns until someone rolls 1.")
    end
end
function A:LocalRole()
    local s=self.session
    return (s and s.host) and "host" or "guest"
end
function A:CanRoll()
    local s=self.session
    if not s or s.stage ~= "play" or not self.ageConfirmed or s.drawIncoming or s.drawOutgoing then return false end
    if s.solo then return true end
    if s.kind == "COIN" then return s.host end
    return s.turn == self:LocalRole()
end
function A:Roll()
    if not self:RequireAge() then return end
    local s=self.session
    if not self:CanRoll() then self:Update("It's not your turn, or a draw offer is pending."); return end
    local now=GetTime and GetTime() or 0
    if now < (self.nextRollAt or 0) then return end
    self.nextRollAt=now+0.18
    local upper=(s.kind=="COIN") and 2 or s.limit
    local result=self:LocalRandom(upper)
    if not result then self:Update("Invalid die size."); return end
    -- Peer clients receive the result via the normal, versioned addon whisper.
    -- This is not validated by the game server and can be spoofed by modified clients.
    if not s.solo then
        local sent
        if s.kind=="COIN" then
            sent=self:Send("FLIP",tostring(s.seq).."|"..tostring(result))
        else
            sent=self:Send("ROLL",tostring(s.seq).."|"..tostring(upper).."|"..tostring(result))
        end
        if not sent then return end
    end
    if s.kind=="COIN" then
        self:ApplyFlip(result)
    else
        self:ApplyDeathroll(s.solo and s.turn or self:LocalRole(),result)
    end
end
function A:OfferDraw()
    local s=self.session
    if not self.ageConfirmed or not s or s.solo or s.stage~="play" or s.drawOutgoing or s.drawIncoming then return end
    if not self:Send("DRAW_OFFER") then return end
    s.drawOutgoing=true
    self:Update("Draw offered to "..s.other..". Waiting for their response.")
end
function A:AnswerDraw(accept)
    local s=self.session
    if not s or s.solo or s.stage~="play" or not s.drawIncoming then return end
    if accept then
        if not self:Send("DRAW_YES") then return end
        s.drawIncoming=false
        self:Finish("draw")
    else
        if not self:Send("DRAW_NO") then return end
        s.drawIncoming=false
        self:Update("You declined the draw. Continue the game.")
    end
end
function A:ApplyFlip(result)
    local s=self.session
    if not s or s.kind ~= "COIN" or s.stage ~= "play" or (result ~= 1 and result ~= 2) then return end
    local isHeads=(result==1)
    if isHeads then s.scoreHost=s.scoreHost+1 else s.scoreGuest=s.scoreGuest+1 end
    local line="Flip "..s.seq..": "..(isHeads and (s.solo and "HEADS (Side A)" or "HEADS (challenger)")
        or (s.solo and "TAILS (Side B)" or "TAILS (opponent)"))
    s.history[#s.history+1]=line
    s.seq=s.seq+1
    local needed=floor(s.best/2)+1
    if s.scoreHost>=needed or s.scoreGuest>=needed then
        self:Finish(s.scoreHost>=needed and "host" or "guest")
    else
        self:Update(line .. ". Next flip ready.")
    end
end
function A:ApplyDeathroll(actor,result)
    local s=self.session
    if not s or s.kind ~= "DEATH" or s.stage ~= "play" then return end
    if actor~=s.turn or result < 1 or result > s.limit then return end
    local who
    if s.solo then
        who=actor=="host" and "Side A (you)" or "Side B (you)"
    else
        who=(actor=="host") and (s.host and (self.myName or "You") or s.other)
            or (s.host and s.other or (self.myName or "You"))
    end
    local line=who.." rolled "..result.." / "..s.limit
    s.history[#s.history+1]=line
    s.seq=s.seq+1
    if result==1 then
        -- The player rolling 1 LOSES.
        self:Finish(actor=="host" and "guest" or "host")
    else
        s.limit=result
        s.turn=(actor=="host") and "guest" or "host"
        self:Update(line .. ". Next player rolls d" .. result .. ".")
    end
end
function A:Finish(winner)
    local s=self.session
    if not s or s.stage~="play" or (winner~="host" and winner~="guest" and winner~="draw") then return end
    s.winner=winner
    s.stage="done"
    self:RecordResult(s,winner)
    if winner=="draw" then
        self:Update("Match ended in a draw. Scoreboard updated.")
    elseif s.solo then
        local side=winner=="host" and "Side A" or "Side B"
        self:Update(side.." won this solo practice game! Scoreboard updated.")
    else
        self:Update(winner==self:LocalRole() and "You won! Scoreboard updated." or "You lost. Scoreboard updated.")
    end
end
function A:HandleIncoming(msg,channel,sender)
    if channel~="WHISPER" or type(msg)~="string" or type(sender)~="string" then return end
    local p=parseParts(msg)
    local action,id=p[1],p[2]
    if not id or not id:match("^%d+$") or #id>30 then return end
    if action=="CHAL" then
        local kind, best = p[3], tonumber(p[4])
        if kind~="COIN" and kind~="DEATH" then return end
        if kind=="COIN" and (best~=1 and best~=3 and best~=5) then return end
        if kind=="DEATH" and best~=1 then return end
        if samePlayer(sender,self.myName or getSelfName()) then return end
        if self.session and self.session.stage~="done" then
            self:Transmit(sender,"BUSY|"..id)
            return
        end
        self.session={id=id,other=sender,host=false,kind=kind,best=best,stage="incoming",
            localReady=false,remoteReady=false,
            history={},scoreHost=0,scoreGuest=0}
        self:Open()
        self:Update("Incoming "..(kind=="COIN" and "Coin Toss" or "Deathroll").." challenge from "..sender..". Accept or decline.")
        return
    end
    local s=self.session
    if not s or s.id~=id or not samePlayer(sender,s.other) then return end
    if action=="BUSY" and s.stage=="invite" then
        self.session=nil; self:Update(sender.." is already in another game.")
    elseif action=="DECLINE" and s.stage=="invite" then
        self.session=nil; self:Update(sender.." declined your challenge.")
    elseif action=="ACCEPT" and s.host and s.stage=="invite" then
        s.stage="ready"
        self:Update(sender.." accepted. Both players must click Ready to begin.")
    elseif action=="READY" and s.stage=="ready" then
        s.remoteReady=true
        self:Update(sender.." is ready.")
        self:MaybeBegin()
    elseif action=="UNREADY" and s.stage=="ready" then
        s.remoteReady=false
        self:Update(sender.." is no longer ready.")
    elseif action=="START" and not s.host and s.stage=="ready" then
        if s.localReady and s.remoteReady then
            self:StartGame()
        else
            self:Update("Start rejected: both players must click Ready first.")
        end
    elseif action=="FLIP" and not s.host and s.kind=="COIN" and s.stage=="play" then
        local seq=tonumber(p[3]); local result=tonumber(p[4])
        if seq==s.seq and (result==1 or result==2) then self:ApplyFlip(result) end
    elseif action=="ROLL" and s.kind=="DEATH" and s.stage=="play" then
        local seq,upper,value=tonumber(p[3]),tonumber(p[4]),tonumber(p[5])
        local remoteRole=s.host and "guest" or "host"
        if s.turn==remoteRole and seq==s.seq and upper==s.limit and value and floor(value)==value and value>=1 and value<=upper then
            self:ApplyDeathroll(remoteRole,value)
        end
    elseif action=="DRAW_OFFER" and s.stage=="play" and not s.solo then
        if s.drawOutgoing then
            -- Simultaneous offers mean both players consent to a draw.
            if self:Send("DRAW_YES") then self:Finish("draw") end
        else
            s.drawIncoming=true
            self:Update(sender.." offered a draw. Accept or decline.")
        end
    elseif action=="DRAW_YES" and s.stage=="play" and s.drawOutgoing then
        s.drawOutgoing=false
        self:Finish("draw")
    elseif action=="DRAW_NO" and s.stage=="play" and s.drawOutgoing then
        s.drawOutgoing=false
        self:Update(sender.." declined the draw. Continue playing.")
    elseif action=="END" then
        s.stage="done"
        s.history[#s.history+1]="Other player closed the game."
        self:Update(sender.." left the table.")
    end
end
function A:OnEvent(event, ...)
    if event=="PLAYER_LOGIN" then
        self.ageConfirmed=false
        self.myName=getSelfName()
        self:InitRandom()
        self:GetStats()
        if not ForeverCasinoDB then ForeverCasinoDB={} end
        if ForeverCasinoDB.minimapAngle==nil then ForeverCasinoDB.minimapAngle=225 end
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            C_ChatInfo.RegisterAddonMessagePrefix(self.prefix)
        end
        if ns.UI and ns.UI.Build then ns.UI:Build() end
        self:Update()
    elseif event=="CHAT_MSG_ADDON" then
        local prefix,msg,channel,sender=...
        if prefix==self.prefix then self:HandleIncoming(msg,channel,sender) end
    end
end
A:SetScript("OnEvent", function(_, event, ...) A:OnEvent(event, ...) end)
A:RegisterEvent("PLAYER_LOGIN")
A:RegisterEvent("CHAT_MSG_ADDON")
SLASH_FOREVERCASINO1="/casino"
SLASH_FOREVERCASINO2="/fcasino"
SlashCmdList.FOREVERCASINO=function(message)
    if trim(message):lower()=="icon" then
        if not ForeverCasinoDB then ForeverCasinoDB={} end
        ForeverCasinoDB.hideMinimap=not ForeverCasinoDB.hideMinimap
        if ns.UI and ns.UI.UpdateMinimap then ns.UI:UpdateMinimap() end
        A:Print(ForeverCasinoDB.hideMinimap and "Minimap button hidden." or "Minimap button shown.")
    else A:Open() end
end
