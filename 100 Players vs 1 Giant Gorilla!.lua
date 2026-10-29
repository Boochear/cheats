-- Library
local DiscordLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Boochear/cheats/main/source.lua"))()

-- Window and Server
local Window = DiscordLib:Window("100 Players vs 1 Giant Gorilla!")
local Server = Window:Server("<3", "rbxthumb://type=GameIcon&id=10769111685&w=150&h=150")

-- Channels
local ChAutofarm = Server:Channel("Autofarm")
local ChTraining = Server:Channel("Training")
local ChPlayer = Server:Channel("Player")
local ChInfo = Server:Channel("Info")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Boxes
local freecamSpeed = 1

local flySpeed = 50

local speedState = {
    enabled  = false,
    value    = 50,
    original = nil,
}

local infiniteJumpEnabled = false
local infiniteJumpConn = nil

-- Functions
-- Auto Giant SandBag and Auto Roulette Pickups
do
    local rouletteBusy = false 
    local gsEnabled   = false
    local gsLoop      = nil
    local gsOnSandbag = false

    local function getSandbag()
        local obj = workspace:FindFirstChild("GiantSandbag")
        if obj and obj:IsA("Model") then return obj end
        return nil
    end

    local function getSandbagPart(model)
        return model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("Head")
            or model:FindFirstChildWhichIsA("BasePart")
    end

    local function getArenaSpawn()
        local arena = workspace:FindFirstChild("Arena")
        if not arena then return nil end
        return arena:FindFirstChild("Spawn")
    end

    local function teleportTo(position)
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    end

    local function sandbagLoop()
        while gsEnabled do
            local success, err = pcall(function()
                task.wait(0.2)
                if not rouletteBusy then
                    local sandbag = getSandbag()
                    if sandbag then
                        if not gsOnSandbag then
                            local part = getSandbagPart(sandbag)
                            if part then
                                teleportTo(part.Position)
                                gsOnSandbag = true
                            end
                        end
                    else
                        if gsOnSandbag then
                            local spawnPart = getArenaSpawn()
                            if spawnPart then
                                teleportTo(spawnPart.Position)
                            end
                            gsOnSandbag = false
                        end
                    end
                end
            end)
            if not success then
                warn("[SandbagFarm] Ошибка в цикле:", err)
            end
        end
    end

    local rpEnabled = false
    local rpLoop    = nil
    local rpConn    = nil
    local queue     = {}

    local function getPickupsFolder()
        return workspace:FindFirstChild("RoulettePickups")
    end

    local function getPositionOf(obj)
        if obj:IsA("BasePart") then return obj.Position end
        return nil
    end

    local function addToQueue(obj)
        if not obj or not obj.Parent then return end
        if obj:IsA("Model") then return end
        if obj:IsA("BasePart") then
            for _, v in ipairs(queue) do
                if v == obj then return end
            end
            table.insert(queue, obj)
        end
    end

    local function setupFolder(folder)
        for _, child in ipairs(folder:GetChildren()) do
            addToQueue(child)
        end
        if rpConn then rpConn:Disconnect() end
        rpConn = folder.ChildAdded:Connect(addToQueue)
    end

    local function rouletteLoop()
        while rpEnabled do
            local success, err = pcall(function()
                task.wait(0.1)
                local folder = getPickupsFolder()
                if folder and folder ~= (rpConn and rpConn.Connected and rpConn) then
                    if not rpConn or not rpConn.Connected then
                        setupFolder(folder)
                    end
                end
                if #queue > 0 then
                    rouletteBusy = true 
                    local target = table.remove(queue, 1)
                    if target and target.Parent then
                        local pos = getPositionOf(target)
                        if pos then
                            local char = LocalPlayer.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                                hrp.AssemblyLinearVelocity = Vector3.new()
                            end
                        end
                    end
                    rouletteBusy = false 
                end
            end)
            if not success then
                warn("[RouletteFarm] Ошибка в цикле:", err)
                rouletteBusy = false
            end
        end
    end

    ChAutofarm:Toggle("Auto Giant Sandbag", false, function(state)
        gsEnabled = state
        _G.SandbagFarmActive = state
        if state then
            if not gsLoop then 
                gsLoop = task.spawn(sandbagLoop) 
            end
        else
            if gsLoop then task.cancel(gsLoop) gsLoop = nil end
            gsOnSandbag = false
        end
    end)
    
    ChAutofarm:Seperator()

    ChAutofarm:Toggle("Auto Roulette Pickups", false, function(state)
        rpEnabled = state
        _G.RouletteFarmActive = state
        if state then
            queue = {}
            local folder = getPickupsFolder()
            if folder then
                setupFolder(folder)
            else
                local wsConn
                wsConn = workspace.ChildAdded:Connect(function(child)
                    if child.Name == "RoulettePickups" and rpEnabled then
                        setupFolder(child)
                        wsConn:Disconnect()
                    end
                end)
            end
            if not rpLoop then 
                rpLoop = task.spawn(rouletteLoop) 
            end
        else
            if rpLoop then task.cancel(rpLoop) rpLoop = nil end
            if rpConn then rpConn:Disconnect() rpConn = nil end
            queue = {}
            rouletteBusy = false
        end
    end)
    
    ChAutofarm:Seperator()
end

-- Auto Gorilla
do 
    local gfEnabled  = false
    local gfLoop     = nil
    local gfAnchor   = nil
    local gfClickRun = false
    local gfClickThread = nil
    local lastChar   = nil
    local anchorPos  = nil

    local function getGorilla()
        local g = workspace:FindFirstChild("ActiveGorilla")
        if g and g:IsA("Model") then return g end
        return nil
    end

    local function getGorillaPos(model)
        local part = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        if part then return part.Position end
        local firstPart = model:FindFirstChildWhichIsA("BasePart")
        return firstPart and firstPart.Position or nil
    end

    local function getArenaSpawn()
        local arena = workspace:FindFirstChild("Arena")
        if not arena then return nil end
        local spawn = arena:FindFirstChild("Spawn")
        if not spawn then return nil end
        if spawn:IsA("BasePart") then return spawn.Position end
        if spawn:IsA("Model") then
            local ok, cf = pcall(function() return spawn:GetPivot() end)
            if ok and cf then return cf.Position end
        end
        return nil
    end

    local function teleportToSpawn()
        local spawnPos = getArenaSpawn()
        if not spawnPos then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.CFrame = CFrame.new(spawnPos + Vector3.new(0, 3, 0))
    end

    local function anchorAt(position)
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if hum then
            hum.PlatformStand = true
        end

        local targetPos = position + Vector3.new(0, 50, 0)
        hrp.CFrame = CFrame.new(targetPos)
        hrp.AssemblyLinearVelocity = Vector3.new()
        hrp.AssemblyAngularVelocity = Vector3.new()
        if gfAnchor then gfAnchor:Destroy() end
        local ap = Instance.new("AlignPosition")
        ap.Name = "GorillaFarmAnchor"
        ap.Mode = Enum.PositionAlignmentMode.OneAttachment
        ap.MaxForce = math.huge
        ap.Responsiveness = 200
        ap.RigidityEnabled = true
        ap.Position = targetPos
        local att = Instance.new("Attachment")
        att.Name = "GorillaFarmAtt"
        att.Parent = hrp
        ap.Attachment0 = att
        ap.Parent = hrp
        gfAnchor = ap
    end

    local function releaseAnchor()
        if gfAnchor then
            local att = gfAnchor.Attachment0
            gfAnchor:Destroy()
            if att then att:Destroy() end
            gfAnchor = nil
        end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end

    local function clickLoop()
        gfClickRun = true
        while gfClickRun do
            task.wait(0.05)
            local vim = game:GetService("VirtualInputManager")
            pcall(function()
                vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            end)
            task.wait(0.01)
            pcall(function()
                vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end)
        end
    end

    local function startClicks()
        if gfClickThread then return end
        gfClickThread = task.spawn(function()
            clickLoop()
            gfClickThread = nil
        end)
    end

    local function stopClicks()
        gfClickRun = false
        if gfClickThread then
            task.cancel(gfClickThread)
            gfClickThread = nil
        end
    end

    local function farmLoop()
        while gfEnabled do
            task.wait(0.2)
            local char = LocalPlayer.Character
            if char ~= lastChar then
                lastChar = char
                gfAnchor = nil 
                if char and anchorPos then
                    anchorAt(anchorPos)
                    startClicks()
                end
            end
            local gorilla = getGorilla()
            if gorilla then
                local pos = getGorillaPos(gorilla)
                if pos then
                    if not gfAnchor or not gfAnchor.Parent then
                        anchorPos = pos + Vector3.new(0, 50, 0)
                        anchorAt(anchorPos)
                        startClicks()
                    end
                end
            else
                if anchorPos then
                    stopClicks()
                    releaseAnchor()
                    teleportToSpawn()
                    anchorPos = nil
                end
            end
        end
    end

    local function toggleGorillaFarm(state)
        gfEnabled = state
        _G.GorillaFarmActive = state
        if state then
            anchorPos = nil
            if not gfLoop then
                gfLoop = task.spawn(farmLoop)
            end
        else
            if gfLoop then
                task.cancel(gfLoop)
                gfLoop = nil
            end
            stopClicks()
            releaseAnchor() 
            anchorPos = nil
        end
    end

    ChAutofarm:Toggle("Auto Gorilla", false, function(state)
        toggleGorillaFarm(state)
    end)

    ChAutofarm:Seperator()
end

-- Training Sandbag
do
    local enabled = false
    local loop    = nil
    local selectedNum = "1"
    local lastTarget = nil
    local anchor = nil
    local lastChar = nil

    local function getTarget()
        local arena = workspace:FindFirstChild("Arena")
        local training = arena and arena:FindFirstChild("Training")
        if not training then return nil end
        local targetName = "sandbag_" .. selectedNum
        for _, child in ipairs(training:GetChildren()) do
            if string.lower(child.Name) == targetName then return child end
        end
        return nil
    end

    local function doAnchor(obj)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end

        local part = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if not part then return end
        
        local targetPos = part.Position + Vector3.new(0, 8, 0)
        hrp.CFrame = CFrame.new(targetPos)
        hrp.AssemblyLinearVelocity = Vector3.new()
        hrp.AssemblyAngularVelocity = Vector3.new()

        if anchor then
            local att = anchor.Attachment0
            anchor:Destroy()
            if att then att:Destroy() end
        end

        local ap = Instance.new("AlignPosition")
        ap.Mode = Enum.PositionAlignmentMode.OneAttachment
        ap.MaxForce = math.huge
        ap.RigidityEnabled = true
        ap.Position = targetPos
        local att = Instance.new("Attachment")
        att.Parent = hrp
        ap.Attachment0 = att
        ap.Parent = hrp
        anchor = ap
    end

    local function releaseAnchor()
        if anchor then
            local att = anchor.Attachment0
            anchor:Destroy()
            if att then att:Destroy() end
            anchor = nil
        end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end

    local function loopFunc()
        while enabled do
            task.wait(0.2)
            local char = LocalPlayer.Character
            if char ~= lastChar then
                lastChar = char
                anchor = nil
                lastTarget = nil
            end
            local isFarmActive = _G.GorillaFarmActive or _G.SandbagFarmActive or _G.RouletteFarmActive
            if isFarmActive then
                if anchor then releaseAnchor() end
                lastTarget = nil 
            else
                local obj = getTarget()
                if obj then
                    if obj ~= lastTarget or not anchor or not anchor.Parent then
                        doAnchor(obj)
                        lastTarget = obj
                    end
                end
            end
        end
    end

    ChTraining:Dropdown("Sandbag Number", {"1", "2", "3", "4", "5", "6", "7", "8", "Admin"}, function(val)
        selectedNum = string.lower(val)
        if enabled then lastTarget = nil releaseAnchor() end
    end)

    ChTraining:Toggle("Enable Sandbag Training", false, function(state)
        enabled = state
        if state then
            lastTarget = nil
            if not loop then loop = task.spawn(loopFunc) end
        else
            if loop then task.cancel(loop) loop = nil end
            releaseAnchor()
            lastTarget = nil
        end
    end)
    ChTraining:Seperator()
end

-- Training Treadmill
do
    local enabled = false
    local loop    = nil
    local selectedNum = "1"
    local lastTarget = nil
    local anchor = nil
    local lastChar = nil

    local function getTarget()
        local arena = workspace:FindFirstChild("Arena")
        local training = arena and arena:FindFirstChild("Training")
        if not training then return nil end
        local targetName = "treadmill_" .. selectedNum
        for _, child in ipairs(training:GetChildren()) do
            if string.lower(child.Name) == targetName then return child end
        end
        return nil
    end

    local function doAnchor(obj)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end

        local part = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if not part then return end
        
        local targetPos = part.Position + Vector3.new(0, 8, 0)
        hrp.CFrame = CFrame.new(targetPos)
        hrp.AssemblyLinearVelocity = Vector3.new()
        hrp.AssemblyAngularVelocity = Vector3.new()

        if anchor then
            local att = anchor.Attachment0
            anchor:Destroy()
            if att then att:Destroy() end
        end

        local ap = Instance.new("AlignPosition")
        ap.Mode = Enum.PositionAlignmentMode.OneAttachment
        ap.MaxForce = math.huge
        ap.RigidityEnabled = true
        ap.Position = targetPos
        local att = Instance.new("Attachment")
        att.Parent = hrp
        ap.Attachment0 = att
        ap.Parent = hrp
        anchor = ap
    end

    local function releaseAnchor()
        if anchor then
            local att = anchor.Attachment0
            anchor:Destroy()
            if att then att:Destroy() end
            anchor = nil
        end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end

    local function loopFunc()
        while enabled do
            task.wait(0.2)
            local char = LocalPlayer.Character
            if char ~= lastChar then
                lastChar = char
                anchor = nil
                lastTarget = nil
            end

            local isFarmActive = _G.GorillaFarmActive or _G.SandbagFarmActive or _G.RouletteFarmActive

            if isFarmActive then
                if anchor then releaseAnchor() end
                lastTarget = nil 
            else
                local obj = getTarget()
                if obj then
                    if obj ~= lastTarget or not anchor or not anchor.Parent then
                        doAnchor(obj)
                        lastTarget = obj
                    end
                end
            end
        end
    end

    ChTraining:Dropdown("Treadmill Number", {"1", "2", "3", "4", "5", "6", "7", "8", "Admin"}, function(val)
        selectedNum = string.lower(val)
        if enabled then lastTarget = nil releaseAnchor() end
    end)

    ChTraining:Toggle("Enable Treadmill Training", false, function(state)
        enabled = state
        if state then
            lastTarget = nil
            if not loop then loop = task.spawn(loopFunc) end
        else
            if loop then task.cancel(loop) loop = nil end
            releaseAnchor()
            lastTarget = nil
        end
    end)
    ChTraining:Seperator()
end

-- Free Camera E
do
    local fcEnabled = false
    local fcPos     = Vector3.new()
    local fcRotX    = 0
    local fcRotY    = 0
    local fcConn    = nil
    local fcSavedWS, fcSavedJP, fcSavedJump

    local function startFreecam()
        fcEnabled = true
        Camera.CameraType = Enum.CameraType.Scriptable

        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                fcSavedWS   = hum.WalkSpeed
                fcSavedJP   = hum.JumpPower
                fcSavedJump = hum.JumpHeight
                hum.WalkSpeed = 0
                hum.JumpPower = 0
                hum.JumpHeight = 0
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            fcPos = hrp and hrp.Position or Camera.CFrame.Position
        else
            fcPos = Camera.CFrame.Position
        end

        fcRotX = 0
        fcRotY = 0
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false

        fcConn = RunService:BindToRenderStep(
            "FreecamCustom",
            Enum.RenderPriority.Camera.Value + 1,
            function()
                if not fcEnabled then return end
                local delta = UserInputService:GetMouseDelta()
                fcRotX = fcRotX - (delta.X * 0.005)
                fcRotY = math.clamp(
                    fcRotY - (delta.Y * 0.005),
                    (-math.pi / 2) + 0.1,
                    (math.pi / 2) - 0.1
                )
                local camCF = CFrame.Angles(0, fcRotX, 0) * CFrame.Angles(fcRotY, 0, 0)
                local move = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
                fcPos = fcPos + move * freecamSpeed * 0.1
                Camera.CFrame = CFrame.lookAt(fcPos, fcPos + camCF.LookVector)
            end
        )
    end

    local function stopFreecam()
        fcEnabled = false
        if fcConn then
            RunService:UnbindFromRenderStep("FreecamCustom")
            fcConn = nil
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        Camera.CameraType = Enum.CameraType.Custom
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                Camera.CameraSubject = hum
                if fcSavedWS   then hum.WalkSpeed = fcSavedWS end
                if fcSavedJP   then hum.JumpPower = fcSavedJP end
                if fcSavedJump then hum.JumpHeight = fcSavedJump end
            end
        end
        fcSavedWS, fcSavedJP, fcSavedJump = nil, nil, nil
    end

    local function toggleFreecam(state)
        if state then startFreecam() else stopFreecam() end
    end

    ChPlayer:Toggle("Free Camera", false, function(state)
        toggleFreecam(state)
    end)

    ChPlayer:Bind("Free Camera Keybind", Enum.KeyCode.E, function()
        toggleFreecam(not fcEnabled)
    end)

    ChPlayer:Slider("Freecam Speed", 1, 50, 1, function(value)
        freecamSpeed = value
    end)
    ChPlayer:Seperator()
end

-- NoClip + Fly R
do
    local flyEnabled   = false
    local flyConn      = nil
    local noclipConn   = nil
    local flyBV        = nil
    local flyChar      = nil
    local flyHRP       = nil

    local function startNoClip()
        if noclipConn then return end
        noclipConn = RunService.Stepped:Connect(function()
            if not flyEnabled then return end
            local c = LocalPlayer.Character
            if not c then return end
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end

    local function stopNoClip()
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end
        local c = LocalPlayer.Character
        if c then
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end

    local function startFly()
        flyChar = LocalPlayer.Character
        if not flyChar then return end
        flyHRP = flyChar:FindFirstChild("HumanoidRootPart")
        if not flyHRP then return end
        local hum = flyChar:FindFirstChildOfClass("Humanoid")

        flyEnabled = true
        startNoClip()
        if hum then hum.PlatformStand = true end

        flyBV = Instance.new("BodyVelocity")
        flyBV.Name = "FlyBV"
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Velocity = Vector3.new()
        flyBV.Parent = flyHRP

        flyConn = RunService.RenderStepped:Connect(function()
            if not flyEnabled or not flyHRP or not flyHRP.Parent then return end
            local move = Vector3.new()
            local keys = {
                W = Vector3.new(0, 0, 1),
                S = Vector3.new(0, 0, -1),
                A = Vector3.new(-1, 0, 0),
                D = Vector3.new(1, 0, 0),
                Space = Vector3.new(0, 1, 0),
                LeftControl = Vector3.new(0, -1, 0),
            }
            for key, dir in pairs(keys) do
                if UserInputService:IsKeyDown(Enum.KeyCode[key]) then
                    move = move + dir
                end
            end
            local cf = Camera.CFrame
            local worldMove = (cf.RightVector * move.X)
                + (Vector3.new(0, move.Y, 0))
                + (cf.LookVector * move.Z)
            flyBV.Velocity = worldMove * flySpeed
        end)
    end

    local function stopFly()
        flyEnabled = false
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if flyBV then flyBV:Destroy() flyBV = nil end
        stopNoClip()
        if flyChar then
            local hum = flyChar:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
        flyChar = nil
        flyHRP = nil
    end

    local function toggleFly(state)
        if state then startFly() else stopFly() end
    end

    ChPlayer:Toggle("NoClip + Fly", false, function(state)
        toggleFly(state)
    end)

    ChPlayer:Bind("Fly Keybind", Enum.KeyCode.R, function()
        toggleFly(not flyEnabled)
    end)

    ChPlayer:Slider("Fly Speed", 16, 500, 50, function(value)
        flySpeed = value
    end)
    ChPlayer:Seperator()
end

-- Fast Run T
do
    local speedEnabled  = false
    local speedValue    = 50
    local speedOriginal = nil

    local function toggleFastRun(state)
        speedEnabled = state
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if state then
            speedOriginal = hum.WalkSpeed
            hum.WalkSpeed = speedValue
        else
            hum.WalkSpeed = speedOriginal or 16
            speedOriginal = nil
        end
    end

    ChPlayer:Toggle("Fast Run", false, function(state)
        toggleFastRun(state)
    end)

    ChPlayer:Bind("Fast Run Keybind", Enum.KeyCode.T, function()
        toggleFastRun(not speedEnabled)
    end)

    ChPlayer:Slider("Speed", 16, 500, 50, function(value)
        speedValue = value
        if speedEnabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = value
            end
        end
    end)
    ChPlayer:Seperator()
end

-- Infinity Jump F
do
    local ijEnabled = false
    local ijConn    = nil

    local function toggleInfJump(state)
        ijEnabled = state
        if state and not ijConn then
            ijConn = UserInputService.JumpRequest:Connect(function()
                if not ijEnabled then return end
                local char = LocalPlayer.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        elseif not state and ijConn then
            ijConn:Disconnect()
            ijConn = nil
        end
    end

    ChPlayer:Toggle("Infinity Jump", false, function(state)
        toggleInfJump(state)
    end)

    ChPlayer:Bind("Infinity Jump Keybind", Enum.KeyCode.F, function()
        toggleInfJump(not ijEnabled)
    end)
    ChPlayer:Seperator()
end

-- Teleport on click G
do
    local tpEnabled = false
    local tpConn    = nil
    local tpMouse   = nil

    local function toggleClickTP(state)
        tpEnabled = state
        if state and not tpConn then
            tpMouse = LocalPlayer:GetMouse()
            tpConn = tpMouse.Button1Down:Connect(function()
                if not tpEnabled then return end
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and tpMouse.Hit then
                    hrp.CFrame = CFrame.new(tpMouse.Hit.Position + Vector3.new(0, 3, 0))
                end
            end)
        elseif not state and tpConn then
            tpConn:Disconnect()
            tpConn = nil
            tpMouse = nil
        end
    end

    ChPlayer:Toggle("Teleport on click", false, function(state)
        toggleClickTP(state)
    end)

    ChPlayer:Bind("Teleport Keybind", Enum.KeyCode.G, function()
        toggleClickTP(not tpEnabled)
    end)
    ChPlayer:Seperator()
end

-- Anti-AFK H
do
    local afkEnabled = false
    local afkConn    = nil

    local function toggleAntiAfk(state)
        afkEnabled = state
        if state and not afkConn then
            afkConn = LocalPlayer.Idled:Connect(function()
                if not afkEnabled then return end
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        elseif not state and afkConn then
            afkConn:Disconnect()
            afkConn = nil
        end
    end

    ChPlayer:Toggle("Anti-AFK", false, function(state)
        toggleAntiAfk(state)
    end)

    ChPlayer:Bind("Anti-AFK Keybind", Enum.KeyCode.H, function()
        toggleAntiAfk(not afkEnabled)
    end)
end

-- Info
ChInfo:Label("More cheats on https://rscripts.net/@boochear")
ChInfo:Button("Copy link to Rscripts", function() setclipboard("https://rscripts.net/@boochear") end)
ChInfo:Seperator()
ChInfo:Label("Want to suggest something or report a bug?")
ChInfo:Label("Type me on telegram @boochear")
ChInfo:Button("Copy link to Telegram", function() setclipboard("https://t.me/boochear") end)
ChInfo:Seperator()
ChInfo:Button("Copy link to game", function() setclipboard("https://www.roblox.com/games/119411164144622") end)