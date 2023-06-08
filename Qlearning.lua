--- Q-learning library for lua.
-- A simple library for didactical porpuses.
--
-- @author Magnini Matteo.
-- June, 2020.


local q = {}
local calculator = require "extended_math"

--- Create Q table initialized with zeros.
--
-- @param number_of_states the cardinality of all possible states.
-- @param number_of_actions the cardinality of all possible actions.
-- @return a Q table with the specified dimention and all values equal to zero.
function q.create_Q_table(number_of_states, number_of_actions)

  assert(number_of_states > 1, "Invalid argument: number of states must be greater than 1.")
  assert(number_of_actions > 1, "Invalid argument: number of actions must be greater than 1.")
  local Q_table = {}
  for i = 1, number_of_states do
    Q_table[i] = {}
    for j = 1, number_of_actions do
      Q_table[i][j] = 0
    end
  end
  
  return Q_table
  
end

--- Save the Q table into a csv file.
--
-- @param file_name the name of the new file (could include path).
-- @param Q_table the table to be saved.
function q.save_Q_table(file_name, Q_table)

  local file = assert(io.open(file_name, "w"), "Impossible to create the file " .. file_name .. " .")
  for i = 1, #Q_table do
    file:write(Q_table[i][1])
    for j = 2, #Q_table[1] do
      file:write(", " .. Q_table[i][j])
    end
    file:write("\n")
  end
  file:close()
  
end

--- Load Q table from a csv file.
--
-- @param file_name the name of an existing file (could include path).
-- @return the Q table.
function q.load_Q_table(file_name)

  local file = assert(io.open(file_name, "r"), "Impossible to open the file " .. file_name .. " .")
  local Q_table = {}
  local i = 1
  for line in file:lines() do
    Q_table[i] = {}
    local j = 1
    for value in line:gmatch("([^,%s]+)") do
      Q_table[i][j] = tonumber(value)
      j = j + 1
    end
    i = i + 1
  end
  file:close()
  
  return Q_table

end

--- Get best action from current state.
--
-- @param state the current state of the agent.
-- @param Q_table the Q table.
-- @return the index of the action with the greatest value.
function q.get_best_action(state, Q_table)
  
  return calculator.argmax(Q_table[state])
  
end

--- Update the Q table.
-- @warning in this function is used table.unpuck, for previous version of lua change it with only unpack.
--
-- @param alpha the learning rate, it must be from 0 (no update) to 1 (no memory).
-- @param gamma the discount factor, it must be from 0 (only immidiate reward) to 1 (all future reward).
-- @param state the starting state.
-- @action the chosen action.
-- @future_state the resulting state of the action in the previous state.
-- @Q_table the Q table.concat
-- @return the updated Q table.
function q.update_Q_table(alpha, gamma, state, action, reward, future_state, Q_table)
  
  assert(alpha <= 1, "Invalid argument: alpha must be lower or equal to 1.")
  assert(alpha >= 0, "Invalid argument: alpha must be greater or equal to 0.")
  assert(gamma <= 1, "Invalid argument: gamma must be lower or equal to 1.")
  assert(gamma >= 0, "Invalid argument: gamma must be greater or equal to 0.")

  Q_table[state][action] = (1-alpha) * Q_table[state][action] + alpha * (reward + gamma * math.max(table.unpack(Q_table[future_state])))
  return Q_table
  
end


--- Get an action randomly with probability epsylon, otherwise choose the one with the gratest value.
--
-- @param epsilon the probability of peeking a random action, it must be from 0 (never random) to 1 (always random).
-- @param state the current state of the agent.
-- @param Q_table the Q table.concat
-- @return the selected action.
function q.get_random_action(epsilon, state, Q_table)

  assert(epsilon <= 1, "Invalid argument: epsilon must be lower or equal to 1.")
  assert(epsilon >= 0, "Invalid argument: epsilon must be greater or equal to 0.")

  local action = 1
  if (math.random() < epsilon) then
    action = math.random(#Q_table[1])
  else
    action = q.get_best_action(state, Q_table)
  end
  
  return action

end

--- Get an action with weighted selection.
--
-- @param k how strong the selection favours actions with hihg Q table value, must be grater or equal to 1.
-- @param state the current state of the agent.
-- @param Q_table the Q table.concat
-- @return the selected action.
function q.get_weighted_action(k, state, Q_table)

  assert(k >= 1, "Invalid argument: k must be greater or equal to 1.")
  local action = 1
  local probabilities = {}
  local normalization = 0
  
  for i = 1, #Q_table[1] do
    normalization = normalization + math.pow(k, Q_table[state][i])
  end
  
  for i = 1, #Q_table[1] do
    probabilities[i] = math.pow(k, Q_table[state][i]) / normalization
  end
  
  return calculator.weighted_selection(probabilities)

end


return q