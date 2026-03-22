-- Controls logic such as level generation, game/score logic and background spinning
titleCtrl = {}

-- Setup game variables
function titleCtrl:Create()
	self.skyboxRotSpeed = Vec(0.3,0.3,0.3)
	
	self.skyboxNodeRef = nil
	self.musicNodeRef = nil
	
	-- turn off logging on title screen if on console
	Log.Enable(true)
	
	-- Init bottom screen with an image (to prove we can!)
	if (Engine.GetPlatform() == "3DS") then
		Engine.GetWorld(2):LoadScene("blankbottomscreen")
		Log.Enable(false)
	end
	
	if (Engine.GetPlatform() == "Wii") then
		Log.Enable(false)
	end
end

function titleCtrl:Start()
	self.skyboxNodeRef = self:GetWorld():FindNode("skybox_instance")
	self.musicNodeRef = self:GetWorld():FindNode("titlebgm")
	self.musicNodeRef:PlayAudio()
end

-- Targets 60fps
function titleCtrl:Tick(delta)
	self.skyboxNodeRef:AddRotation(self.skyboxRotSpeed)
	
	local startPress = Input.IsGamepadDown(Gamepad.Start)
	local xPress = Input.IsGamepadDown(Gamepad.X)
	local yPress = Input.IsGamepadDown(Gamepad.Y)
	if (xPress and yPress) then
		Engine.GetWorld(1):LoadScene("cubescene")
	end
	
	--exit on gamepad button down?
	if (startPress) then
		Engine.Quit()
	end
end