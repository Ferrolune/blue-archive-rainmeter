-- Script to catalog listed YouTube channels and provide functions for the parent skin.

-- Draws the scroll bar at the bottom of the widget
-- NOTE: Should NOT be called if only one YouTube channel is defined
local function DrawScrollUI()
    SKIN:Bang('!SetOption', 'ScrollUI', 'Shape', 'Rectangle (-8*#GScale#),(-8*#GScale#),(('.. (TOTAL_CHANNELS * 12) .. '+4)*#GScale#),(16*#GScale#),(6*#GScale#),(6*#GScale#) | StrokeWidth 0 | Fill Color #ScrollUIColor#')
    for i = 1, TOTAL_CHANNELS, 1 do
        SKIN:Bang('!SetOption', 'ScrollUI', 'Shape' .. (i + 1), 'Ellipse (' .. ((i - 1) * 12) .. '*#GScale#),0,(3.5*#GScale#) | StrokeWidth 0 | Fill Color #DeselectColor#')
    end
    SKIN:Bang('!SetOption', 'ScrollUI', 'X', '((#BubbleSize#+#Indent#)-((' .. (TOTAL_CHANNELS * 6) .. '-6)*#GScale#))')

    SKIN:Bang('!SetOption', 'ScrollHitbox', 'Shape', 'Rectangle 0,0,('.. (TOTAL_CHANNELS * 12) .. '*#GScale#),(16*#GScale#) | #Hitbox#')
    SKIN:Bang('!SetOption', 'ScrollHitbox', 'X', '((#BubbleSize#+#Indent#)-(' .. (TOTAL_CHANNELS * 6) .. '*#GScale#))')

    return 1
end

-- Highlights the appropriate node in the Scroll UI according to the displayed channel
local function SelectNode(oldindex, newindex)
    SKIN:Bang('!SetOption', 'ScrollUI', 'Shape' .. (oldindex + 1), 'Ellipse (' .. ((oldindex - 1) * 12) .. '*#GScale#),0,(3.5*#GScale#) | StrokeWidth 0 | Fill Color #DeselectColor#')
    SKIN:Bang('!SetOption', 'ScrollUI', 'Shape' .. (newindex + 1), 'Ellipse (' .. ((newindex - 1) * 12) .. '*#GScale#),0,(3.5*#GScale#) | StrokeWidth 0 | Fill Color #SelectColor#')

    return 1
end

-- Sets the next channel to be transitioned in
local function SetNextChannel(selection)
    if (selection < 0) then
        NEXT_CHANNEL = (CURRENT_CHANNEL % TOTAL_CHANNELS) + 1
    else
        NEXT_CHANNEL = selection
    end

    return 1
end

-- A checker function for an empty database for case handlers
local function IsEmpty()
    return TOTAL_CHANNELS <= 0
end

-- Renders starting information once all assets have been downloaded and verified
local function Startup()
    CURRENT_CHANNEL = 1
    SetNextChannel(-1)

    if (TOTAL_CHANNELS > 1) then
       SKIN:Bang('!EnableMeasure', 'Ticker')
       DrawScrollUI()
       SelectNode(TOTAL_CHANNELS, 1)
    end

    SKIN:Bang('!UpdateMeterGroup', 'YouTubeGroup')

    return 1
end

-- Handles grammar structure for upload time strings
local function Plural(value, time)
    if value == 1 then
        return value .. " " .. time
    end
    return value .. " " .. time .. "s"
end

-- Calculates the appropriate time estimates since video upload
local function LargestTime(pasttime)
    pasttime = pasttime / 60
    if (pasttime < 60) then
        pasttime = math.floor(pasttime)
        return Plural(pasttime, "min") .. " ago!!!"
    end
    pasttime = pasttime / 60
    if (pasttime < 24) then
        pasttime = math.floor(pasttime)
        return Plural(pasttime, "hr") .. " ago!"
    end
    pasttime = pasttime / 24
    if (pasttime < 7) then
        pasttime = math.floor(pasttime)
        return Plural(pasttime, "day") .. " ago!"
    end
    pasttime = pasttime / 7
    if (pasttime < 5) then
        pasttime = math.floor(pasttime)
        return Plural(pasttime, "wk") .. " ago."
    end
    pasttime = (pasttime * 7) / 30.5
    if (pasttime < 12) then
        pasttime = math.floor(pasttime)
        return pasttime .. " mo. ago..."
    end
    pasttime = (pasttime * 30.5) / 365
    pasttime = math.floor(pasttime)
    return Plural(pasttime, "yr") .. " ago..."
end

-- Extrapolates a Unix timestamp from a string and returns a formatted dialog string
-- CREDITS: https://stackoverflow.com/questions/4105012/convert-a-string-date-to-a-timestamp
-- NOTE: Time structure is as follows: YYYY-MM-DDTHH:MM:SS+HH:MM where [T] is a literal
local function CalculateTime(videotime)

    local pattern = "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)"
    local ryear, rmonth, rday, rhour, rmin, rsec = videotime:match(pattern)

    local unixtime = os.time({year = ryear, month = rmonth, day = rday, hour = rhour, min = rmin, sec = rsec})
    local pasttime = os.time(os.date("!*t")) - unixtime

    return LargestTime(pasttime)
end

-- Returns stringified file content located in [filepath]
local function ReadFile(filepath)
    filepath = SKIN:MakePathAbsolute(filepath)

    local file = io.open(filepath)
    if not file then
        print('Unable to open file at ' .. filepath)
        return
    end

    local contents = file:read('*all')
    file:close()

    return contents
end

-- Writes [content] to the specified [filepath]
local function WriteFile(filepath, content)
    filepath = SKIN:MakePathAbsolute(filepath)

    local file = io.open(filepath, "w")
    if not file then
        print('Unable to open file at ' .. filepath)
        return
    end

    file:write(content)
    file:close()

    return 0
end

-- Fetches channel data from db.json located in the respective skin folder
local function FetchDatabase()
    local contents = ReadFile(SKIN:GetVariable('@') .. 'json/youtube.json')
    if not contents then return end

    local jsonarray = JSON.parse(contents)

    local db = {}
    local count = 0

    for k, v in ipairs(jsonarray.data) do
        if v.enable then
            table.insert(db, { id = v.id, key = k } )
            count = count + 1

            if v.use_name then
                db[count].name = v.name
            end
        end
    end

    return db, count, jsonarray
end

function Initialize()
    JSON = dofile(SKIN:GetVariable('@') .. 'lua/json.lua')

    CHANNEL, TOTAL_CHANNELS, FULL_ARRAY = FetchDatabase()

    CURRENT_CHANNEL = 1
    NEXT_CHANNEL = 2 % TOTAL_CHANNELS
    DOWNLOADED_CHANNELS = 0

    TRANSITIONING = false
    UPDATE_PAIR = 0
    EQUALIZER = 0

    return 1
end

-- Creates a filename. Used primarily to save YouTube channel profile pictures
function GenerateFileName()
    if IsEmpty() then return '' end

    return CHANNEL[CURRENT_CHANNEL].id .. ".jpg"
end

function StoreMainData()
    if (CHANNEL[CURRENT_CHANNEL].name == nil) then CHANNEL[CURRENT_CHANNEL].name = SKIN:GetMeasure("NameModule"):GetStringValue() end

    CHANNEL[CURRENT_CHANNEL].title = SKIN:GetMeasure("TitleModule"):GetStringValue()
    CHANNEL[CURRENT_CHANNEL].link = SKIN:GetMeasure("LinkModule"):GetStringValue()
    CHANNEL[CURRENT_CHANNEL].date = SKIN:GetMeasure("DateModule"):GetStringValue()

    if FULL_ARRAY.cache[CHANNEL[CURRENT_CHANNEL].id] then
        UpdateCheck()
        return 0
    end

    SKIN:Bang('!EnableMeasure', 'IconModule')
    SKIN:Bang('!CommandMeasure', 'IconModule', 'Update')
    SKIN:Bang('!UpdateMeasure', 'IconModule')

    return 0
end

function CheckImage()
    if not FULL_ARRAY.cache[CHANNEL[CURRENT_CHANNEL].id] or FULL_ARRAY.cache[CHANNEL[CURRENT_CHANNEL].id] ~= SKIN:GetMeasure("IconModule"):GetStringValue() then
        SKIN:Bang('!EnableMeasure', 'IconDownloadModule')
        SKIN:Bang('!CommandMeasure', 'IconDownloadModule', 'Update')
        SKIN:Bang('!UpdateMeasure', 'IconDownloadModule')
    else
        UpdateCheck()
    end

    return 0
end

function CatalogImage()
    FULL_ARRAY.cache[CHANNEL[CURRENT_CHANNEL].id] = SKIN:GetMeasure("IconModule"):GetStringValue()
    WriteFile(SKIN:GetVariable('@') .. 'json/youtube.json', JSON.stringify(FULL_ARRAY))

    UpdateCheck()

    return 0
end

function UpdateCheck()
    DOWNLOADED_CHANNELS = DOWNLOADED_CHANNELS + 1

    if (DOWNLOADED_CHANNELS >= TOTAL_CHANNELS) then
        Startup()
        return 1
    else
        SetNextChannel(-1)
        CURRENT_CHANNEL = NEXT_CHANNEL
        SKIN:Bang('!CommandMeasure', 'VideoModule', 'Update')
        SKIN:Bang('!UpdateMeasure', 'VideoModule')
        SKIN:Bang('!UpdateMeter', 'BubbleText1')
    end

    return 0
end

-- A tracker function that is updated every time a component is downloaded
-- NOTE: Each YouTube channel requires 2 downloads - one for their profile picture, and another that captures the details of their latest upload
-- function UpdateCheck()
--     UPDATE_PAIR = UPDATE_PAIR + 1

--     if (UPDATE_PAIR >= 2) then
--         CatalogData(CURRENT_CHANNEL)
--         DOWNLOADED_CHANNELS = DOWNLOADED_CHANNELS + 1
--         UPDATE_PAIR = 0

--         if (DOWNLOADED_CHANNELS >= TOTAL_CHANNELS) then
--             Startup()
--             return 1
--         else
--             -- print('Downloading next entry...')
--             SetNextChannel(-1)
--             CURRENT_CHANNEL = NEXT_CHANNEL
--             SKIN:Bang('!CommandMeasure', 'IconModule', 'Update')
--             SKIN:Bang('!UpdateMeasure', 'IconModule')
--             SKIN:Bang('!CommandMeasure', 'VideoModule', 'Update')
--             SKIN:Bang('!UpdateMeasure', 'VideoModule')
--             SKIN:Bang('!UpdateMeter', 'BubbleText1')
--             return 0
--         end
--     end

--     return -1
-- end

-- Returns the appropriate URL to fetch a YouTube channel profile icon
function GetThumbnailURL()
    if IsEmpty() then return '' end

    return "https://www.youtube.com/channel/" .. CHANNEL[CURRENT_CHANNEL].id
end

-- Returns the appropriate URL to fetch the most recent YouTube channel uploads
function GetVideoURL()
    if IsEmpty() then return '' end

    return "https://www.youtube.com/feeds/videos.xml?channel_id=" .. CHANNEL[CURRENT_CHANNEL].id
end

-- Returns the Filepath to the desired YouTube channel icon
function GetIcon(index)
    if (DOWNLOADED_CHANNELS <= 0) then
        return SKIN:GetVariable('@') .. "assets/icons/youtube_default.png"
    end
    if (index + EQUALIZER >= 1) then
        return SKIN:GetVariable('CURRENTPATH') .. "DownloadFile/" .. CHANNEL[NEXT_CHANNEL].id .. ".jpg"
    end
    return SKIN:GetVariable('CURRENTPATH') .. "DownloadFile/" .. CHANNEL[CURRENT_CHANNEL].id .. ".jpg"
end

-- Returns the name of the desired YouTube channel
function GetName(index)
    if (DOWNLOADED_CHANNELS <= 0) then
        return "YouTube"
    end
    if (index + EQUALIZER >= 1) then
        return CHANNEL[NEXT_CHANNEL].name
    end

    return CHANNEL[CURRENT_CHANNEL].name
end

-- Returns the title of the desired YouTube channel video
function GetTitle(index)
    if (TOTAL_CHANNELS <= 0) then
        return ""
    end
    if (DOWNLOADED_CHANNELS < TOTAL_CHANNELS) then
        return "Please wait a moment..."
    end
    if (index + EQUALIZER >= 1) then
        return CHANNEL[NEXT_CHANNEL].title
    end

    return CHANNEL[CURRENT_CHANNEL].title
end

-- Returns the direct link of the desired YouTube channel video
function GetLink(index)
    if (DOWNLOADED_CHANNELS <= 0) then
        return ""
    end
    if (index + EQUALIZER >= 1) then
        return CHANNEL[NEXT_CHANNEL].link
    end

    return CHANNEL[CURRENT_CHANNEL].link
end

-- Opens the appropriate video link in the user's preferred browser
function GotoLink(index)
    if (DOWNLOADED_CHANNELS <= 0) then
        return ""
    end
    if (index + EQUALIZER >= 1) then
        SKIN:Bang(CHANNEL[NEXT_CHANNEL].link)
    end

    SKIN:Bang(CHANNEL[CURRENT_CHANNEL].link)

    return 1
end

-- Returns the formatted upload date dialog of the desired YouTube channel video
function GetTime(index)
    if (TOTAL_CHANNELS <= 0) then
        return "Not tracking channels."
    end
    if (DOWNLOADED_CHANNELS < TOTAL_CHANNELS) then
        return "Connecting...(" .. DOWNLOADED_CHANNELS .. "/" .. TOTAL_CHANNELS .. ")"
    end
    if (index + EQUALIZER >= 1) then
        return "Uploaded " .. CalculateTime(CHANNEL[NEXT_CHANNEL].date)
    end

    return "Uploaded " .. CalculateTime(CHANNEL[CURRENT_CHANNEL].date)
end

-- Sets the primary bubble to the offset bubble for re-entry
function Equalize()
    EQUALIZER = 1
    SKIN:Bang('!UpdateMeterGroup', 'YouTubeGroup')
    SelectNode(CURRENT_CHANNEL, NEXT_CHANNEL)

    return 1
end

-- Sets the offset bubble to the default next entry
function Step()
    CURRENT_CHANNEL = NEXT_CHANNEL
    SetNextChannel(-1)
    EQUALIZER = 0
    SKIN:Bang('!UpdateMeterGroup', 'YouTubeGroup')

    TRANSITIONING = false

    return 1
end

-- Sets the offset bubble to a user-defined input [x] and immediately performs a transition
function ManualSelect(x)
    if (DOWNLOADED_CHANNELS < TOTAL_CHANNELS or TRANSITIONING) then
        return -1
    end

    local selection = (math.floor((x / 100) * TOTAL_CHANNELS))
    if (selection < 0 or selection >= TOTAL_CHANNELS) then
        return -1
    end

    if (selection + 1 == CURRENT_CHANNEL) then
        return 0
    end

    TRANSITIONING = true

    SetNextChannel(selection + 1)

    SKIN:Bang('!UpdateMeterGroup', 'YouTubeGroup')
    SKIN:Bang('!UpdateMeasure', 'Ticker')
    return 1
end

function Err(code)
    local error = { "Icon download failed.", "RSS Feed inacessible." }

    -- Icon update override
    local f = io.open(SKIN:GetVariable('CURRENTPATH') .. "DownloadFile/" .. CHANNEL[NEXT_CHANNEL].id .. ".jpg", "r")
    if (f ~= nil) then
        io.close(f)
        UpdateCheck()
        return 0
    end

    io.close(f)

    SKIN:Bang('!SetOption', 'BubbleText1', 'Text', error[code])
    SKIN:Bang('!UpdateMeter', 'BubbleText1')
    SKIN:Bang('!SetOption', 'CaptionTextName1', 'Connection failure.')
    SKIN:Bang('!UpdateMeter', 'CaptionTextName1')

    return code
end