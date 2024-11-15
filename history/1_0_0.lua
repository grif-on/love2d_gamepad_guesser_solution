local ggs = {
    _URL = "https://github.com/Vovkiv/gamepad_guesser_solution",
    _DOCUMENTATION = "https://github.com/Vovkiv/gamepad_guesser_solution/blob/main/README.md",

    _VERSION_MAJOR = 1,
    _VERSION_MINOR = 0,
    _VERSION_PATCH = 0,
    _LOVE = "11.5",

    _NAME = "Gamepad Guesser Solution",
    _DESCRIPTION = "Guess gamepad type like a pro, implementation of gamepads_types_database for Love2D.",

    _LICENSE = "MIT-0",
    _LICENSE_TEXT =
[[
MIT No Attribution

Copyright 2024 volkov

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
}

-- If true will print some debug messages to terminal.
ggs.debug = false

-- Will add "Gamepad Guesser Solution debug info:" to each debug print that this library produces.
ggs.debug_info_string = ggs._NAME .. " debug info:"

-- Function used internally by library to print some useful info to terminal,
-- if ggs.debug == true.
ggs.debug_print = function (...)
    if not ggs.debug then
        return
    end

    print(ggs.debug_info_string, ...)
end

-- Fallback gamepad type that will be returned in case if GUID or gamepad name not in database.
ggs.fallback_gamepad_type = "MicrosoftXBOX360"

-- Parsed database from csv file to lua table.
-- Use helper functions to get data that you need from it.
ggs.database = {}

-- Line in csv file where version of database stored.
-- It will be incremented if database format somehow will change.
-- Shouldn't be edited by user.
ggs.csv_line_where_version_of_database = nil

-- Line in csv file where links to database is stored.
-- Shouldn't be edited by user.
ggs.csv_line_where_links_to_database = nil

-- Line in csv file where license info of database is stored.
-- Shouldn't be edited by user.
ggs.csv_line_where_license_of_database_stored = nil

-- Line in csv file where detailed types are listed.
-- e.g: "SonyPS1", "MicrosoftXBOX360", "SegaDreamCast", etc.
-- Shouldn't be edited by user.
ggs.csv_line_where_detailed_types = nil

-- Line in csv file where simple types are listed.
-- e.g: "Sony", "Microsoft", "Sega", etc.
-- Shouldn't be edited by user.
ggs.csv_line_where_simple_types = nil

-- Line in csv file where "guid, name, type" list starts.
-- Shouldn't be edited by user.
ggs.csv_line_where_gamepads_list_starts = 6

-- Will load database.
--
-- 1st argument should be string with path for ftcsv library that distributed with Guesser library.
-- It should follow require() syntax, so "path.to.ftcsv"
-- If nothing/nil will be passed, default path will be used, which is "ftcsv"
--
-- 2nd argument should be string with path for database.
-- It should follow love2d filesystem path.
-- If nothing/nil will be passed, default path will be used, which is "/gamecontrollerdb.csv"
ggs.load_database = function (path_to_ftcsv, path_to_database)

    ggs.debug_print("-------------------------------------")
    ggs.debug_print("Print library info.")
    ggs.debug_print("Library name:", ggs._NAME)
    ggs.debug_print("Library description:", ggs._DESCRIPTION)
    ggs.debug_print("Library version:", ggs._VERSION_MAJOR, ggs._VERSION_MINOR, ggs._VERSION_PATCH)
    ggs.debug_print("Love version that library made for:", ggs._LOVE)
    ggs.debug_print("Library repo:", ggs._URL)
    ggs.debug_print("Library license:", ggs._LICENSE)
    ggs.debug_print("Library license text:", "\n" .. ggs._LICENSE_TEXT)
    ggs.debug_print("-------------------------------------")

    ggs.debug_print("Check if love module exist.")

    if love == nil then
        error(".load_database: This library intended to be run in Love2D game framework. Make sure that you initilised \"love\" table before this library.")
    end

    ggs.debug_print("Check if filesystem module exist.")
    if love.filesystem == nil then
        error(".load_database: " .. ggs._NAME .. " can\'t function without love.filesystem module.")
    end

    ggs.debug_print("Sanitize path to ftcsv library.")
    if path_to_ftcsv == nil then
        path_to_ftcsv = "ftcsv"
    end

    if type(path_to_ftcsv) ~= "string" then
        error(".load_database: 1st argument should be string. You pass: " .. type(path_to_ftcsv))
    end

    ggs.debug_print("Try to load ftcsv library.")
    local ftcsv_ok, ftcsv = pcall(require, path_to_ftcsv)
    if not ftcsv_ok then
        error(".load_database: You passed path to ftcsv library that don't exist.\n" .. ftcsv)
    end

    ggs.debug_print("Sanitize database file path.")
    if path_to_database == nil then
        path_to_database = "/gamecontrollerdb.csv"
    end

    if type(path_to_database) ~= "string" then
        error(".load_database: 2nd argument should be string. You pass: " .. type(path_to_database))
    end

    ggs.debug_print("Try to check if file with database even exist.")
    local info_raw_database = love.filesystem.getInfo(path_to_database)

    if not info_raw_database then
        error(".load_database: You passed path to database file that don't exist.\n\"" .. path_to_database .. "\"")
    end
    ggs.debug_print("-------------------------------------")
    ggs.debug_print("Info about database file:", "Size: " .. tostring(info_raw_database.size))


    ggs.debug_print("Load raw database file as string from file.")
    local raw_database = love.filesystem.read(path_to_database)

    ggs.debug_print("Pass batabase string to ftcsv library.")
    local database = ftcsv.parse(raw_database, {loadFromString=true, headers=false})

    -- Link local database to in-library variable.
    ggs.database = database

    ggs.debug_print("Check database.")

    for i in ipairs(database) do
        -- Version line.
        if database[i][1] == "DatabaseVersion" then
            ggs.debug_print("Check where version line.")
            ggs.csv_line_where_version_of_database = i

            -- Remove "tag" value from table.
            table.remove(database[i], 1)
        end

        -- Database links line.
        if database[i][1] == "DatabaseLinks" then
            ggs.debug_print("Check where links line.")
            ggs.csv_line_where_links_to_database = i

            -- Remove "tag" value from table.
            table.remove(database[i], 1)
        end

        -- License info line.
        if database[i][1] == "DatabaseLicenseInfo" then
            ggs.debug_print("Check where license line.")
            ggs.csv_line_where_license_of_database_stored = i

            -- Remove "tag" value from table.
            table.remove(database[i], 1)
        end

        -- Detailed gamepad types line.
        if database[i][1] == "DetailedGamepadTypes" then
            ggs.debug_print("Check where detailed gamepad types line.")
            ggs.csv_line_where_detailed_types = i

            -- Remove "tag" value from table.
            table.remove(database[i], 1)
        end

        -- Simple gamepad types line.
        if database[i][1] == "SimpleGamepadTypes" then
            ggs.debug_print("Check where simple gamepad types line.")
            ggs.csv_line_where_simple_types = i

            -- Remove "tag" value from table.
            table.remove(database[i], 1)
        end

        -- Gamepads list line.
        if database[i][1] == "DummyGUID" then
            ggs.debug_print("Check where gamepads list starts.")
            ggs.csv_line_where_gamepads_list_starts = i

            break
        end

    end

    ggs.debug_print("Testing if all metadata okay.")

    ggs.debug_print("Test version metadata.")
    if not ggs.csv_line_where_version_of_database then
        error(".load_database: self-test failed! Can't locate version line!")
    end
    if not ggs.get_database_version() then
        error(".load_database: self-test failed! No version number!")
    end

    ggs.debug_print("Test database links metadata.")
    if not ggs.csv_line_where_links_to_database then
        error(".load_database: self-test failed! Can't locate database links line!")
    end
    if not ggs.get_link_to_repo_of_database() then
        error(".load_database: self-test failed! No link to database!")
    end
    if not ggs.get_link_to_file_of_database() then
        error(".load_database: self-test failed! No direct link to database file!")
    end

    ggs.debug_print("Test license metadata.")
    if not ggs.csv_line_where_version_of_database then
        error(".load_database: self-test failed! Can't locate license line!")
    end
    if not ggs.get_license_of_database() then
        error(".load_database: self-test failed! No license!")
    end
    if not ggs.get_license_text_of_database() then
        error(".load_database: self-test failed! No license text!")
    end

    ggs.debug_print("Test detailed gamepad types metadata.")
    if not ggs.csv_line_where_detailed_types then
        error(".load_database: self-test failed! Can't locate detailed gamepad types line!")
    end
    if not ggs.get_table_with_detailed_gamepad_types() then
        error(".load_database: self-test failed! No detailed gamepad types!")
    end

    ggs.debug_print("Test simple gamepad types metadata.")
    if not ggs.csv_line_where_simple_types then
        error(".load_database: self-test failed! Can't locate simple gamepad types line!")
    end
    if not ggs.get_table_with_simple_gamepad_types() then
        error(".load_database: self-test failed! No simple gamepad types!")
    end

    ggs.debug_print("Test gamepads list metadata.")
    if not ggs.csv_line_where_gamepads_list_starts then
        error(".load_database: self-test failed! Can't locate where gamepads lists starts line!")
    end
    if ggs.get_gamepads_database_size() < 0 then
        error(".load_database: self-test failed! No gamepads in list?")
    end

    ggs.debug_print("Finished testing metadata.")

    local detailed_types = ggs.get_table_with_detailed_gamepad_types()

    ggs.debug_print("Check if all gamepads has correct types and clean notes.")
    for i = ggs.csv_line_where_gamepads_list_starts, ggs.get_gamepads_database_size() do

        -- Check gamepad type in each gamepad entry.
        -- If I inputed wrong type, type that doesn't exist or made typo,
        -- then self-test SHOULD fail.
        local success = ggs.validate_gamepad_type(database[i][3])
        if not success then
            error(".load_database: self-test failed!\nLine " .. tostring(i) .. " has type " .. "\"" .. database[i][3] .. "\"" .. " which is incorrect type!")
        end

        -- Remove notes.
        database[i][4] = nil
    end

    -- Print about database.
    ggs.debug_print("-------------------------------------")
    ggs.debug_print("Print database info.")
    ggs.debug_print("Link to database repo:", ggs.get_link_to_repo_of_database())
    ggs.debug_print("Direct link to database file:", ggs.get_link_to_file_of_database())
    ggs.debug_print("Version of database:", ggs.get_database_version())
    ggs.debug_print("Amount of gamepads in database:", ggs.get_gamepads_database_size())
    ggs.debug_print("Amount of detailed gamepad types in database:", #ggs.get_table_with_detailed_gamepad_types())
    ggs.debug_print("Database license:", ggs.get_license_of_database())
    ggs.debug_print("Database license text:", "\n" .. ggs.get_license_text_of_database())
end


-- Simple pass gamepad GUID and it will check if passed GUID is in database.
-- If it is, then it will return type of detailed gamepad type AND true.
-- If GUID is not in database, it will return fallback gamepad type AND false.
-- Second return value is useful for doing checks like:
-- local type, success = ggs.guess_gamepad_by_guid("NonExistingGUID")
ggs.guess_gamepad_by_guid = function (guid_of_gamepad_in_question)
    -- Sanitize GUID.
    if guid_of_gamepad_in_question == nil or type(guid_of_gamepad_in_question) ~= "string" then
        error(".guess_gamepad_by_guid: 1st agrument should be string. You pass: " .. guid_of_gamepad_in_question)
    end

    -- Localize database for SPEED.
    local database = ggs.database

    -- Start from line where detailed gamepad types stored.
    for i = ggs.csv_line_where_gamepads_list_starts, #database do
        -- Yes, gamepad GUID is in database!
        if guid_of_gamepad_in_question == database[i][1] then
            return database[i][3], true
        end
    end

    -- Nope, database doesn't have this GUID.
    return ggs.fallback_gamepad_type, false
end

-- Simple pass gamepad name and it will check if passed name is in database.
-- If it is, then it will return type of detailed gamepad type AND true.
-- If name is not in database, it will return fallback gamepad type AND false.
-- Second return value is useful for doing checks like:
-- local type, success = ggs.guess_gamepad_by_name("SonyPS33")
ggs.guess_gamepad_by_name = function (name_of_gamepad_in_question)
    -- Sanitize name.
    if name_of_gamepad_in_question == nil or type(name_of_gamepad_in_question) ~= "string" then
        error(".guess_gamepad_by_guid: 1st agrument should be string, you give " .. name_of_gamepad_in_question)
    end

    -- Localize database for SPEED.
    local database = ggs.database

    for i = ggs.csv_line_where_gamepads_list_starts, #database do
        -- Yes, gamepad name is in database!
        if name_of_gamepad_in_question == database[i][2] then
            return database[i][3], true
        end
    end

    -- Nope, database doesn't have this name.
    return ggs.fallback_gamepad_type, false
end

-- Simplify family of gamepads to single string.
-- For example, passing "MicrosoftXBOX360" or "MicrosoftXBOXSeries" will both return "Microsoft".
-- Passing already simplified type, such as "Unknown" will return that simple type back (in this example, "Unknown").
-- Passing non-existing type will raise error.
ggs.simplify_type = function (type_to_simplify)
    if type_to_simplify == nil or type(type_to_simplify) ~= "string" then
        error(".simplify_type: 1st argument should be string. You pass: " .. type(type_to_simplify))
    end

    local succees = ggs.validate_gamepad_type(type_to_simplify)
    if not succees then
        -- Generate list of all possible types.
        error(".simplify_type: You passed type that don't exist in database: " .. type_to_simplify, 2)
    end
    local detailed_types = ggs.get_table_with_detailed_gamepad_types()
    local simple_types = ggs.get_table_with_simple_gamepad_types()

    for detailed_types_i = 1, #detailed_types do
        if type_to_simplify == detailed_types[detailed_types_i] then
            return simple_types[detailed_types_i]
        end
    end

    -- Most likely user passed simplified type. In this case, just return it back.
    return type_to_simplify
end

-- Function to validate if given type is existing one.
-- Return true if exist and false i doesn't.
-- Validate both simple and detailed types.
ggs.validate_gamepad_type = function (gamepad_type_to_validate)
    local detailed_types = ggs.get_table_with_detailed_gamepad_types()
    local simple_types = ggs.get_table_with_simple_gamepad_types()

    for i = 1, #detailed_types do
        -- Check detailed type.
        if detailed_types[i] == gamepad_type_to_validate then
            return true
        end

        -- Then simple.
        if simple_types[i] == gamepad_type_to_validate then
            return true
        end
    end

    -- Nope, seems user passed wrong gamepad type.
    return false
end

-- Will return table with detailed gamepad types that database has.
ggs.get_table_with_detailed_gamepad_types = function ()
    return ggs.database[ggs.csv_line_where_detailed_types]
end

-- Will return table with simplified gamepad types that database has.
ggs.get_table_with_simple_gamepad_types = function ()
    return ggs.database[ggs.csv_line_where_simple_types]
end

-- Function to get database version. Will return int.
-- This value will change if database format somehow will be changed.
ggs.get_database_version = function ()
    return tonumber(ggs.database[ggs.csv_line_where_version_of_database][1])
end

-- Will return int of size of database with all gamepads.
ggs.get_gamepads_database_size = function ()
    return #ggs.database - (ggs.csv_line_where_gamepads_list_starts - 1)
end

-- Gets link to repo where database is hosted.
ggs.get_link_to_repo_of_database = function ()
    return ggs.database[ggs.csv_line_where_links_to_database][1]
end

-- Gets direct link to file of database.
-- Might be useful, if you want to implement automatic database download system.
ggs.get_link_to_file_of_database = function ()
    return ggs.database[ggs.csv_line_where_links_to_database][2]
end

-- Gets license type of database.
-- Useful if you want to show it somewhere in-game screen.
ggs.get_license_of_database = function ()
    return ggs.database[ggs.csv_line_where_license_of_database_stored][1]
end

-- Gets license text of database.
-- Useful if you want to show it somewhere in-game screen.
ggs.get_license_text_of_database = function ()
    return ggs.database[ggs.csv_line_where_license_of_database_stored][2]
end

return ggs
