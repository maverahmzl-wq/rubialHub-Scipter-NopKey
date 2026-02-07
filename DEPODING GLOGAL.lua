-- MAXIMUM STUDIO ADMIN PANEL (NON-EXPLOIT)
-- Single LocalScript | Roblox Studio / Own Game

--------------------------------------------------
-- SERVICES
--------------------------------------------------
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Teams = game:GetService("Teams")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--------------------------------------------------
-- CHARACTER
--------------------------------------------------
local Char, Hum, HRP
local function Refresh()
	Char = Player.Character or Player.CharacterAdded:Wait()
	Hum = Char:WaitForChild("Humanoid")
	HRP = Char:WaitForChild("HumanoidRootPart")
end
Refresh()
Player.CharacterAdded:Connect(Refresh)

--------------------------------------------------
-- STATE
--------------------------------------------------
local State = {
	Fly=false,
	Noclip=false,
	Spin=false,
	ESPNames=false,
	ESPBoxes=false,
	FlySpeed=80,
	SavedPos=nil,
	TimeLock=nil,
	FollowESP=false,
	LockESP=false,
	NameLockESP=false,
	NameLockTarget="",
	SeeMode=nil,
	SeeList={},
	SeeIndex=1,
	SeeManualTarget=nil
}

--------------------------------------------------
-- GUI
--------------------------------------------------
local Gui = Instance.new("ScreenGui", Player.PlayerGui)
Gui.ResetOnSpawn = false

local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.fromScale(0.65,0.65)
Main.Position = UDim2.fromScale(0.175,0.175)
Main.BackgroundColor3 = Color3.fromRGB(22,22,28)
Main.Visible = false
Main.Active = true
Instance.new("UICorner",Main).CornerRadius = UDim.new(0,14)

-- Drag FIX
do
	local dragging, dragStart, startPos
	Main.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = i.Position
			startPos = Main.Position
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - dragStart
			Main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
end

local Left = Instance.new("Frame", Main)
Left.Size = UDim2.fromScale(0.28,1)
Left.BackgroundColor3 = Color3.fromRGB(32,32,42)
Instance.new("UICorner",Left).CornerRadius = UDim.new(0,14)

local Right = Instance.new("Frame", Main)
Right.Size = UDim2.fromScale(0.72,1)
Right.Position = UDim2.fromScale(0.28,0)
Right.BackgroundTransparency = 1

Instance.new("UIListLayout",Left).Padding = UDim.new(0,8)
Instance.new("UIListLayout",Right).Padding = UDim.new(0,10)

--------------------------------------------------
-- UI HELPERS
--------------------------------------------------
local function clearRight()
	for _,v in pairs(Right:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end
end

local function Box(title,height)
	local f = Instance.new("Frame",Right)
	f.Size = UDim2.new(1,-20,0,height or 70)
	f.BackgroundColor3 = Color3.fromRGB(45,45,65)
	Instance.new("UICorner",f)

	local t = Instance.new("TextLabel",f)
	t.Text = title
	t.Size = UDim2.new(1,-10,0,26)
	t.Position = UDim2.new(0,10,0,0)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextSize = 14
	t.TextColor3 = Color3.new(1,1,1)

	return f
end

local function Input(parent,ph,y)
	local i = Instance.new("TextBox",parent)
	i.Size = UDim2.new(0.55,0,0,28)
	i.Position = UDim2.new(0,10,0,y)
	i.PlaceholderText = ph
	i.Text = ""
	i.BackgroundColor3 = Color3.fromRGB(30,30,45)
	i.TextColor3 = Color3.new(1,1,1)
	i.Font = Enum.Font.Gotham
	i.TextSize = 13
	Instance.new("UICorner",i)
	return i
end

local function Button(parent,text,x,y)
	local b = Instance.new("TextButton",parent)
	b.Text = text
	b.Size = UDim2.new(0.3,0,0,28)
	b.Position = UDim2.new(x,0,0,y)
	b.BackgroundColor3 = Color3.fromRGB(75,75,115)
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	Instance.new("UICorner",b)
	return b
end

--------------------------------------------------
-- FLY / NOCLIP / TIME LOOP
--------------------------------------------------
local LV, AO, ATT
RunService.RenderStepped:Connect(function()
	-- FLY
	if State.Fly and LV then
		local dir = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
		LV.VectorVelocity = dir * State.FlySpeed
		AO.CFrame = Camera.CFrame
	end

	-- NOCLIP
	if State.Noclip then
		Hum:ChangeState(Enum.HumanoidStateType.Physics)
		for _,p in pairs(Char:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	else
		for _,p in pairs(Char:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = true end
		end
	end

	-- TIME LOCK
	if State.TimeLock ~= nil then
		Lighting.ClockTime = State.TimeLock
	end
end)

--------------------------------------------------
-- ESP SYSTEM
--------------------------------------------------
local ESPFolder = Instance.new("Folder",Gui)
ESPFolder.Name="ESP"

local function ClearESP()
	for _,v in pairs(ESPFolder:GetChildren()) do v:Destroy() end
end

local function UpdateESP()
	ClearESP()
	local myTeam = Player.Team
	for _,plr in pairs(Players:GetPlayers()) do
		if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			-- Names ESP with team colors
			if State.ESPNames then
				local bb = Instance.new("BillboardGui",ESPFolder)
				bb.Adornee = plr.Character.HumanoidRootPart
				bb.Size = UDim2.fromOffset(120,40)
				bb.AlwaysOnTop = true
				local tl = Instance.new("TextLabel",bb)
				tl.Size = UDim2.fromScale(1,1)
				tl.BackgroundTransparency = 1
				tl.Text = plr.Name
				if plr.Team == myTeam then
					tl.TextColor3 = Color3.fromRGB(0,150,255) -- Mavi
				else
					tl.TextColor3 = Color3.fromRGB(255,0,0) -- Kırmızı
				end
				tl.TextStrokeTransparency = 0
			end
			-- Boxes ESP
			if State.ESPBoxes then
				local box = Instance.new("BoxHandleAdornment")
				box.Adornee = plr.Character
				box.AlwaysOnTop = true
				box.ZIndex = 10
				box.Size = plr.Character:GetExtentsSize() + Vector3.new(0.5,0.5,0.5)
				box.Transparency = 0.6
				box.Color3 = Color3.fromRGB(255,60,60)
				box.Parent = ESPFolder
			end
		end
	end
end

Players.PlayerAdded:Connect(UpdateESP)
Players.PlayerRemoving:Connect(UpdateESP)

--------------------------------------------------
-- CATEGORIES
--------------------------------------------------
local Categories = {}

-- MOVEMENT
Categories.Movement = function()
	clearRight()
	local b1 = Box("Walk Speed")
	local i1 = Input(b1,"e.g. 50",30)
	Button(b1,"Apply",0.65,30).MouseButton1Click:Connect(function()
		Hum.WalkSpeed = tonumber(i1.Text) or Hum.WalkSpeed
	end)

	local b2 = Box("Jump Power")
	local i2 = Input(b2,"e.g. 120",30)
	Button(b2,"Apply",0.65,30).MouseButton1Click:Connect(function()
		Hum.JumpPower = tonumber(i2.Text) or Hum.JumpPower
	end)

	local b3 = Box("Fly")
	local i3 = Input(b3,"Fly Speed",30)
	Button(b3,"Toggle",0.65,30).MouseButton1Click:Connect(function()
		State.FlySpeed = tonumber(i3.Text) or State.FlySpeed
		State.Fly = not State.Fly
		if State.Fly then
			ATT = Instance.new("Attachment",HRP)
			LV = Instance.new("LinearVelocity",HRP)
			LV.Attachment0 = ATT
			LV.MaxForce = math.huge
			AO = Instance.new("AlignOrientation",HRP)
			AO.Attachment0 = ATT
			AO.MaxTorque = math.huge
		else
			if LV then LV:Destroy() end
			if AO then AO:Destroy() end
			if ATT then ATT:Destroy() end
		end
	end)

	local b4 = Box("Noclip",50)
	Button(b4,"Toggle",0.1,22).MouseButton1Click:Connect(function()
		State.Noclip = not State.Noclip
	end)
end

-- VISUAL
Categories.Visual = function()
	clearRight()
	local b1 = Box("ESP")
	Button(b1,"Names",0.1,30).MouseButton1Click:Connect(function()
		State.ESPNames = not State.ESPNames
		UpdateESP()
	end)
	Button(b1,"Boxes",0.45,30).MouseButton1Click:Connect(function()
		State.ESPBoxes = not State.ESPBoxes
		UpdateESP()
	end)

	local b2 = Box("FOV")
	local i2 = Input(b2,"e.g. 100",30)
	Button(b2,"Apply",0.65,30).MouseButton1Click:Connect(function()
		Camera.FieldOfView = tonumber(i2.Text) or Camera.FieldOfView
	end)

	local b3 = Box("Time")
	Button(b3,"Day",0.1,30).MouseButton1Click:Connect(function()
		State.TimeLock = 14
	end)
	Button(b3,"Night",0.45,30).MouseButton1Click:Connect(function()
		State.TimeLock = 0
	end)
end

-- CHARACTER
Categories.Character = function()
	clearRight()
	local b1 = Box("God Mode",50)
	Button(b1,"God",0.1,22).MouseButton1Click:Connect(function()
		Hum.MaxHealth = math.huge
		Hum.Health = math.huge
	end)
	Button(b1,"Ungod",0.45,22).MouseButton1Click:Connect(function()
		Hum.MaxHealth = 100
		Hum.Health = 100
	end)

	local b2 = Box("Visibility",50)
	Button(b2,"Invisible",0.1,22).MouseButton1Click:Connect(function()
		for _,p in pairs(Char:GetDescendants()) do
			if p:IsA("BasePart") then p.Transparency = 1 end
		end
	end)
	Button(b2,"Visible",0.45,22).MouseButton1Click:Connect(function()
		for _,p in pairs(Char:GetDescendants()) do
			if p:IsA("BasePart") then p.Transparency = 0 end
		end
	end)
end

-- TELEPORT
Categories.Teleport = function()
	clearRight()
	local b1 = Box("Teleport To Player")
	local i1 = Input(b1,"Player name",30)
	Button(b1,"TP",0.65,30).MouseButton1Click:Connect(function()
		for _,p in pairs(Players:GetPlayers()) do
			if string.find(string.lower(p.Name), string.lower(i1.Text)) then
				if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
					HRP.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-3)
				end
			end
		end
	end)
	local b2 = Box("Positions",50)
	Button(b2,"Save",0.1,22).MouseButton1Click:Connect(function()
		State.SavedPos = HRP.CFrame
	end)
	Button(b2,"Load",0.45,22).MouseButton1Click:Connect(function()
		if State.SavedPos then HRP.CFrame = State.SavedPos end
	end)
end

-- SEE
Categories.See = function()
	clearRight()

	local b1 = Box("See",200)

	-- Random Label
	local lbl = Instance.new("TextLabel",b1)
	lbl.Text = "Random"
	lbl.Size = UDim2.new(1,0,0,20)
	lbl.Position = UDim2.new(0,0,0,0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.new(1,1,1)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14

	-- Alt Frame for X / <- / -> buttons
	local BottomFrame = Instance.new("Frame", Gui)
	BottomFrame.Size = UDim2.new(0.3,0,0,40)
	BottomFrame.Position = UDim2.new(0.35,0,0.95,0)
	BottomFrame.BackgroundTransparency = 0.5
	BottomFrame.Visible = false
	Instance.new("UICorner", BottomFrame)

	local function CreateBottomButton(text, posX)
		local btn = Instance.new("TextButton", BottomFrame)
		btn.Text = text
		btn.Size = UDim2.new(0.3,0,1,0)
		btn.Position = UDim2.new(posX,0,0,0)
		btn.BackgroundColor3 = Color3.fromRGB(75,75,115)
		btn.TextColor3 = Color3.new(1,1,1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		Instance.new("UICorner", btn)
		return btn
	end

	local btnX = CreateBottomButton("X",0.35)
	btnX.MouseButton1Click:Connect(function()
		State.SeeMode = nil
		State.SeeManualTarget = nil
		BottomFrame.Visible = false
	end)

	local btnLeft = CreateBottomButton("<-",0.05)
	btnLeft.MouseButton1Click:Connect(function()
		if #State.SeeList > 0 then
			State.SeeIndex -= 1
			if State.SeeIndex < 1 then State.SeeIndex = #State.SeeList end
		end
	end)

	local btnRight = CreateBottomButton("->",0.65)
	btnRight.MouseButton1Click:Connect(function()
		if #State.SeeList > 0 then
			State.SeeIndex += 1
			if State.SeeIndex > #State.SeeList then State.SeeIndex = 1 end
		end
	end)

	-- Random Buttons
	local function RandomButton(text, x, filterFunc)
		local btn = Instance.new("TextButton",b1)
		btn.Text = text
		btn.Size = UDim2.new(0.3,0,0,28)
		btn.Position = UDim2.new(x,0,0,25)
		btn.BackgroundColor3 = Color3.fromRGB(75,75,115)
		btn.TextColor3 = Color3.new(1,1,1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		Instance.new("UICorner",btn)

		btn.MouseButton1Click:Connect(function()
			State.SeeList = {}
			for _,plr in pairs(Players:GetPlayers()) do
				if filterFunc(plr) then
					table.insert(State.SeeList, plr)
				end
			end
			if #State.SeeList > 0 then
				State.SeeIndex = 1
				State.SeeMode = true
				Main.Visible = false
				BottomFrame.Visible = true
			end
		end)

		return btn
	end

	RandomButton("Your Team",0.05,function(plr) return plr.Team == Player.Team and plr ~= Player end)
	RandomButton("Left Team",0.35,function(plr) return plr.Team ~= Player.Team end)
	RandomButton("All Team",0.65,function(plr) return plr ~= Player end)

	-- Name Input + See button
	local nameInput = Input(b1,"Player Name",100)
	local seeBtn = Button(b1,"See",0.65,100)
	seeBtn.MouseButton1Click:Connect(function()
		local name = nameInput.Text
		for _,plr in pairs(Players:GetPlayers()) do
			if string.lower(plr.Name) == string.lower(name) then
				State.SeeManualTarget = plr
				Main.Visible = false
				BottomFrame.Visible = true
			end
		end
	end)
end

-- SEE FOLLOW LOOP
RunService.RenderStepped:Connect(function()
	if State.SeeMode and #State.SeeList > 0 then
		local target = State.SeeList[State.SeeIndex]
		if target and target.Character and target.Character:FindFirstChild("Humanoid") then
			Camera.CameraSubject = target.Character.Humanoid
			Camera.CameraType = Enum.CameraType.Custom
		end
	elseif State.SeeManualTarget then
		local target = State.SeeManualTarget
		if target and target.Character and target.Character:FindFirstChild("Humanoid") then
			Camera.CameraSubject = target.Character.Humanoid
			Camera.CameraType = Enum.CameraType.Custom
		end
	else
		Camera.CameraSubject = Hum
		Camera.CameraType = Enum.CameraType.Custom
	end
end)


-- LEFT PANEL
for name,func in pairs(Categories) do
	local b = Instance.new("TextButton",Left)
	b.Size = UDim2.new(1,-12,0,36)
	b.Text = name
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(60,60,90)
	Instance.new("UICorner",b)
	b.MouseButton1Click:Connect(func)
end

-- TOGGLE KEY
UIS.InputBegan:Connect(function(i,gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.T then
		Main.Visible = not Main.Visible
	end
end)
