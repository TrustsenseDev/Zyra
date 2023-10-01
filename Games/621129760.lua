if shared.cleanup then shared.cleanup() end;

local game = game
local Drawing = Drawing
local Color3 = Color3
local Vector2 = Vector2
local Ray = Ray

local client = game:GetService('Players').LocalPlayer;
local camera = workspace.CurrentCamera;

local mouse = client:GetMouse();

local DEFAULT_WALK_SPEED = 16
local DEFAULT_JUMP_POWER = 50

if ( not IsElectron ) then
    client:Kick('This script was only made using Electron, it was not tested on other exploits!')
    return
end

-- </ Utility Table > --
local util = {}
do
    function util.is_alive(player)
        if not player then
            return false
        end

        local character = player.Character
        if not character then
            return false
        end

        local humanoid = character:FindFirstChildOfClass('Humanoid')
        local rootPart = character:FindFirstChild('HumanoidRootPart')

        return humanoid and rootPart and humanoid.Health > 0 or false
    end

    function util.teleport(cf)
        if not util.is_alive(client) then
            return
        end;

        client.Character.PrimaryPart:PivotTo(cf)
    end

    function util.get_enemy(fovEnabled, radius)
        if not util.is_alive(client) then
            return
        end

        local enemy, min_distance = nil, math.huge
        local player_pos = client.Character.HumanoidRootPart.Position

        local players = game.Players:GetPlayers()
        for i = 1, #players do
            local player = players[i]

            if (player == client) or (not util.is_alive(player)) then
                continue 
            end

            local head = player.Character.Head.Position
            local distance

            if (fovEnabled) then
                local viewportPoint = camera:WorldToViewportPoint(head)
                local xDiff = viewportPoint.X - mouse.X
                local yDiff = viewportPoint.Y - mouse.Y
                distance = math.sqrt(xDiff * xDiff + yDiff * yDiff)

                if (distance > radius or viewportPoint.Z <= 0) then
                    continue
                end
            else
                distance = (player_pos - head).magnitude
            end

            if (distance < min_distance) then
                enemy = player
                min_distance = distance
            end
        end

        return enemy
    end

    function util.fly(bool, speed)
        if bool then
            if (not util.is_alive(client)) then
                return
            end

            local root = client.Character.HumanoidRootPart
            local flycf = util.FlyCF or CFrame.new(root.CFrame.Position)
            local camcf = camera.CFrame

            local force = Vector3.new()
            local delta = task.wait()

            local userInputService = game:GetService('UserInputService')

            if userInputService:IsKeyDown(Enum.KeyCode.W) then force = force + (camcf.LookVector * speed) end
            if userInputService:IsKeyDown(Enum.KeyCode.S) then force = force - (camcf.LookVector * speed) end
            if userInputService:IsKeyDown(Enum.KeyCode.A) then force = force - (camcf.RightVector * speed) end
            if userInputService:IsKeyDown(Enum.KeyCode.D) then force = force + (camcf.RightVector * speed) end
            if userInputService:IsKeyDown(Enum.KeyCode.Space) then force = force + (camcf.UpVector * speed) end
            if userInputService:IsKeyDown(Enum.KeyCode.LeftControl) then force = force - (camcf.UpVector * speed) end

            flycf = flycf * CFrame.new(force * delta)

            root.CFrame = CFrame.lookAt(flycf.Position, camcf.Position + (camcf.LookVector * 1000))
            root.Velocity = Vector3.new()

            util.FlyCF = nil
        end
    end

    function util.upd_movement(walkspeed_active, walkspeed_value, jumppower_active, jumppower_value)
        if not util.is_alive(client) then
            return
        end

        local humanoid = client.Character.Humanoid

        if walkspeed_active then
            humanoid.WalkSpeed = walkspeed_value
        else
            humanoid.WalkSpeed = DEFAULT_WALK_SPEED
        end

        if jumppower_active then
            humanoid.JumpPower = jumppower_value
        else
            humanoid.JumpPower = DEFAULT_JUMP_POWER
        end
    end
end

-- </ ESP > --
local circle = Drawing.new('Circle')

local circle_props = {
    Visible = false,
    Color = Color3.new(1, 1, 1),
    Thickness = 1,
    NumSides = 32,
    Radius = 30,
    Transparency = 1
};

for k, v in pairs(circle_props) do
    circle[k] = v;
end;

local function upd_circle(properties)
    for k, v in pairs(properties) do
        circle[k] = v;
    end;
end;

-- </ Silent Aim > --
local is_silent_active = nil;
local target = nil;

-- </ Connections Cleaner > --
shared.tasks = {};
do
    shared.onCleanup = function(task)
        shared.tasks[#shared.tasks + 1] = task
    end;

    shared.cleanup = function()
        for _, task in pairs(shared.tasks) do
            if not shared.tasks then return end
            if typeof(task) == 'RBXScriptConnection' then task:Disconnect() end;
            if typeof(task) == 'thread' then coroutine.yield(task) end;
        end;

        shared.tasks = {};
    end;
end

local idledConn = client.Idled:Connect(function()
    game:GetService('VirtualUser'):CaptureController()
    game:GetService('VirtualUser'):ClickButton2(Vector2.new())
end)

shared.onCleanup(function()
    idledConn:Disconnect()
    idledConn = nil
end)

-- </ Script > --
local Iris = loadstring(game:HttpGet('https://raw.githubusercontent.com/x0581/iris-Exploit-Bundle/2.0.4/bundle.lua'))().Init(game.CoreGui)
local ESP = loadstring(game:HttpGet('https://raw.githubusercontent.com/wally-rblx/ESP-Lib/main/ESP.lua'))() do
    ESP:Toggle(false);

    ESP.FaceCamera = true;
    ESP.TeamMates = false;
    ESP.Names = false;
    ESP.Tracers = false;
    ESP.Boxes = false;
end

Iris:Connect(function()
    local is_silent = Iris.State(false)
    local is_fov_based = Iris.State(false)
    local should_show_fov = Iris.State(false)

    local fov_attributes = {}
    for k, v in pairs(circle_props) do
        if k ~= "Visible" then
            fov_attributes["Fov " .. k] = Iris.State(v)
        end
    end

    local fov_range_values = {
        ["Fov Color"] = {"Fov Color"},
        ["Fov NumSides"] = {"Fov NumSides", 1, 1, 32},
        ["Fov Thickness"] = {"Fov Thickness", 1, 1, 5},
        ["Fov Radius"] = {"Fov Radius", 1, 1, 1000},
        ["Fov Transparency"] = {"Fov Transparency", 0.1, 0, 1}
    }

    local esp = {}
    esp.Enabled = Iris.State(false)
    esp.FaceCamera = Iris.State(false)
    esp.Teammates = Iris.State(false)
    esp.Names = Iris.State(false)
    esp.Tracers = Iris.State(false)
    esp.Boxes = Iris.State(false)

    local is_walkspeed_active = Iris.State(false)
    local is_jumppower_active = Iris.State(false)
    local is_flight_active = Iris.State(false)
    local is_noclip_active = Iris.State(false)
    local is_noclip_xray_active = Iris.State(false)

    local walkspeed_value = Iris.State(DEFAULT_WALK_SPEED)
    local jumppower_value = Iris.State(DEFAULT_JUMP_POWER)
    local flight_speed = Iris.State(45)

    Iris.Window({'Zyra | KAT!'}, {size = Iris.State(Vector2.new(430, 450))})
        Iris.Text{'Have a nice day * ' .. os.date('%x')}
        Iris.Separator()

        Iris.CollapsingHeader({'Main'})
            Iris.Checkbox({'Silent Aimbot'}, {isChecked = is_silent})
        Iris.End()

        Iris.CollapsingHeader({'Settings'})
            Iris.SameLine()
                Iris.Group()
                    Iris.Checkbox({'Fov Based'}, {isChecked = is_fov_based})
                    Iris.Checkbox({'Show Fov'}, {isChecked = should_show_fov})
                Iris.End()

                Iris.Separator()

                Iris.Group()
                    Iris.PushConfig({ContentWidth = UDim.new(0, 195)})
                        for k, v in pairs(fov_attributes) do
                            if k == "Fov Color" then
                                Iris.InputColor3(fov_range_values[k], {color = v})
                            else
                                Iris.SliderNum(fov_range_values[k], {number = v})
                            end
                        end
                    Iris.PopConfig()
                Iris.End()
            Iris.End()
        Iris.End()

        Iris.CollapsingHeader({'Esp'})
            local espKeys = {}

            for key in pairs(esp) do
                espKeys[#espKeys + 1] = key
            end
            local half = math.floor(#espKeys / 2)

            Iris.SameLine()
                Iris.Group()
                        for i = 1, half do
                            Iris.Checkbox({espKeys[i]}, {isChecked = esp[espKeys[i]]})
                        end
                Iris.End()

                Iris.Separator()

                Iris.Group()
                    for i = half + 1, #espKeys do
                        Iris.Checkbox({espKeys[i]}, {isChecked = esp[espKeys[i]]})
                    end
                Iris.End()
            Iris.End()
        Iris.End()

        Iris.CollapsingHeader({"Local Player"})
            Iris.SameLine()
                Iris.Group()
                    Iris.Checkbox({"WalkSpeed"}, {isChecked = is_walkspeed_active})
                    Iris.Checkbox({"JumpPower"}, {isChecked = is_jumppower_active})
                    Iris.Checkbox({"Fly"}, {isChecked = is_flight_active})
                    Iris.Checkbox({"Noclip"}, {isChecked = is_noclip_active})
                Iris.End()

                Iris.Separator()

                Iris.Group()
                    Iris.PushConfig({ContentWidth = UDim.new(0, 170)})
                        Iris.SliderNum({"WalkSpeed", 1, DEFAULT_WALK_SPEED, 300}, {number = walkspeed_value})
                        Iris.SliderNum({"JumpPower", 1, DEFAULT_JUMP_POWER, 300}, {number = jumppower_value})
                        Iris.SliderNum({"Fly Speed", 1, 1, 300}, {number = flight_speed})
                        Iris.Checkbox({"Noclip XRay"}, {isChecked = is_noclip_xray_active})
                    Iris.PopConfig()
                Iris.End()
            Iris.End()
        Iris.End()

        Iris.CollapsingHeader({"Credits"})
            Iris.Text('Developer: Trustsense')
            Iris.Text('Menu: littlemike & michael')
        Iris.End()
    Iris.End()


    local newProperties = {
        Visible = should_show_fov.value,
        Color = fov_attributes["Fov Color"]:get(),
        Thickness = fov_attributes["Fov Thickness"].value,
        NumSides = fov_attributes["Fov NumSides"].value,
        Radius = fov_attributes["Fov Radius"].value,
        Transparency = fov_attributes["Fov Transparency"].value
    }

    upd_circle(newProperties)

    local mousePos = game:GetService('UserInputService'):GetMouseLocation()
    circle.Position = Vector2.new(mousePos.X, mousePos.Y)

    is_silent_active = is_silent.value

    if util.get_enemy(is_fov_based.value, fov_attributes["Fov Radius"].value) then
        target = util.get_enemy(is_fov_based.value, fov_attributes["Fov Radius"].value)
    end

    ESP:Toggle(esp.Enabled.value);

    ESP.FaceCamera = esp.FaceCamera.value;
    ESP.TeamMates = esp.Teammates.value;
    ESP.Names = esp.Names.value;
    ESP.Tracers = esp.Tracers.value;
    ESP.Boxes = esp.Boxes.value;

    if util.is_alive(client) then
        util.upd_movement(is_walkspeed_active.value, walkspeed_value.value, is_jumppower_active.value, jumppower_value.value)
        util.fly(is_flight_active.value, flight_speed.value)

        if is_noclip_active.value then
            client.Character.Humanoid:ChangeState(11)
        end

        client.DevCameraOcclusionMode = is_noclip_xray_active.value and 1 or 0
    end
end)

local argsTable = {}; local __namecall; __namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local nArgsTableSize = select('#', ...)

    for i = 1, nArgsTableSize do
        argsTable[i] = select(i,...)
    end

    if (not checkcaller()) and (getnamecallmethod() == "FindPartOnRayWithIgnoreList") then
        if (is_silent_active) and (table.find(argsTable[2], workspace.WorldIgnore.Ignore)) and (target and target.Character) then
            local Origin = argsTable[1].Origin
            argsTable[1] = Ray.new(Origin, target.Character.Head.Position - Origin)
        end
    end

    return __namecall(self, unpack(argsTable, 1, nArgsTableSize))
end)
