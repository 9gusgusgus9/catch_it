-- Put your global variables here

MOVE_STEPS = 15
MAX_VELOCITY = 10
LIGHT_THRESHOLD = 1.5


n_steps = 0
left_v = 0
right_v = 0
local L = robot.wheels.axis_length
local vector = require "vector"

--[[ This function is executed every time you press the 'execute'
     button ]]
function init()
	reset()
end



-- This function set the velocity of the wheels to a random value
function goRandom()
	vel = {left = 0, right = 0}
	vel.left = robot.random.uniform(0,MAX_VELOCITY)
	vel.right = robot.random.uniform(0,MAX_VELOCITY)
	setVelocity(vel)
end

function setVelocity(vel)
	robot.wheels.set_velocity(vel.left,vel.right)
end

function vector_catch_it()
	vec = {length = 0, angle = 0}
	return vec;
end

function vector_get_out()
	vec = {length = 0, angle = 0}
	return vec;
end

function from_vector_to_velocities(vec)
	local vel = { left = 0, right = 0}
	vel.left = vec.length  + (-L/2) * vec.angle
	vel.right = vec.length + (L/2) * vec.angle
	return vel
end

-- This method print the stats of the robot
function logStats()
	-- log("robot.position.x = " .. robot.positioning.position.x)
	-- log("robot.position.y = " .. robot.positioning.position.y)
	-- log("robot.position.z = " .. robot.positioning.position.z)
	
	
	-- light_front = robot.light[1].value + robot.light[24].value
	-- log("robot.light_front = " .. light_front)

	-- -- Search for the reading with the highest value
	-- value = -1 -- highest value found so far
	-- idx = -1   -- index of the highest value
	-- for i=1,#robot.proximity do
	-- 	idx = i
	-- 	value = robot.proximity[i].value
	-- 	angle = robot.proximity[i].angle
	-- 	log("robot proximity sensor: " .. idx .. "------" .. value .. "------" .. angle)
	-- end
	


	-- vector = vector_avoid_obstacles()
	-- log("avoid_obstacles_vector_length: " .. vector.length)
	-- log("avoid_obstacles_vector_angle: " .. vector.angle)
end


--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
	-- Set the robot led on if it is close to the light
	n_steps = n_steps + 1

	-- Set the velocity of the wheels
	vec = vector.vec2_polar_sum(vector_avoid_obstacles(), vector_phototaxis())
	vel = from_vector_to_velocities(vec)
	if vel.left == 0 and vel.right == 0 then
		goRandom()
	else
		setVelocity(vel)
	end
	
	-- Log the stats of the robot
	logStats()

end


--[[ This function is executed every time you press the 'reset'
 button in the GUI. It is supposed to restore the state
 of the controller to whatever it was right after init() was
 called. The state of sensors and actuators is reset
 automatically by ARGoS. ]]
 function reset()
    left_v = robot.random.uniform(0,MAX_VELOCITY)
    right_v = robot.random.uniform(0,MAX_VELOCITY)
    robot.wheels.set_velocity(left_v,right_v)
    n_steps = 0
    robot.leds.set_all_colors("black")
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
end
