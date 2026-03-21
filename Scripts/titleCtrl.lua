-- Controls logic such as level generation, game/score logic and background spinning
titleCtrl = {}

-- Setup game variables
function titleCtrl:Create()
	-- turn off logging on title screen
	Log.Enable(false)
	
	self.skyboxRotSpeed = Vec(0.3,0.3,0.3)
	
	self.skyboxNodeRef = nil
	self.musicNodeRef = nil
	
	-- Init bottom screen with an image (to prove we can!)
	if (Engine.GetPlatform() == "3DS") then
		Engine.GetWorld(2):LoadScene("blankbottomscreen")
	end
	
end

function titleCtrl:Start()
	self.skyboxNodeRef = self:GetWorld():FindNode("skybox_instance")
	self.musicNodeRef = self:GetWorld():FindNode("title_music")
	self.musicNodeRef:PlayAudio()
end

-- Targets 60fps
function titleCtrl:Tick(delta)
	self.skyboxNodeRef:AddRotation(self.skyboxRotSpeed)
	
	local startPress = Input.IsGamepadDown(Gamepad.Start)
	local xPress = Input.IsGamepadDown(Gamepad.X)
	local yPress = Input.IsGamepadDown(Gamepad.Y)
	if (xPress and yPress) then
		Engine.GetWorld(1):LoadScene("gamescene")
	end
	
	--exit on gamepad button down?
	if (startPress) then
		Engine.Quit()
	end
end