-- Controls the player plane animation and movement
-- As well as the child shadow node
-- Main game logic handles the moving of the world and such.
playerAnimator = {}

-- Setup UV offsetter (used as animation frame)
function playerAnimator:Create()
	self.uvOffset = Vec(0,0,0)
	self.uvFrameSize = Vec()
	
	-- 3D accel (as used by the game's chunks, not the player model!)
	self.speed = 0
	
	-- and rotation to apply to the game, not the player (rotates chunks around player)
	-- Worth noting that this snaps instantly, whereas the main gameCtrl lerps it fairly quickly
	self.rotationTarget = Vec(0,0,0)
	
	-- And L/R movement
	self.positionX = 0
	-- If over 0, moves player upwards!
	self.jumpTime = 0
	-- if true, then on floor / chunk
	self.onGround = false
	-- and last state, to find state changes and thus play animations
	self.lastOnGround = true
	
	-- Delta accumulation for advancing frames
	-- Main animation speed control!
	self.frameTime = 0
	--INCed after a set delta: set to 1 (array access) and moduluoed by lenth of the animation in question
	self.frameCounter = 1
	
	-- animation state
	self.falling = false
	self.jumpTime = 0
	
	-- Animation frames!
	-- 16 frames are provided on a 128x atlas
		-- SO ALL OF THE BELOW NEED DIVIDING BY 4
	-- Frames go from left to right, top to bottom
	self.ANIM_RUN = {
		Vec(0, 0, 0),
		Vec(1, 0, 0),
		Vec(2, 0, 0),
		Vec(3, 0, 0),
		Vec(0, 1, 0),
		Vec(1, 1, 0),
		Vec(2, 1, 0),
		Vec(3, 1, 0),
		Vec(0, 2, 0),
		Vec(1, 2, 0),
		Vec(2, 2, 0),
		Vec(3, 2, 0)
	}
	
	-- Mid walk cycles of the running animation, to look like a light jog
	-- Only done at low speeds
	self.ANIM_JOG = {
		Vec(1, 1, 0),
		Vec(1, 3, 0),
		Vec(3, 2, 0),
		Vec(1, 3, 0),
	}
	
	-- 13,13,14,14 are done when initiating a jump (a/b press) (on doubles, e.g. half speed)
	self.ANIM_JUMP = {
		Vec(0, 3, 0),
		Vec(0, 3, 0),
		Vec(0, 3, 0),
		Vec(0, 3, 0),
		Vec(0, 3, 0),
		Vec(0, 3, 0),
		Vec(1, 3, 0),
		Vec(1, 3, 0),
		Vec(1, 3, 0),
		Vec(1, 3, 0),
		Vec(1, 3, 0),
		Vec(1, 3, 0)
	}
	
	-- 13,15,16 are shown when the player starts to fall (after a jump or otherwise)
	self.ANIM_FALL = {
		Vec(1, 3, 0),
		Vec(0, 3, 0),
		Vec(2, 3, 0),
		Vec(3, 3, 0)
	}
end

function playerAnimator:Start()
	-- The player should not roll over! (the collider is a sphere)
	self:SetAngularFactor(Vec(0,0,0))
	-- And can only move along x and y
	self:SetLinearFactor(Vec(1,1,0))
end

-- AND Reset the player in case they fall
function playerAnimator:Reset()
	self:SetPosition(Vec(0,0,-6))
	self:SetRotation(Vec(0,0,0))
	self.rotationTarget = Vec(0,0,0)
	self:ClearForces()
	self:SetAngularFactor(Vec(0,0,0))
	self:SetLinearFactor(Vec(1,1,0))
	self.speed = 0
	self.jumpTime = 0
	self.onGround = false -- this will set up the animation on the first frame
	self.lastOnGround = true
	
end

-- Return speed
function playerAnimator:GetSpd()
	return self.speed
end
function playerAnimator:GetRotationTarget()
	return self.rotationTarget
end

-- And return player's opinion on whether they have fallen off the level or not!
function playerAnimator:HasFallenOff()
	if self:GetPosition().y < -10 then
		self:ClearForces()
		self:AddImpulse(Vec(0,80, 0)) --and reduce gravity a bit as we land back down
		return true --level will restart on next frame
	end
	return false
end

function playerAnimator:Tick(delta)
	self.frameTime = self.frameTime + delta * (self.speed+1) --faster speed, faster animations
	--self:SetAngularVelocity(Vec(0,0,0)) --don't want player collider rolling around, might mess with raycasts!
	
	-- First, detect if on ground
	self.lastOnGround = self.onGround
	local groundRay = self:SweepToWorldPosition(self:GetPosition() + Vec(0,-0.007,0.01), 0, true) --testOnly=true to stop player actually moving to the ray hit!
	-- If we hit a floor (normal pointing up etc)
	if (groundRay.hitNode and groundRay.hitNormal.y > 0) then
		self.onGround = true
		
		if self.lastOnGround == false then --animation early if this just happened
			self.frameCounter = 0 -- one will be added later
			self.frameTime = 1
		end
	else
		self.onGround = false
		if self.lastOnGround then --animation early if this just happened
			self.frameCounter = 0 -- one will be added later
			self.frameTime = 1
		end
	end
	
	-- then, if we hit a wall, kill the speed!
	local wallRay = self:SweepToWorldPosition(self:GetPosition() + Vec(0,0.03,-0.01), 0, true) --testOnly=true to stop player actually moving to the ray hit!
	if (wallRay.hitNode and wallRay.hitNormal.z > 0.1) then
		self.speed = 0
		self.frameTime = 1 -- Change animation early
		--Log.Debug(groundRay.hitFraction)
	else
		-- Accelerate player if not smacking into a wall
		self.speed = self.speed + delta*8
		if self.speed > 18.0 then
			self.speed = 18.0
		end
	end
	
	local aPress = Input.IsGamepadDown(Gamepad.A)
	local bPress = Input.IsGamepadDown(Gamepad.B)
	if aPress or bPress then
		--If on ground
		if (self.onGround and self.lastOnGround and self.jumpTime == 0) then
			self.frameTime = 1 -- If we jumped, do the next animation frame early
			self.frameCounter = 0 -- one will be added later
			self.jumpTime = 0.15
		end
	else --short hops
		self.jumpTime = 0
	end
	
	-- Or rotate chunks
	local leftPress = Input.IsGamepadPressed(Gamepad.L1 | Gamepad.C)
	local rightPress = Input.IsGamepadPressed(Gamepad.R1 | Gamepad.Z)
	if leftPress then
		self.rotationTarget.z = self.rotationTarget.z + 90.0
	end
	if rightPress then
		self.rotationTarget.z = self.rotationTarget.z - 90.0
	end
	
	--Gravity only! Speed added to chunks in main game
	self:AddForce(Vec(0,-120,0))
	
	--and left/right only
	local xx = Input.GetGamepadAxis(Gamepad.AxisLX)
	self:AddImpulse(Vec(xx*2,0,0))
	
	-- And constrain X velocity
	local velo = self:GetLinearVelocity()
	if velo.x > 10 then
		velo.x = 10
		self:SetLinearVelocity(velo)
	end
	if velo.x < -10 then
		velo.x = -10
		self:SetLinearVelocity(velo)
	end
	if self.onGround == false then
		velo.x = velo.x * 0.99
		self:SetLinearVelocity(velo)
	end
	
	
	
	-- And jump player
	if self.jumpTime > 0 then
		if self.jumpTime == 0.15 then
			self:AddImpulse(Vec(0,24,0))
		else
			self:AddImpulse(Vec(0,3,0))
		end
		self.jumpTime = self.jumpTime - delta
	end
	
	
	--Finally do shadow logic once forces applied
	--Snap child shadowplane mesh position to nearest floor
	local shadowRay = self:SweepToWorldPosition(self:GetPosition() + Vec(0,-6,0), 0, true)
	if (shadowRay.hitNode) then
		self:GetChild(2):SetVisible(true)
		-- since shadow is so close to the floor, adjust to prevent velocity hiding it?
		local phaseY = velo.y * delta * 0.9
		self:GetChild(2):SetPosition(Vec(0, -0.63 - phaseY - shadowRay.hitFraction*6, 0)) --avoid setting to world space in case it moves behind us?
	else
		--If no floor available, then hide it
		self:GetChild(2):SetVisible(false)
	end
	
	
	--advance frame of an animation depending on state
	if (self.frameTime > 0.7) then
		self.frameTime = 0.0
		self.frameCounter = self.frameCounter + 1
		
		if (self.jumpTime > 0) then
			self.frameCounter = math.fmod(self.frameCounter, #self.ANIM_JUMP) --looping animation
			self.uvOffset = self.ANIM_JUMP[self.frameCounter+1] / Vec(4,4,4)
		elseif (self.onGround == false) then
			if self.frameCounter > 3 then --non looping animation
				self.frameCounter = 3
			end
			self.uvOffset = self.ANIM_FALL[self.frameCounter+1] / Vec(4,4,4)
		else
			if self.speed > 7 then -- If fast
				self.frameCounter = math.fmod(self.frameCounter, #self.ANIM_RUN)
				self.uvOffset = self.ANIM_RUN[self.frameCounter+1] / Vec(4,4,4)
			elseif self.speed > 1 then -- if slow
				self.frameCounter = math.fmod(self.frameCounter, #self.ANIM_JOG)
				self.uvOffset = self.ANIM_JOG[self.frameCounter+1] / Vec(4,4,4)
				-- in fact, keep speed below 8 until we hit the right frame. Makes animaiton smoother
				if frameCounter ~= 3 then
					if self.speed >= 6.9 then
						self.speed = 6.9
					end
				end
			else -- if still
				self.uvOffset = Vec(1,3,0) / Vec(4,4,4)
			end
		end
		self:GetChild(1):GetMaterial():SetUvOffset(self.uvOffset)
	end
end