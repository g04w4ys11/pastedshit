if not game:IsLoaded() then
	game.Loaded:Wait();
end
local SilentAimSettings = {Enabled=false,ClassName="MARINE.ALPHA",ToggleKey="non",TeamCheck=false,VisibleCheck=false,SpiderEnabled=false,SpiderSpeed=50,SpiderToggleKey="non",NoShadow=false,NoFog=false,ForceDay=false,NoSky=false,ThirdPersonEnabled=false,ThirdPersonDistance=20,ThirdPersonHeight=5,ThirdPersonSensitivity=0.25,AntiAimEnabled=false,AntiAimSpinSpeed=40,TargetPart="HumanoidRootPart",SilentAimMethod="Raycast",FOVRadius=130,FOVVisible=false,HitChance=100,AmbienceEnabled=false,SelectedAmbience="Green",CameraFOV=70,CameraFOVMin=30,CameraFOVMax=120,CameraFOVStep=5,SnaplineEnabled=false,SnaplineColor=Color3.fromRGB(255, 255, 255),SnaplineThickness=1,HomeXrayEnabled=false,CustomSkyEnabled=false,SelectedSkybox="",StaffOnlineEnabled=true,ShowAllStaff=false};
getgenv().SilentAimSettings = SilentAimSettings;
local MainFileName = "MARINEALPHA";
local SelectedFile, FileToSave = "", "";
local Camera = workspace.CurrentCamera;
local Players = game:GetService("Players");
local RunService = game:GetService("RunService");
local GuiService = game:GetService("GuiService");
local UserInputService = game:GetService("UserInputService");
local HttpService = game:GetService("HttpService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Lighting = game:GetService("Lighting");
local currentFOV = SilentAimSettings.CameraFOV;
local function UpdateFOV(newFOV)
	currentFOV = math.clamp(newFOV, SilentAimSettings.CameraFOVMin, SilentAimSettings.CameraFOVMax);
	Camera.FieldOfView = currentFOV;
end
UpdateFOV(SilentAimSettings.CameraFOV);
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return;
	end
	if (input.KeyCode == Enum.KeyCode.L) then
		UpdateFOV(currentFOV + SilentAimSettings.CameraFOVStep);
		print("FOV D3C2C5CbC8D7C5Cd: " .. currentFOV);
	end
	if (input.KeyCode == Enum.KeyCode.K) then
		UpdateFOV(currentFOV - SilentAimSettings.CameraFOVStep);
		print("FOV D3CcC5CdDcD8C5Cd: " .. currentFOV);
	end
end);
local AmbiencePresets = {Red=Color3.fromRGB(255, 80, 80),Green=Color3.fromRGB(100, 255, 100),Blue=Color3.fromRGB(100, 100, 255),Yellow=Color3.fromRGB(255, 255, 100),Purple=Color3.fromRGB(180, 100, 255)};
local function ApplyAmbience()
	if SilentAimSettings.AmbienceEnabled then
		local color = AmbiencePresets[SilentAimSettings.SelectedAmbience];
		if color then
			Lighting.Ambient = color;
			Lighting.OutdoorAmbient = color;
			Lighting.FogColor = color;
		end
	else
		Lighting.Ambient = Color3.fromRGB(127, 127, 127);
		Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127);
		Lighting.FogColor = Color3.fromRGB(191, 191, 191);
	end
end
ApplyAmbience(SilentAimSettings.SelectedAmbience);
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();
local GetChildren = game.GetChildren;
local GetPlayers = Players.GetPlayers;
local WorldToScreen = Camera.WorldToScreenPoint;
local WorldToViewportPoint = Camera.WorldToViewportPoint;
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget;
local FindFirstChild = game.FindFirstChild;
local RenderStepped = RunService.RenderStepped;
local GuiInset = GuiService.GetGuiInset;
local GetMouseLocation = UserInputService.GetMouseLocation;
local resume = coroutine.resume;
local create = coroutine.create;
local ValidTargetParts = {"Head","HumanoidRootPart"};
local fov_circle = Drawing.new("Circle");
fov_circle.Thickness = 1;
fov_circle.NumSides = 100;
fov_circle.Radius = 130;
fov_circle.Filled = false;
fov_circle.Visible = false;
fov_circle.ZIndex = 999;
fov_circle.Transparency = 1;
fov_circle.Color = Color3.fromRGB(255, 255, 255);
local snapline = Drawing.new("Line");
snapline.Color = SilentAimSettings.SnaplineColor;
snapline.Thickness = SilentAimSettings.SnaplineThickness;
snapline.Transparency = 1;
snapline.Visible = false;
snapline.ZIndex = 998;
local ExpectedArguments = {Raycast={ArgCountRequired=3,Args={"Instance","Vector3","Vector3","RaycastParams"}}};
function CalculateChance(Percentage)
	Percentage = math.floor(Percentage);
	local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100;
	return chance <= (Percentage / 100);
end
local function GetFiles()
	local out = {};
	for i, file in ipairs(listfiles(string.format("%s/%s", MainFileName, tostring(game.PlaceId)))) do
		if (file:sub(-4) == ".lua") then
			local pos = file:find(".lua", 1, true);
			local start = pos;
			local char = file:sub(pos, pos);
			while (char ~= "/") and (char ~= "\\") and (char ~= "") do
				pos = pos - 1;
				char = file:sub(pos, pos);
			end
			if ((char == "/") or (char == "\\")) then
				table.insert(out, file:sub(pos + 1, start - 1));
			end
		end
	end
	return out;
end
local function UpdateFile(FileName)
	assert(type(FileName) == "string", "FileName must be a string");
	writefile(string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName), HttpService:JSONEncode(SilentAimSettings));
end
local function LoadFile(FileName)
	assert(type(FileName) == "string", "FileName must be a string");
	local File = string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName);
	local ConfigData = HttpService:JSONDecode(readfile(File));
	for Index, Value in next, ConfigData do
		SilentAimSettings[Index] = Value;
	end
	Options.CameraFOV:SetValue(SilentAimSettings.CameraFOV);
	Options.FOVStep:SetValue(SilentAimSettings.CameraFOVStep);
	UpdateFOV(SilentAimSettings.CameraFOV);
end
local function getPositionOnScreen(Vector)
	local Vec3, OnScreen = WorldToScreen(Camera, Vector);
	return Vector2.new(Vec3.X, Vec3.Y), OnScreen;
end
local function ValidateArguments(Args, RayMethod)
	local Matches = 0;
	if (#Args < RayMethod.ArgCountRequired) then
		return false;
	end
	for Pos, Argument in next, Args do
		if (typeof(Argument) == RayMethod.Args[Pos]) then
			Matches = Matches + 1;
		end
	end
	return Matches >= RayMethod.ArgCountRequired;
end
local function getDirection(Origin, Position)
	return (Position - Origin).Unit * 1000;
end
local function getMousePosition()
	return GetMouseLocation(UserInputService);
end
local function IsPlayerVisible(Player)
	local PlayerCharacter = Player.Character;
	local LocalPlayerCharacter = LocalPlayer.Character;
	if not (PlayerCharacter and LocalPlayerCharacter) then
		return;
	end
	local PlayerRoot = FindFirstChild(PlayerCharacter, SilentAimSettings.TargetPart) or FindFirstChild(PlayerCharacter, "HumanoidRootPart");
	if not PlayerRoot then
		return;
	end
	local CastPoints = {PlayerRoot.Position};
	local IgnoreList = {LocalPlayerCharacter,PlayerCharacter};
	local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList);
	return ObscuringObjects == 0;
end
local function getClosestPlayer()
	if not Options.TargetPart.Value then
		return;
	end
	local Closest;
	local DistanceToMouse;
	for _, Player in next, GetPlayers(Players) do
		if (Player == LocalPlayer) then
			continue;
		end
		if (Toggles.TeamCheck.Value and (Player.Team == LocalPlayer.Team)) then
			continue;
		end
		local Character = Player.Character;
		if not Character then
			continue;
		end
		if (Toggles.VisibleCheck.Value and not IsPlayerVisible(Player)) then
			continue;
		end
		local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart");
		local Humanoid = FindFirstChild(Character, "Humanoid");
		if (not HumanoidRootPart or not Humanoid or (Humanoid.Health <= 0)) then
			continue;
		end
		local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position);
		if not OnScreen then
			continue;
		end
		local Distance = (getMousePosition() - ScreenPosition).Magnitude;
		if (Distance <= (DistanceToMouse or Options.Radius.Value or 2000)) then
			Closest = ((Options.TargetPart.Value == "Random") and Character[ValidTargetParts[math.random(1, #ValidTargetParts)]]) or Character[Options.TargetPart.Value];
			DistanceToMouse = Distance;
		end
	end
	return Closest;
end
local function setupNoRecoil()
	local recoilModule = nil;
	pcall(function()
		recoilModule = require(ReplicatedStorage:WaitForChild("Gun"):WaitForChild("Scripts"):WaitForChild("RecoilHandler"));
	end);
	if recoilModule then
		RunService.RenderStepped:Connect(function()
			pcall(function()
				recoilModule.nextStep = function()
				end;
				recoilModule.setRecoilMultiplier = function()
				end;
			end);
		end);
		print("No Recoil enabled!");
	else
		warn("&a0�0f recoilModule CdC5 CdC0C9C4C5Cd!");
	end
end
local RunService = game:GetService("RunService");
local whitelistKeywords = {"TwigWall","SoloTwigFrame","TrigTwigRoof","TwigFrame","TwigWindow","TwigRoof"};
local function isWhitelisted(name)
	for _, keyword in ipairs(whitelistKeywords) do
		if string.find(name, keyword) then
			return true;
		end
	end
	return false;
end
local xrayTargets = {};
local function registerForXray(obj)
	if xrayTargets[obj] then
		return;
	end
	if (obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation")) then
		if isWhitelisted(obj.Name) then
			xrayTargets[obj] = {OriginalTransparency=obj.Transparency};
			if SilentAimSettings.HomeXrayEnabled then
				obj.Transparency = 0.7;
			end
			obj.CanCollide = true;
		end
	end
	for _, desc in pairs(obj:GetDescendants()) do
		if (desc:IsA("BasePart") or desc:IsA("MeshPart") or desc:IsA("UnionOperation")) then
			if isWhitelisted(desc.Name) then
				xrayTargets[desc] = {OriginalTransparency=desc.Transparency};
				if SilentAimSettings.HomeXrayEnabled then
					desc.Transparency = 0.7;
				end
				desc.CanCollide = true;
			end
		end
	end
end
local function initializeXray()
	for _, obj in pairs(workspace:GetDescendants()) do
		if isWhitelisted(obj.Name) then
			registerForXray(obj);
		end
	end
end
local descendantAddedConnection;
local function connectDescendantAdded()
	descendantAddedConnection = workspace.DescendantAdded:Connect(function(obj)
		if isWhitelisted(obj.Name) then
			task.delay(1, function()
				registerForXray(obj);
			end);
		end
	end);
end
local xrayConnection;
local function updateXray()
	if not xrayConnection then
		xrayConnection = RunService.RenderStepped:Connect(function()
			if SilentAimSettings.HomeXrayEnabled then
				for part, data in pairs(xrayTargets) do
					if (part and part:IsDescendantOf(workspace)) then
						part.Transparency = 0.7;
						part.CanCollide = true;
					end
				end
			else
				for part, data in pairs(xrayTargets) do
					if (part and part:IsDescendantOf(workspace)) then
						part.Transparency = data.OriginalTransparency;
						part.CanCollide = true;
					end
				end
			end
		end);
	end
end
local function toggleHomeXray(enabled)
	SilentAimSettings.HomeXrayEnabled = enabled;
	if enabled then
		initializeXray();
		connectDescendantAdded();
		updateXray();
	else
		if xrayConnection then
			xrayConnection:Disconnect();
			xrayConnection = nil;
		end
		if descendantAddedConnection then
			descendantAddedConnection:Disconnect();
			descendantAddedConnection = nil;
		end
		for part, data in pairs(xrayTargets) do
			if (part and part:IsDescendantOf(workspace)) then
				part.Transparency = data.OriginalTransparency;
			end
		end
	end
end
local skyboxPresets = {Galaxy={SkyboxBk="rbxassetid://1138550863",SkyboxDn="rbxassetid://1138551165",SkyboxFt="rbxassetid://1138552163",SkyboxLf="rbxassetid://1138551555",SkyboxRt="rbxassetid://1138552890",SkyboxUp="rbxassetid://153520294"},Island={SkyboxBk="http://www.roblox.com/asset/?id=14753804949",SkyboxDn="http://www.roblox.com/asset/?id=14753795573",SkyboxFt="http://www.roblox.com/asset/?id=14753807625",SkyboxLf="http://www.roblox.com/asset/?id=14753797417",SkyboxRt="http://www.roblox.com/asset/?id=14753799966",SkyboxUp="http://www.roblox.com/asset/?id=14753810287"},["Purple Sky"]={SkyboxBk="http://www.roblox.com/asset/?id=16553658937",SkyboxDn="http://www.roblox.com/asset/?id=16553660713",SkyboxFt="http://www.roblox.com/asset/?id=16553662144",SkyboxLf="http://www.roblox.com/asset/?id=16553664042",SkyboxRt="http://www.roblox.com/asset/?id=16553665766",SkyboxUp="http://www.roblox.com/asset/?id=16553667750"},Forest={SkyboxBk="rbxassetid://17428978603",SkyboxDn="rbxassetid://17428977445",SkyboxFt="rbxassetid://17428977114",SkyboxLf="rbxassetid://17428978399",SkyboxRt="rbxassetid://17428976828",SkyboxUp="rbxassetid://17428976669"},City={SkyboxBk="http://www.roblox.com/asset/?id=10345426",SkyboxDn="http://www.roblox.com/asset/?id=10345444",SkyboxFt="http://www.roblox.com/asset/?id=10345426",SkyboxLf="http://www.roblox.com/asset/?id=10345426",SkyboxRt="http://www.roblox.com/asset/?id=10345426",SkyboxUp="http://www.roblox.com/asset/?id=10345487"},Minecraft={SkyboxBk="http://www.roblox.com/asset/?id=3754796725",SkyboxDn="http://www.roblox.com/asset/?id=3754833439",SkyboxFt="http://www.roblox.com/asset/?id=3754795891",SkyboxLf="http://www.roblox.com/asset/?id=3754798649",SkyboxRt="http://www.roblox.com/asset/?id=3754799327",SkyboxUp="http://www.roblox.com/asset/?id=3754888841"}};
local originalSkyProperties = nil;
local function applySkybox(skyboxName)
	local sky = game.Lighting:FindFirstChild("Sky");
	if not sky then
		sky = Instance.new("Sky");
		sky.Parent = game.Lighting;
	end
	if (SilentAimSettings.CustomSkyEnabled and skyboxName and skyboxPresets[skyboxName]) then
		if not originalSkyProperties then
			originalSkyProperties = {SkyboxBk=sky.SkyboxBk,SkyboxDn=sky.SkyboxDn,SkyboxFt=sky.SkyboxFt,SkyboxLf=sky.SkyboxLf,SkyboxRt=sky.SkyboxRt,SkyboxUp=sky.SkyboxUp};
		end
		local preset = skyboxPresets[skyboxName];
		sky.SkyboxBk = preset.SkyboxBk;
		sky.SkyboxDn = preset.SkyboxDn;
		sky.SkyboxFt = preset.SkyboxFt;
		sky.SkyboxLf = preset.SkyboxLf;
		sky.SkyboxRt = preset.SkyboxRt;
		sky.SkyboxUp = preset.SkyboxUp;
	elseif originalSkyProperties then
		sky.SkyboxBk = originalSkyProperties.SkyboxBk;
		sky.SkyboxDn = originalSkyProperties.SkyboxDn;
		sky.SkyboxFt = originalSkyProperties.SkyboxFt;
		sky.SkyboxLf = originalSkyProperties.SkyboxLf;
		sky.SkyboxRt = originalSkyProperties.SkyboxRt;
		sky.SkyboxUp = originalSkyProperties.SkyboxUp;
	end
end
local groupId = 15631191;
local ranks = {Admin=Color3.fromRGB(255, 0, 0),["Admin+"]=Color3.fromRGB(139, 0, 0),Bob=Color3.fromRGB(0, 255, 0)};
local windowPos = Vector2.new(200, 200);
local windowW, headerH = 220, 24;
local dragging, offset = false, Vector2.new(0, 0);
local bg = Drawing.new("Square");
bg.Filled = true;
bg.Color = Color3.fromRGB(20, 20, 20);
bg.Transparency = 1;
bg.Visible = SilentAimSettings.StaffOnlineEnabled;
local title = Drawing.new("Text");
title.Text = "Staff List";
title.Size = 16;
title.Color = Color3.new(1, 1, 1);
title.Outline = true;
title.Center = false;
title.Visible = SilentAimSettings.StaffOnlineEnabled;
local entries, staff = {}, {};
local function loadStaff()
	staff = {};
	local success, rolesRaw = pcall(function()
		return game:HttpGet("https://groups.roblox.com/v1/groups/" .. groupId .. "/roles");
	end);
	if not success then
		warn("Failed to load group roles");
		return;
	end
	local roles = HttpService:JSONDecode(rolesRaw).roles;
	local userCache = {};
	for _, role in ipairs(roles) do
		if ranks[role.name] then
			local url = string.format("https://groups.roblox.com/v1/groups/%d/roles/%d/users?limit=100", groupId, role.id);
			local ok, usersRaw = pcall(function()
				return game:HttpGet(url);
			end);
			if ok then
				local users = HttpService:JSONDecode(usersRaw).data;
				for _, user in ipairs(users) do
					if not userCache[user.username] then
						userCache[user.username] = true;
						table.insert(staff, {name=user.username,rank=role.name,online=false});
					end
				end
			end
		end
	end
end
local function updateOnline()
	for _, e in pairs(staff) do
		e.online = false;
	end
	for _, p in pairs(Players:GetPlayers()) do
		for _, e in pairs(staff) do
			if (p.Name == e.name) then
				e.online = true;
			end
		end
	end
end
local function redraw()
	for _, v in ipairs(entries) do
		v.rank:Remove();
		v.name:Remove();
		v.status:Remove();
	end
	entries = {};
	if not SilentAimSettings.StaffOnlineEnabled then
		bg.Visible = false;
		title.Visible = false;
		return;
	end
	local visibleStaff = {};
	for _, e in ipairs(staff) do
		if (SilentAimSettings.ShowAllStaff or e.online) then
			table.insert(visibleStaff, e);
		end
	end
	bg.Size = Vector2.new(windowW, headerH + (#visibleStaff * 18));
	bg.Position = windowPos;
	bg.Visible = true;
	title.Position = windowPos + Vector2.new(5, 2);
	title.Visible = true;
	for i, e in ipairs(visibleStaff) do
		local y = windowPos.Y + headerH + ((i - 1) * 18);
		local tr = Drawing.new("Text");
		tr.Text = e.rank;
		tr.Color = ranks[e.rank];
		tr.Size = 14;
		tr.Outline = true;
		tr.Position = Vector2.new(windowPos.X + 5, y);
		tr.Visible = true;
		local tn = Drawing.new("Text");
		tn.Text = e.name;
		tn.Color = Color3.fromRGB(230, 230, 230);
		tn.Size = 14;
		tn.Outline = true;
		tn.Position = Vector2.new(windowPos.X + 75, y);
		tn.Visible = true;
		local ts = Drawing.new("Text");
		ts.Text = (e.online and "�3d�e2 ON") or "&ab OFF";
		ts.Color = (e.online and Color3.fromRGB(0, 255, 0)) or Color3.fromRGB(120, 120, 120);
		ts.Size = 14;
		ts.Outline = true;
		ts.Position = Vector2.new(windowPos.X + 160, y);
		ts.Visible = true;
		table.insert(entries, {rank=tr,name=tn,status=ts});
	end
end
local staffConnection;
local function toggleStaffOnline(enabled)
	SilentAimSettings.StaffOnlineEnabled = enabled;
	if enabled then
		loadStaff();
		updateOnline();
		redraw();
		if not staffConnection then
			staffConnection = RunService.RenderStepped:Connect(function()
				if dragging then
					local m = UserInputService:GetMouseLocation();
					if (m and windowPos) then
						windowPos = m - offset;
						bg.Position = windowPos;
						title.Position = windowPos + Vector2.new(5, 2);
						redraw();
					end
				end
			end);
			Players.PlayerAdded:Connect(function()
				updateOnline();
				redraw();
			end);
			Players.PlayerRemoving:Connect(function()
				updateOnline();
				redraw();
			end);
		end
	else
		if staffConnection then
			staffConnection:Disconnect();
			staffConnection = nil;
		end
		for _, v in ipairs(entries) do
			v.rank:Remove();
			v.name:Remove();
			v.status:Remove();
		end
		entries = {};
		bg.Visible = false;
		title.Visible = false;
	end
end
UserInputService.InputBegan:Connect(function(input)
	if ((input.UserInputType == Enum.UserInputType.MouseButton1) and SilentAimSettings.StaffOnlineEnabled) then
		local m = UserInputService:GetMouseLocation();
		if (m and windowPos and (m.X >= windowPos.X) and (m.X <= (windowPos.X + windowW)) and (m.Y >= windowPos.Y) and (m.Y <= (windowPos.Y + headerH))) then
			dragging = true;
			offset = m - windowPos;
		end
	end
end);
UserInputService.InputEnded:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1) then
		dragging = false;
	end
end);
toggleStaffOnline(SilentAimSettings.StaffOnlineEnabled);
local spiderConnection;
local function updateSpider()
	local speaker = Players.LocalPlayer;
	local userInputService = game:GetService("UserInputService");
	local character = speaker.Character;
	local humanoidRootPart;
	spiderConnection = RunService.RenderStepped:Connect(function(delta)
		if not SilentAimSettings.SpiderEnabled then
			return;
		end
		character = speaker.Character;
		if (not character or not character.Parent or not character:FindFirstChild("HumanoidRootPart")) then
			speaker.CharacterAdded:Wait();
			character = speaker.Character;
		end
		humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart");
		if not humanoidRootPart then
			return;
		end
		local rayOrigin = humanoidRootPart.Position;
		local rayDirection = humanoidRootPart.CFrame.LookVector * 2;
		local raycastParams = RaycastParams.new();
		raycastParams.FilterDescendantsInstances = {character};
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist;
		local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams);
		if (raycastResult and userInputService:IsKeyDown(Enum.KeyCode.Space)) then
			local moveDirection = Vector3.new(0, 1, 0);
			humanoidRootPart.Velocity = moveDirection * SilentAimSettings.SpiderSpeed;
		else
			humanoidRootPart.Velocity = Vector3.new(humanoidRootPart.Velocity.X, humanoidRootPart.Velocity.Y, humanoidRootPart.Velocity.Z);
		end
	end);
end
local visualConnection;
local originalFogEnd = Lighting.FogEnd;
local originalClockTime = Lighting.ClockTime;
local originalGlobalShadows = Lighting.GlobalShadows;
local originalSky = Lighting:FindFirstChildOfClass("Sky");
local function updateVisuals()
	if not visualConnection then
		visualConnection = RunService.RenderStepped:Connect(function()
			if SilentAimSettings.NoShadow then
				Lighting.GlobalShadows = false;
			else
				Lighting.GlobalShadows = originalGlobalShadows;
			end
			if SilentAimSettings.NoFog then
				Lighting.FogEnd = 100000;
			else
				Lighting.FogEnd = originalFogEnd;
			end
			if SilentAimSettings.ForceDay then
				Lighting.ClockTime = 12;
			else
				Lighting.ClockTime = originalClockTime;
			end
			if SilentAimSettings.NoSky then
				local sky = Lighting:FindFirstChildOfClass("Sky");
				if sky then
					sky.Parent = nil;
				end
			elseif (originalSky and not Lighting:FindFirstChildOfClass("Sky")) then
				originalSky.Parent = Lighting;
			end
		end);
	end
end
local thirdPersonConnection;
local thirdPersonMouseConnection;
local function updateThirdPerson()
	local char = LocalPlayer.Character;
	if not char then
		return;
	end
	local HRP = char:FindFirstChild("HumanoidRootPart");
	local humanoid = char:FindFirstChild("Humanoid");
	if (not HRP or not humanoid) then
		return;
	end
	if (SilentAimSettings.ThirdPersonEnabled and not thirdPersonConnection) then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
		UserInputService.MouseIconEnabled = false;
		Camera.CameraType = Enum.CameraType.Scriptable;
		local yaw = 0;
		local pitch = 0;
		thirdPersonMouseConnection = UserInputService.InputChanged:Connect(function(input)
			if ((input.UserInputType == Enum.UserInputType.MouseMovement) and SilentAimSettings.ThirdPersonEnabled) then
				yaw = yaw - (input.Delta.X * SilentAimSettings.ThirdPersonSensitivity);
				pitch = math.clamp(pitch - (input.Delta.Y * SilentAimSettings.ThirdPersonSensitivity), -80, 80);
			end
		end);
		thirdPersonConnection = RunService.RenderStepped:Connect(function()
			if not SilentAimSettings.ThirdPersonEnabled then
				thirdPersonConnection:Disconnect();
				thirdPersonMouseConnection:Disconnect();
				thirdPersonConnection = nil;
				thirdPersonMouseConnection = nil;
				Camera.CameraType = Enum.CameraType.Custom;
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
				UserInputService.MouseIconEnabled = true;
				return;
			end
			if (HRP and char:FindFirstChild("Humanoid")) then
				local startPos = HRP.Position + Vector3.new(0, SilentAimSettings.ThirdPersonHeight, 0);
				local rotation = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0);
				local camOffset = rotation:VectorToWorldSpace(Vector3.new(0, 0, SilentAimSettings.ThirdPersonDistance));
				local camPos = startPos + camOffset;
				Camera.CFrame = CFrame.new(camPos, startPos);
			end
		end);
		humanoid.Died:Connect(function()
			SilentAimSettings.ThirdPersonEnabled = false;
			Toggles.ThirdPersonEnabled:SetValue(false);
			Camera.CameraType = Enum.CameraType.Custom;
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
			UserInputService.MouseIconEnabled = true;
			if thirdPersonConnection then
				thirdPersonConnection:Disconnect();
			end
			if thirdPersonMouseConnection then
				thirdPersonMouseConnection:Disconnect();
			end
			thirdPersonConnection = nil;
			thirdPersonMouseConnection = nil;
		end);
	elseif (not SilentAimSettings.ThirdPersonEnabled and thirdPersonConnection) then
		thirdPersonConnection:Disconnect();
		thirdPersonMouseConnection:Disconnect();
		thirdPersonConnection = nil;
		thirdPersonMouseConnection = nil;
		Camera.CameraType = Enum.CameraType.Custom;
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
		UserInputService.MouseIconEnabled = true;
	end
end
local antiAimConnection;
local function updateAntiAim()
	if (SilentAimSettings.AntiAimEnabled and not antiAimConnection) then
		antiAimConnection = RunService.RenderStepped:Connect(function()
			if not SilentAimSettings.AntiAimEnabled then
				antiAimConnection:Disconnect();
				antiAimConnection = nil;
				return;
			end
			local char = LocalPlayer.Character;
			if (char and char:FindFirstChild("HumanoidRootPart")) then
				local hrp = char.HumanoidRootPart;
				hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SilentAimSettings.AntiAimSpinSpeed), 0);
			end
		end);
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid");
		if humanoid then
			humanoid.Died:Connect(function()
				SilentAimSettings.AntiAimEnabled = false;
				Toggles.AntiAimEnabled:SetValue(false);
				if antiAimConnection then
					antiAimConnection:Disconnect();
					antiAimConnection = nil;
				end
			end);
		end
	elseif (not SilentAimSettings.AntiAimEnabled and antiAimConnection) then
		antiAimConnection:Disconnect();
		antiAimConnection = nil;
	end
end
do
	if not isfolder(MainFileName) then
		makefolder(MainFileName);
	end
	if not isfolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId))) then
		makefolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId)));
	end
end
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))();
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/DetainedMonkey2891/ThemeManager/refs/heads/main/Maina"))();
local Window = Library:CreateWindow({Title="MARINE.ALPHA",Center=true,AutoShow=true,TabPadding=12,MenuFadeTime=0.2,Size=UDim2.new(0, 550, 0, 500)});
Library.KeybindFrame.Visible = true;
ThemeManager.Library = Library;
ThemeManager.BuiltInThemes = {Default={1,HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"6759b3","BackgroundColor":"141414","OutlineColor":"323232"}')},Venom={2,HttpService:JSONDecode('{"FontColor":"BFBFBF","MainColor":"0E0E0E","AccentColor":"ff0000","BackgroundColor":"0E0E0E","OutlineColor":"0B0B0B"}')},Cyan={1,HttpService:JSONDecode('{"FontColor":"BFBFBF","MainColor":"0F0F0F","AccentColor":"00ffef","BackgroundColor":"101010","OutlineColor":"0B0B0B"}')},Burn={4,HttpService:JSONDecode('{"FontColor":"FF8200","MainColor":"0C0C0C","AccentColor":"FF8200","BackgroundColor":"0C0C0C","OutlineColor":"0C0C0C"}')},Fatality={5,HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"28204F"}')},GameSense={6,HttpService:JSONDecode('{"FontColor":"FFFFFF","MainColor":"171717","AccentColor":"98E22E","BackgroundColor":"171717","OutlineColor":"31371C"}')},["Comet.pub"]={7,HttpService:JSONDecode('{"FontColor":"5E5E5E","MainColor":"0F0F0F","AccentColor":"5D589D","BackgroundColor":"0F0F0F","OutlineColor":"191919"}')}};
ThemeManager:ApplyTheme("Cyan");
local CombatTab = Window:AddTab("Combat");
local SilentAimBOX = CombatTab:AddLeftTabbox("SilentAim");
do
	local Main = SilentAimBOX:AddTab("Silent Aim");
	Main:AddToggle("aim_Enabled", {Text="Enabled"}):AddKeyPicker("aim_Enabled_KeyPicker", {Default="RightAlt",SyncToggleState=true,Mode="Toggle",Text="Silent Aim",NoUI=false});
	Options.aim_Enabled_KeyPicker:OnClick(function()
		SilentAimSettings.Enabled = not SilentAimSettings.Enabled;
		Toggles.aim_Enabled.Value = SilentAimSettings.Enabled;
		Toggles.aim_Enabled:SetValue(SilentAimSettings.Enabled);
	end);
	Main:AddToggle("TeamCheck", {Text="Team Check",Default=SilentAimSettings.TeamCheck}):OnChanged(function()
		SilentAimSettings.TeamCheck = Toggles.TeamCheck.Value;
	end);
	Main:AddToggle("VisibleCheck", {Text="Visible Check",Default=SilentAimSettings.VisibleCheck}):OnChanged(function()
		SilentAimSettings.VisibleCheck = Toggles.VisibleCheck.Value;
	end);
	Main:AddDropdown("TargetPart", {AllowNull=true,Text="Target Part",Default=SilentAimSettings.TargetPart,Values={"Head","HumanoidRootPart","Random"}}):OnChanged(function()
		SilentAimSettings.TargetPart = Options.TargetPart.Value;
	end);
	Main:AddSlider("HitChance", {Text="Hit Chance",Default=100,Min=0,Max=100,Rounding=1});
	Options.HitChance:OnChanged(function()
		SilentAimSettings.HitChance = Options.HitChance.Value;
	end);
	Main:AddToggle("FOVVisible", {Text="Show FOV Circle"}):AddColorPicker("Color", {Default=Color3.fromRGB(255, 255, 255)}):OnChanged(function()
		fov_circle.Visible = Toggles.FOVVisible.Value;
		SilentAimSettings.FOVVisible = Toggles.FOVVisible.Value;
	end);
	Main:AddSlider("Radius", {Text="FOV Circle Radius",Min=0,Max=360,Default=130,Rounding=0}):OnChanged(function()
		fov_circle.Radius = Options.Radius.Value;
		SilentAimSettings.FOVRadius = Options.Radius.Value;
	end);
	Main:AddToggle("SnaplineEnabled", {Text="Show Snapline"}):AddColorPicker("SnaplineColor", {Default=Color3.fromRGB(255, 255, 255)}):OnChanged(function()
		snapline.Visible = Toggles.SnaplineEnabled.Value and SilentAimSettings.Enabled;
		SilentAimSettings.SnaplineEnabled = Toggles.SnaplineEnabled.Value;
		snapline.Color = Options.SnaplineColor.Value;
		SilentAimSettings.SnaplineColor = Options.SnaplineColor.Value;
	end);
	Main:AddSlider("SnaplineThickness", {Text="Snapline Thickness",Min=1,Max=5,Default=1,Rounding=0}):OnChanged(function()
		snapline.Thickness = Options.SnaplineThickness.Value;
		SilentAimSettings.SnaplineThickness = Options.SnaplineThickness.Value;
	end);
end
local CombatMiscBOX = CombatTab:AddRightTabbox("Misc");
do
	local Main = CombatMiscBOX:AddTab("Misc");
	Main:AddToggle("NoRecoil", {Text="No Recoil",Default=false}):OnChanged(function()
		if Toggles.NoRecoil.Value then
			setupNoRecoil();
		end
	end);
	Main:AddToggle("AntiAimEnabled", {Text="Enable Anti-Aim",Default=SilentAimSettings.AntiAimEnabled}):OnChanged(function()
		SilentAimSettings.AntiAimEnabled = Toggles.AntiAimEnabled.Value;
		updateAntiAim();
	end);
	Main:AddSlider("AntiAimSpinSpeed", {Text="Spin Speed",Default=SilentAimSettings.AntiAimSpinSpeed,Min=10,Max=100,Rounding=1}):OnChanged(function()
		SilentAimSettings.AntiAimSpinSpeed = Options.AntiAimSpinSpeed.Value;
	end);
end
local ManipulateTab = Window:AddTab("Manipulate");
local ManipulateBOX = ManipulateTab:AddLeftTabbox("Environment");
do
	local Main = ManipulateBOX:AddTab("Environment");
	Main:AddToggle("HomeXrayEnabled", {Text="Home Xray",Default=SilentAimSettings.HomeXrayEnabled}):OnChanged(function()
		toggleHomeXray(Toggles.HomeXrayEnabled.Value);
	end);
end
local StaffOnlineBOX = ManipulateTab:AddLeftTabbox("Staff Online");
do
	local Main = StaffOnlineBOX:AddTab("Staff Online");
	Main:AddToggle("StaffOnlineEnabled", {Text="Enable Staff List",Default=SilentAimSettings.StaffOnlineEnabled}):OnChanged(function()
		toggleStaffOnline(Toggles.StaffOnlineEnabled.Value);
	end);
	Main:AddToggle("ShowAllStaff", {Text="Show All Staff",Default=SilentAimSettings.ShowAllStaff}):OnChanged(function()
		SilentAimSettings.ShowAllStaff = Toggles.ShowAllStaff.Value;
		redraw();
	end);
end
local MiscTab = Window:AddTab("Misc");
local MiscBOX = MiscTab:AddLeftTabbox("Config");
do
	local Main = MiscBOX:AddTab("Config");
	Main:AddInput("CreateConfigTextBox", {Default="",Numeric=false,Text="Create Configuration",Placeholder="File Name here"}):OnChanged(function()
		FileToSave = Options.CreateConfigTextBox.Value;
	end);
	Main:AddButton("Create Configuration", function()
		if (FileToSave ~= "") then
			UpdateFile(FileToSave);
		end
	end);
	Main:AddDropdown("SaveConfigDropdown", {AllowNull=true,Values=GetFiles(),Text="Save Configuration"}):OnChanged(function()
		SelectedFile = Options.SaveConfigDropdown.Value;
	end);
	Main:AddButton("Save Configuration", function()
		if SelectedFile then
			UpdateFile(SelectedFile);
		end
	end);
	Main:AddDropdown("LoadConfigDropdown", {AllowNull=true,Values=GetFiles(),Text="Load Configuration"}):OnChanged(function()
		SelectedFile = Options.LoadConfigDropdown.Value;
	end);
	Main:AddButton("Load Configuration", function()
		if SelectedFile then
			LoadFile(SelectedFile);
			Toggles.TeamCheck:SetValue(SilentAimSettings.TeamCheck);
			Toggles.VisibleCheck:SetValue(SilentAimSettings.VisibleCheck);
			Toggles.SpiderEnabled:SetValue(SilentAimSettings.SpiderEnabled);
			Options.SpiderSpeed:SetValue(SilentAimSettings.SpiderSpeed);
			Toggles.NoShadow:SetValue(SilentAimSettings.NoShadow);
			Toggles.NoFog:SetValue(SilentAimSettings.NoFog);
			Toggles.ForceDay:SetValue(SilentAimSettings.ForceDay);
			Toggles.NoSky:SetValue(SilentAimSettings.NoSky);
			Toggles.ThirdPersonEnabled:SetValue(SilentAimSettings.ThirdPersonEnabled);
			Options.ThirdPersonDistance:SetValue(SilentAimSettings.ThirdPersonDistance);
			Options.ThirdPersonHeight:SetValue(SilentAimSettings.ThirdPersonHeight);
			Options.ThirdPersonSensitivity:SetValue(SilentAimSettings.ThirdPersonSensitivity);
			Toggles.AntiAimEnabled:SetValue(SilentAimSettings.AntiAimEnabled);
			Options.AntiAimSpinSpeed:SetValue(SilentAimSettings.AntiAimSpinSpeed);
			Options.TargetPart:SetValue(SilentAimSettings.TargetPart);
			Toggles.FOVVisible:SetValue(SilentAimSettings.FOVVisible);
			Options.Radius:SetValue(SilentAimSettings.FOVRadius);
			Options.HitChance:SetValue(SilentAimSettings.HitChance);
			Options.SnaplineEnabled:SetValue(SilentAimSettings.SnaplineEnabled);
			Options.SnaplineColor:SetValue(SilentAimSettings.SnaplineColor);
			Options.SnaplineThickness:SetValue(SilentAimSettings.SnaplineThickness);
			Options.AmbiencePreset:SetValue(SilentAimSettings.SelectedAmbience);
			Options.CustomSkyEnabled:SetValue(SilentAimSettings.CustomSkyEnabled);
			Options.SelectedSkybox:SetValue(SilentAimSettings.SelectedSkybox);
			Options.StaffOnlineEnabled:SetValue(SilentAimSettings.StaffOnlineEnabled);
			Options.ShowAllStaff:SetValue(SilentAimSettings.ShowAllStaff);
			applySkybox(SilentAimSettings.SelectedSkybox);
			if SilentAimSettings.ThirdPersonEnabled then
				updateThirdPerson();
			end
			if SilentAimSettings.AntiAimEnabled then
				updateAntiAim();
			end
		end
	end);
end
local MiscBOX = MiscTab:AddLeftTabbox("Config");
do
	local Main = MiscBOX:AddTab("Config");
	Main:AddDropdown("ThemeSelector", {Text="Select Theme",Default="Cyan",Values={"Default","Venom","Cyan","Burn","Fatality","GameSense","Comet.pub"},Tooltip="Choose a UI theme"}):OnChanged(function()
		ThemeManager:ApplyTheme(Options.ThemeSelector.Value);
	end);
end
local SpiderBOX = MiscTab:AddRightTabbox("Spider");
do
	local Main = SpiderBOX:AddTab("Spider");
	Main:AddToggle("SpiderEnabled", {Text="Enable Spider",Default=SilentAimSettings.SpiderEnabled}):AddKeyPicker("SpiderEnabled_KeyPicker", {Default="V",SyncToggleState=true,Mode="Toggle",Text="Spider",NoUI=false});
	Options.SpiderEnabled_KeyPicker:OnClick(function()
		SilentAimSettings.SpiderEnabled = not SilentAimSettings.SpiderEnabled;
		Toggles.SpiderEnabled.Value = SilentAimSettings.SpiderEnabled;
		Toggles.SpiderEnabled:SetValue(SilentAimSettings.SpiderEnabled);
		if (SilentAimSettings.SpiderEnabled and not spiderConnection) then
			updateSpider();
		elseif (not SilentAimSettings.SpiderEnabled and spiderConnection) then
			spiderConnection:Disconnect();
			spiderConnection = nil;
		end
	end);
	Main:AddSlider("SpiderSpeed", {Text="Movement Speed",Default=SilentAimSettings.SpiderSpeed,Min=10,Max=100,Rounding=1}):OnChanged(function()
		SilentAimSettings.SpiderSpeed = Options.SpiderSpeed.Value;
	end);
end
local CameraBOX = MiscTab:AddRightTabbox("Camera");
do
	local Main = CameraBOX:AddTab("Camera Settings");
	Main:AddSlider("CameraFOV", {Text="Field of View",Default=SilentAimSettings.CameraFOV,Min=SilentAimSettings.CameraFOVMin,Max=SilentAimSettings.CameraFOVMax,Rounding=0,Tooltip="Adjust camera field of view"}):OnChanged(function()
		UpdateFOV(Options.CameraFOV.Value);
		SilentAimSettings.CameraFOV = Options.CameraFOV.Value;
	end);
	Main:AddButton("Increase FOV (L)", function()
		UpdateFOV(currentFOV + SilentAimSettings.CameraFOVStep);
		Options.CameraFOV:SetValue(currentFOV);
	end);
	Main:AddButton("Decrease FOV (K)", function()
		UpdateFOV(currentFOV - SilentAimSettings.CameraFOVStep);
		Options.CameraFOV:SetValue(currentFOV);
	end);
	Main:AddSlider("FOVStep", {Text="FOV Change Step",Default=SilentAimSettings.CameraFOVStep,Min=1,Max=20,Rounding=0,Tooltip="Step size for FOV changes"}):OnChanged(function()
		SilentAimSettings.CameraFOVStep = Options.FOVStep.Value;
	end);
end
local CustomSkyBOX = MiscTab:AddLeftTabbox("Custom Sky");
do
	local Main = CustomSkyBOX:AddTab("Custom Sky");
	Main:AddToggle("CustomSkyEnabled", {Text="Enable Custom Sky",Default=SilentAimSettings.CustomSkyEnabled}):OnChanged(function()
		SilentAimSettings.CustomSkyEnabled = Toggles.CustomSkyEnabled.Value;
		applySkybox(SilentAimSettings.SelectedSkybox);
	end);
	Main:AddDropdown("SelectedSkybox", {Text="Skybox",Default=SilentAimSettings.SelectedSkybox,Values={"Galaxy","Island","Purple Sky","Forest","City","Minecraft"},AllowNull=true,Tooltip="Select a custom skybox"}):OnChanged(function()
		SilentAimSettings.SelectedSkybox = Options.SelectedSkybox.Value;
		if SilentAimSettings.CustomSkyEnabled then
			applySkybox(SilentAimSettings.SelectedSkybox);
		end
	end);
end
local VisualsBOX = MiscTab:AddRightTabbox("Visuals");
do
	local Main = VisualsBOX:AddTab("Visuals");
	Main:AddToggle("AmbienceEnabled", {Text="Enable Ambience",Default=SilentAimSettings.AmbienceEnabled}):OnChanged(function()
		SilentAimSettings.AmbienceEnabled = Toggles.AmbienceEnabled.Value;
		ApplyAmbience();
	end);
	Main:AddDropdown("AmbiencePreset", {Text="Ambience Color",Default=SilentAimSettings.SelectedAmbience,Values={"Red","Green","Blue","Yellow","Purple"},Tooltip="Select ambient lighting color"}):OnChanged(function()
		SilentAimSettings.SelectedAmbience = Options.AmbiencePreset.Value;
		ApplyAmbience();
	end);
	Main:AddToggle("NoShadow", {Text="No Shadow",Default=SilentAimSettings.NoShadow}):OnChanged(function()
		SilentAimSettings.NoShadow = Toggles.NoShadow.Value;
		if (SilentAimSettings.NoShadow and not visualConnection) then
			updateVisuals();
		end
	end);
	Main:AddToggle("NoFog", {Text="No Fog",Default=SilentAimSettings.NoFog}):OnChanged(function()
		SilentAimSettings.NoFog = Toggles.NoFog.Value;
		if (SilentAimSettings.NoFog and not visualConnection) then
			updateVisuals();
		end
	end);
	Main:AddToggle("ForceDay", {Text="Force Day",Default=SilentAimSettings.ForceDay}):OnChanged(function()
		SilentAimSettings.ForceDay = Toggles.ForceDay.Value;
		if (SilentAimSettings.ForceDay and not visualConnection) then
			updateVisuals();
		end
	end);
	Main:AddToggle("NoSky", {Text="No Sky",Default=SilentAimSettings.NoSky}):OnChanged(function()
		SilentAimSettings.NoSky = Toggles.NoSky.Value;
		if (SilentAimSettings.NoSky and not visualConnection) then
			updateVisuals();
		end
	end);
end
local ThirdPersonBOX = MiscTab:AddRightTabbox("ThirdPerson");
do
	local Main = ThirdPersonBOX:AddTab("Third Person");
	Main:AddToggle("ThirdPersonEnabled", {Text="Enable Third Person",Default=SilentAimSettings.ThirdPersonEnabled}):OnChanged(function()
		SilentAimSettings.ThirdPersonEnabled = Toggles.ThirdPersonEnabled.Value;
		updateThirdPerson();
	end);
	Main:AddSlider("ThirdPersonDistance", {Text="Camera Distance",Default=SilentAimSettings.ThirdPersonDistance,Min=5,Max=50,Rounding=1}):OnChanged(function()
		SilentAimSettings.ThirdPersonDistance = Options.ThirdPersonDistance.Value;
	end);
	Main:AddSlider("ThirdPersonHeight", {Text="Camera Height",Default=SilentAimSettings.ThirdPersonHeight,Min=0,Max=20,Rounding=1}):OnChanged(function()
		SilentAimSettings.ThirdPersonHeight = Options.ThirdPersonHeight.Value;
	end);
	Main:AddSlider("ThirdPersonSensitivity", {Text="Mouse Sensitivity",Default=SilentAimSettings.ThirdPersonSensitivity,Min=0.1,Max=1,Rounding=2}):OnChanged(function()
		SilentAimSettings.ThirdPersonSensitivity = Options.ThirdPersonSensitivity.Value;
	end);
end
local CrosshairBOX = MiscTab:AddRightTabbox("Crosshair");
do
	local CrosshairTab = CrosshairBOX:AddTab("Advanced Crosshair");
	local crosshairSettings = {Enabled=true,Color=Color3.fromRGB(255, 0, 0),LineLength=10,Gap=6,Thickness=2,RotationSpeed=60,EnableRotation=true};
	local Player = game:GetService("Players").LocalPlayer;
	local Gui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"));
	Gui.Name = "AdvancedCrosshair";
	Gui.ResetOnSpawn = false;
	local lines = {};
	local function createLine(name)
		local line = Instance.new("Frame");
		line.Name = name;
		line.Size = UDim2.new(0, crosshairSettings.Thickness, 0, crosshairSettings.LineLength);
		line.BackgroundColor3 = crosshairSettings.Color;
		line.BorderSizePixel = 0;
		line.AnchorPoint = Vector2.new(0.5, 0.5);
		line.Visible = crosshairSettings.Enabled;
		line.Parent = Gui;
		return line;
	end
	lines.Top = createLine("Top");
	lines.Bottom = createLine("Bottom");
	lines.Left = createLine("Left");
	lines.Right = createLine("Right");
	local angle = 0;
	local function updateCrosshair(dt)
		if not crosshairSettings.Enabled then
			for _, line in pairs(lines) do
				line.Visible = false;
			end
			return;
		end
		for _, line in pairs(lines) do
			line.Visible = true;
			line.BackgroundColor3 = crosshairSettings.Color;
			line.Size = UDim2.new(0, crosshairSettings.Thickness, 0, crosshairSettings.LineLength);
		end
		if crosshairSettings.EnableRotation then
			angle = (angle + (crosshairSettings.RotationSpeed * dt)) % 360;
		end
		local center = Vector2.new(Gui.AbsoluteSize.X / 2, Gui.AbsoluteSize.Y / 2);
		local function rotatedOffset(angleDeg, dist)
			local rad = math.rad(angleDeg);
			return Vector2.new(math.cos(rad), math.sin(rad)) * dist;
		end
		lines.Top.Position = UDim2.new(0, center.X, 0, center.Y) + UDim2.new(0, rotatedOffset(angle + 270, crosshairSettings.Gap).X, 0, rotatedOffset(angle + 270, crosshairSettings.Gap).Y);
		lines.Bottom.Position = UDim2.new(0, center.X, 0, center.Y) + UDim2.new(0, rotatedOffset(angle + 90, crosshairSettings.Gap).X, 0, rotatedOffset(angle + 90, crosshairSettings.Gap).Y);
		lines.Left.Position = UDim2.new(0, center.X, 0, center.Y) + UDim2.new(0, rotatedOffset(angle + 180, crosshairSettings.Gap).X, 0, rotatedOffset(angle + 180, crosshairSettings.Gap).Y);
		lines.Right.Position = UDim2.new(0, center.X, 0, center.Y) + UDim2.new(0, rotatedOffset(angle + 0, crosshairSettings.Gap).X, 0, rotatedOffset(angle + 0, crosshairSettings.Gap).Y);
		lines.Top.Rotation = angle;
		lines.Bottom.Rotation = angle;
		lines.Left.Rotation = angle;
		lines.Right.Rotation = angle;
	end
	game:GetService("RunService").RenderStepped:Connect(updateCrosshair);
	CrosshairTab:AddToggle("CrosshairEnabled", {Text="Enable Crosshair",Default=crosshairSettings.Enabled}):OnChanged(function()
		crosshairSettings.Enabled = Toggles.CrosshairEnabled.Value;
	end);
	CrosshairTab:AddSlider("CrosshairLength", {Text="Line Length",Default=crosshairSettings.LineLength,Min=5,Max=30,Rounding=1}):OnChanged(function()
		crosshairSettings.LineLength = Options.CrosshairLength.Value;
	end);
	CrosshairTab:AddSlider("CrosshairGap", {Text="Gap Size",Default=crosshairSettings.Gap,Min=0,Max=20,Rounding=1}):OnChanged(function()
		crosshairSettings.Gap = Options.CrosshairGap.Value;
	end);
	CrosshairTab:AddSlider("CrosshairThickness", {Text="Line Thickness",Default=crosshairSettings.Thickness,Min=1,Max=5,Rounding=1}):OnChanged(function()
		crosshairSettings.Thickness = Options.CrosshairThickness.Value;
	end);
	CrosshairTab:AddToggle("CrosshairRotation", {Text="Enable Rotation",Default=crosshairSettings.EnableRotation}):OnChanged(function()
		crosshairSettings.EnableRotation = Toggles.CrosshairRotation.Value;
	end);
	CrosshairTab:AddSlider("CrosshairSpeed", {Text="Rotation Speed",Default=crosshairSettings.RotationSpeed,Min=0,Max=360,Rounding=1}):OnChanged(function()
		crosshairSettings.RotationSpeed = Options.CrosshairSpeed.Value;
	end);
end
local esp_tab = Window:AddTab("ESP");
do
	local espLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/flog-gok/simfonia-hub/refs/heads/main/custom%20ESP%20lib"))();
	local players = game:GetService("Players");
	local espSettings = {player={enabled=false,box=true,name=true,distance=true,healthbar=true,rainbow=false}};
	local playerESPs = {};
	local function updatePlayerESP()
		for _, esp in pairs(playerESPs) do
			if (espSettings.player.enabled and esp.current and esp.current.active) then
				esp:loop(espSettings.player, (esp.current.rootPart.Position - players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude);
			else
				esp:hideDrawings();
			end
		end
	end
	local function initializePlayerESP()
		for _, player in pairs(players:GetPlayers()) do
			if (player ~= players.LocalPlayer) then
				playerESPs[player] = espLibrary.playerESP.new(player, espSettings.player.rainbow);
			end
		end
	end
	players.PlayerAdded:Connect(function(player)
		if (player ~= players.LocalPlayer) then
			playerESPs[player] = espLibrary.playerESP.new(player, espSettings.player.rainbow);
		end
	end);
	players.PlayerRemoving:Connect(function(player)
		if playerESPs[player] then
			playerESPs[player]:remove();
			playerESPs[player] = nil;
		end
	end);
	game:GetService("RunService").RenderStepped:Connect(function()
		if (not players.LocalPlayer.Character or not players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then
			return;
		end
		updatePlayerESP();
	end);
	local ESPBOX = esp_tab:AddLeftTabbox("ESP");
	local Main = ESPBOX:AddTab("ESP");
	Main:AddToggle("esp_player_enabled", {Text="Enable Player ESP",Default=false}):OnChanged(function()
		espSettings.player.enabled = Toggles.esp_player_enabled.Value;
	end);
	Main:AddToggle("esp_player_box", {Text="Player Box",Default=true}):OnChanged(function()
		espSettings.player.box = Toggles.esp_player_box.Value;
	end);
	Main:AddToggle("esp_player_name", {Text="Player Name",Default=true}):OnChanged(function()
		espSettings.player.name = Toggles.esp_player_name.Value;
	end);
	Main:AddToggle("esp_player_distance", {Text="Player Distance",Default=true}):OnChanged(function()
		espSettings.player.distance = Toggles.esp_player_distance.Value;
	end);
	Main:AddToggle("esp_player_healthbar", {Text="Player Health Bar",Default=true}):OnChanged(function()
		espSettings.player.healthbar = Toggles.esp_player_healthbar.Value;
	end);
	Main:AddToggle("esp_player_rainbow", {Text="Player Rainbow Colors",Default=false}):OnChanged(function()
		espSettings.player.rainbow = Toggles.esp_player_rainbow.Value;
		for _, esp in pairs(playerESPs) do
			esp.useRainbow = Toggles.esp_player_rainbow.Value;
		end
	end);
	initializePlayerESP();
end
resume(create(function()
	RunService.RenderStepped:Connect(function()
		local mouseLocation = getMousePosition();
		if (Toggles.FOVVisible and Toggles.FOVVisible.Value) then
			fov_circle.Visible = Toggles.FOVVisible.Value;
			fov_circle.Color = Options.Color.Value;
			fov_circle.Position = mouseLocation;
			fov_circle.Radius = SilentAimSettings.FOVRadius;
		else
			fov_circle.Visible = false;
		end
		if (SilentAimSettings.SnaplineEnabled and Toggles.aim_Enabled and Toggles.aim_Enabled.Value) then
			local closestPlayer = nil;
			local shortestDistance = SilentAimSettings.FOVRadius;
			for _, plr in ipairs(Players:GetPlayers()) do
				if (plr ~= LocalPlayer) then
					if (SilentAimSettings.TeamCheck and (plr.Team == LocalPlayer.Team)) then
						continue;
					end
					local char = plr.Character;
					if (char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") and (char:FindFirstChildOfClass("Humanoid").Health > 0)) then
						if (SilentAimSettings.VisibleCheck and not IsPlayerVisible(plr)) then
							continue;
						end
						local pos, onScreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position);
						if onScreen then
							local screenPos = Vector2.new(pos.X, pos.Y);
							local dist = (mouseLocation - screenPos).Magnitude;
							if (dist <= shortestDistance) then
								shortestDistance = dist;
								closestPlayer = plr;
							end
						end
					end
				end
			end
			if closestPlayer then
				local char = closestPlayer.Character;
				local hrp = char and char:FindFirstChild("HumanoidRootPart");
				if hrp then
					local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position);
					if onScreen then
						local screenPos = Vector2.new(pos.X, pos.Y);
						snapline.From = mouseLocation;
						snapline.To = screenPos;
						snapline.Visible = true;
						snapline.Color = SilentAimSettings.SnaplineColor;
						snapline.Thickness = SilentAimSettings.SnaplineThickness;
					else
						snapline.Visible = false;
					end
				else
					snapline.Visible = false;
				end
			else
				snapline.Visible = false;
			end
		else
			snapline.Visible = false;
		end
	end);
end));
local oldNamecall;
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
	local Method = getnamecallmethod();
	local Arguments = {...};
	local self = Arguments[1];
	local chance = CalculateChance(SilentAimSettings.HitChance);
	if (Toggles.aim_Enabled.Value and (self == workspace) and not checkcaller() and chance) then
		if ((Method == "Raycast") and (SilentAimSettings.SilentAimMethod == "Raycast")) then
			if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
				local A_Origin = Arguments[2];
				local HitPart = getClosestPlayer();
				if HitPart then
					Arguments[3] = getDirection(A_Origin, HitPart.Position);
					return oldNamecall(unpack(Arguments));
				end
			end
		end
	end
	return oldNamecall(...);
end));
