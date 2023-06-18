-- Put your global variables here

MOVE_STEPS = 3
MAX_VELOCITY = 10
FILENAME = "./Qtable-catch_it.csv"
LIGHT_THRESHOLD = 1.5
TIME_TO_SWITCH = 50
RANGE_MIN = 19
Status = {HERO = 0, ENEMY = 1, BECOMING_ENEMY = 2}

n_steps = 0
left_v = 0
right_v = 0
local L = robot.wheels.axis_length
local vector = require "vector"
local Qlearning = require "Qlearning"
local my_status
local time_from_last_switch = -50
local states =  {}

--[[ This function is executed every time you press the 'execute'
     button ]]
function init()
    total_state_acquisition = 0
    on_catching_acquisition = 0


	local vel = {left = robot.random.uniform(0, MAX_VELOCITY), right = robot.random.uniform(0, MAX_VELOCITY)}

    alpha = 0.1
    gamma = 0.9
    epsilon = 0.9
    k = 2

    state = old_state
    action = 0

    --States: one state for each degree of the circle
    angle_states = { -157.5, -135, -112.5, -90, -67.5, -45, -22.5, 0, 22.5, 45, 67.5, 90, 112.5, 135, 157.5, 180 }
    distance_states = { 30, 60, 90, 120, 150, 180, 210, 240, 270, 300}
    number_of_states = #angle_states * #distance_states
    
    counter = 1
    for i = 1, #angle_states do
        local states_distance = {}
        for j = 1, #distance_states do
            states_distance[j] = counter
            counter = counter + 1
        end
        states[i] = states_distance
    end


    --Actions: 8 in total
    -- Threre is no symmetry: a vector direction cannot be cancelled by a opposite vector.
    -- In this way we avoid stupid behaviours such that go forward and then immediately backward.
    velocity_direction_names = {"N", "NW", "W", "SW", "S", "SE", "E", "NE"}
    velocity_directions = {
        ["N"] = 0,
        ["NW"] = math.pi / 4, -- 45 degree
        ["W"] = math.pi / 2, -- 90 degree
        ["SW"] = 3 * math.pi / 4, -- 135 degree
        ["S"] = math.pi, -- 180 degree
        ["SE"] = - 3 * math.pi / 4, -- -135 degree
        ["E"] = - math.pi / 2, -- -90 degree
        ["NE"] = - math.pi / 4, -- -45 degree
    }

    number_of_actions = #velocity_direction_names

    Q_table = {}

    -- Dimension: 160 x 8 = 1280
    Q_table = Qlearning.load_Q_table(FILENAME)

    setVelocity(vel)

    if robot.id == "fb0" then
        my_status = Status.HERO
    else
        my_status = Status.ENEMY
    end
    reset()
end

function get_index_of_state(state)
    local index_ang = 0
    for i = 1, #angle_states do
        if state.angle <= angle_states[i] then
            index_ang = i
            break
        end
    end
    for i = 1, #distance_states do
        if state.range <= distance_states[i] then
            index_dist = i
            break
        end
    end

    return states[index_ang][index_dist]
end

function competenceNegative()
    local velocity = {left = robot.random.uniform(0, MAX_VELOCITY), right = robot.random.uniform(0, MAX_VELOCITY)}
    return velocity
end

function competencePositive()
    function action_to_velocity(action)

        function limit_v(vel)

            function limit(value)
                if value > MAX_VELOCITY then
                    return MAX_VELOCITY
                elseif value < -MAX_VELOCITY then
                    return -MAX_VELOCITY
                else
                    return value
                end
            end

            return {left = limit(vel.left), right = limit(vel.right)}
        end
        local angle = velocity_directions[velocity_direction_names[action]]
        local vel = {left = 0, right = 0}
        vel.left = MAX_VELOCITY - (angle * L / 2)
        vel.right = MAX_VELOCITY + (angle * L / 2)
        vel = limit_v(vel)

        return {left = vel.left * robot.random.uniform(0.9, 1), right = vel.right * robot.random.uniform(0.9, 1)}
    end

    function get_state()
        --States goes from -1 (i don't see the other robot) to 359
        local new_state = {angle = 0, range = -1}
        if robot.range_and_bearing[1] ~= nil then
            new_state.range = robot.range_and_bearing[1].range
            new_state.angle = robot.range_and_bearing[1].horizontal_bearing
            new_state.angle = math.floor(math.deg(new_state.angle))
        end
        return new_state
    end

    local state = get_state()
    local index = get_index_of_state(state)
    local action = Qlearning.get_best_action(index, Q_table)
    log("action: " .. velocity_direction_names[action] .. " index: " .. index .. " state: " .. state.angle .. " " .. state.range)
    local subsumption = true

    total_state_acquisition = total_state_acquisition + 1

    if state.range == -1 then
        subsumption = false
    else
        on_catching_acquisition = on_catching_acquisition + 1
    end
    
    return subsumption, action_to_velocity(action)

end

function switch_status()
    if my_status == Status.HERO then
        time_from_last_switch = n_steps
        my_status = Status.BECOMING_ENEMY
    elseif my_status == Status.ENEMY then
        my_status = Status.HERO
    end
end

--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
	-- Set the robot led on if it is close to the light
	n_steps = n_steps + 1

    if my_status == Status.BECOMING_ENEMY then
        robot.leds.set_all_colors("yellow")
        setVelocity({left = 0, right = 0})
        if time_from_last_switch + TIME_TO_SWITCH < n_steps then
            my_status = Status.ENEMY
        end
    elseif my_status == Status.ENEMY then
        robot.leds.set_all_colors("red")
        if n_steps % MOVE_STEPS == 0 then

            velNegative = competenceNegative()
            subsumption, velPositive = competencePositive()

            if subsumption then
                setVelocity(velPositive)
            else
                setVelocity(velNegative)
            end
        end
        if robot.range_and_bearing[1] ~= nil then
            if robot.range_and_bearing[1].range < RANGE_MIN  and time_from_last_switch + TIME_TO_SWITCH < n_steps then
                switch_status()
            end
        end
    else
        robot.leds.set_all_colors("green")
        robot.range_and_bearing.set_data(1, 0)

        vec_get_out = vector_get_out()
        vec_get_out.length = 5
        
        vec = vector_avoid_obstacles_force_enemy()
        vec.length = vec.length * 10
        vec = vector.vec2_polar_sum(vec, vec_get_out)
        
        if vec.length > 0 then
            setVelocity(from_vector_to_velocities(vec))
        else
            goRandom()
        end
        if robot.range_and_bearing[1] ~= nil then
            if robot.range_and_bearing[1].range < RANGE_MIN  and time_from_last_switch + TIME_TO_SWITCH < n_steps then
                log(robot.id .. ": ho preso l'altro robot")
                switch_status()
            end
        end
    end

	-- Log the stats of the robot
	-- logStats()
end

--This function return the best way for the enemy
function vector_catch_it()
	vec = {length = 0, angle = 0}
    if robot.range_and_bearing[1] ~= nil then
        vec.length = robot.range_and_bearing[1].range
        vec.angle = robot.range_and_bearing[1].horizontal_bearing
    end
    return vec
end


function vector_get_out()
	vec = {length = 0, angle = 0}
    if robot.range_and_bearing[1] ~= nil then
        vec.length = robot.range_and_bearing[1].range
        vec.angle = robot.range_and_bearing[1].horizontal_bearing
        if vec.angle > 0 then
            vec.angle = vec.angle - math.pi
        else
            vec.angle = vec.angle + math.pi
        end
    end
	return vec
end

function vector_avoid_obstacles_force_enemy()
	vec = {length = 0, angle = 0}
    enemy = vector_get_out()
    enemy.length = 0.5
	for i=1,#robot.proximity do
		ang = robot.proximity[i].angle
		if ang > 0 then
			ang = ang - math.pi
		else
			ang = ang + math.pi
		end
		vec = vector.vec2_polar_sum(vec, {length = robot.proximity[i].value, angle = ang})
	end
    
    vec = vector.vec2_polar_sum(vec, enemy)
	return vec
end

function vector_avoid_ostacles_exclude_target()
    vec = {length = 0, angle = 0}
    target = vector_catch_it()
    target.length = 0.5
    for i=1,#robot.proximity do
        ang = robot.proximity[i].angle
        if ang > 0 then
            ang = ang - math.pi
        else
            ang = ang + math.pi
        end
        vec = vector.vec2_polar_sum(vec, {length = robot.proximity[i].value, angle = ang})
    end

    vec = vector.vec2_polar_sum(vec, target)
    return vec
end


function from_vector_to_velocities(vec)
	local vel = { left = 0, right = 0}
	vel.left = vec.length  + (-L/2) * vec.angle
	vel.right = vec.length + (L/2) * vec.angle
	return vel
end

function goRandom()
	vel = {left = 0, right = 0}
	vel.left = robot.random.uniform(0,MAX_VELOCITY)
	vel.right = robot.random.uniform(0,MAX_VELOCITY)
	setVelocity(vel)
end

function setVelocity(vel)
	robot.wheels.set_velocity(vel.left,vel.right)
end

function logStats()
    if robot.range_and_bearing[1] ~= nil then
        log("robot.range_and_bearing[1].data[1] = " .. robot.range_and_bearing[1].data[1])
        log("robot.range_and_bearing[1].horizontal_bearing = " .. robot.range_and_bearing[1].horizontal_bearing)
        log("robot.range_and_bearing[1].range = " .. robot.range_and_bearing[1].range)
    end
end

--[[ This function is executed every time you press the 'reset'
 button in the GUI. It is supposed to restore the state
 of the controller to whatever it was right after init() was
 called. The state of sensors and actuators is reset
 automatically by ARGoS. ]]
function reset()
    vel = {left = 0, right = 0}
    setVelocity(vel)
    n_steps = 0
    robot.leds.set_all_colors("black")
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here

   
end
