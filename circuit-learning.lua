-- Put your global variables here.

MOVE_STEPS = 5
MAX_VELOCITY = 5
FILENAME = "Qtable-circuit.csv"
WHEEL_DIST = -1

n_steps = 0


--- This function is executed every time you press the 'execute' button.
function init()

  Qlearning = require "Qlearning"
	
	WHEEL_DIST = robot.wheels.axis_length
  
  -- First action is to go forward.
	local left_v = MAX_VELOCITY
	local right_v = MAX_VELOCITY
  
  alpha = 0.1
  gamma = 0.9
  epsilon = 0.9
  k = 2
  
  old_state = get_state()
  state = old_state
  action = 3
  
  -- States: each direction can be 0 or 1, a state is a combination of those.
  -- So in total the states are 2^8 = 256.
  sensor_direction_names = {"N", "NW", "W", "SW", "S", "SE", "E", "NE"}
  number_of_states = math.pow(2, #sensor_direction_names)
  
  -- Actions: 5 in total
  -- Threre is no symmetry: a vector direction cannot be cancelled by a opposite vector.
  -- In this way we avoid stupid behaviours such that go forward and then immediately backward.
  velocity_direction_names = {"WNW", "NNW", "N", "NNE", "ENE"}
  velocity_directions = {
    ["WNW"] = math.pi / 4, -- 45 degree
    ["NNW"] = math.pi / 8, -- 22.5 degree
    ["N"] = 0,
    ["NNE"] = - math.pi / 8, -- -22.5 degree
    ["ENE"] = - math.pi / 4, -- -45 degree
  }
  
  number_of_actions = #velocity_direction_names
  
  Q_table = {}
  
  -- Dimension: 256 x 5 = 1280 values.
  Q_table = Qlearning.load_Q_table(FILENAME)
  
	robot.wheels.set_velocity(left_v,right_v)
  
end

function get_state()
  
  -- State goes from 1 to 256.
  -- 1 equals that all sensors are 1.
  local new_state = 1
  
  for i = 1, #robot.base_ground do
    if robot.base_ground[i].value == 0 then new_state = new_state + math.pow(2,i-1) end
  end
  
  return new_state
  
end

function get_reward()

  local black_sensors = 0
  
  for i = 1, #robot.base_ground do
    if robot.base_ground[i].value == 0 then black_sensors = black_sensors + 1 end
  end
  
  return math.pow(black_sensors/#robot.base_ground, 2)

end

function perform_action(action)
  
  -- Ensure not to exceed MAX_VELOCITY
  function limit_v(left_v, right_v)

    function limit(value)
      if (value > MAX_VELOCITY) then
        value = MAX_VELOCITY
      end
      
      if (value < - MAX_VELOCITY) then
        value = - MAX_VELOCITY
      end

      return value
    end
    
    return limit(left_v), limit(right_v)

  end
  
  local angle = velocity_directions[velocity_direction_names[action]]
  local left_v = MAX_VELOCITY - (angle * WHEEL_DIST / 2)
  local right_v = MAX_VELOCITY + (angle * WHEEL_DIST / 2)
  
  left_v, right_v = limit_v(left_v, right_v)
  
  robot.wheels.set_velocity(left_v,right_v)
  
end

--- This function is executed at each time step.
-- It must contain the logic of your controller.
function step()
	n_steps = n_steps + 1
  
	if n_steps % MOVE_STEPS == 0 then
    
    -- Update
    state = get_state()
    Q_table = Qlearning.update_Q_table(alpha, gamma, old_state, action, get_reward(), state, Q_table)

    -- Perform action
    action = Qlearning.get_random_action(epsilon, state, Q_table)
    --action = Qlearning.get_weighted_action(k, old_state, Q_table)
    perform_action(action)
    old_state = state

  end
 
end


--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the state
     of the controller to whatever it was right after init() was
     called. The state of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
	local left_v = MAX_VELOCITY
	local right_v = MAX_VELOCITY
  action = 3
	robot.wheels.set_velocity(left_v,right_v)
	n_steps = 0
end


--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
   
   Qlearning.save_Q_table(FILENAME, Q_table)
   
end
