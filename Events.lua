-- This is the Events Module that is used for the items I place in the Touchables folder, This is to prevent repetitive coding and more efficient troubleshooting

local ServerStorage = game:GetService("ServerStorage") -- This allows me to access the server storage  
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- Replicated Storage
local Players = game:GetService("Players") -- Players 
local TweenService = game:GetService("TweenService") -- TweenService

local szs = ServerStorage:WaitForChild("SimpleZSpawner") -- We then access a local script stored in server storage called SimpleZSpawner, which essentially clones a model of drooling zombiies I had prteviously made
local gameSettings = ReplicatedStorage.Settings -- stored the variables for the spawner in replicated storage in a folder called settings, this will allow me to add variables without having to define them as varables
local part = workspace.Touchables.Interactables.Barrel.LidTop -- this will be the part that is being interacted with
local prompt = part.ActionPrompt -- this is the toggle that the user will access to spawn the zombies
local alarm = part.alarm -- this is a sound ran on a loop that will notify the user that zombies are being spawned
local zombieModel = szs:WaitForChild("Zombies") -- this is the zombie model that the simplezspawner is hosting

local DamageAmount = 15 -- This is a variable we will be visiting in muliple functions below.
local HealAmount = 30 -- This will be a reused variable as well.
local WalkSpeed = 50
local JumpRaise = 10

local Events = {} -- this is used to define a module script

-- This event is for the bomb option in the landmines. I will edit this a bit and add the explosion funcitonality from my previous bomb
function Events:Boomify(area, ignore) -- function contains 2 requirements, the name and the things to ignore.
	local newTouch -- defining the variable before redefining it as a function.
	newTouch = area.Plate.Touched:Connect(function(hit) -- newTouch variable will activate when a BasePart is touched and then immediately disconnects so there is no spamming
		if hit:IsA("BasePart") and not table.find(ignore, hit) then  -- this is a conditional statement that checks to see if the hit parameter is a basepart and if it is not in my table of ignored items 
			newTouch:Disconnect()
			local exp = Instance.new("Explosion", area.Plate) -- used the pre-built explosion instance and stored in in a variable named exp
			exp.Position = area.Plate.Position -- set the explosion instance to the same location of the plate for the landmine
			exp.BlastPressure = 500000 -- this is standard settings for an explosion using the roblox instance
			exp.BlastRadius = 5 -- this is standard settings for an explosion using the roblox instance
			exp.ExplosionType = Enum.ExplosionType.NoCraters -- this is to make sure there is no craters made in the terrain

			local sound = ReplicatedStorage.Assets.Sounds.boom:Clone()  -- created a sound variable that accesses the replicated storage
			sound.Parent = area.Plate -- attached the sound varable to the landmine plate 
			sound:Play() -- played the sound estimated 20 seconds
			game.Debris:AddItem(sound, 2) -- used the debris function to delete the sound after 2 seconds
			print("Boom!") -- used the boom for confimation to check for any errors in the script
			task.spawn(function()
				task.wait(2)  -- waited 2 seconds before destroying the landmine
				area:Destroy()
			end)
		end
	end)
end

-- This event is used to allow the zombie event to execute based on loading the prompt
function Events:SetZombiePrompt(prompt) -- in this function we are passing the prompt 
	local newTrigger -- defining a varable to be later used to connect the triggered instance
	newTrigger = prompt.Triggered:Connect(function(hit)
		-- newTrigger:Disconnect() 
		if gameSettings:GetAttribute("Activation") == true then -- checking to see if the activated attribute is true, then will toggle it
			gameSettings:SetAttribute("Activation", false)
			alarm:Stop()
		else
			gameSettings:SetAttribute("Activation", true)
			alarm:Play() -- toggle to play and stop the alarm sound
		end
	end)
end

-- This event is used for spawning the zombie models
function Events:ZombieSpawner() -- in this function the zombies are cloned after a certain amount of time defined in the game settings variable 
	while true do
		task.wait(gameSettings:GetAttribute('Intermission')) -- waiting for the intermission attribute which is numerical
		if gameSettings:GetAttribute("Activation") then -- then checking to see if the activation attribute is true and if it is then the zombie model is cloned to the spawn point
			local zombies = zombieModel:Clone()
			zombies.Parent = workspace -- setting the parent of the zombies to the workspace otherwise they do not appear in game
			task.wait(gameSettings:SetAttribute("Round")) -- waits till the end of the round
			game.Debris:AddItem(zombies, gameSettings:GetAttribute("TimeToLive")) -- then uses the debris function to remove the existing zombies after the time to live period has passed
		end
	end

end

-- This event is for inflicting damage when a certain part is touched
function Events:Damage(area, ignore) -- function contains 2 requirements, the name and the things to ignore.
	local newTouch -- defining the variable before redefining it as a function.
	newTouch = area.Touched:Connect(function(hit)  -- newTouch variable will activate when a BasePart is touched and then immediately disconnects so there is no spamming
		if hit:IsA("BasePart") and hit.Parent:FindFirstChild("Humanoid") and not table.find(ignore, hit) then -- conditional to make sure the hit parameter's parent is a humanoid so the dameage will not work otherwise
			newTouch:Disconnect()

			local hum = hit.Parent:FindFirstChild("Humanoid") -- created a local variable named hum to get as the humanoid touching the part
			hum.Health -= DamageAmount -- we then damage the humanoid by the predefined global variable DamageAmount
			print(hit.Parent.Name .. " has been damaged by " .. tostring(DamageAmount) .. "!") -- print to make sure everything is working properly
			area:Destroy() -- destroy the part after the damage has been dealt
		end
	end)
end

-- This event is for when a healing part is touched
function Events:Heal(area, ignore)  -- function contains 2 requirements, the name and the things to ignore.
	local newTouch  -- defining the variable before redefining it as a function.
	newTouch = area.Touched:Connect(function(hit)  -- newTouch variable will activate when a BasePart is touched and then immediately disconnects so there is no spamming
		if hit:IsA("BasePart") and hit.Parent:FindFirstChild("Humanoid") and not table.find(ignore, hit) then  -- conditional to make sure the hit parameter's parent is a humanoid so the dameage will not work otherwise
			newTouch:Disconnect()

			local hum = hit.Parent:FindFirstChild("Humanoid") -- created a local variable named hum to get as the humanoid touching the part
			hum.Health += HealAmount -- this is where we add the health to the humanoid part
			print(hit.Parent.Name .. " has been healed by " .. tostring(HealAmount) .. "!") -- print to make sure everything is working properly
			area:Destroy() -- destroy the part after the damage has been dealt
		end
	end)
end

-- This event is for when a flame part is touched
function Events:Flammable(area, ignore)
	local newTouch
	newTouch = area.Touched:Connect(function(hit) -- nested function to carry out in the case of the part being touched
		if hit:IsA("BasePart") and hit.Parent:FindFirstChild("Humanoid") and not table.find(ignore, hit) then  -- conditional to make sure the hit parameter's parent is a humanoid so the dameage will not work otherwise
			newTouch:Disconnect()

			local hum = hit.Parent:FindFirstChild("Humanoid") -- checking to see if what touched it is a humanoid
			local fire = Instance.new("Fire", hit) -- using the fire instance and connecting it to the part that touched the object
			fire.Name = "Fire" -- naming the instance for better reference
			print(hit.Parent.Name .. " has been set on fire !") -- print to make sure everything is working properly
			area:Destroy() -- destroying the object after being touched to avoid multiple touches
			spawn(function() -- nested loop that takes health until about 50% just so they do not end up dead
				while fire and fire.Parent and hum and hum.Health > 50 do
					hum:TakeDamage(5) -- taking damage 5% at a time and having a wait of a second in between
					task.wait(1)
				end

			end)
		end
	end)
end

-- This event is for when a shock part is touched
function Events:Shock(area, ignore)
	local newTouch
	newTouch = area.Touched:Connect(function(hit)
		if hit.Parent and hit.Parent:FindFirstChild("Humanoid") and not table.find(ignore, hit) then
			newTouch:Disconnect()

			local humanoid = hit.Parent:FindFirstChild("Humanoid") -- checking to see if the otherpart that touched the object is a humanoid
			local spark = Instance.new("SparkEffect") -- Creating a new instance and configuring the instance
			spark.Parent = area
			spark.SparkColor = ColorSequence.new(Color3.new(1, 1, 1))
			spark.SparkSize = NumberSequence.new(0.2, 0.5)
			spark.Enabled = true

			local sound = ReplicatedStorage.Assets.Sounds.Electric_shock:Clone() -- accessed a shock sound from the toolbox that is in replicated storage
			sound.Parent = area
			sound:Play() -- play the sound then getting rid of it with the debris game service
			game.Debris:AddItem(sound, sound.TimeLength + 1) -- getting rid of the sound one second after it has finished playing

			humanoid:TakeDamage(DamageAmount) -- using the global variable DamageAmount to give the humanoid damage
			humanoid.WalkSpeed = humanoid.WalkSpeed * 0.5 -- decrease their speed by half to show they have been stunned
			task.wait(2) -- setting the stunned effect to 2 seconds 
			humanoid.WalkSpeed = humanoid.WalkSpeed * 2 -- setting it back to normal levels
			spark:Destroy() -- destroying the object so it does not execute multiple times.
			game.Debris:AddItem(area, 2) -- debris game service to clear the area
		end
	end)
end

-- This event will give the character increased speed and jump capabilities.
function Events:Speedify(area, ignore)
	local newTouch
	newTouch = area.Touched:Connect(function(hit)
		if hit.Parent:FindFirstChild("Humanoid") and not table.find(ignore, hit) then
			newTouch:Disconnect()

			local hum = hit.Parent:FindFirstChild("Humanoid") -- after checking to see if the part belongs to a humanoid
			hum.WalkSpeed = hum.WalkSpeed + WalkSpeed -- increase the speed by the global varable WalkSpeed value
			hum.JumpPower = hum.JumpPower + JumpRaise -- increase the speed by the global variable JumpRaise value

			print(hit.Parent.Name .. " speed and jump has been increased by " .. tostring(WalkSpeed) .. " and " .. tostring(JumpRaise) .. " !") -- print to make sure everything is working properly
		
			area:Destroy() -- destroy the part after the speed effect has been dealt
			
			task.wait(15) -- i set a timer for about 15 seconds for the effect and then set their values back to normal.
			hum.WalkSpeed = hum.WalkSpeed - WalkSpeed
			hum.JumpPower = hum.JumpPower - JumpRaise
			print((hit.Parent.Name .. "Speed is back to normal"))
			
		end
	end)
end

-- This is the actual run loop I would have in my main script that would check to see if any of the 
-- items were touched and then check which functions are associated with them

local Ign = workspace.Ignore:GetChildren() -- This is the ignore folder/table. I created this to avoid certain things happening unintentionally in the script

for i, v in pairs (workspace.Touchables:GetDescendants()) do -- key value pair loop for all of the children in the touchables folder
	-- This was the main idea behind the modulazation. The folders are set in a way that is easily scalable and replacable to add new objects 
	-- And functions
	if v.Parent.Name =="Boomable" then -- if the item is under the boomables folder under the touchables folder then execute the function Boomify
		Events:Boomify(v, Ign) -- v and Ign are the parameters with v being the part and Ign being what to ignore
	elseif v.Parent.Name == "Healing" then -- if the item is under the healing folder under the touchables folder then execute the function Heal
		Events:Heal(v, Ign)
	elseif v.Parent.Name == "Damage" then -- if the item is under the healing folder under the touchables folder then execute the function Damage
		Events:Damage(v, Ign)
	elseif v.Parent.Name == "Interactables" then -- if the item is under the interactables folder then 4execute the functions SetZombiePrompt and ZombieSpawner
		Events:SetZombiePrompt(v.LidTop.ActionPrompt) -- because this is a model i created, it has a specific part that needs to be triggered
		Events:ZombieSpawner()
	elseif v.Parent.Name == "Flammable" then -- if the item is under the Flammable folder then execute the function Flammable
		Events:Flammable(v, Ign)
	elseif v.Parent.Name == "Boostables" then -- if the item is under the Boostables folder then execute the Speedify function
		Events:Speedify(v, Ign)
	end
end


return Events -- returns the module script
