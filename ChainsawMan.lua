local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "You Are An idiot",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "100%",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ArsenalSmoothFull"
    },
    KeySystem = false
})

local MovementTab = Window:CreateTab("プレイヤー", "move")
local CombatTab   = Window:CreateTab("戦闘", "swords")
local AntiTab     = Window:CreateTab("アンチ", "shield")
local TrollTab    = Window:CreateTab("荒らし", "skull")
local ESPTab      = Window:CreateTab("ESP", "eye")
local TeleportTab = Window:CreateTab("テレポート", "map-pin")
local DiscordTab  = Window:CreateTab("情報", "info")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Settings
local MovementSettings = {
    Enabled = false,            
    WalkspeedEnabled = false,   
    WalkspeedValue = 50,      
    JumpPowerEnabled = true,
    JumpPowerValue = 300,
    NoclipEnabled = false,
    Connections = {}
}

-- Utils
local function GetCharacterParts(character)
    local char = character or LocalPlayer.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hum, hrp
end

-- WalkSpeed
local ACCEL = 50
local currentSpeed = 0

local function EnableSpeed()
    local hum, hrp = GetCharacterParts()
    if not hum or not hrp then return end

    hum.WalkSpeed = 16  -- WalkSpeedは低めにセット（キック回避のため）

    if MovementSettings.Connections.Speed then
        MovementSettings.Connections.Speed:Disconnect()
    end

    MovementSettings.Connections.Speed = RunService.Heartbeat:Connect(function()
        if not MovementSettings.Enabled then return end

        if hum.MoveDirection.Magnitude == 0 then
            currentSpeed = math.max(0, currentSpeed - ACCEL * 2)
        else
            currentSpeed = math.clamp(currentSpeed + ACCEL, 0, MovementSettings.WalkspeedValue)
        end

        hrp.Velocity = hum.MoveDirection * currentSpeed + Vector3.new(0, hrp.Velocity.Y, 0)
    end)
end

local function DisableSpeed()
    if MovementSettings.Connections.Speed then
        MovementSettings.Connections.Speed:Disconnect()
        MovementSettings.Connections.Speed = nil
    end

    local hum, _ = GetCharacterParts()
    if hum then
        hum.WalkSpeed = 16 
    end
    currentSpeed = 0
end

-- Jump Power
local function OnStateChanged(oldState, newState)
    if not MovementSettings.JumpPowerEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if newState == Enum.HumanoidStateType.Jumping then
        hum.JumpPower = math.clamp(MovementSettings.JumpPowerValue, 0, 1000)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, hrp.Velocity.Y + MovementSettings.JumpPowerValue * 0.5, hrp.Velocity.Z)
        end
    elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Freefall then
        hum.JumpPower = 50
    end
end

local function SetupCharacter(character)
    local hum = character:WaitForChild("Humanoid")
    hum.StateChanged:Connect(OnStateChanged)
end

-- Noclip
local function ToggleNoclip(state)
    MovementSettings.NoclipEnabled = state

    if MovementSettings.Connections.Noclip then
        MovementSettings.Connections.Noclip:Disconnect()
        MovementSettings.Connections.Noclip = nil
    end

    if state then
        MovementSettings.Connections.Noclip =
            RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
    else
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- CharacterAdded
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.3)

    SetupCharacter(character)

    local hum, _ = GetCharacterParts(character)
    if hum then
        if MovementSettings.JumpPowerEnabled then
            hum.JumpPower = math.clamp(MovementSettings.JumpPowerValue, 0, 300)
        else
            hum.JumpPower = 50
        end
    end

    if MovementSettings.Enabled then
        EnableSpeed()
    else
        DisableSpeed()
    end

    if MovementSettings.NoclipEnabled then
        ToggleNoclip(true)
    else
        ToggleNoclip(false)
    end
end)

if LocalPlayer.Character then
    SetupCharacter(LocalPlayer.Character)

    if MovementSettings.Enabled then
        EnableSpeed()
    end

    if MovementSettings.NoclipEnabled then
        ToggleNoclip(true)
    end
end


-- Movement Button
MovementTab:CreateSection("プレイヤー")

local MovementMessage = "スピードハック起動するとキックされるのを無くしました"

MovementTab:CreateLabel(MovementMessage)

MovementTab:CreateToggle({
    Name = "スピードハック",
    CurrentValue = false,
    Callback = function(v)
        MovementSettings.Enabled = v
        if v then
            EnableSpeed()
        else
            DisableSpeed()
        end
    end
})

MovementTab:CreateSlider({
    Name = "スピード速さ",
    Range = {1, 500},
    Increment = 1,
    CurrentValue = MovementSettings.WalkspeedValue,
    Callback = function(v)
        MovementSettings.WalkspeedValue = v
        if MovementSettings.Enabled then
            EnableSpeed()
        end
    end
})

MovementTab:CreateToggle({
    Name = "ジャンプ力",
    CurrentValue = MovementSettings.JumpPowerEnabled,
    Callback = function(state)
        MovementSettings.JumpPowerEnabled = state
    end
})

MovementTab:CreateSlider({
    Name = "ジャンプ力",
    Range = {50, 1000},
    Increment = 10,
    CurrentValue = MovementSettings.JumpPowerValue,
    Callback = function(value)
        MovementSettings.JumpPowerValue = value
    end
})

MovementTab:CreateToggle({
    Name = "ノークリップ",
    CurrentValue = MovementSettings.NoclipEnabled,
    Callback = function(state)
        ToggleNoclip(state)
    end
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 共通関数
local function GetHRP(char)
	return char and char:FindFirstChild("HumanoidRootPart")
end

-- Aim Lock
CombatTab:CreateSection("キル数")

local KillLabel = CombatTab:CreateLabel("キル数: 0")
local BaseKillCount = 0 
local LastKillCount = 0
local KillValueConnection 

local function UpdateKills()
	if LocalPlayer:FindFirstChild("leaderstats")
	and LocalPlayer.leaderstats:FindFirstChild("Kills") then
		local currentKills = LocalPlayer.leaderstats.Kills.Value
		local displayKills = currentKills - BaseKillCount
		if displayKills < 0 then
			displayKills = 0
		end
		KillLabel:Set("キル数: " .. displayKills)
		
		if currentKills > LastKillCount then
			LastKillCount = currentKills
			
			if CombatTab.Notify then
				CombatTab.Notify({
					Title = "キル通知",
					Content = "キル数が " .. displayKills .. " に増えました！",
					Duration = 3
				})
			else
				print("キル通知: キル数が " .. displayKills .. " に増えました！")
			end
		end
	else
		KillLabel:Set("キル数: N/A")
	end
end

local function ConnectKills()
	if KillValueConnection then
		KillValueConnection:Disconnect()
		KillValueConnection = nil
	end
	
	if LocalPlayer:FindFirstChild("leaderstats")
	and LocalPlayer.leaderstats:FindFirstChild("Kills") then
		local kills = LocalPlayer.leaderstats.Kills
		BaseKillCount = kills.Value -- 基準キル数をここで取得
		LastKillCount = BaseKillCount
		UpdateKills()
		KillValueConnection = kills:GetPropertyChangedSignal("Value"):Connect(UpdateKills)
	end
end

LocalPlayer.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then
		local kills = child:WaitForChild("Kills", 5)
		if kills then
			ConnectKills()
		end
	end
end)

ConnectKills()

CombatTab:CreateSection("エイム")

local CombatMessage = "ターゲットを選択したらエイムロックをオンにしよう"

CombatTab:CreateLabel(CombatMessage)

local AimEnabled = false
local AimTargetName = nil
local AimSmoothness = 0.25

CombatTab:CreateDropdown({
	Name = "ターゲット",
	Options = (function()
		local t = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				table.insert(t, p.Name)
			end
		end
		return t
	end)(),
	CurrentOption = {},
	Callback = function(v)
		AimTargetName = (type(v) == "table") and v[1] or v
	end
})

-- プレイヤー一覧
local function GetOtherPlayerNames()
	local t = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(t, p.Name)
		end
	end
	return t
end

CombatTab:CreateToggle({
	Name = "エイムロック",
	CurrentValue = false,
	Callback = function(v)
		AimEnabled = v
	end
})

-- Auto Farm
CombatTab:CreateSection("バックロック")

local BackLockEnabled = false
local BackLockAllEnabled = false
local BackLockTargetName = nil

local BackLockDistance = 2.5
local BackLockRange = 150
local BackLockSmoothness = 0.25

local CombatMessage = "ターゲットを選択して、バックロックをオンにしよう"

CombatTab:CreateLabel(CombatMessage)

CombatTab:CreateToggle({
	Name = "バックロック",
	CurrentValue = false,
	Callback = function(v)
		BackLockEnabled = v
	end
})

CombatTab:CreateToggle({
	Name = "バックロックオール",
	CurrentValue = false,
	Callback = function(v)
		BackLockAllEnabled = v
	end
})

CombatTab:CreateDropdown({
	Name = "バックロックターゲット",
	Options = (function()
		local t = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				table.insert(t, p.Name)
			end
		end
		return t
	end)(),
	CurrentOption = {},
	Callback = function(v)
		BackLockTargetName = (type(v) == "table") and v[1] or v
	end
})

CombatTab:CreateSlider({
	Name = "バックロックディスタンス",
	Range = {1, 8},
	Increment = 0.5,
	Suffix = "stud",
	CurrentValue = 2.5,
	Callback = function(v)
		BackLockDistance = v
	end
})

local function GetNearestEnemy(myHRP)
	local nearestHRP = nil
	local nearestDist = math.huge

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local hrp = GetHRP(p.Character)
			local hum = p.Character:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local d = (myHRP.Position - hrp.Position).Magnitude
				if d < nearestDist and d <= BackLockRange then
					nearestDist = d
					nearestHRP = hrp
				end
			end
		end
	end

	return nearestHRP
end

RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end

	local myHRP = GetHRP(char)
	if not myHRP then return end

	if AimEnabled and AimTargetName then
		local target = Players:FindFirstChild(AimTargetName)
		if target and target.Character then
			local tHRP = GetHRP(target.Character)
			if tHRP then
				Camera.CFrame = Camera.CFrame:Lerp(
					CFrame.lookAt(Camera.CFrame.Position, tHRP.Position),
					AimSmoothness
				)
			end
		end
	end

	local targetHRP = nil

	if BackLockEnabled and BackLockTargetName then
		local p = Players:FindFirstChild(BackLockTargetName)
		if p and p.Character then
			targetHRP = GetHRP(p.Character)
		end
	end

	if BackLockAllEnabled then
		targetHRP = GetNearestEnemy(myHRP)
	end

	if targetHRP then
		local behindPos =
			targetHRP.Position -
			(targetHRP.CFrame.LookVector * BackLockDistance)

		local cf = CFrame.new(behindPos, targetHRP.Position)
		myHRP.CFrame = myHRP.CFrame:Lerp(cf, BackLockSmoothness)
	end
end)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- Anti
local Anti = {
    Knockback = false,
    Hitstun = false,
    Fling = false,
    Ragdoll = false,
    AntiLag = false,
    AntiSlowWalk = false,
    AntiGravity = false  
}

local AntiGravityConnection = nil

local AntiConnection
local AntiKickdownConnection
local AntiCameraShakeConnection
local AntiAFKConnection
local AntiGravityConnection 

-- 処理機能
local function StartAnti()
    if AntiConnection then return end

    AntiConnection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (hrp and hum and hum.Health > 0) then return end

        -- Anti Fling
        if Anti.Fling then
            if hrp.AssemblyLinearVelocity.Magnitude > 60 then
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
            if hrp.AssemblyAngularVelocity.Magnitude > 40 then
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end

        -- Anti Hitstun
        if Anti.Hitstun then
            local s = hum:GetState()
            if s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end

            if hum.WalkSpeed < 16 then
                hum.WalkSpeed = 16
            end
            if hum.UseJumpPower and hum.JumpPower < 50 then
                hum.JumpPower = 50
            end
        end

        -- Anti SlowWalk
        if Anti.AntiSlowWalk then
            if hum.WalkSpeed < 16 then
                hum.WalkSpeed = 16
            end
        end
    end)
end

-- Anti Gravity
local function StartAntiGravity()
    if AntiGravityConnection then return end
    AntiGravityConnection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if hrp.AssemblyLinearVelocity.Y < -50 then
                hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
            end
        end
    end)
end

local function StopAntiIfNeeded()
    if not (Anti.Knockback or Anti.Hitstun or Anti.Fling or Anti.AntiLag or Anti.AntiSlowWalk or Anti.AntiGravity) then
        if AntiConnection then
            AntiConnection:Disconnect()
            AntiConnection = nil
        end
    end

    if not Anti.AntiGravity and AntiGravityConnection then
        AntiGravityConnection:Disconnect()
        AntiGravityConnection = nil
    end
end

-- Anti Kickdown
local AntiKickdownEnabled = false

local function ToggleAntiKickdown(state)
    AntiKickdownEnabled = state

    if AntiKickdownConnection then
        AntiKickdownConnection:Disconnect()
        AntiKickdownConnection = nil
    end

    if state then
        AntiKickdownConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not (hrp and hum and hum.Health > 0) then return end

            local stateType = hum:GetState()
            if stateType == Enum.HumanoidStateType.Ragdoll or
               stateType == Enum.HumanoidStateType.Physics or
               stateType == Enum.HumanoidStateType.FallingDown or
               stateType == Enum.HumanoidStateType.GettingUp or
               stateType == Enum.HumanoidStateType.Seated or
               stateType == Enum.HumanoidStateType.PlatformStanding then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end

            local vel = hrp.AssemblyLinearVelocity
            if vel.Y > 0 then
                vel = Vector3.new(vel.X, 0, vel.Z)
            end
            hrp.AssemblyLinearVelocity = vel

            if hum.PlatformStand then
                hum.PlatformStand = false
            end
        end)
    end
end

-- Anti Camera Shake
local AntiCameraShakeEnabled = false

local function ToggleAntiCameraShake(state)
    AntiCameraShakeEnabled = state

    if AntiCameraShakeConnection then
        AntiCameraShakeConnection:Disconnect()
        AntiCameraShakeConnection = nil
    end

    if state then
        AntiCameraShakeConnection = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.CameraOffset = Vector3.new(0, 0, 0)
                end
            end
        end)
    end
end

-- Anti AFK
local AntiAFKEnabled = false

local function ToggleAntiAFK(state)
    AntiAFKEnabled = state

    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end

    if state then
        AntiAFKConnection = LocalPlayer.Idled:Connect(function()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end

-- Anti Gravity
local function StartAntiGravity()
    if AntiGravityConnection then return end

    AntiGravityConnection = RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local velocity = hrp.AssemblyLinearVelocity

        if velocity.Y < -50 then
            hrp.AssemblyLinearVelocity = Vector3.new(velocity.X, 0, velocity.Z)
        end
    end)
end

-- Anti Gravity
local function StopAntiGravity()
    if AntiGravityConnection then
        AntiGravityConnection:Disconnect()
        AntiGravityConnection = nil
    end
end

-- Anti Gravity
local function ToggleAntiGravity(state)
    Anti.AntiGravity = state
    if state then
        StartAntiGravity()
    else
        StopAntiGravity()
    end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ENABLED = false
local CONNECTION

local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPPOWER = 50

local BLOCK = {
	BodyVelocity = true,
	BodyPosition = true,
	BodyGyro = true,
	BodyAngularVelocity = true,
	AlignPosition = true,
	AlignOrientation = true,
	LinearVelocity = true,
	AngularVelocity = true
}

local function setupHumanoid(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		DEFAULT_WALKSPEED = hum.WalkSpeed
		DEFAULT_JUMPPOWER = hum.JumpPower
	end
end

local function forceRestore(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end

	-- 減速検知 → 即復元
	if hum.WalkSpeed ~= DEFAULT_WALKSPEED then
		hum.WalkSpeed = DEFAULT_WALKSPEED
	end

	if hum.JumpPower ~= DEFAULT_JUMPPOWER then
		hum.JumpPower = DEFAULT_JUMPPOWER
	end

	-- 固定解除
	hum.PlatformStand = false
	hum.AutoRotate = true

	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
		end
		if BLOCK[p.ClassName] then
			p:Destroy()
		end
	end
end

local function start()
	if CONNECTION then return end

	CONNECTION = RunService.Heartbeat:Connect(function()
		if not ENABLED then return end
		local char = LocalPlayer.Character
		if char then
			forceRestore(char)
		end
	end)
end

local function stop()
	if CONNECTION then
		CONNECTION:Disconnect()
		CONNECTION = nil
	end
end

_G.ToggleAntiSlow = function(state)
	ENABLED = state
	if state then
		start()
	else
		stop()
	end
end

LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.3)
	setupHumanoid(char)
end)

if LocalPlayer.Character then
	setupHumanoid(LocalPlayer.Character)
end

-- Button
AntiTab:CreateSection("アンチ")

local AntiMessage = "全部機能します　バグがあれば教えてください"

AntiTab:CreateLabel(AntiMessage)

AntiTab:CreateToggle({
    Name = "アンチラグドール",
    CurrentValue = false,
    Callback = function(state)
        ToggleAntiKickdown(state)
    end
})

AntiTab:CreateToggle({
    Name = "アンチフライング",
    CurrentValue = false,
    Callback = function(v)
        Anti.Fling = v
        if v then
            StartAnti()
        else
            StopAntiIfNeeded()
        end
    end
})

AntiTab:CreateToggle({
    Name = "アンチ重力",
    CurrentValue = false,
    Callback = function(state)
        ToggleAntiGravity(state)
    end
})

AntiTab:CreateToggle({
    Name = "アンチシェイク",
    CurrentValue = false,
    Callback = ToggleAntiCameraShake
})

-- Troll Tab
TrollTab:CreateSection("荒らし")

TrollTab:CreateButton({
    Name = "invisible",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/OBYJ1UWC/raw"))()
    end
})

TrollTab:CreateButton({
    Name = "Kill all",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/aW96SQyL/raw"))()
    end
})

TrollTab:CreateButton({
    Name = "Touch Fling",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/zxzPV1gw/raw"))()
    end
})

-- ESP Tab
ESPTab:CreateSection("ESP")

local NameESP = false
local BoxESP = false
local LineESP = false
local SkeletonEnabled = false
local HealthBarEnabled = false
local ESPObjects = {}


ESPTab:CreateToggle({ Name="Name ESP", CurrentValue=false, Callback=function(v) NameESP=v end })
ESPTab:CreateToggle({ Name="Box ESP",  CurrentValue=false, Callback=function(v) BoxESP=v end })
ESPTab:CreateToggle({ Name="Line ESP", CurrentValue=false, Callback=function(v) LineESP=v end })

-- ESP Utils
local function ClearESP(plr)
	if ESPObjects[plr] then
		for _, obj in pairs(ESPObjects[plr]) do
			pcall(function() obj:Remove() end)
		end
		ESPObjects[plr] = nil
	end
end

-- Main Loop
RunService.RenderStepped:Connect(function()
	local myChar = LocalPlayer.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

	-- AimLock
	if AimEnabled and AimTarget then
		local p = Players:FindFirstChild(AimTarget)
		if p and p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				Camera.CFrame = Camera.CFrame:Lerp(
					CFrame.lookAt(Camera.CFrame.Position, hrp.Position),
					0.25
				)
			end
		end
	end

	-- BackLock
	if myHRP and (BackLock or BackLockAll) then
		local nearest, dist = nil, math.huge
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				local hrp = p.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local d = (myHRP.Position - hrp.Position).Magnitude
					if d < dist then
						dist = d
						nearest = hrp
					end
				end
			end
		end
		if nearest then
			local pos = nearest.Position - nearest.CFrame.LookVector * BackDistance
			myHRP.CFrame = myHRP.CFrame:Lerp(
				CFrame.new(pos, nearest.Position),
				0.25
			)
		end
	end

	-- ESP
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == LocalPlayer then continue end
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local head = char and char:FindFirstChild("Head")

		if not char or not hrp then
			ClearESP(plr)
			continue
		end

		local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
		if not onScreen then
			ClearESP(plr)
			continue
		end

		ESPObjects[plr] = ESPObjects[plr] or {}

		-- Name ESP
		if NameESP and head and not head:FindFirstChild("NameESP") then
			local b = Instance.new("BillboardGui", head)
			b.Name="NameESP"
			b.Size=UDim2.new(0,100,0,30)
			b.AlwaysOnTop=true
			local t=Instance.new("TextLabel",b)
			t.Size=UDim2.new(1,0,1,0)
			t.BackgroundTransparency=1
			t.Text=plr.Name
			t.TextColor3=Color3.fromRGB(255,255,255)
		elseif not NameESP and head and head:FindFirstChild("NameESP") then
			head.NameESP:Destroy()
     end
    
		if BoxESP then
			if not ESPObjects[plr].Box then
				pcall(function()
					local box = Drawing.new("Square")
					box.Thickness=1
					box.Color=Color3.fromRGB(255,0,0)
					box.Filled=false
					ESPObjects[plr].Box=box
				end)
			end
			local box = ESPObjects[plr].Box
			if box then
				box.Size=Vector2.new(18,36)
				box.Position=Vector2.new(pos.X-9,pos.Y-18)
				box.Visible=true
			end
		elseif ESPObjects[plr].Box then
			ESPObjects[plr].Box.Visible=false
		end

		if LineESP then
			if not ESPObjects[plr].Line then
				pcall(function()
					local l=Drawing.new("Line")
					l.Thickness=1
					l.Color=Color3.fromRGB(255,0,0)
					ESPObjects[plr].Line=l
				end)
			end
			local line=ESPObjects[plr].Line
			if line then
				line.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
				line.To=Vector2.new(pos.X,pos.Y)
				line.Visible=true
			end
		elseif ESPObjects[plr].Line then
			ESPObjects[plr].Line.Visible=false
		end
	end
end)

-- Utils
local function GetHRP()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	return char:WaitForChild("HumanoidRootPart")
end

local function GetPlayerNames()
	local t = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(t, p.Name)
		end
	end
	return t
end

-- Teleport Tab
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function GetHRP()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function GetPlayerNames()
    local names = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(names, player.Name)
        end
    end
    return names
end

-- ▼ 現在座標を文字列で取得
local function GetPositionString()
    local hrp = GetHRP()
    if not hrp then return nil end

    local p = hrp.Position
    return string.format(
        "CFrame.new(%f, %f, %f)",
        p.X, p.Y, p.Z
    )
end

local PlayerNames = GetPlayerNames()
local SelectedTeleportPlayer = nil

TeleportTab:CreateSection("プレイヤー")

local function Notify(text)
    Rayfield:Notify({
        Title = "Teleport",
        Content = text,
        Duration = 3
    })
end

TeleportTab:CreateDropdown({
    Name = "プレイヤー選択",
    Options = PlayerNames,
    CurrentOption = PlayerNames[1],
    Callback = function(value)
        if typeof(value) == "table" then
            SelectedTeleportPlayer = value[1]
        else
            SelectedTeleportPlayer = value
        end
    end
})

TeleportTab:CreateButton({
    Name = "テレポート",
    Callback = function()
        if not SelectedTeleportPlayer then
            warn("No player selected")
            return
        end

        local targetPlayer = Players:FindFirstChild(SelectedTeleportPlayer)
        if not targetPlayer then
            warn("Target player not found")
            return
        end

        local targetChar = targetPlayer.Character
        local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local myHRP = GetHRP()

        if targetHRP and myHRP then
            myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -3)
            Notify("テレポートしました")
        else
            warn("HumanoidRootPart missing")
        end
    end
})

-- ▼ 座標表示＆コピー
TeleportTab:CreateSection("現在の座標")

local PositionLabel = TeleportTab:CreateLabel("座標: 未取得")

TeleportTab:CreateButton({
    Name = "座標を表示",
    Callback = function()
        local posStr = GetPositionString()
        if posStr then
            PositionLabel:Set("座標: " .. posStr)
            Notify("座標を取得しました")
        else
            warn("HumanoidRootPart not found")
        end
    end
})

TeleportTab:CreateButton({
    Name = "座標をコピー",
    Callback = function()
        local posStr = GetPositionString()
        if posStr and setclipboard then
            setclipboard(posStr)
            Notify("座標をコピーしました")
        else
            warn("コピーできません")
        end
    end
})

-- ▼ マップ
TeleportTab:CreateSection("マップ")

TeleportTab:CreateButton({ 
    Name = "映画館", 
    Callback = function()
        local hrp = GetHRP()
        if hrp then
            hrp.CFrame = CFrame.new(-425.6559143066406, -0.47859877347946167, 428.0661315917969)
            Notify("テレポートしました")
        end
    end 
})

TeleportTab:CreateButton({ 
    Name = "練習場",
    Callback = function()
        local hrp = GetHRP()
        if hrp then
            hrp.CFrame = CFrame.new(316.0783996582031, -5.144254684448242, -279.22332763671875)
            Notify("テレポートしました")
        end
    end 
})

TeleportTab:CreateButton({ 
    Name = "1v1エリア",
    Callback = function()
        local hrp = GetHRP()
        if hrp then
            hrp.CFrame = CFrame.new(292.80853271484375, 11.69509506225586, -13.354337692260742)
            Notify("テレポートしました")
        end
    end 
})

local DiscordMessage = "制作者:デスドル"

DiscordTab:CreateLabel(DiscordMessage)

local DiscordMessage = "ディスコードサーバー↓↓↓"

DiscordTab:CreateLabel(DiscordMessage)

DiscordTab:CreateButton({
    Name = "リンクコピー",
    Callback = function()
        setclipboard("https://discord.gg/di-zheng-huang-rashigong-he-guo-1403496250715803790")

        Rayfield:Notify({
            Title = "Discord",
            Content = "リンクコピーしました",
            Duration = 3,
            Image = 4483362458
        })
    end
})
