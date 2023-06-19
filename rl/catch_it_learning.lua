-- Put your global variables here

MOVE_STEPS = 3
MAX_VELOCITY = 20
FILENAME = "Qtable-catch-it.csv"
TIME_TO_SWITCH = 50
RANGE_MIN = 19
Status = {HERO = 0, ENEMY = 1, BECOMING_ENEMY = 2}

n_steps = 0
vel = {left = 0, right = 0}
local L = robot.wheels.axis_length
local vector = require "vector"
local Qlearning = require "Qlearning"
local my_status
local time_from_last_switch = -50

--[[ This function is executed every time you press the 'execute'
     button ]]
function init()
	local vel = {left = 0, right = 0}

    alpha = 0.1
    gamma = 0.9
    epsilon = 0.9
    k = 2

    old_state = get_state()
    state = old_state
    action = 3

    --States: 160 in total (16 angle states * 10 distance states)
    angle_states = { -157.5, -135, -112.5, -90, -67.5, -45, -22.5, 0, 22.5, 45, 67.5, 90, 112.5, 135, 157.5, 180 }
    distance_states = {  30, 60, 90, 120, 150, 180, 210, 240, 270, 300}
    number_of_states = #angle_states * #distance_states

    --Actions: 8 in total
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

    robot.wheels.set_velocity(vel.left, vel.right)

    if robot.id == "fb0" then
        my_status = Status.HERO
    else
        my_status = Status.ENEMY
        Q_table = Qlearning.load_Q_table(FILENAME)
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

    return (((index_ang - 1) * #distance_states) + index_dist)
end


function get_state()
    --States goes from 1 to 160 (all the combinations of angle and distance)
    local new_state = {angle = 0, range = -1}

    if robot.range_and_bearing[1] ~= nil then
        new_state.range = robot.range_and_bearing[1].range
        new_state.angle = robot.range_and_bearing[1].horizontal_bearing
        new_state.angle = math.floor(math.deg(new_state.angle))
    end
    return new_state
end

function get_reward(state, old_state)
    if state.range == -1 then
        --If i don't see the hero
        return 0
    elseif state.range < RANGE_MIN then
        --If i touch the hero
        return 1
    else
        if (state.angle > 0 and old_state.angle > 0) or (state.angle < 0 and old_state.angle < 0) then
            --If I'm entering the goal towards my center, calculate the difference from old state angle and new state angle normalazite to 0 and 0.66
            angle_reward = (math.abs(state.angle) - math.abs(old_state.angle)) / 540
        elseif state.angle == 0 then
            -- If the hero is in front of me i take the max reward for the angle
            angle_reward = 0.66
        elseif state.angle < 10 and state.angle > -10 then
            -- If the hero is in front of me i take 0.65 reward for the angle
            angle_reward = 0.65
        else
            -- Else 0
            angle_reward = 0
        end
        -- Calculate the difference from old state distance and new state distance normalazite to 0 and 0.33
        distance_reward = (state.range - old_state.range) / 900
        if angle_reward < 0 then
            angle_reward = 0
        end
        if distance_reward < 0 then
            distance_reward = 0
        end
        -- Reward calculated as the sum of the two rewards (66% angle reward + 33% distance reward)
        return angle_reward + (2*distance_reward)
    end
end

function perform_action(action)

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

    local vel = {left = 0, right = 0}
    local angle = velocity_directions[velocity_direction_names[action]]
    vel.left = MAX_VELOCITY - (angle * L / 2)
    vel.right = MAX_VELOCITY + (angle * L / 2)

    setVelocity(limit_v(vel))
end

function switch_status()
    time_from_last_switch = n_steps
    if my_status == Status.HERO then
        my_status = Status.BECOMING_ENEMY
    elseif my_status == Status.ENEMY then
        my_status = Status.HERO
        Qlearning.save_Q_table(FILENAME, Q_table)
    end
end

function step()
	n_steps = n_steps + 1

    if my_status == Status.BECOMING_ENEMY then
        robot.leds.set_all_colors("yellow")
        setVelocity({left = 0, right = 0})
        if time_from_last_switch + TIME_TO_SWITCH < n_steps then
            my_status = Status.ENEMY
            Q_table = Qlearning.load_Q_table(FILENAME)
        end
    elseif my_status == Status.ENEMY then
        robot.leds.set_all_colors("red")
        robot.range_and_bearing.set_data(1, 0)
        if n_steps % MOVE_STEPS == 0 then
            state = get_state()
            old_state_index = get_index_of_state(old_state)
            state_index = get_index_of_state(state)


            reward = get_reward(state, old_state)
            Q_table = Qlearning.update_Q_table(alpha, gamma, old_state_index, action, reward, state_index, Q_table)

            action = Qlearning.get_random_action(epsilon, state_index, Q_table)
            perform_action(action)

            old_state = state
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
                switch_status()
            end
        end
    end

	-- Log the stats of the robot
	--logStats()
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
    action = 3
    setVelocity(vel)
    n_steps = 0
    robot.leds.set_all_colors("black")
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
    if my_status == Status.ENEMY then
        Qlearning.save_Q_table(FILENAME, Q_table)
    end
end
