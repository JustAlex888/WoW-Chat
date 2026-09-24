local ADDON_NAME, ns = ...

local copyFrame
local editBox
local scrollFrame
local cleanCheck
local controlsFrame
local measureString

local copyButtons = {}
local currentChatFrame
local cleanMode = false
local pendingReveal = false

local function Clamp01(value)
    value = tonumber(value) or 1

    if value < 0 then
        return 0
    elseif value > 1 then
        return 1
    end

    return value
end

local function ColorCode(r, g, b)
    local rr = math.floor(Clamp01(r) * 255 + 0.5)
    local gg = math.floor(Clamp01(g) * 255 + 0.5)
    local bb = math.floor(Clamp01(b) * 255 + 0.5)

    return string.format("|cff%02x%02x%02x", rr, gg, bb)
end

local function CleanText(text)
    text = text:gsub("|T.-|t", "")
    text = text:gsub("|H.-|h(.-)|h", "%1")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")

    return text
end

local function ColorizeEntry(entry)
    local text = entry.text or ""
    local base = ColorCode(entry.r, entry.g, entry.b)

    -- WoW color codes are not a stack. Re-apply the original ChatFrame line
    -- color after inner resets so whispers/system/channel colors remain intact.
    text = text:gsub("|r", "|r" .. base)

    return base .. text .. "|r"
end

local function BuildCopyText(frame)
    local entries = ns.History_GetEntries(frame)
    local output = {}

    for i = 1, #entries do
        if cleanMode then
            output[#output + 1] = CleanText(entries[i].text or "")
        else
            output[#output + 1] = ColorizeEntry(entries[i])
        end
    end

    return table.concat(output, "\n")
end

local function GetMaxVerticalScroll()
    if not scrollFrame then
        return 0
    end

    if scrollFrame.GetVerticalScrollRange then
        return math.max(0, scrollFrame:GetVerticalScrollRange() or 0)
    end

    if not editBox then
        return 0
    end

    return math.max(0, (editBox:GetHeight() or 0) - (scrollFrame:GetHeight() or 0))
end

local function UpdateEditBoxHitRect()
    if not editBox or not scrollFrame or not editBox.SetHitRectInsets then
        return
    end

    local childHeight = editBox:GetHeight() or 0
    local viewportHeight = scrollFrame:GetHeight() or 0
    local scroll = scrollFrame:GetVerticalScroll() or 0

    local topInset = math.max(0, math.min(scroll, childHeight))
    local bottomInset = math.max(0, childHeight - topInset - viewportHeight)

    editBox:SetHitRectInsets(0, 0, topInset, bottomInset)
end

local function RestoreScrollPosition(position)
    if not scrollFrame then
        return
    end

    scrollFrame:UpdateScrollChildRect()
    scrollFrame:SetVerticalScroll(math.min(math.max(position or 0, 0), GetMaxVerticalScroll()))
    UpdateEditBoxHitRect()
end

local function MeasureTextHeight(text)
    if not measureString or not editBox or not scrollFrame then
        return scrollFrame and scrollFrame:GetHeight() or 400
    end

    -- These match editBox:SetTextInsets(4, 4, 4, 4) below. Keeping the
    -- values explicit avoids relying on newer convenience getters.
    local left, right, top, bottom = 4, 4, 4, 4

    measureString:SetWidth(math.max(1, (editBox:GetWidth() or 640) - left - right))
    measureString:SetText((text and text ~= "") and text or " ")

    local measured = measureString:GetStringHeight() or 0
    local minimum = scrollFrame:GetHeight() or 400

    return math.max(minimum, math.ceil(measured + top + bottom + 8))
end

local function CursorInsideVisibleTextArea()
    if not scrollFrame or not GetCursorPosition then
        return false
    end

    local left = scrollFrame:GetLeft()
    local right = scrollFrame:GetRight()
    local top = scrollFrame:GetTop()
    local bottom = scrollFrame:GetBottom()

    if not left or not right or not top or not bottom then
        return false
    end

    local scale = scrollFrame:GetEffectiveScale() or 1
    if scale <= 0 then
        scale = 1
    end

    local x, y = GetCursorPosition()
    x = x / scale
    y = y / scale

    return x >= left and x <= right and y >= bottom and y <= top
end

local function HandleCursorChanged(self, x, y, w, h)
    self.cursorOffset = y
    self.cursorHeight = h

    if self.selectionDragActive then
        self.handleCursorChange = true
    end
end

local function HandleScrollingEditUpdate(self)
    if not scrollFrame then
        return
    end

    if not self.selectionDragActive then
        self.handleCursorChange = false
        return
    end

    if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
        self.selectionDragActive = false
        self.handleCursorChange = false
        return
    end

    if not self.handleCursorChange then
        return
    end

    local height = scrollFrame:GetHeight() or 0
    local range = GetMaxVerticalScroll()
    local scroll = scrollFrame:GetVerticalScroll() or 0
    local cursorOffset = -(self.cursorOffset or 0)
    local cursorHeight = self.cursorHeight or 0

    if math.floor(height) <= 0 then
        self.handleCursorChange = false
        return
    end

    while cursorOffset < scroll do
        scroll = scroll - (height / 2)

        if scroll < 0 then
            scroll = 0
        end

        scrollFrame:SetVerticalScroll(scroll)
        UpdateEditBoxHitRect()
    end

    while (cursorOffset + cursorHeight) > (scroll + height) and scroll < range do
        scroll = scroll + (height / 2)

        if scroll > range then
            scroll = range
        end

        scrollFrame:SetVerticalScroll(scroll)
        UpdateEditBoxHitRect()
    end

    self.handleCursorChange = false
end

local function UpdateEditBox(preserveScroll)
    if not currentChatFrame or not editBox then
        return
    end

    local oldScroll = preserveScroll and (scrollFrame:GetVerticalScroll() or 0) or 0
    local hadFocus = editBox:HasFocus()

    if hadFocus then
        editBox:ClearFocus()
    end

    local text = BuildCopyText(currentChatFrame)

    editBox:SetText(text)
    editBox:SetHeight(MeasureTextHeight(text))
    scrollFrame:UpdateScrollChildRect()

    if preserveScroll then
        editBox.handleCursorChange = false
        RestoreScrollPosition(oldScroll)
    else
        editBox:SetCursorPosition(0)
        editBox.handleCursorChange = false
        RestoreScrollPosition(0)
    end

    if hadFocus then
        editBox:SetFocus()
    end
end

local function ResetCleanMode()
    cleanMode = false

    if cleanCheck then
        cleanCheck:SetChecked(false)
    end
end

local function FinalizeInitialLayout()
    if not pendingReveal then
        return
    end

    pendingReveal = false

    if not copyFrame or not copyFrame:IsShown() or not editBox or not scrollFrame then
        return
    end

    -- Legion's multiline EditBox can finish wrapping long formatted text one UI
    -- frame after SetText/SetHeight. Re-measure once after that layout pass so
    -- selection highlighting and the ScrollFrame use the final geometry.
    local text = editBox:GetText() or ""

    editBox:SetHeight(MeasureTextHeight(text))
    scrollFrame:UpdateScrollChildRect()

    -- The most recent chat messages are normally the ones the player wants to
    -- inspect or copy. Start at the end of the history after the final layout
    -- pass so the copy window opens on the newest saved lines, not the oldest.
    editBox:SetCursorPosition(string.len(text))
    editBox.handleCursorChange = false
    editBox.selectionDragActive = false
    RestoreScrollPosition(GetMaxVerticalScroll())

    copyFrame:SetAlpha(1)
    copyFrame:EnableMouse(true)
    editBox:EnableMouse(true)
    editBox:SetFocus()
end

local function SelectAllText()
    if not editBox then
        return
    end

    local oldScroll = scrollFrame:GetVerticalScroll() or 0
    local text = editBox:GetText() or ""

    editBox:SetFocus()
    editBox:HighlightText(0, string.len(text))

    -- Highlighting a long multiline EditBox can move the viewport. Keep the
    -- reader at the same place and prevent the next cursor update from undoing it.
    editBox.handleCursorChange = false
    RestoreScrollPosition(oldScroll)
end

local function CreateCopyFrame()
    if copyFrame then
        return
    end

    copyFrame = CreateFrame("Frame", "WoWChatCopyFrame", UIParent)
    copyFrame:SetSize(720, 520)
    copyFrame:SetPoint("CENTER")
    copyFrame:SetFrameStrata("DIALOG")
    copyFrame:EnableMouse(true)
    copyFrame:SetMovable(true)
    copyFrame:RegisterForDrag("LeftButton")

    copyFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    copyFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    copyFrame:SetScript("OnHide", function()
        pendingReveal = false
        ResetCleanMode()
        currentChatFrame = nil
        copyFrame:SetAlpha(1)
        copyFrame:EnableMouse(true)

        if editBox then
            editBox.selectionDragActive = false
            editBox.handleCursorChange = false
            editBox:EnableMouse(true)
            editBox:ClearFocus()
        end
    end)

    copyFrame:SetScript("OnUpdate", function()
        FinalizeInitialLayout()
    end)

    copyFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {
            left = 11,
            right = 12,
            top = 12,
            bottom = 11,
        },
    })

    local title = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText(ns.L.COPY_TITLE)

    scrollFrame = CreateFrame("ScrollFrame", "WoWChatCopyScrollFrame", copyFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 24, -52)
    scrollFrame:SetPoint("BOTTOMRIGHT", -46, 72)

    editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(640)
    editBox:SetHeight(400)
    editBox:SetTextInsets(4, 4, 4, 4)
    editBox:SetJustifyH("LEFT")
    editBox:SetJustifyV("TOP")

    editBox:SetScript("OnEscapePressed", function()
        copyFrame:Hide()
    end)

    editBox:SetScript("OnMouseDown", function(self, button)
        self.handleCursorChange = false

        if button == "LeftButton" and CursorInsideVisibleTextArea() then
            self.selectionDragActive = true
        else
            self.selectionDragActive = false
        end
    end)

    editBox:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self.selectionDragActive = false
            self.handleCursorChange = false
        end
    end)

    editBox:SetScript("OnKeyDown", function(self, key)
        if IsControlKeyDown() and key == "A" then
            SelectAllText()
        end
    end)

    editBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
        HandleCursorChanged(self, x, y, w, h)
    end)

    editBox:SetScript("OnUpdate", function(self)
        HandleScrollingEditUpdate(self)
    end)

    editBox:SetScript("OnTextChanged", function()
        if scrollFrame then
            scrollFrame:UpdateScrollChildRect()
            UpdateEditBoxHitRect()
        end
    end)

    scrollFrame:SetScrollChild(editBox)

    if scrollFrame.HookScript then
        scrollFrame:HookScript("OnVerticalScroll", function()
            UpdateEditBoxHitRect()
        end)
    end

    -- A hidden FontString using the same font/width gives the actual rendered
    -- wrapped-text height. This avoids the accumulated selection offset caused by
    -- estimating height as "line count × 14" on long chat histories.
    measureString = copyFrame:CreateFontString(nil, "BACKGROUND", "ChatFontNormal")
    measureString:SetPoint("TOPLEFT", copyFrame, "TOPLEFT", -5000, 5000)
    measureString:SetWidth(632)
    measureString:SetJustifyH("LEFT")
    measureString:SetJustifyV("TOP")
    if measureString.SetWordWrap then
        measureString:SetWordWrap(true)
    end
    measureString:SetAlpha(0)

    -- Keep controls above the tall multiline EditBox's mouse hit rectangle.
    controlsFrame = CreateFrame("Frame", nil, copyFrame)
    controlsFrame:SetPoint("BOTTOMLEFT", copyFrame, "BOTTOMLEFT", 18, 14)
    controlsFrame:SetPoint("BOTTOMRIGHT", copyFrame, "BOTTOMRIGHT", -18, 14)
    controlsFrame:SetHeight(42)
    controlsFrame:SetFrameStrata("DIALOG")
    controlsFrame:SetFrameLevel((scrollFrame:GetFrameLevel() or 1) + 20)
    controlsFrame:EnableMouse(true)

    local selectAll = CreateFrame("Button", nil, controlsFrame, "UIPanelButtonTemplate")
    selectAll:SetSize(120, 24)
    selectAll:SetPoint("BOTTOMLEFT", 6, 6)
    selectAll:SetText(ns.L.SELECT_ALL)

    selectAll:SetScript("OnClick", function()
        SelectAllText()
    end)

    local close = CreateFrame("Button", nil, controlsFrame, "UIPanelButtonTemplate")
    close:SetSize(100, 24)
    close:SetPoint("BOTTOMRIGHT", -6, 6)
    close:SetText(ns.L.CLOSE)

    close:SetScript("OnClick", function()
        copyFrame:Hide()
    end)

    cleanCheck = CreateFrame("CheckButton", nil, controlsFrame, "UICheckButtonTemplate")
    cleanCheck:SetPoint("BOTTOMLEFT", selectAll, "BOTTOMRIGHT", 20, 0)
    cleanCheck:SetSize(24, 24)

    local cleanLabel = cleanCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cleanLabel:SetPoint("LEFT", cleanCheck, "RIGHT", 2, 1)
    cleanLabel:SetText(ns.L.CLEAN_TEXT)

    cleanCheck:SetScript("OnClick", function(self)
        cleanMode = self:GetChecked() and true or false
        UpdateEditBox(true)
    end)

    copyFrame:Hide()
end

local function OpenCopyWindow(frame)
    CreateCopyFrame()

    currentChatFrame = frame
    ResetCleanMode()

    -- Build and lay out the long multiline EditBox before revealing the window.
    -- A second geometry pass on the next UI frame avoids the intermittent
    -- selection-highlight drift seen on Legion 7.3.5 with long histories.
    pendingReveal = false
    copyFrame:SetAlpha(0)
    copyFrame:EnableMouse(false)
    editBox:EnableMouse(false)
    copyFrame:Show()

    UpdateEditBox(false)
    editBox.selectionDragActive = false
    editBox.handleCursorChange = false
    pendingReveal = true
end

local function CreateCopyButton(index, frame)
    if index == 2 or copyButtons[frame] then
        return
    end

    local button = CreateFrame("Button", nil, frame)
    button:SetSize(20, 20)
    button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", 0, 0)
    label:SetText(ns.L.COPY_BUTTON_LABEL)

    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    button:SetScript("OnClick", function()
        OpenCopyWindow(frame)
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(ns.L.COPY_TOOLTIP)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    copyButtons[frame] = button
end

function ns.Copy_RefreshButtons()
    local maxWindows = NUM_CHAT_WINDOWS or 10

    for index = 1, maxWindows do
        if index ~= 2 then
            local frame = _G["ChatFrame" .. index]

            if frame then
                CreateCopyButton(index, frame)

                local button = copyButtons[frame]

                if button then
                    if ns.db.settings.copyButton then
                        button:Show()
                    else
                        button:Hide()
                    end
                end
            end
        end
    end
end

function ns.Copy_Init()
    CreateCopyFrame()
    ns.Copy_RefreshButtons()
end
