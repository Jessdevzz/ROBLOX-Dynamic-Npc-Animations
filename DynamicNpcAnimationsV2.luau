local dynamicNpcAnimationsV2 = {}
-- DEPENDENCIES
local npcAnimations = workspace.NPC_ANIMATIONS
local zoneModule = require(script.ZoneModule)
local playerService = game:GetService("Players")
-- VARS
local initalized = false
local loadedNPCS: {[Instance]: boolean} = {}
local npcStates: {[Instance]: string} = {}
local npcZonePlayers: {[Instance]: number} = {}
local npcAnimationData: {[Instance]: {currentTrack: AnimationTrack, animations: {[string]: AnimationTrack}, inTransition:boolean}} = {}
local npcZoneConnections: {[Instance]: {inConnection: RBXScriptConnection, outConnection: RBXScriptConnection}} = {}
local overriddenNpcs = {}
-- FUNCTIONS

--[[
Returns the npc's folder in NPC_ANIMATIONS
@param npc:Instance - the npc to find the folder for
@return Folder - the npc's folder
]]
local function findNpcFolder(npc:Instance):Folder
	for i, npcFolder in pairs(npcAnimations:GetChildren()) do
		if npcFolder:IsA('Folder') and npcFolder.NPC.Value == npc then
			return npcFolder
		end
	end
	return nil
end

--[[
Plays an animation on the npc and cancels any other animations
@param npc:Instance - the npc to play the animation on
@param animation:AnimationTrack - the animation to play
@param looped:boolean - if the animation should loop
@return AnimationTrack - the animation track
]]
local function playAnimation(npc:Instance, animation:AnimationTrack, looped:boolean)
	local currentTrack:AnimationTrack = npcAnimationData[npc].currentTrack


	if currentTrack == animation then
		-- If the same animation is already playing, ensure it loops
		currentTrack.Looped = looped or false
		-- If the same animation is supposed to be playing, but isnt, play it!
		if not currentTrack.IsPlaying then
			currentTrack:Play()
		end

		return
	end


	local trackToStop = currentTrack -- stop previous animation after the next animation plays

	currentTrack = animation
	currentTrack.Looped = looped or false
	currentTrack:Play()
	npcAnimationData[npc].currentTrack = animation


	task.spawn(function()
		task.wait(0.1) -- animations must be longer than this,,,
		if trackToStop then trackToStop:Stop() end
	end)
end

--[[
Returns a boolean indicating if the npc is loaded or not
@param npc:Instance - the npc to check
@return boolean - if the npc is loaded or not
]]
local function isLoaded(npc:Instance): boolean
	return loadedNPCS[npc]
end

--[[
Returns a boolean indicating if the npc should be loaded or not
@param npc:Instance - the npc to check
@return boolean - if the npc should be loaded or not
]]
local function shouldBeLoaded(npc:Instance): boolean
	if table.find(overriddenNpcs, npc) then
		return loadedNPCS[npc] == true
	end
	local npcFolder = findNpcFolder(npc)
	if npcFolder.CONFIG.Streamed.Value == false then
		return true
	else
		local streamDistance:number = npcFolder.CONFIG.StreamDistance.Value
		for _, player in pairs(playerService:GetPlayers()) do
			local playerCharacter = player.Character
			if playerCharacter then
				local distance = (playerCharacter:GetPivot().Position - npc:GetPivot().Position).Magnitude
				if distance <= streamDistance then
					return true
				end
			end
		end
	end
	return false
end

--[[
loads and connects an npc
@param npc:Instance - the npc to load
]]
local function loadNPC(npc:Instance)
	if npcZonePlayers[npc] == nil then return end
	if npcZoneConnections[npc].inConnection ~= nil then return end
	local npcFolder = findNpcFolder(npc)
	local npcZone:Instance = npcFolder.Zone
	local newZone = zoneModule.new(npcZone)

	npcZoneConnections[npc].inConnection = newZone.playerEntered:Connect(function()
		npcZonePlayers[npc] += 1
	end)

	npcZoneConnections[npc].outConnection = newZone.playerExited:Connect(function()
		npcZonePlayers[npc] -= 1 
		if npcZonePlayers[npc] < 0 then
			npcZonePlayers[npc] = 0
		end
	end)
end

--[[
unloads and disconnects an npc
@param npc:Instance - the npc to unload
]]
local function unloadNPC(npc:Instance)
	if npcZonePlayers[npc] == nil then return end
	local conns = npcZoneConnections[npc]
	if conns and conns.inConnection then conns.inConnection:Disconnect() end
	if conns and conns.outConnection then conns.outConnection:Disconnect() end
	npcZoneConnections[npc].inConnection = nil
	npcZoneConnections[npc].outConnection = nil
	npcZonePlayers[npc] = 0
end

--[[
Initializes an npc
@param npcFolder:Instance - the npc folder to initialize
]]
local function initNPC(npcFolder)
	-- vars
	local npc:Instance = npcFolder.NPC.Value
	local humanoid:Humanoid = npc:WaitForChild("Humanoid")
	local animator:Animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

	-- REQUIRED
	local idleAnimation = animator:LoadAnimation(npcFolder.Idle)
	idleAnimation.Priority = Enum.AnimationPriority.Idle

	-- OPTIONAL animations (support minimal setup)
	local idleToActiveAnimation:AnimationTrack? = nil
	local activeIdleAnimation:AnimationTrack? = nil
	local activeToIdleAnimation:AnimationTrack? = nil

	if npcFolder:FindFirstChild("IdleToActive") then
		idleToActiveAnimation = animator:LoadAnimation(npcFolder.IdleToActive)
		idleToActiveAnimation.Priority = Enum.AnimationPriority.Action4
	end

	if npcFolder:FindFirstChild("ActiveIdle") then
		activeIdleAnimation = animator:LoadAnimation(npcFolder.ActiveIdle)
		activeIdleAnimation.Priority = Enum.AnimationPriority.Idle
	end

	if npcFolder:FindFirstChild("ActiveToIdle") then
		activeToIdleAnimation = animator:LoadAnimation(npcFolder.ActiveToIdle)
		activeToIdleAnimation.Priority = Enum.AnimationPriority.Action4
	end



	-- create animation data
	npcAnimationData[npc] = {
		['currentTrack'] = idleAnimation,
		['animations'] = {
			['Idle'] = idleAnimation,
			['IdleToActive'] = idleToActiveAnimation,
			['ActiveIdle'] = activeIdleAnimation,
			['ActiveToIdle'] = activeToIdleAnimation
		},
		['inTransition'] = false
	}


	npcZoneConnections[npc] = {inConnection = nil, outConnection = nil}

	npcZonePlayers[npc] = 0

	-- load npc
	if shouldBeLoaded(npc) then
		loadedNPCS[npc] = true
		loadNPC(npc)
	end
	-- load all animations into memory
	for _, animation in pairs(npcAnimationData[npc].animations) do
		if animation then
			playAnimation(npc, animation, false)
			task.wait(0.1)
			animation:Stop()
		end
	end


	playAnimation(npc, idleAnimation, true)
	npcStates[npc] = 'Idle'

end

--[[
Initalizes the npc animation system
Can not be ran more than once.
]]
dynamicNpcAnimationsV2.Init = function()
	if initalized then return end
	initalized = true
	for i, npcFolder in pairs(npcAnimations:GetChildren()) do
		task.spawn(function()
			if npcFolder:IsA('Folder') and npcFolder.Name ~= 'NPC_TEMPLATE' then
				initNPC(npcFolder)
			end
		end)
		npcFolder.ChildAdded:Connect(function(npcFolder)
			if npcFolder:IsA('Folder') and npcFolder.Name ~= 'NPC_TEMPLATE' then
				initNPC(npcFolder)
			end
		end)
	end

	-- main loop
	game:GetService('RunService').Heartbeat:Connect(function()
		for _, npcFolder in pairs(npcAnimations:GetChildren()) do
			if npcFolder:IsA('Folder') == false or npcFolder.Name == 'NPC_TEMPLATE' then continue end
		
			local npc:Instance = npcFolder.NPC.Value
			-- ensure npc has been initalized
			if npcAnimationData[npc] == nil then continue end
			if npcZonePlayers[npc] == nil then continue end
			if npcZoneConnections[npc] == nil then continue end

			-- LOAD NPC?
			local shouldLoad = shouldBeLoaded(npc)
			if shouldLoad ~= loadedNPCS[npc] then
				if shouldLoad then
					loadNPC(npc)
				else
					unloadNPC(npc)
				end
			end
			loadedNPCS[npc] = shouldLoad

			if isLoaded(npc) == false then continue end

		
			local players:number = npcZonePlayers[npc]
			local currentTrack:AnimationTrack = npcAnimationData[npc].currentTrack
			if npcAnimationData[npc].inTransition == true then continue end

			local anims = npcAnimationData[npc].animations
			local hasTransitions = (anims.IdleToActive ~= nil and anims.ActiveToIdle ~= nil)

			if players > 0 then
				-- someone in the zone
				if npcStates[npc] == "Idle" then
					if hasTransitions then
						if currentTrack ~= anims.IdleToActive then
							local trackToPlay:AnimationTrack = anims.IdleToActive
							npcAnimationData[npc].inTransition = true
							playAnimation(npc, trackToPlay, false)
							local trackLength = math.max(trackToPlay.Length, 0.05)
							
							task.delay(trackLength, function()
								npcAnimationData[npc].inTransition = false
								npcStates[npc] = "Active"
							end)
						end
					else
						--no transitions, just flip state once
						npcStates[npc] = "Active"
					end
				end

				if npcStates[npc] == "Active" then
					local desired = anims.ActiveIdle or anims.Idle
					if desired and currentTrack ~= desired then
						playAnimation(npc, desired, true)
					end
				end
			else
				-- no one in the zone
				if npcStates[npc] == "Active" then
					if hasTransitions then
						if currentTrack ~= anims.ActiveToIdle then
							local trackToPlay:AnimationTrack = anims.ActiveToIdle
							npcAnimationData[npc].inTransition = true
							playAnimation(npc, trackToPlay, false)
							local trackLength = math.max(trackToPlay.Length, 0.05)
							task.delay(trackLength, function()
								npcAnimationData[npc].inTransition = false
								npcStates[npc] = "Idle"
							end)
						end
					else
						-- no transitions, just flip state once
						npcStates[npc] = "Idle"
					end
				end

				if npcStates[npc] == "Idle" and currentTrack ~= anims.Idle then
					playAnimation(npc, anims.Idle, true)
				end
			end
		end
	end)

end

--[[
Returns the provided npc's current state (idle or active)
@param npc The npc to get the state of
@return The provided npc's current state OR nil
]]
dynamicNpcAnimationsV2.GetState = function(npc:Instance): string | nil
	local state = npcStates[npc] or nil
	return state
end

--[[
Returns the loaded state of the provided npc
@param npc The npc to check
@return The loaded state of the provided npc
]]
dynamicNpcAnimationsV2.IsLoaded = function(npc:Instance): boolean
	return isLoaded(npc) or false
end

--[[
Returns the amount of players in the provided npc's zone
@param npc The npc to get the player count of
@return The amount of players in the provided npc's zone
]]
dynamicNpcAnimationsV2.GetPlayers = function(npc:Instance): number | nil
	return npcZonePlayers[npc] or nil
end

--[[
Forces the load of an npc's zone
Forever overrides automatic loading behavior, it is now manual
@param npc The npc to load
]]
dynamicNpcAnimationsV2.ForceLoad = function(npc:Instance)
	if not table.find(overriddenNpcs, npc) then
		table.insert(overriddenNpcs, npc)
	end
	loadNPC(npc)
end

--[[
Forces the unload of an npc's zone
Forever overrides automatic loading behavior, it is now manual
@param npc The npc to unload
]]
dynamicNpcAnimationsV2.ForceUnload = function(npc:Instance)
	if not table.find(overriddenNpcs, npc) then
		table.insert(overriddenNpcs, npc)
	end
	unloadNPC(npc)
end


return dynamicNpcAnimationsV2
