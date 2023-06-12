local QLibrary = require "Qlearning"

local params = {...}

if (#params ~= 3 ) then
  print("You must specify exactly three parameters:\n" ..
    " - the filename of the new Q-table;\n" ..
    " - the number of states;\n" ..
    " - the number of actions;\n")
  print("(ex: ../data/Qtable.csv 1024 4)")
  os.exit()
end

local filename = params[1]
local states = tonumber(params[2])
local actions = tonumber(params[3])

local qTable = QLibrary.create_Q_table(states,actions)
QLibrary.save_Q_table(filename, qTable)
