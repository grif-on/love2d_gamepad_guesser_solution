-- BEFORE RUNNING THIS EXAMPLE, MAKE SURE THAT YOU PLACED THIS FILES IN ROOT DIRECTORY OF THIS EXAMPLE!!!!!!
-- ftcsv.lua gamecontrollerdb.csv gamepad_guesser_solution.lua
--
-- Slightly more elaborated example of how this library can be used.
-- Here I will show you:
-- * how to change icon based on type of last connected gamepad,
-- * how you can exclude gamepad types that you don't want to support,
-- * why you might want to simplify types
-- * and slightly more.
--
-- Some things were ommited in example for laziness purposes, so you would need
-- to figure out them by yourself, sorry! (Maybe I'll extend this manual in Future(TM).
-- Things like:
-- * change icons when gamepad buttons were pressed (for example, if user has 2 connected gamepads
-- and you want to show icons for gamepad that was last "active")
-- * How to cache results with gamepads (love has function https://love2d.org/wiki/Joystick:getID, it will assign
-- unique ID for each connected and disconnected gamepad during game runtime, which allow you to simple store
-- gamepad type in variable instead of re-checking gamepad every time when new gamepad connected)
-- * Some optimization tips. (Implementation of database is quite simple for developement purposes, but this resulted in
-- not that optimized code. For example, entire database always stored in memory and library don't do anything with it ever,
-- or that library simple for looping entire database when you asking it to guess gamepad type by GUID or name; And
-- at moment of writing this, there around +2k of gamepads! So if you targeting low end devices, this implementation (or database in general)
-- might be not the best decision).
-- * And more.
local gamepad_guesser_solution = require("gamepad_guesser_solution")

gamepad_guesser_solution.load_database()
-- Let's setup fallback type.
-- Since we will operate on simple types, rather then detailed,
-- we will use "Microsoft" as fallback (which is simple type for all XBOX gamepads).
gamepad_guesser_solution.fallback_gamepad_type = "Microsoft"

-- Here will be stored icons for all gamepad types that we will support.
local icons = {}
-- Make currently connected gamepad type as fallback until we will guess type.
local current_gamepad_type = gamepad_guesser_solution.fallback_gamepad_type
-- Current gamepad, used to show GUID and name for visualisation purposes.
local current_gamepad = nil
-- Just list of currently connected gamepads.
local joysticks = {}

-- Our main helper function that will do actual guessing.
local check_gamepad_type = function (joystick)
    -- Seems that no joysticks, so let's return fallback type
    if joystick == nil then
        current_gamepad_type = gamepad_guesser_solution.fallback_gamepad_type
        return
    end

    -- Let's start guessing with GUID.
    local gamepad_type, success = gamepad_guesser_solution.guess_gamepad_by_guid(joystick:getGUID())

    -- If it will found GUID in database, then good!
    -- If it doesn't, let's try guess via name.
    if not success then
        gamepad_type, success = gamepad_guesser_solution.guess_gamepad_by_name(joystick:getName())

        -- It it still can't found gamepad, then sorry!
        -- Fallback type will be used instead.
        -- Please, report your missing gamepad to repo, thanks!
    end

    -- Now, in our example, we want to support only 3 icon sets:
    -- PS4, XBOX One, Nintendo Switch.
    -- And we want to show PS4 icons for any PlayStation device (e.g PS3, PS4 or PS5)
    -- XBOX One icons for any XBOX gamepad (e.g XBOX 360, XBOX One or XBOX Series)
    -- Nintendo Switch icons for any nintendo device (e.g Nintendo Switch, Game Cube, Wii, etc)
    -- And XBOX One icons for everyone else as fallback.
    -- To achieve this, first, we can (and should in our case) simplify types.
    -- It will allow us to label entire gamepad families to single string
    -- For example, any PlayStation gamepad become simple "Sony".
    gamepad_type = gamepad_guesser_solution.simplify_type(gamepad_type)

    -- Now that we simplified types, we want to exclude type that we don't want to support.
    -- Yet again, you probably could automate this based on directory items where you store images for icons,
    -- But I'm lazy so I will input list by hand.
    if (gamepad_type ~= "Sony" or gamepad_type ~= "Microsoft" or gamepad_type ~= "Nintendo") then

    else
        -- We will return fallback gamepad type.
        gamepad_type = gamepad_guesser_solution.fallback_gamepad_type
    end

    -- Done!
    -- Now we can safely return type back!
    current_gamepad_type = gamepad_type
end

-- We will check gamepad type of latest connected gamepad.
love.joystickadded = function (joystick)
    joysticks = love.joystick.getJoysticks()
    -- Pass latest connected gamepad to guesser helper function.
    for i in ipairs(joysticks) do
        if joysticks[i] == joystick then
            check_gamepad_type(joysticks[i])
        end
    end
    current_gamepad = joystick
end

-- If gamepad was removed, then we will check latest one in list
-- And if no gamepads left, then we will use fallback one.
love.joystickremoved = function (joystick)
    -- If there no joysticks left, then tels pass nothing to helper function
    -- so it will correctly return fallback type.
    joysticks = love.joystick.getJoysticks()

    if #joysticks <= 0 then
        check_gamepad_type(nil)
        current_gamepad = nil
    -- If we still have more then 0 gamepads connected
    -- then lets pick latest connected one.
    else
        check_gamepad_type(joysticks[#joysticks])
        current_gamepad = joysticks[#joysticks]
    end

end

love.load = function ()
    joysticks = love.joystick.getJoysticks()

    -- Of course, you can use love.filesystem.getDirectoryItems to automate adding new icons for types,
    -- by simple throwing images into folder, but I'm lazy. Sotty.
    icons.Microsoft = love.graphics.newImage("/assets/Microsoft.png")
    icons.Sony = love.graphics.newImage("/assets/Sony.png")
    icons.Nintendo = love.graphics.newImage("/assets/Nintendo.png")
end

love.draw = function ()
    -- Let's draw things!
    -- If we have connected gamepad, let's print it's name and GUID
    if current_gamepad ~= nil then
        love.graphics.print("Current gamepad name: " .. current_gamepad:getName(), 100, 30)
        love.graphics.print("Current gamepad GUID: " .. current_gamepad:getGUID(), 100, 50)
    else
        -- If there no currently connected gamepads, then let's use know abou this.
        love.graphics.print("Current gamepad name: none, using fallback type.", 100, 30)
    end

    -- Let's print in text form type of gamepad.
    love.graphics.print("Current gamepad type: " .. current_gamepad_type, 100, 70)

    -- LEt's finally draw icon for our gamepad type!
    love.graphics.draw(icons[current_gamepad_type], 100, 100)
end