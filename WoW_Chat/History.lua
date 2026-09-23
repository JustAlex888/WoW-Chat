local ADDON_NAME, ns = ...

local hookedFrames = {}
local frameKeys = {}
local watcher
local restoring = false

local MIN_LINES = 200
local MAX_LINES = 5000

local function GetFramesStore()
    if not ns.profile then
        return nil
    end

    if type(ns.profile.frames) ~= "table" then
        ns.profile.frames = {}
    end

    return ns.profile.frames
end

local function ClampLimit(value)
    value = tonumber(value) or 2000
    value = math.floor(value)

    if value < MIN_LINES then
        value = MIN_LINES
    elseif value > MAX_LINES then
        value = MAX_LINES
    end

    return value
end

local function GetWindowName(index, frame)
    local name = GetChatWindowInfo(index)

    if not name or name == "" then
        name = frame:GetName() or ("ChatFrame" .. index)
    end

    return name
end

local function BuildFrameKey(index, frame)
    return tostring(index) .. "|" .. GetWindowName(index, frame)
end

local function NewBuffer(capacity)
    return {
        capacity = capacity,
        head = 1,
        count = 0,
        lines = {},
    }
end

local function GetEntriesFromBuffer(buffer)
    local result = {}

    if not buffer
        or type(buffer.lines) ~= "table"
        or not buffer.capacity
        or buffer.capacity <= 0
        or not buffer.count
        or buffer.count <= 0
    then
        return result
    end

    local capacity = buffer.capacity
    local count = math.min(buffer.count, capacity)
    local head = buffer.head or 1
    local first = ((head - count - 1) % capacity) + 1

    for i = 0, count - 1 do
        local index = ((first + i - 1) % capacity) + 1
        local entry = buffer.lines[index]

        if entry then
            result[#result + 1] = entry
        end
    end

    return result
end

local function ResizeBuffer(buffer, newCapacity)
    local oldEntries = GetEntriesFromBuffer(buffer)
    local newBuffer = NewBuffer(newCapacity)
    local first = 1

    if #oldEntries > newCapacity then
        first = #oldEntries - newCapacity + 1
    end

    for i = first, #oldEntries do
        local entry = oldEntries[i]
        newBuffer.lines[newBuffer.head] = entry
        newBuffer.head = (newBuffer.head % newCapacity) + 1
        newBuffer.count = newBuffer.count + 1
    end

    return newBuffer
end

local function EnsureBuffer(key)
    local frames = GetFramesStore()

    if not frames then
        return nil
    end

    local capacity = ClampLimit(ns.db.settings.maxLines)
    ns.db.settings.maxLines = capacity

    local buffer = frames[key]

    if type(buffer) ~= "table" then
        buffer = NewBuffer(capacity)
        frames[key] = buffer
        return buffer
    end

    if buffer.capacity ~= capacity then
        buffer = ResizeBuffer(buffer, capacity)
        frames[key] = buffer
    end

    if type(buffer.lines) ~= "table" then
        buffer.lines = {}
    end

    buffer.head = tonumber(buffer.head) or 1
    buffer.count = tonumber(buffer.count) or 0

    return buffer
end

local function AppendLine(key, text, r, g, b)
    if restoring or ns.suppressHistoryCapture then
        return
    end

    if not ns.db.settings.enabled then
        return
    end

    if type(text) ~= "string" or text == "" then
        return
    end

    local buffer = EnsureBuffer(key)

    if not buffer then
        return
    end

    local capacity = buffer.capacity

    buffer.lines[buffer.head] = {
        text = text,
        time = time(),
        r = r,
        g = g,
        b = b,
    }

    buffer.head = (buffer.head % capacity) + 1

    if buffer.count < capacity then
        buffer.count = buffer.count + 1
    end
end

local function HookFrame(index, frame)
    if hookedFrames[frame] then
        return
    end

    -- ChatFrame2 is the Combat Log and is intentionally excluded.
    if index == 2 then
        return
    end

    hookedFrames[frame] = true

    hooksecurefunc(frame, "AddMessage", function(self, text, r, g, b)
        local key = frameKeys[self]

        if key then
            AppendLine(key, text, r, g, b)
        end
    end)
end

local function RefreshFrames()
    local maxWindows = NUM_CHAT_WINDOWS or 10

    for index = 1, maxWindows do
        if index ~= 2 then
            local frame = _G["ChatFrame" .. index]

            if frame then
                frameKeys[frame] = BuildFrameKey(index, frame)
                HookFrame(index, frame)
            end
        end
    end
end

local function RestoreFrame(frame)
    local key = frameKeys[frame]
    local frames = GetFramesStore()

    if not key or not frames then
        return
    end

    local buffer = frames[key]

    if not buffer then
        return
    end

    local entries = GetEntriesFromBuffer(buffer)

    for i = 1, #entries do
        local entry = entries[i]
        frame:AddMessage(entry.text, entry.r, entry.g, entry.b)
    end
end

local function RestoreAll()
    if not ns.db.settings.enabled then
        return
    end

    restoring = true

    local maxWindows = NUM_CHAT_WINDOWS or 10

    for index = 1, maxWindows do
        if index ~= 2 then
            local frame = _G["ChatFrame" .. index]

            if frame then
                RestoreFrame(frame)
            end
        end
    end

    restoring = false
end

function ns.History_GetFrameKey(frame)
    return frameKeys[frame]
end

function ns.History_GetEntries(frame)
    local key = frameKeys[frame]
    local frames = GetFramesStore()

    if not key or not frames then
        return {}
    end

    return GetEntriesFromBuffer(frames[key])
end

function ns.History_ClearFrame(frame)
    local key = frameKeys[frame]
    local frames = GetFramesStore()

    if key and frames then
        frames[key] = nil
    end
end

function ns.History_ClearAll()
    if ns.profile then
        ns.profile.frames = {}
    end
end

function ns.History_SetMaxLines(value)
    local newLimit = ClampLimit(value)
    ns.db.settings.maxLines = newLimit

    local frames = GetFramesStore()

    if frames then
        for key, buffer in pairs(frames) do
            frames[key] = ResizeBuffer(buffer, newLimit)
        end
    end

    return newLimit
end

function ns.History_RefreshFrames()
    RefreshFrames()
end

local function IsOwnServiceMessage(entry)
    return entry
        and type(entry.text) == "string"
        and (entry.text:find("UWoW Chat:", 1, true) ~= nil or entry.text:find("WoW Chat:", 1, true) ~= nil)
end

local function PurgeOwnServiceMessages()
    if not ns.profile or ns.profile.historySanitizedV4 then
        return
    end

    local frames = GetFramesStore()

    if frames then
        for key, buffer in pairs(frames) do
            local entries = GetEntriesFromBuffer(buffer)
            local cleaned = NewBuffer(ClampLimit(buffer.capacity or ns.db.settings.maxLines))

            for i = 1, #entries do
                local entry = entries[i]

                if not IsOwnServiceMessage(entry) then
                    cleaned.lines[cleaned.head] = entry
                    cleaned.head = (cleaned.head % cleaned.capacity) + 1

                    if cleaned.count < cleaned.capacity then
                        cleaned.count = cleaned.count + 1
                    end
                end
            end

            frames[key] = cleaned
        end
    end

    ns.profile.historySanitizedV4 = true
end

function ns.History_Init()
    if ns.historyInitialized then
        return
    end

    ns.historyInitialized = true

    PurgeOwnServiceMessages()
    RefreshFrames()
    RestoreAll()

    watcher = CreateFrame("Frame")
    watcher:RegisterEvent("UPDATE_CHAT_WINDOWS")

    watcher:SetScript("OnEvent", function()
        RefreshFrames()

        if ns.Copy_RefreshButtons then
            ns.Copy_RefreshButtons()
        end
    end)
end
