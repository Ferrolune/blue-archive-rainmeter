-- Script to catalog listed YouTube channels and provide functions for the parent skin.
local JSON, CACHE

local LIMIT = 15

local DATA, CHANNEL, TOTAL_CHANNELS

local CURRENT_CHANNEL = 1
local NEXT_CHANNEL
local DOWNLOADED_CHANNELS = 0

local TRANSITIONING = false

local STEP = { 0.00, -0.05, -0.15, -0.30, -0.50, -0.70, -0.85, -0.95, -1.00 }
local PULL = { 1, 1 }

local C, CI
local ID_TABLE = {}

-- draws the scroll bar at the bottom of the widget
local function DrawScrollUI()
    local pinSize = SKIN:GetVariable('PinSize')
    local len = (TOTAL_CHANNELS - 1) * pinSize * 1.5
    local bigLen = TOTAL_CHANNELS * pinSize * 1.5

    SKIN:Bang('!SetOption', 'ScrollUI', 'Shape', 'Line (' .. len / -2 .. '*#GScale#),0,(' .. len / 2 .. '*#GScale#),0 | StrokeWidth (' .. pinSize * 2 .. '*#GScale#) | StrokeColor #OuterColor# | StrokeStartCap #PopUpCap# | StrokeEndCap #PopUpCap#')
    SKIN:Bang('!SetOption', 'ScrollUI', 'Shape2', 'Line (' .. (len / -2) .. '*#GScale#),0,(' .. (len / 2) .. '*#GScale#),0 | StrokeWidth (' .. pinSize .. '*#GScale#) | StrokeColor #DeselectColor# | StrokeStartCap #PopUpCap# | StrokeEndCap #PopUpCap# | StrokeDashCap #PopUpCap# | StrokeDashes 0, 1.5 | StrokeDashOffset 0')

    SKIN:Bang('!SetOption', 'ScrollHitbox', 'Shape', 'Rectangle ' .. bigLen / -2 .. ',' .. -pinSize .. ',('.. bigLen .. '*#GScale#),(' .. (pinSize * 2) .. '*#GScale#) | #Hitbox#')

    return 1
end

-- highlights the appropriate node in the Scroll UI according to the displayed channel
local function SelectNode(newindex)
    local pinSize = SKIN:GetVariable('PinSize')
    local len = (TOTAL_CHANNELS - 1) * pinSize * 1.5

    SKIN:Bang('!SetOption', 'ScrollUI', 'Shape3', 'Line ('.. (len / -2) + ((newindex - 1) * 1.5 * pinSize) .. '*#GScale#),0,(' .. (len / -2) + ((newindex - 1) * 1.5 * pinSize) .. '*#GScale#),0 | StrokeWidth (' .. pinSize .. '*#GScale#) | StrokeColor #SelectColor# | StrokeStartCap #PopUpCap# | StrokeEndCap #PopUpCap# | StrokeDashCap #PopUpCap# | StrokeDashes 0, 1.5 | StrokeDashOffset 0')

    return 1
end

-- sets the next channel to be transitioned in
local function SetNextChannel(selection)
    if (selection < 0) then
        NEXT_CHANNEL = (CURRENT_CHANNEL % TOTAL_CHANNELS) + 1
    else
        NEXT_CHANNEL = selection
    end

    return 1
end

-- renders starting information once all assets have been downloaded and verified
local function Startup(cacheFlag)
    CURRENT_CHANNEL = 1
    SetNextChannel(-1)

    if cacheFlag then
        C:setTime(ID_TABLE)
        C:setTime()
        JSON.writeFile(SKIN:GetVariable('CURRENTPATH') .. 'DownloadFile\\youtube.cache', C:getTable())
        JSON.writeFile(SKIN:GetVariable('CURRENTPATH') .. 'DownloadFile\\youtubeimg.cache', CI:getTable())
    end

    DrawScrollUI()
    SelectNode(1)

    if (TOTAL_CHANNELS > 1) then
       SKIN:Bang('!EnableMeasure', 'Ticker')
    end

    SKIN:Bang('!UpdateMeterGroup', 'YouTubeGroup')
    SKIN:Bang('!Redraw')

    return 1
end

-- handles grammar structure for upload time strings
local function Plural(value, time)
    if value == 1 then
        return value .. ' ' .. time
    end

    return value .. ' ' .. time .. 's'
end

-- calculates the appropriate time estimates since video upload
local function LargestTime(pasttime)
    pasttime = pasttime / 60
    if (pasttime < 60) then
        pasttime = math.floor(pasttime)
        return Plural(pasttime, 'min') .. ' ago!'
    end
    pasttime = pasttime / 60
    if (pasttime < 24) then
        pasttime = math.floor(pasttime)
        return Plural(pasttime, 'hr') .. ' ago!'
    end
    pasttime = pasttime / 24
    if (pasttime < 7) then
        pasttime = math.floor(pasttime)
        return Plural(pasttime, 'day') .. ' ago!'
    end
    pasttime = pasttime / 7
    if (pasttime < 5) then
        pasttime = math.floor(pasttime)
        return Plural(pasttime, 'wk') .. ' ago.'
    end
    pasttime = (pasttime * 7) / 30.5
    if (pasttime < 12) then
        pasttime = math.floor(pasttime)
        return pasttime .. ' mo. ago...'
    end
    pasttime = (pasttime * 30.5) / 365
    pasttime = math.floor(pasttime)
    return Plural(pasttime, 'yr') .. ' ago...'
end

-- extrapolates a Unix timestamp from a string and returns a formatted dialog string
-- CITATION: https://stackoverflow.com/questions/4105012/convert-a-string-date-to-a-timestamp
-- NOTE: Time structure is as follows: YYYY-MM-DDTHH:MM:SS+HH:MM where [T] is a literal
local function CalculateTime(videotime)

    local pattern = '(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)'
    local ryear, rmonth, rday, rhour, rmin, rsec = videotime:match(pattern)

    local unixtime = os.time({year = ryear, month = rmonth, day = rday, hour = rhour, min = rmin, sec = rsec})
    local pasttime = os.time(os.date('!*t')) - unixtime

    return LargestTime(pasttime)
end

function Initialize()
    JSON = dofile(SKIN:GetVariable('@') .. 'lua\\lib\\jsonhandler.lua')
    CACHE = dofile(SKIN:GetVariable('@') .. 'lua\\lib\\cache.lua')

    DATA = JSON.readFile(SKIN:GetVariable('@') .. 'json\\youtube.json')
    CHANNEL = JSON.filterEnabled(DATA.data, LIMIT, 'This is to prevent the Navigation UI from spilling.')
    TOTAL_CHANNELS = table.getn(CHANNEL)

    NEXT_CHANNEL = 2 % TOTAL_CHANNELS

    C = CACHE.new(JSON.readFile(SKIN:GetVariable('CURRENTPATH') .. 'DownloadFile\\youtube.cache'))
    CI = CACHE.new(JSON.readFile(SKIN:GetVariable('CURRENTPATH') .. 'DownloadFile\\youtubeimg.cache'))
    for _, v in pairs(CHANNEL) do
        table.insert(ID_TABLE, v.id)
    end

    if TOTAL_CHANNELS <= 0 then
        return 1
    elseif (C:isRecent(3600, ID_TABLE)) then
        DOWNLOADED_CHANNELS = TOTAL_CHANNELS + 1
        Startup()

        return 0
    end

    SKIN:Bang('!SetOption', 'BubbleFrame1', 'Shape5', '')
    SKIN:Bang('!SetOption', 'BubbleFrame1', 'Shape6', '')
    SKIN:Bang('!SetOption', 'BubbleFrame2', 'Shape5', '')
    SKIN:Bang('!SetOption', 'BubbleFrame2', 'Shape6', '')

    if TOTAL_CHANNELS >= 1 then
        SKIN:Bang('!EnableMeasure', 'VideoModule')
    end

    return 1
end

-- creates a filename to save YouTube channel profile pictures to
function GenerateFileName()
    if TOTAL_CHANNELS <= 0 or DOWNLOADED_CHANNELS > TOTAL_CHANNELS then return '' end

    return CHANNEL[DOWNLOADED_CHANNELS + 1].id .. '.jpg'
end

-- checks and stores downloaded data into cache
function StoreMainData()
    if not C.data[tostring(CHANNEL[DOWNLOADED_CHANNELS + 1].id)] then C.data[tostring(CHANNEL[DOWNLOADED_CHANNELS + 1].id)] = {} end

    C.data[tostring(CHANNEL[DOWNLOADED_CHANNELS + 1].id)].name = SKIN:GetMeasure('NameModule'):GetStringValue() or 'YouTube'
    C.data[tostring(CHANNEL[DOWNLOADED_CHANNELS + 1].id)].title = SKIN:GetMeasure('TitleModule'):GetStringValue() or '<No Title>'
    C.data[tostring(CHANNEL[DOWNLOADED_CHANNELS + 1].id)].link = SKIN:GetMeasure('LinkModule'):GetStringValue() or 'https://www.youtube.com'
    C.data[tostring(CHANNEL[DOWNLOADED_CHANNELS + 1].id)].date = SKIN:GetMeasure('DateModule'):GetStringValue() or ''

    -- NOTE: Old bug workaround patch; better patch has since been applied.
    --       Now redundant, but archived for revisiting if bug resurfaces
    -- if C.data[tostring(CHANNEL[DOWNLOADED_CHANNELS + 1].id)].date == '' then return -1 end

    if CI.data[tostring(CHANNEL[DOWNLOADED_CHANNELS + 1].id)] then
        UpdateCheck()
        return 0
    end

    SKIN:Bang('!EnableMeasure', 'IconModule')
    SKIN:Bang('!CommandMeasure', 'IconModule', 'Update')
    SKIN:Bang('!UpdateMeasure', 'IconModule')

    return 0
end

-- prompts the [IconDownloadModule] measure to download the parsed image
function CheckImage()
    SKIN:Bang('!EnableMeasure', 'IconDownloadModule')
    SKIN:Bang('!CommandMeasure', 'IconDownloadModule', 'Update')
    SKIN:Bang('!UpdateMeasure', 'IconDownloadModule')

    return 0
end

-- caches a [true] flag for the downloaded channel icon
-- NOTE: this caching exists so that a channel's profile icon is only download once, ever
function CatalogImage()
    CI.data[tostring(CHANNEL[DOWNLOADED_CHANNELS + 1].id)] = true

    UpdateCheck()

    return 0
end

-- checks whether all entry information has been downloaded and whether there is more to download
function UpdateCheck()
    DOWNLOADED_CHANNELS = DOWNLOADED_CHANNELS + 1

    if (DOWNLOADED_CHANNELS >= TOTAL_CHANNELS) then
        Startup(true)
        return 1
    else
        SKIN:Bang('!CommandMeasure', 'VideoModule', 'Update')
        SKIN:Bang('!UpdateMeasure', 'VideoModule')
        SKIN:Bang('!UpdateMeter', 'BubbleText1')
        SKIN:Bang('!Redraw')
    end

    return 0
end

-- returns the appropriate URL to fetch a YouTube channel profile icon
function GetThumbnailURL()
    if TOTAL_CHANNELS <= 0 or DOWNLOADED_CHANNELS > TOTAL_CHANNELS then return '' end

    return 'https://www.youtube.com/channel/' .. CHANNEL[DOWNLOADED_CHANNELS + 1].id
end

-- returns the appropriate URL to fetch the most recent YouTube channel uploads
function GetVideoURL()
    if TOTAL_CHANNELS <= 0 or DOWNLOADED_CHANNELS > TOTAL_CHANNELS then return '' end

    return 'https://www.youtube.com/feeds/videos.xml?channel_id=' .. CHANNEL[DOWNLOADED_CHANNELS + 1].id
end

-- returns the Filepath to the desired YouTube channel icon
function GetIcon(index)
    if (DOWNLOADED_CHANNELS <= 0) then
        return ''
    end

    local element = CURRENT_CHANNEL
    if index == 1 then element = NEXT_CHANNEL end

    return SKIN:GetVariable('CURRENTPATH') .. 'DownloadFile\\' .. CHANNEL[element].id .. '.jpg'
end

-- returns the name of the desired YouTube channel
function GetName(index)
    if (DOWNLOADED_CHANNELS <= 0) then
        return 'YouTube'
    end

    local element = CURRENT_CHANNEL
    if index == 1 then element = NEXT_CHANNEL end

    if CHANNEL[element].use_name then return CHANNEL[element].name end

    return C.data[tostring(CHANNEL[element].id)].name
end

-- returns the title of the desired YouTube channel video
function GetTitle(index)
    if (TOTAL_CHANNELS <= 0) then
        return ''
    end
    if (DOWNLOADED_CHANNELS < TOTAL_CHANNELS) then
        return 'Please wait a moment...'
    end

    local element = CURRENT_CHANNEL
    if index == 1 then element = NEXT_CHANNEL end

    return C.data[tostring(CHANNEL[element].id)].title
end

-- returns the direct link of the desired YouTube channel video
function GetLink()
    if (DOWNLOADED_CHANNELS <= 0) then
        return ''
    end

    return C.data[tostring(CHANNEL[CURRENT_CHANNEL].id)].link
end

-- returns the direct link of the desired YouTube homepage
function GetHome()
    if (DOWNLOADED_CHANNELS <= 0) then
        return ''
    end

    return 'https://www.youtube.com/channel/' .. tostring(CHANNEL[CURRENT_CHANNEL].id)
end

-- returns the formatted upload date dialog of the desired YouTube channel video
function GetTime(index)
    if (TOTAL_CHANNELS <= 0) then
        return 'Not tracking channels.'
    end
    if (DOWNLOADED_CHANNELS < TOTAL_CHANNELS) then
        return 'Connecting...(' .. DOWNLOADED_CHANNELS .. '/' .. TOTAL_CHANNELS .. ')'
    end

    local element = CURRENT_CHANNEL
    if index == 1 then element = NEXT_CHANNEL end

    return 'Uploaded ' .. CalculateTime(C.data[tostring(CHANNEL[element].id)].date)
end

-- sets the offset bubble to a user-defined input [x] and immediately performs a transition
function ManualSelect(x)
    x = (x + 100) / 2
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
    SKIN:Bang('!Redraw')

    return 1
end

-- goes forwards in the YouTube catalogue
function ChangeChannel()
    SelectNode(NEXT_CHANNEL)
    CURRENT_CHANNEL = NEXT_CHANNEL
    SetNextChannel(-1)

    TRANSITIONING = false

    return 0
end

-- changes the animation sequence to the specified values
function Step(a, b)

    PULL[1] = math.min(math.max(PULL[1] + tonumber(a), 1), 9)
    PULL[2] = math.min(math.max(PULL[2] + tonumber(b), 1), 9)

    return 0
end

-- gets the current animation step
function GetStep(index)
    return STEP[PULL[index]]
end

-- prints an error message
function Err(code)
    local error = { { msg = 'Connection failed. Try again later.', display = 'OFFLINE' }, { msg = 'Download failed. Try again later.', display = 'ERROR' } }
    print(error[tonumber(code)].msg)

    SKIN:Bang('!SetOption', 'CaptionTextTitle1', 'Text', error[tonumber(code)].display)
    SKIN:Bang('!SetOption', 'BubbleText1', 'Text', 'Connection/parse error.')
    SKIN:Bang('!UpdateMeterGroup', 'YouTubeGroup')
    SKIN:Bang('!Redraw')

    return 0
end

-- forces a data update
function ManualUpdate()
    C:resetTime()

    JSON.writeFile(SKIN:GetVariable('CURRENTPATH') .. 'DownloadFile\\youtube.cache', C:getTable())

    SKIN:Bang('!Refresh')

    return 1
end

-- forces a data update by clearing cache files
function ClearCache()
    C:clearCache()
    CI:clearCache(function(k, _) return SKIN:GetVariable('CURRENTPATH') .. 'DownloadFile\\' .. k .. '.jpg' end)

    JSON.writeFile(SKIN:GetVariable('CURRENTPATH') .. 'DownloadFile\\youtube.cache', C:getTable())
    JSON.writeFile(SKIN:GetVariable('CURRENTPATH') .. 'DownloadFile\\youtubeimg.cache', CI:getTable())

    SKIN:Bang('!Refresh')

    return 1
end