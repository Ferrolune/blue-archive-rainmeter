-- Handles driver plug-ins and their storage space details.

-- Check if a file or directory exists in this path
-- Credits to Hisham from StackOverflow: https://stackoverflow.com/questions/1340230/check-if-directory-exists-in-lua
local function exists(file)
    local ok, err, code = os.rename(file, file)
    if not ok then
        if code == 13 then
            -- Permission denied, but it exists
            return true
        end
    end

    return ok, err
end

 -- Check if a directory exists in this path
local function isdir(path)
    -- "/" works on both Unix and Windows
    return exists(path.."/")
end

function Initialize()
    DRIVER_LIST = { "C:", "D:", "E:", "F:", "G:", "H:", "I:", "J:", "K:", "L:" }
    DRIVER_COUNT = 10
    FORMAT_LIST = { '', 'K', 'M', 'G', 'T', 'P' }

    CURRENT_DRIVER = "C:"

    return 1
end

-- Formats a number string to have commas.
-- Credits to Bart Kiers from StackOverflow: https://stackoverflow.com/questions/10989788/format-integer-in-lua
function FormatIntString(number, format)
    local suffix = 1
    while number >= 1000000 and suffix <= 6 do
        number = number / 1024
        suffix = suffix + 1
    end

    local _, _, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')

    -- reverse the int-string and append a comma to all blocks of 3 digits
    int = int:reverse():gsub("(%d%d%d)", "%1,")

    -- reverse the int-string back remove an optional comma and put the
    -- optional minus and fractional part back
    return minus .. int:reverse():gsub("^,", "") .. ' ' .. FORMAT_LIST[suffix] .. 'B'
end

-- Returns the current Driver that is selected
function CurrentDrive()
    if not isdir(CURRENT_DRIVER) then
        NextDrive()
    end

    return CURRENT_DRIVER
end

-- Selects the next drive alphabetically, wrapping back
-- Returns the C: Drive if nothing else is found
function NextDrive()
    local index = 1
    for i, d in ipairs(DRIVER_LIST) do
        if d == CURRENT_DRIVER then
            index = i
            break
        end
    end

    for s = 1, DRIVER_COUNT, 1 do
        local drive = s + index
        if drive > DRIVER_COUNT then
            drive = drive % DRIVER_COUNT
        end
        if isdir(DRIVER_LIST[drive]) then
            CURRENT_DRIVER = DRIVER_LIST[drive]
            print("New Driver:" .. CURRENT_DRIVER)
            return 1
        end
    end

    CURRENT_DRIVER = DRIVER_LIST[1]

    return 1
end