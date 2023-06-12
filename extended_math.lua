
local calculator = {}

--- Get the argmax of a table.
--
-- @param arry the table.
-- @return the index of the gratest value.
function calculator.argmax(array)

  local max_index = 1
  local max_value = - math.huge
  for i = 1, #array do 
    if (array[i] > max_value) then
      max_value = array[i]
      max_index = i
    end
  end

  return max_index

end

--- Get a random element with weighted selection.
-- Function based on https://rosettacode.org/wiki/Probabilistic_choice#Lua
--
-- @param map a map with elements as keys and probabilities as values.
-- @return the selected element.
function calculator.weighted_selection(map)

  local probability = math.random()
  local element = 0
  
  for k, v in pairs(map) do
    if probability < v then
        element = k
        break;
    else
        probability = probability - v
    end
  end
  
  return element

end


return calculator