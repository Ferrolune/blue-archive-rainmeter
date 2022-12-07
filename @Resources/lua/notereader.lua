
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

-- Splits the string [s] according to the delimiter
-- Credits to https://www.codegrepper.com/code-examples/lua/lua+split+string+by+delimiter
local function Split(s, delimiter)
    local result = { }
    local size = 0

    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
        size = size + 1
    end

    return result, size
end

-- Reads the notes.txt file located in the @Resources folder
local function Read(filename)
    -- Opens file to read
    local filepath = SKIN:GetVariable('@') .. "notes\\" .. filename .. ".txt"
    local file = assert(io.open(filepath, "r"), "file not found or does not exist")

    if (file == nil) then
        return -1
    end

    -- Reads .txt file and prepares an array
    local notestring = file:read("*all")
    local notelist, length = Split(notestring, "\n")

    -- Closes file
    file:close()

    return notestring, notelist, length
end

-- Fetches channel data from db.json located in the respective skin folder
local function FetchDatabase()
    local contents = ReadFile(SKIN:GetVariable('@') .. 'json/note.json')
    if not contents then return end

    local jsonarray = JSON.parse(contents)

    local db = {}
    local count = 0

    for k, v in ipairs(jsonarray.data) do
        if v.enable then
            table.insert(db, { filename = v.filename, sensitive = v.sensitive, key = k } )
            count = count + 1
        end
    end

    return db, count, jsonarray
end

-- Sets the visibility of the notes according to its settings
local function SetLock()
    if (NOTE_FILE_LIST[SELECTION].sensitive) then
        SKIN:Bang('!SetOption', 'WarnLock', 'W', '(150*#GScale#)')
        SKIN:Bang('!SetOption', 'WarnText', 'Text', 'SENSITIVE DATA!#CRLF#Open the .txt in private.')
    else
        SKIN:Bang('!SetOption', 'WarnLock', 'W', '0')
        SKIN:Bang('!SetOption', 'WarnText', 'Text', '')
    end

    SKIN:Bang('!UpdateMeter', 'WarnLock')
    SKIN:Bang('!UpdateMeter', 'WarnText')

    return 1
end

-- Sets the visibility of the up and down arrows according to the scroll and length of the notes
local function SetArrows()
    if (LENGTH <= BUFFER or NOTE_FILE_LIST[SELECTION].sensitive) then
        SKIN:Bang('!HideMeterGroup', 'ArrowGroup')
        SKIN:Bang('!UpdateMeterGroup', 'ArrowGroup')
        return 0
    end

    if (SCROLL <= 0) then
        SKIN:Bang('!HideMeter', 'UpArrow')
        SKIN:Bang('!HideMeter', 'UpHitbox')
    else
        SKIN:Bang('!ShowMeter', 'UpArrow')
        SKIN:Bang('!ShowMeter', 'UpHitbox')
    end

    if (SCROLL + BUFFER >= LENGTH) then
        SKIN:Bang('!HideMeter', 'DownArrow')
        SKIN:Bang('!HideMeter', 'DownHitbox')
    else
        SKIN:Bang('!ShowMeter', 'DownArrow')
        SKIN:Bang('!ShowMeter', 'DownHitbox')
    end
    
    SKIN:Bang('!UpdateMeterGroup', 'ArrowGroup')

    return 1
end

function Initialize()
    JSON = dofile(SKIN:GetVariable('@') .. 'lua/json.lua')
    NOTE_FILE_LIST, TOTAL_NOTE_FILES, _ = FetchDatabase()

    SELECTION = tonumber(SKIN:GetVariable('NoteSelection', 1))
    NOTES = nil
    NOTES_LIST = {}
    LENGTH = 0

    SCROLL = 0
    BUFFER = 7

    return 1
end

-- Scrolls the Notes in the specified direction
function Scroll(direction)
    if (direction < 0 and SCROLL > 0) then
        SCROLL = SCROLL - 1
    end
    if (direction > 0 and SCROLL < LENGTH - BUFFER) then
        SCROLL = SCROLL + 1
    end

    SetArrows()

    return 1
end

-- Returns the file name
function GetName()
    return NOTE_FILE_LIST[SELECTION].filename
end

-- Returns the text string at the specified index
function ReadLine(index)
    if (NOTE_FILE_LIST[SELECTION].sensitive) then return " " end

    index = tonumber(index) + SCROLL
    local data = NOTES_LIST[index]
    if data == nil or data == "" then return " " end

    return data
end

-- Loads the currently selected file
function Load()
    if (NOTES ~= nil) then return -1 end

    NOTES, NOTES_LIST, LENGTH = Read(NOTE_FILE_LIST[SELECTION].filename)
    SCROLL = 0
    SKIN:Bang('!UpdateMeterGroup', 'NoteGroup')
    SetLock()
    SetArrows()

    return 1
end

-- Unloads the currently selected file
function Unload()
    NOTES = nil
    NOTES_LIST = {}
    LENGTH = 0
    SCROLL = 0
    SetArrows()

    return 1
end

-- Iterates to the next file in the collection
function NextNote()
    SELECTION = (SELECTION % TOTAL_NOTE_FILES) + 1
    Unload()
    Load()

    SKIN:Bang('!SetOption', 'Variables', 'NoteSelection', SELECTION)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'NoteSelection', SELECTION)

    return 1
end