-- Small script to handle extraneous issues with the update banner.
local function CatalogData(index)
    local updatetitle = SKIN:GetMeasure("TitleModule"):GetStringValue()
    local updatedate = SKIN:GetMeasure("DateModule"):GetStringValue()
    local updatelink = SKIN:GetMeasure("LinkModule"):GetStringValue()

    if (updatetitle == '' or updatetitle == nil) then
        updatetitle = "No Recent Updates!"
    end

    if (updatedate == '' or updatedate == nil) then
        updatedate = os.date("01 Jan 1970")
    end

    if (updatelink == '' or updatelink == nil) then
        updatelink = 'https://store.steampowered.com/news/app/' .. GAME[index].id
    end

    GAME[index].title = updatetitle
    GAME[index].date = updatedate
    GAME[index].link = updatelink
    return 1
end

-- Sets the next channel to be transitioned in
local function SetNextGame(selection)
    if (selection < 0) then
        NEXT_GAME = (CURRENT_GAME % TOTAL_GAMES) + 1
    else
        NEXT_GAME = selection
    end

    return 1
end

-- Starts up the Rainmeter skin
local function Startup()
    CURRENT_GAME = 1
    SetNextGame(-1)

    if (TOTAL_GAMES > 1) then
       SKIN:Bang('!EnableMeasure', 'Ticker')
    end

    SKIN:Bang('!UpdateMeterGroup', 'BannerGroup')
    SKIN:Bang('!ShowMeterGroup', 'BannerGroup')
    return 1
end

local function DownloadBanner(imagePath)
    SKIN:Bang('!EnableMeasure', 'ImageModule')
    SKIN:Bang('!CommandMeasure', 'ImageModule', 'Update')
    SKIN:Bang('!UpdateMeasure', 'ImageModule')

    return 1
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

-- Fetches app data from db.json located in the respective skin folder
local function FetchDatabase()
    local contents = ReadFile(SKIN:GetVariable('@') .. 'json/steamevent.json')
    if not contents then return end

    local jsonarray = JSON.parse(contents)

    local db = {}
    local count = 0

    for k,v in ipairs(jsonarray.data) do
        if v.enable then
        end
    end

    for k, v in ipairs(jsonarray.data) do
        if v.enable then
            table.insert(db, { id = v.id, key = k, name = v.name } )
            count = count + 1
        end
    end

    return db, count, jsonarray
end

local function IsDate(datestring)
    if (string.match(datestring, "01 Jan 1970")) then
        return "[No Date]"
    end

    return datestring
end

function Initialize()
    JSON = dofile(SKIN:GetVariable('@') .. 'lua/json.lua')

    GAME, TOTAL_GAMES, _ = FetchDatabase()

    CURRENT_GAME = 1
    NEXT_GAME = 2 % TOTAL_GAMES
    DOWNLOADED_GAMES = 0

    URL_CONTAINER = ""
    EQUALIZER = 0

    return 1
end

-- Generates the RSS Feed Steam URL for data parsing
function GetSteamURL()
    return 'https://store.steampowered.com/feeds/news/app/' .. GAME[CURRENT_GAME].id .. '/'
end

-- Generates a filename for the app's image
function GenerateFileName()
    return GAME[CURRENT_GAME].id .. '.jpg'
end

-- Returns the image filename to download
function GetImageURL()
    return URL_CONTAINER
end

-- Downloads the appropriate banner image depending on if the update feed has an image or not
function ImageStep()
    local item = SKIN:GetMeasure('SteamRSSModule'):GetStringValue()

    if (string.find(item, '<enclosure')) then
        URL_CONTAINER = string.match(item, '<enclosure url="(.*)" length')
        -- print('Image is attached at URL ' .. URL_CONTAINER)
    else
        URL_CONTAINER = 'https://cdn.cloudflare.steamstatic.com/steam/apps/' .. GAME[CURRENT_GAME].id .. '/header.jpg'
        -- print('No image attached. Use default banner at ' .. URL_CONTAINER)
    end

    CatalogData(CURRENT_GAME)

    DownloadBanner()

    return 1
end

-- A tracker function that is updated every time a component is downloaded
function UpdateCheck()
    SKIN:Bang('!DisableMeasure', 'ImageModule')
    DOWNLOADED_GAMES = DOWNLOADED_GAMES + 1
    URL_CONTAINER = ''
    
    if (DOWNLOADED_GAMES >= TOTAL_GAMES) then
        Startup()
        return 1
    else
        SetNextGame(-1)
        CURRENT_GAME = NEXT_GAME
        SKIN:Bang('!CommandMeasure', 'SteamRSSModule', 'Update')
        SKIN:Bang('!UpdateMeasure', 'SteamRSSModule')
        return 0
    end

    return -1
end

-- Returns the image location of the desired app's update banner
function GetBanner(index)
    if (DOWNLOADED_GAMES <= 0) then
        return SKIN:GetVariable('@') .. "assets/icons/youtube_default.png"
    end
    if (index + EQUALIZER >= 1) then
        return SKIN:GetVariable('CURRENTPATH') .. "DownloadFile/" .. GAME[NEXT_GAME].id .. ".jpg"
    end
    return SKIN:GetVariable('CURRENTPATH') .. "DownloadFile/" .. GAME[CURRENT_GAME].id .. ".jpg"
end

-- Returns the date of the desired app's update
function GetDate(index)
    if (DOWNLOADED_GAMES <= 0) then
        return "01 Jan 1970"
    end
    if (index + EQUALIZER >= 1) then
        return IsDate(GAME[NEXT_GAME].date)
    end
    return IsDate(GAME[CURRENT_GAME].date)
end

-- Returns the title of the desired app's update
function GetTitle(index)
    if (DOWNLOADED_GAMES <= 0) then
        return "Lorem Ipsum"
    end
    if (index + EQUALIZER >= 1) then
        return GAME[NEXT_GAME].title
    end
    return GAME[CURRENT_GAME].title
end

-- Returns the direct link of the desired update page
function GotoLink(index)
    if (DOWNLOADED_GAMES <= 0) then
        return ""
    end
    if (index + EQUALIZER >= 1) then
        SKIN:Bang("steam://openurl/" .. GAME[NEXT_GAME].link)
    end

    SKIN:Bang("steam://openurl/" .. GAME[CURRENT_GAME].link)

    return 1
end

function IsRecent(index)
    if (DOWNLOADED_GAMES <= 0) then
        return 0
    end

    local updatedate = GAME[CURRENT_GAME].date

    if (index + EQUALIZER >= 1) then
        updatedate = GAME[NEXT_GAME].date
    end

    local pattern = "(%d+) (%a+) (%d+)"
    local rday, rmonth, ryear = updatedate:match(pattern)
    local wordmonth = { Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12 }
    rmonth = wordmonth[rmonth]

    local unixtime = os.time({year = ryear, month = rmonth, day = rday})

    if (os.time(os.date("!*t")) - unixtime >= (10*86400) or unixtime == 0) then
        return 0
    end

    return 255
end

-- Sets the primary bubble to the offset bubble for re-entry
function Equalize()
    EQUALIZER = 1
    SKIN:Bang('!UpdateMeterGroup', 'BannerGroup')

    return 1
end

-- Sets the offset bubble to the default next entry
function Step()
    CURRENT_GAME = NEXT_GAME
    SetNextGame(-1)
    EQUALIZER = 0
    SKIN:Bang('!UpdateMeterGroup', 'BannerGroup')

    -- TRANSITIONING = false

    return 1
end