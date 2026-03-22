-- Controls logic such as level generation, game/score logic and background spinning
gameCtrl = {}

-- Setup game variables
function gameCtrl:Create()
	-- Init bottom screen with an image (to prove we can!)
	if (Engine.GetPlatform() == "3DS") then
		Engine.GetWorld(2):LoadScene("blankbottomscreen")
		Log.Enable(false)
	end
	
	if (Engine.GetPlatform() == "Wii") then
		Log.Enable(false)
	end
	-- may implement gravity as a varying force i.e. turned off when touching floor to add floatiness
	Engine.GetWorld(1):SetGravity(Vec(0,0,0))
	
	-- Audio is done in this script. Unfortunately the original audio loader kept causing crashes,
	-- so the code was changed to use three compressed tracks at 1/8th the size, allowing all three to be in RAM.
	self.musicNode = nil
		-- modulates by three. lua indexes from 1
	self.bgmIndex = 1
	
	-- Like title but set rather than add in this case
	self.skyBoxRot = Vec(0,0,0)
	self.skyboxNodeRef = nil
	self.lightref = nil --we should move the light around as well...
	
	-- A reference to the chunkstore, the place where all 3d level chunks are appended during runtime
	self.chunkstore = nil
	
	-- A reference to the main camera
	self.camera = nil
	-- The camera isn't inside the player's head, just nearby
	self.cameraOffset = Vec(0,2,6)
	
	-- and a refernce to the level label (time in deltas)
	-- if >0, the level label is updated and displayed onscreen for a short time to inform the user the level was complete
	self.levelText = nil
	self.TWO_SECONDS = 2.0
	self.showLevelTime = self.TWO_SECONDS
	
	-- lua indexes from 1!
	self.levelNumber = 1
	-- Increments as chunks are loaded in a conveyor-like fashion. Resets to zero when: a checkpoint chunk is passed / level is complete
	self.chunkNumber = 1
	
	-- Upon completing a level, slowly transition the colour of the material instances!
	self.cubeColour = Vec(0.8,0.8,0.8)
	self.targetColour = Vec(0.1, 0.4, 1.0) --start off as blue, see below!
	
	----- NOTE: vec3 spawnsway was taken out, as it doesn't really add anything! It also messes with the chunk rotations when pressing L/R.
	-- Chunk spawn location. Normally always abour 64m away from camera, each chunk being about 8m long?
	self.chunkSpawnPos = Vec()
	-- Rotation only affects chunks and background, not the player!
	self.chunkRotation = Vec(0,0,0)
	
	-- Level data. Small isn't it?
		-- you can edit them by dragging them to the top!
	self.LEVELS = {
		"==L=R=AEIKJ=GRI#", --level 1 : welcome, clumsy
		"=GLRLSKKOEZXC=FXZKOG#", --level 2 : sideward
		"=LIPOQZOOPIOZ#", --level 3 : upside up
		"=ZOIOZGAFSF=#", --level 4 : faith
		"=TSLCTSLTHQPR#", --level 5: copycat
		"=AVSVOAVSV=#", --level 6 : no jumping
		"=EKTFHOAZXCV=KOGTJO=#", --level 7 : twisty trail
		"=QPGAOHAAZHATQQIA#", --level 8 : it's all a haze
		"=QTIJQAPTLCRIJAQPQ#",--level 9: Get Jumpy
		"=QPIPRPLPQHGHGI#", --level 10: the end
		"=O=FO=OF#", --thanks for playing
		"=O=OFFO=#", --more to come
		"===!P!P!PPPPP", ---Jackitron
		--game crashes after this point
	}
	-- Preload assets! What? Turn it in, lad!
	-- And chunk<-->asset TABLE for loading
	self.CHUNKDATA = {}
	self.CHUNKDATA["#"] = LoadAsset("chunk_checkpoint")							-- '#' blank chunk with an ending plane that, when marked for destruction, increments the level
	self.CHUNKDATA["="] = LoadAsset("chunk_flat")		-- '-' blank chunk, all flat bottom for 8 units
	self.CHUNKDATA["!"] = LoadAsset("chunk_deadend")		-- '-' sort-of-impassable wall. End of game?
	
	self.CHUNKDATA["Q"] = LoadAsset("chunk_tunnelgap")
	self.CHUNKDATA["W"] = nil
	self.CHUNKDATA["E"] = LoadAsset("chunk_rightwall")		-- cubes on right with small wall
	self.CHUNKDATA["R"] = LoadAsset("chunk_right")			-- cubes on right only, force player right
	self.CHUNKDATA["T"] = LoadAsset("chunk_rightisland")	-- two island chunks one on top and one on bottom
	self.CHUNKDATA["Y"] = nil								-- split path?
	self.CHUNKDATA["U"] = nil						
	self.CHUNKDATA["I"] = LoadAsset("chunk_island")			-- one big island chunk, opposite of G?
	self.CHUNKDATA["O"] = LoadAsset("chunk_tunnel")			-- tunnel chunk
	self.CHUNKDATA["P"] = LoadAsset("chunk_shorthop")			-- strip on bottom side, wide and short
	
	self.CHUNKDATA["A"] = LoadAsset("chunk_clockwise")					-- equivalent of rotated 270
	self.CHUNKDATA["S"] = LoadAsset("chunk_anticlockwise")				-- equivalent of rotated 90 right
	self.CHUNKDATA["D"] = nil							
	self.CHUNKDATA["F"] = LoadAsset("chunk_ceilings")		-- top and bottom
	self.CHUNKDATA["G"] = LoadAsset("chunk_gap") 		--single gap on bottom side
	self.CHUNKDATA["H"] = LoadAsset("chunk_skylight")	--single gap on top side
	self.CHUNKDATA["J"] = LoadAsset("chunk_leftisland")		-- double fence piece, two long runways and three gaps
	self.CHUNKDATA["K"] = LoadAsset("chunk_leftwall")		-- flat, rotated clockwise with wall
	self.CHUNKDATA["L"] = LoadAsset("chunk_left")		-- cubes on left only, force player left
	
	self.CHUNKDATA["Z"] = LoadAsset("chunk_roof")
	self.CHUNKDATA["X"] = LoadAsset("chunk_roof1")		-- ceiling moved downwards
	self.CHUNKDATA["C"] = LoadAsset("chunk_roof2")		-- ceiling moved further down
	self.CHUNKDATA["V"] = LoadAsset("chunk_roofwise")	-- equivalent of rotated 180 of clockwise chunk
	
	--Log.Debug(self.CHUNKDATA["x"]:GetName())
	-- And level colours
	self.COLOURS = {
		Vec(0.2, 0.4, 1.0), --blue
		Vec(0.0, 0.7, 0.9), --cyan
		Vec(0.2, 1.0, 0.4), --green
		Vec(1.0, 0.8, 0.0), --yellow
		Vec(1.0, 0.7, 0.1), --orange
		Vec(0.7, 0.7, 0.7), --grey
		Vec(1.0, 0.1, 0.1), --red
		Vec(0.8, 0.3, 0.6), --purple
	}
end



-- Upon first frame, find the skybox node in the scene
function gameCtrl:Start()
	self.skyboxNodeRef = self:GetWorld():FindNode("skybox_instance") --remember self:A() is self.A(self) --- unlike python, no assumptions are made to allow for static functions!
	self.chunkstore = self:GetWorld():FindNode("chunkstore")
	self.camera = self:GetWorld():FindNode("camera")
	self.levelText = self:GetWorld():FindNode("level_text")
	self.player = self:GetWorld():FindNode("player_ins")
	
	-- And make a new level!
	self:RestartLevel()
	self.showLevelTime = self.TWO_SECONDS
	
	--start playing track 1:
	self:NextBGM()
end

-- Playlist of game music tracks - could be a callback if OCTAVE's AssetManager has callbacks!
function gameCtrl:NextBGM()
	-- change the node reference to keep an eye on the playing state
	self.musicNode = self:GetWorld():FindNode("track" .. self.bgmIndex)
	self.musicNode:ResetAudio()
	self.musicNode:PlayAudio()
	--Log.Debug("track" .. self.bgmIndex)
	
	--loop playlist
	self.bgmIndex = self.bgmIndex + 1
	if self.bgmIndex > 3 then
		self.bgmIndex = 1
	end
end

-- If we fall off, return the chunk loading to the beginning of the level we reached
-- Adds in 8 chunks to start with, incrementing the spawn position as we go to compensate for there not being any chunks on the conveyor
function gameCtrl:RestartLevel()
	-- clear all chunks away
	local chunkSz = self.chunkstore:GetNumChildren()
	
	-- Delete each one (and set colour back to normal)
	for c = 1,chunkSz do
		self.chunkstore:GetChild(c):GetChild(1):GetMaterial():SetColor(Vec(1,1,1))
		self.chunkstore:GetChild(c):DestroyDeferred()
	end
	
	-- reset chunkidx, not level!
	self.chunkNumber = 1
	-- and spawn point along conveyor
	self.chunkRotation = Vec(0,0,0)
	self.chunkSpawnPos.y = 0.0
	
	for zed=0,-112,-16 do
		self.chunkSpawnPos.z = zed
		self:SpawnChunk()
	end
	self.chunkSpawnPos.z = -112.0 --final spawn place
	
	-- Reset player vars (not score or collectibles)
	self.player:Reset()
	self.camera:SetPosition(self.player:GetPosition() + self.cameraOffset)
	-- What level was it again?
	self.showLevelTime = self.TWO_SECONDS
end



-- Targets 60fps
function gameCtrl:Tick(delta)
	-- Skybox first
	self.skyBoxRot.z = self.skyBoxRot.z + delta
	self.skyboxNodeRef:SetRotation(self.chunkRotation + self.skyBoxRot)
	
	-- Amount to move chunks by
	local conveyorStep = Vec(0,0,delta * self.player:GetSpd())
	local chunkNeeded = false -- spawns one more later if true
	local chunkSz = self.chunkstore:GetNumChildren()
	
	-- And slowly transition colour when needed
	self.cubeColour = Vector.Lerp(self.cubeColour,self.targetColour, delta)
	-- set colour of the material instance (which all chunks share)
	if chunkSz > 0 then
		self.chunkstore:GetChild(1):GetChild(1):GetMaterial():SetColor(self.cubeColour)
	end
	-- Also, the camera lerps to the player!
	self.camera:SetPosition(
		Vector.Lerp ( self.camera:GetPosition(), self.player:GetPosition() + self.cameraOffset, delta*4)
	)
	-- AND lerp all the chunks to this rotation (z) at 15 degrees a frame?
	self.chunkRotation = Vector.Lerp(self.chunkRotation, self.player:GetRotationTarget(), delta * 15)
	
	local pos = Vec() --reference this later as the last chunk plus the width of a chunk. If we just used a number value, delta error would accumulate as the spawn logic is tied to the movement!
	-- Crawl each chunk towards camera (for var=initial,final,<step>)
	for c = 1,chunkSz do
		pos = self.chunkstore:GetChild(c):GetPosition()
		if (pos.z > 15) then -- delete offscreen chunks
			self.chunkstore:GetChild(c):DestroyDeferred()
			-- If checkpoint, then increment level!
			if self.chunkstore:GetChild(c):HasTag("end") then
				self.targetColour = self.COLOURS[ 1+(self.levelNumber % 8) ]
				self.levelNumber = self.levelNumber + 1
				self.levelText:SetText("LEVEL " .. tostring(self.levelNumber))
				if self.levelNumber == 11 then
					self.levelText:SetText("Thanks for playing...")
				end
				if self.levelNumber == 12 then
					self.levelText:SetText("...more to come?")
				end
				if self.levelNumber == 13 then
					self.levelText:SetText("-Jackitron")
				end
				self.showLevelTime = self.TWO_SECONDS
				self.chunkNumber = 1
			end
			chunkNeeded = true
		else --or move/rotate
			self.chunkstore:GetChild(c):SetPosition( pos + conveyorStep )
			self.chunkstore:GetChild(c):SetRotation( self.chunkRotation )
		end
	end
	
	-- Spawn *one* more if needed from the last position (assmumes adding a child puts it on the end i.e. furthest away!)
	if chunkNeeded then
		self.chunkSpawnPos.z = (pos.z - 16.0) + conveyorStep.z
		self:SpawnChunk()
	end
	
	-- Has the player fallen down?
	if self.player:HasFallenOff() then
		self:RestartLevel()
	end
	
	-- and show/hide level?
	if self.showLevelTime > 0 then
		self.levelText:SetVisible(true)
		self.showLevelTime = self.showLevelTime - delta
	else
		self.levelText:SetVisible(false)
	end

	--exit on gamepad button down?
	local startPress = Input.IsGamepadDown(Gamepad.Start)
	if (startPress) then
		Engine.Quit()
	end
	
	-- If sound is not playing then the end of the track has been reached
	if self.musicNode:IsPlaying() == false then
		self:NextBGM()
	end
end


-- Generate chunk info for a level number
	-- Each level has a number of chunks, and chunk difficulties to place into the level
	-- level colours start at blue and then rotate hues
	-- the formula for chunk difficulties is above.
function gameCtrl:SpawnChunk()
	levelSize = self.LEVELS[self.levelNumber]:len() --also, see # operator!
	
	-- defualt to blank
	local chunkType = "="
	
	-- Load one char/chunk of level? (if level is done, next level will be loaded)
	if (self.chunkNumber <= levelSize) then
		chunkType = self.LEVELS[self.levelNumber]:sub(self.chunkNumber,self.chunkNumber)
	else -- OR get chunks of the next level
		local nextNum = self.chunkNumber - levelSize
		chunkType = self.LEVELS[self.levelNumber + 1]:sub(nextNum,nextNum)
	end
	local newChunk = self.CHUNKDATA[chunkType]:Instantiate()
	newChunk:SetPosition(self.chunkSpawnPos)
	newChunk:SetRotation(self.chunkRotation)
	self.chunkstore:AddChild(newChunk)
	
	self.chunkNumber = self.chunkNumber + 1
end
