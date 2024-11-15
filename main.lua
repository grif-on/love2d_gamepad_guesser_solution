-- This is quick demo and test for library.
-- For this file to run correctly, you should connect any gamepad, otherwise it will stop with error.
print("-------------------------------------")
print("Require gamepad guesser library...")
local gamepad_guesser_solution = require("gamepad_guesser_solution")
print("Turn on library debug info printing.")
gamepad_guesser_solution.debug = true

print("Loading database...")
gamepad_guesser_solution.load_database()

print("-------------------------------------")
print("Fallback gamepad type:", gamepad_guesser_solution.fallback_gamepad_type)
print("-------------------------------------")
print("Get info about gamepad in 1st slot.")

local gamepad = love.joystick.getJoysticks()[1]
if not gamepad then
    local error_text = "There no gamepad in slot 1, error!"
    print(error_text)
    error(error_text)
end
print("GUID:", gamepad:getGUID())
print("Name:", gamepad:getName())
print("-------------------------------------")
print("Guess gamepad type by GUID value.")
local gamepad_type, success = gamepad_guesser_solution.guess_gamepad_by_guid(gamepad:getGUID())
if not success then
    print("Seems there is no GUID of this gamepad in database.\nPlease, report your gamepad to", gamepad_guesser_solution._DATABASE_REPO)
    print("Fallback gamepad type is used.")
else
    print("Success!")
end
print("Guessed gamepad type:", gamepad_type)
print("-------------------------------------")
print("Guess gamepad type by name value.")
gamepad_type, success = gamepad_guesser_solution.guess_gamepad_by_name(gamepad:getName())
if not success then
    print("Seems there is no name of this gamepad in database.\nPlease, report your gamepad to", gamepad_guesser_solution._DATABASE_REPO)
    print("Fallback gamepad type is used.")
else
    print("Success!")
end
print("Guessed gamepad type:", gamepad_type)
print("-------------------------------------")
print("List all gamepad types and test simplifing function.")
local gamepad_types_database = gamepad_guesser_solution.get_table_with_detailed_gamepad_types()
for i_of_type in ipairs(gamepad_types_database) do
    print(gamepad_types_database[i_of_type], "->", gamepad_guesser_solution.simplify_type(gamepad_types_database[i_of_type]))
end
-- Should return "Sega"
print("Test passing simplified type:", gamepad_guesser_solution.simplify_type("Sega"))
print("-------------------------------------")

love.draw = function ()
    love.graphics.print("Check terminal output.")
end