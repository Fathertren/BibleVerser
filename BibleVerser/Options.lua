local ADDON_NAME, ns = ...

-- Canvas-based Settings panel compatible with Dragonflight+
local panel = CreateFrame("Frame", "BibleVerserOptionsPanel")
panel:Hide()

panel.name = "BibleVerser"

panel:SetScript("OnShow", function(self)
  if self._initialized then return end
  self._initialized = true

  -- Title
  local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("BibleVerser Options")

  -- Emote checkbox
  local emote = CreateFrame("CheckButton", "$parentEmote", self, "UICheckButtonTemplate")
  emote:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
  emote.Text:SetText("Show Emote when verse displays")
  emote:SetChecked(BibleVerserDB and BibleVerserDB.emote)
  emote:SetScript("OnClick", function(cb)
    if BibleVerserDB then
      BibleVerserDB.emote = cb:GetChecked()
    end
  end)

  -- Lock frame checkbox
  local lock = CreateFrame("CheckButton", "$parentLock", self, "UICheckButtonTemplate")
  lock:SetPoint("TOPLEFT", emote, "BOTTOMLEFT", 0, -10)
  lock.Text:SetText("Lock frame position (disable dragging)")
  lock:SetChecked(BibleVerserDB and BibleVerserDB.locked)
  lock:SetScript("OnClick", function(cb)
    if BibleVerserDB then
      BibleVerserDB.locked = cb:GetChecked()
    end
  end)

  -- Show on Login checkbox
  local showLogin = CreateFrame("CheckButton", "$parentShowLogin", self, "UICheckButtonTemplate")
  showLogin:SetPoint("TOPLEFT", lock, "BOTTOMLEFT", 0, -10)
  showLogin.Text:SetText("Show on Login")
  showLogin:SetChecked(BibleVerserDB and BibleVerserDB.showOn and BibleVerserDB.showOn.login)
  showLogin:SetScript("OnClick", function(cb)
    if BibleVerserDB and BibleVerserDB.showOn then
      BibleVerserDB.showOn.login = cb:GetChecked()
    end
  end)

  -- Show on Mount checkbox
  local showMount = CreateFrame("CheckButton", "$parentShowMount", self, "UICheckButtonTemplate")
  showMount:SetPoint("TOPLEFT", showLogin, "BOTTOMLEFT", 0, -6)
  showMount.Text:SetText("Show on Mount")
  showMount:SetChecked(BibleVerserDB and BibleVerserDB.showOn and BibleVerserDB.showOn.mount)
  showMount:SetScript("OnClick", function(cb)
    if BibleVerserDB and BibleVerserDB.showOn then
      BibleVerserDB.showOn.mount = cb:GetChecked()
    end
  end)

  -- Show on Zone Change checkbox
  local showZone = CreateFrame("CheckButton", "$parentShowZone", self, "UICheckButtonTemplate")
  showZone:SetPoint("TOPLEFT", showMount, "BOTTOMLEFT", 0, -6)
  showZone.Text:SetText("Show on Zone Change")
  showZone:SetChecked(BibleVerserDB and BibleVerserDB.showOn and BibleVerserDB.showOn.zone)
  showZone:SetScript("OnClick", function(cb)
    if BibleVerserDB and BibleVerserDB.showOn then
      BibleVerserDB.showOn.zone = cb:GetChecked()
    end
  end)

  -- Allow in Instances checkbox
  local allowInstance = CreateFrame("CheckButton", "$parentAllowInstance", self, "UICheckButtonTemplate")
  allowInstance:SetPoint("TOPLEFT", showZone, "BOTTOMLEFT", 0, -6)
  allowInstance.Text:SetText("Allow in Instances")
  allowInstance:SetChecked(BibleVerserDB and BibleVerserDB.allowInInstance)
  allowInstance:SetScript("OnClick", function(cb)
    if BibleVerserDB then
      BibleVerserDB.allowInInstance = cb:GetChecked()
    end
  end)

  -- Min Cooldown slider
  local slider = CreateFrame("Slider", "$parentCooldown", self, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", allowInstance, "BOTTOMLEFT", 0, -24)
  slider:SetWidth(240)
  slider:SetMinMaxValues(5, 120)
  slider:SetValueStep(5)
  slider:SetObeyStepOnDrag(true)
  _G[slider:GetName().."Low"]:SetText("5s")
  _G[slider:GetName().."High"]:SetText("120s")
  _G[slider:GetName().."Text"]:SetText("Minimum cooldown between verses")
  slider:SetValue((BibleVerserDB and BibleVerserDB.minCooldown) or 30)
  slider:SetScript("OnValueChanged", function(self, val)
    val = math.floor(val + 0.5)
    if BibleVerserDB then
      BibleVerserDB.minCooldown = val
    end
  end)

  -- Say mode dropdown (none/say/yell)
  local drop = CreateFrame("Frame", "$parentSayMode", self, "UIDropDownMenuTemplate")
  drop:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", -16, -18)

  local options = { {text="none", value="none"}, {text="say", value="say"}, {text="yell", value="yell"} }
  local function OnSelect(_, value)
    if BibleVerserDB then
      BibleVerserDB.sayMode = value
      UIDropDownMenu_SetSelectedValue(drop, value)
    end
  end

  UIDropDownMenu_Initialize(drop, function(frame, level, menuList)
    local current = (BibleVerserDB and BibleVerserDB.sayMode) or "none"
    for _, opt in ipairs(options) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = opt.text
      info.value = opt.value
      info.func = OnSelect
      info.checked = (opt.value == current)
      UIDropDownMenu_AddButton(info)
    end
  end)
  UIDropDownMenu_SetWidth(drop, 120)
  UIDropDownMenu_SetSelectedValue(drop, (BibleVerserDB and BibleVerserDB.sayMode) or "none")
  UIDropDownMenu_SetText(drop, "Chat output")

  -- Hint text
  local hint = self:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  hint:SetPoint("TOPLEFT", drop, "BOTTOMLEFT", 16, -12)
  hint:SetText("Use /bv test   or   /bv play <index>")

end)

-- Register as a canvas layout category in the new Settings UI
local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)

-- Slash command to open options
SLASH_BIBLEVERSEROPT1 = "/bvopt"
SlashCmdList.BIBLEVERSEROPT = function()
  Settings.OpenToCategory(category:GetID())
end
