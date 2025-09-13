local ADDON_NAME, ns = ...

-- ================= Saved Vars and Defaults =================
local defaults = {
  pos = { point = "CENTER", x = 0, y = 0 },
  scale = 1.0,
  locked = false,
  emote = true,
  showOn = { mount = true, login = true, zone = false, resurrect = true },
  minCooldown = 30,
  allowInInstance = true,
  sayMode = "none",
}

BibleVerserDB = BibleVerserDB or {}
ns._lastShown = ns._lastShown or 0

local function copyDefaults(src, dst)
  if type(dst) ~= "table" then dst = {} end
  for k, v in pairs(src) do
    if type(v) == "table" then
      dst[k] = copyDefaults(v, dst[k])
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
  return dst
end

-- ================= UI Construction =================
local UI = CreateFrame("Frame", "BibleVerserFrame", UIParent, "BasicFrameTemplateWithInset")
UI:SetSize(640, 360)
UI:SetMovable(true)
UI:EnableMouse(true)
UI:RegisterForDrag("LeftButton")

local function OnDragStart(self)
  if not BibleVerserDB.locked then
    self:StartMoving()
  end
end

local function OnDragStop(self)
  self:StopMovingOrSizing()
  local p, _, _, x, y = self:GetPoint()
  BibleVerserDB.pos.point = p
  BibleVerserDB.pos.x = x
  BibleVerserDB.pos.y = y
end

UI:SetScript("OnDragStart", OnDragStart)
UI:SetScript("OnDragStop", OnDragStop)

UI:Hide()

if UI.TitleBg then UI.TitleBg:Hide() end
if UI.TopLeftCorner then UI.TopLeftCorner:Hide() end
if UI.TopRightCorner then UI.TopRightCorner:Hide() end
if UI.TopBorder then UI.TopBorder:Hide() end

UI.bg = UI:CreateTexture(nil, "BACKGROUND")
UI.bg:SetAllPoints(true)
UI.bg:SetTexture("Interface\\\\DialogFrame\\\\UI-DialogBox-Background-Dark")
UI.bg:SetVertexColor(0.15,0.15,0.18,1)

UI.model = CreateFrame("PlayerModel", nil, UI)
UI.model:SetPoint("TOPLEFT", 12, -12)
UI.model:SetSize(280, 336)
UI.model:SetUnit("player")

local right = CreateFrame("Frame", nil, UI)
right:SetPoint("TOPLEFT", UI.model, "TOPRIGHT", 12, -20)
right:SetPoint("BOTTOMRIGHT", -10, 10)

UI.refFS = right:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
UI.refFS:SetPoint("TOPLEFT", right, "TOPLEFT", 0, -4)
UI.refFS:SetJustifyH("LEFT")

UI.asvFS = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
UI.asvFS:SetPoint("TOPLEFT", UI.refFS, "BOTTOMLEFT", 0, -8)
UI.asvFS:SetWidth(300)
UI.asvFS:SetWordWrap(true)
UI.asvFS:SetJustifyH("LEFT")
UI.asvFS:SetTextColor(1, 0.9, 0.4)

UI.kjvFS = right:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
UI.kjvFS:SetPoint("TOPLEFT", UI.asvFS, "BOTTOMLEFT", 0, -8)
UI.kjvFS:SetWidth(300)
UI.kjvFS:SetWordWrap(true)
UI.kjvFS:SetJustifyH("LEFT")
UI.kjvFS:SetTextColor(0.8, 0.85, 0.9)

UI.closeBtn = CreateFrame("Button", nil, UI, "UIPanelCloseButton")
UI.closeBtn:SetPoint("TOPRIGHT", -2, -2)

local function OnMouseWheel(self, delta)
  if BibleVerserDB.locked then
    return
  end
  local s = BibleVerserDB.scale + (delta > 0 and 0.05 or -0.05)
  if s < 0.6 then s = 0.6 end
  if s > 1.6 then s = 1.6 end
  BibleVerserDB.scale = s
  UI:SetScale(s)
  setPosition()
end

UI:EnableMouseWheel(true)
UI:SetScript("OnMouseWheel", OnMouseWheel)

function setPosition()
  UI:ClearAllPoints()
  UI:SetPoint(BibleVerserDB.pos.point, UIParent, BibleVerserDB.pos.point, BibleVerserDB.pos.x, BibleVerserDB.pos.y)
  UI:SetScale(BibleVerserDB.scale or 1.0)
end

-- ================= Simple Scene Engine =================
local function resetModel()
  UI.model:ClearModel()
  UI.model:Show()
  UI.model:SetUnit("player")
end

local function showKneel()
  resetModel()
  UI.model:SetAnimation(115)
end

local function showTalk()
  resetModel()
  UI.model:SetAnimation(60)
end

local function showFlex()
  resetModel()
  UI.model:SetAnimation(82)
end

local function showWalk()
  resetModel()
  UI.model:SetAnimation(4)
end

local sceneMap = {
  [1] = showKneel,
  [2] = showTalk,
  [3] = showFlex,
  [4] = showWalk,
  [5] = showKneel,
  [6] = showTalk,
  [7] = showFlex,
  [8] = showWalk,
  [9] = showKneel,
  [10] = showTalk,
}

-- ================= Show Logic =================
local function formatVerse(entry)
  UI.refFS:SetText(entry.ref or "Verse")
  UI.asvFS:SetText("(ASV) "..(entry.asv or ""))
  UI.kjvFS:SetText("(KJV) "..(entry.kjv or ""))
end

function ns.ShowVerseByIndex(index, source)
  if InCombatLockdown() then return end
  local entry = BibleVerser_Verses and BibleVerser_Verses[index]
  if not entry then return end
  formatVerse(entry)
  local func = sceneMap[index] or showKneel
  func()
  -- Always trigger /read emote
  DoEmote("READ")
  if BibleVerserDB.emote then
    SendChatMessage("begins to pray.", "EMOTE")
  end
  UI:Show()

  if BibleVerserDB.sayMode and BibleVerserDB.sayMode ~= "none" then
    local msg = (entry.ref or "").." — "..(entry.asv ~= "" and entry.asv or entry.kjv or "")
    SendChatMessage(msg:sub(1,255), BibleVerserDB.sayMode:upper())
  end
end

function ns.ShowVerse(source)
  if InCombatLockdown() then return end
  if not BibleVerserDB.allowInInstance and IsInInstance() then return end
  if source ~= "test" then
    if (GetTime() - ns._lastShown) < (BibleVerserDB.minCooldown or 30) then return end
  end
  ns._lastShown = GetTime()
  local count = BibleVerser_Verses and #BibleVerser_Verses or 0
  if count == 0 then return end
  ns.ShowVerseByIndex(math.random(count), source)
end

-- Events
local f = CreateFrame("Frame")

local function OnAddonLoaded(event, arg1)
  if arg1 == ADDON_NAME then
    BibleVerserDB = copyDefaults(defaults, BibleVerserDB or {})
    setPosition()
  end
end

local function OnPlayerLogin()
  local function loginFunc()
    if BibleVerserDB.showOn.login then
      ns.ShowVerse("login")
    end
  end
  C_Timer.After(10, loginFunc)
end

local function OnMountChanged()
  if BibleVerserDB.showOn.mount and IsMounted() and not InCombatLockdown() then
    ns.ShowVerse("mount")
  end
end

local function OnZoneChanged()
  if BibleVerserDB.showOn.zone and not InCombatLockdown() then
    ns.ShowVerse("zone")
  end
end

local function OnResurrect()
  if BibleVerserDB.showOn.resurrect and IsInRaid() and not InCombatLockdown() then
    ns.ShowVerse("resurrect")
  end
end

local function OnCombatStart()
  UI:Hide()
end

f:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" then
    OnAddonLoaded(event, arg1)
  elseif event == "PLAYER_LOGIN" then
    OnPlayerLogin()
  elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
    OnMountChanged()
  elseif event == "ZONE_CHANGED_NEW_AREA" then
    OnZoneChanged()
  elseif event == "PLAYER_ALIVE" then
    OnResurrect()
  elseif event == "PLAYER_REGEN_DISABLED" then
    OnCombatStart()
  end
end)

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("PLAYER_ALIVE")
f:RegisterEvent("PLAYER_REGEN_DISABLED")

-- Slash Commands
SLASH_BIBLEVERSER1 = "/bv"
SlashCmdList.BIBLEVERSER = function(msg)
  msg = (msg or ""):lower()
  if msg=="test" then
    ns.ShowVerse("test")
  elseif msg:match("^play%s+%d+") then
    local idx = tonumber(msg:match("(%d+)")) or 1
    ns.ShowVerseByIndex(idx, "test")
  else
    print("BibleVerser: /bv test  |  /bv play <index>")
  end
end

ns._UI = UI
ns.defaults = defaults
