Jess’s Dynamic NPC Animations V2

This is my zone-based NPC animation script that makes NPCs feel more alive without you having to write 400 lines of “if player near then wave” code.
NPCs will Idle when nobody’s around, then switch to Active vibes when players enter their zone.

"What makes this special"
  This system has support for custom transition animations! Which makes this much more powerful than an "if in box then animate" system
  I hope anyway...
  
What it does
  Automatically switches NPC animations based on players inside a zone
  Supports streaming distance loading to enable massive scalability
  Handles both fancy setups and lazy setups
  Custom transitions support
  
Full setup (with transitions)
  If you want smooth transitions, you can use:
    Idle
    IdleToActive
    ActiveIdle
    ActiveToIdle
    
Simple setup (no transitions)
  If you don’t want transition animations at all:
    Idle only
    Idle + ActiveIdle
  (These NPCs will just swap instantly, no extra animations needed.)

External functions you can use
I thought I'd make this a little bit cooler so twitter didn't kill me, so I added some external features!
If you wanna manually control stuff or check what an NPC is doing, the module includes:
  Init() (ok well you have to do this one)
  
  GetState(npc)
  
  IsLoaded(npc)
  
  GetPlayers(npc)
  
  ForceLoad(npc)
  
  ForceUnload(npc)
  
If you want a placefile instead, YOU'RE IN LUCK!!!
https://www.roblox.com/games/86582491164528/Dynamic-NPC-Animations-V2

Notes
Works best when your animations are longer than 0.1 seconds
Made to be editable, stealable, and customizable (please do)

thank you for using my work fr it means a lot :)
