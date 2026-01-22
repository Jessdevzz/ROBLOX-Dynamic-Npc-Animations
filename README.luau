-- JESS'S DYNAMIC NPC ANIMATION SCRIPT V2

-- V2.0
-- Last updated on 1/21/26

-- INSTRUCTIONS
--[[
	Place the DynamicNpcAnimations module inside of Server Script Service
	Place the init script inside of Server Script Service OR use .Init() on the module
	Duplicate the NPC_TEMPLATE folder to create new NPC data
	You must rename all of the NPC data folders to something other than NPC_TEMPLATE
	
	Edit the animations to contain the proper animation ids
	
		REQUIRED:
			Idle - the idle animation that plays when 0 players are near the npc
			
		OPTIONAL (for custom transitions):
			IdleToActive - the animation that transitions between idle and active
			ActiveIdle - the animation that plays when a player is near the npc, and has been transitioned from idle
			ActiveToIdle - the animation that transitions between active and idle
			
		OPTIONAL (simple setup):
			ActiveIdle - if you ONLY want an extra "near player" idle animation (no transitions needed)
			
		YES!! You can now have NPCs that only use:
			- Idle
			- Idle + ActiveIdle
		(no custom transition animations required!)

	
		
	Resize and reposition the zone to be wherever you want, this is the zone that detects when the player is near the npc, no coding nessecary!
	Edit the NPC object value to be the the npc you want to animate
	
	And you're done!!
	
	Be sure to keep all animations longer than 0.1 seconds, or there may be small transition issues
	
	Feel free to edit the code however you like, its yours!
	
	2 SECOND CONFIG TUTORIAL:
		At extreme scales, many zones may cause memory to become an issue
		This is why I introduced the StreamDistance and Streamed configs to each npc
		Streamed -> enables/disables automatic zone loading/unloading to conserve memory
		StreamDistance -> the maximum distance a player has to be away from a zone for it to stream
		
		If streaming is disabled, all zones will be permanantly loaded (unless overridden)
	
	Since this is no longer a paid product, I cannot guarentee instant customer service
	However, I will try to get back to you whenever I can if you message me @jessonomondays on discord
	
	EXTERNAL FUNCTIONS (THINGS YOU CAN CALL IN YOUR OWN SCRIPTS!!)
	
		NOTE:
			These are optional, the system works automatically without you touching anything.
			But they are here if you want manual control / debugging / cool custom systems :)
			
			! Force unload sets the zones players to 0, this may cause desync issues !
		
		.Init()
			Starts the entire animation system.
			This can only run once.
			
			Example:
				local DynamicNpcAnimations = require(path.to.script)
				DynamicNpcAnimations.Init()
		
		.GetState(npc) -> "Idle" | "Active" | nil
			Returns the npc's current state.
			
			Example:
				print(DynamicNpcAnimations.GetState(workspace.NPCS.Neil))
		
		.IsLoaded(npc) -> boolean
			Returns if the npc is currently loaded (aka has its zone connections active).
			
			Example:
				if DynamicNpcAnimations.IsLoaded(npc) then
					print("npc is running!")
				end
		
		.GetPlayers(npc) -> number | nil
			Returns how many players are currently in the npc's zone.
			
			Example:
				print("players in zone:", DynamicNpcAnimations.GetPlayers(npc))
		
		.ForceLoad(npc)
			Forces the npc to load + permanently disables automatic loading for that npc.
			(use this if you want to handle zone management yourself)
			
			Example:
				DynamicNpcAnimations.ForceLoad(workspace.NPCS.Neil)
		
		.ForceUnload(npc)
			Forces the npc to unload + permanently disables automatic loading for that npc.
			(use this if you want to handle zone management yourself)
			
			Example:
				DynamicNpcAnimations.ForceUnload(workspace.NPCS.Neil)
	
	
	TROUBLESHOOTING!!
		Npc not playing any animations
			Ensure you init the module script!
			Ensure the Idle animationid is set (Idle is required!!)
			Ensure the npc object value is correctly set
			Ensure the zone object is anchored
			Ensure the npc has a rig + humanoid
			
		Animations in the wrong order
			Ensure the animationids are correct for the animation it is supposed to be
			
		Transitions look weird / cut off
			Make sure your animations are longer than 0.1 seconds
			Make sure your transition animations are set to the correct ids (IdleToActive / ActiveToIdle)
			
		Any further questions, please contact me on discord @jessonmondays

]]

-- thank you for using my work! it means a lot :)
-- credit is NOT required, but it would make me smile to see a game use my system ^^

-- have fun :D
