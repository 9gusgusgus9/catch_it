-- Put your global variables here

MOVE_STEPS = 15
MAX_VELOCITY = 10
LIGHT_THRESHOLD = 1.5
TIME_TO_SWITCH = 50
RANGE_MIN = 19
Status = {HERO = 0, ENEMY = 1, BECOMING_ENEMY = 2}

n_steps = 0
left_v = 0
right_v = 0
local L = robot.wheels.axis_length
local vector = require "vector"
local my_status
local time_from_last_switch = -50

--[[ This function is executed every time you press the 'execute'
     button ]]
function init()
    if robot.id == "fb1" then
        my_status = Status.HERO
    else
        my_status = Status.ENEMY
    end
    reset()
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
        robot.range_and_bearing.set_data(1, 0)

        vec_catch = vector_catch_it()
        vec_catch.length = 5

        vec = vector_avoid_ostacles_exclude_target()
        vec.length = vec.length * 10
        vec = vector.vec2_polar_sum(vec, vec_catch)
        
        if vec.length > 0 then
            --log("vec.length = " .. vec.length .. " vec.angle = " .. vec.angle)
            setVelocity(from_vector_to_velocities(vec))
        else
            goRandom()
        end

        if robot.range_and_bearing[1] ~= nil then
            if robot.range_and_bearing[1].range < RANGE_MIN then
                switch_status()
                time_from_last_switch = n_steps
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
	logStats()
end

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
    goRandom()
    n_steps = 0
    robot.leds.set_all_colors("black")
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
end
