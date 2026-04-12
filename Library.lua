if getgenv().Solance_CounterBlox_Loaded then
    return
end
getgenv().Solance_CounterBlox_Loaded = true

local repo = 'https://raw.githubusercontent.com/wizzardd1337/solancelib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()

if game.PlaceId ~= 301549746 then
    if Library and Library.NotifyError then
        pcall(function() Library:NotifyError("wrong game, join counter blox", 10) end)
    elseif Library and Library.NotifyMid then
        pcall(function() Library:NotifyMid("wrong game, join counter blox", 10) end)
    end
    task.delay(4, function() pcall(function() Library:Unload() end) end)
    getgenv().Solance_CounterBlox_Loaded = nil
    return
end

-- [[ SOLANCE AUTOMATED SECURITY GATE ]] --
local SUPABASE_URL = "https://kgcpzexkgrdsvupaxpmv.supabase.co"
local SUPABASE_KEY = "sb_publishable_j0TFGJANFx3WUC_SMmOo8g_yLLDG7o5"

local function SolanceAuth()
    local http_service = game:GetService("HttpService")
    local request_func = syn and syn.request or http_request or request or (http and http.request)
    
    local function fail(msg)
        local lmsg = string.lower(msg)
        if string.find(lmsg, "banned") then
            if Library and Library.NotifyError then
                pcall(function() Library:NotifyError("[solance]: banned, check website for details", 10) end)
            end
            local lp = game:GetService("Players").LocalPlayer
            if lp then lp:Kick("\n[solance]\n" .. msg) end
        elseif string.find(lmsg, "no active sub") or string.find(lmsg, "expired") then
            local lp = game:GetService("Players").LocalPlayer
            if lp then lp:Kick("\n[solance]\n" .. msg) end
        else
            if Library and Library.NotifyError then
                pcall(function() Library:NotifyError("[solance]: " .. msg, 10) end)
            elseif Library and Library.NotifyMid then
                pcall(function() Library:NotifyMid("[solance]: " .. msg, 10) end)
            end
            task.delay(4, function() pcall(function() Library:Unload() end) end)
        end
        getgenv().Solance_CounterBlox_Loaded = nil
        return false
    end

    if not request_func then return fail("executor not supported (missing request function)") end


    local function GetLocalSession()
        local success, res = pcall(function()
            return request_func({
                Url = "http://127.0.0.1:9999/auth",
                Method = "GET"
            })
        end)
        
        if not success or res.StatusCode ~= 200 then return nil end
        
        local data = http_service:JSONDecode(res.Body)
        return data.user_id
    end
    local function Verify()
        local current_id = GetLocalSession()
        if not current_id then return false, "loader not found! open the loader first" end

        local profile_res = request_func({
            Url = SUPABASE_URL .. "/rest/v1/profiles?select=is_banned,ban_reason,ban_expires_at&id=eq." .. current_id,
            Method = "GET",
            Headers = { ["apikey"] = SUPABASE_KEY, ["Authorization"] = "Bearer " .. SUPABASE_KEY, ["Content-Type"] = "application/json" }
        })
        
        if profile_res and profile_res.StatusCode == 200 then
            local pdata = http_service:JSONDecode(profile_res.Body)
            if #pdata > 0 then
                local p = pdata[1]
                if p.is_banned then
                    if not p.ban_expires_at then
                        return false, "banned, check website for details"
                    else
                        local exp_str = p.ban_expires_at:gsub("T", " "):gsub("Z", "")
                        local y,m,d,h,min,s = exp_str:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
                        if y then
                            local exp_time = os.time({year=y, month=m, day=d, hour=h, min=min, sec=s})
                            if os.time() <= exp_time then
                                return false, "banned, check website for details"
                            end
                        end
                    end
                end
            end
        end

        local url = SUPABASE_URL .. "/rest/v1/subscriptions?select=expires_at,is_loader_active&user_id=eq." .. current_id
        local res = request_func({
            Url = url,
            Method = "GET",
            Headers = {
                ["apikey"] = SUPABASE_KEY,
                ["Authorization"] = "Bearer " .. SUPABASE_KEY,
                ["Content-Type"] = "application/json"
            }
        })

        if res.StatusCode ~= 200 then 
            return false, "server connection failed (error " .. tostring(res.StatusCode) .. ")" 
        end
        
        local data = http_service:JSONDecode(res.Body)
        if #data == 0 then 
            return false, "no active subscription found for this account."
        end
        
        local sub = data[1]
        if not sub.is_loader_active then 
            return false, "loader session inactive! please login to the .exe first." 
        end

        local expire_str = sub.expires_at:gsub("T", " "):gsub("Z", "")
        local y, m, d, h, min, s = expire_str:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
        local expire_time = os.time({year=y, month=m, day=d, hour=h, min=min, sec=s})
        
        if os.time() > expire_time then 
            return false, "your subscription has expired." 
        end

        return true
    end

    local ok, err = Verify()
    if not ok then return fail(err) end

    task.spawn(function()
        while task.wait(10) do
            if Library.Unloaded then break end
            local still_ok, check_err = Verify()
            if not still_ok then 
                fail(check_err)
                break 
            end
        end
    end)
    return true
end

if not SolanceAuth() then return end
-- [[ END SECURITY GATE ]] --

-- [[ ANTI-REVERSE ENGINEERING SHIELD ]] --
Library._SolanceIntegrity = "verified"
local AntiReverse = loadstring(game:HttpGet("https://kgcpzexkgrdsvupaxpmv.supabase.co/functions/v1/smart-action?script=antireverse"))()
AntiReverse.Init({
    supabase_url = SUPABASE_URL,
    supabase_key = SUPABASE_KEY,
    user_id = (function()
        local rf = syn and syn.request or http_request or request or (http and http.request)
        local ok, res = pcall(function() return rf({ Url = "http://127.0.0.1:9999/auth", Method = "GET" }) end)
        if ok and res.StatusCode == 200 then
            return game:GetService("HttpService"):JSONDecode(res.Body).user_id
        end
        return nil
    end)(),
    request_func = syn and syn.request or http_request or request or (http and http.request),
    library = Library
})
AntiReverse.Start()
-- [[ END ANTI-REVERSE ]] --

local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local function GetBoundingBox3D(cf, size)
    local w, h, d = size.X / 2, size.Y / 2, size.Z / 2
    return {
        cf * CFrame.new(-w, -h, -d),
        cf * CFrame.new(w, -h, -d),
        cf * CFrame.new(w, h, -d),
        cf * CFrame.new(-w, h, -d),
        cf * CFrame.new(-w, -h, d),
        cf * CFrame.new(w, -h, d),
        cf * CFrame.new(w, h, d),
        cf * CFrame.new(-w, h, d)
    }
end

local Window = Library:CreateWindow({
    Title = 'solance counter blox | by mkusha666'  ,
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    visuals = Window:AddTab('visuals'),
    legit = Window:AddTab('legit'),
    rage = Window:AddTab('rage'),
    misc = Window:AddTab('misc'),
    skins = Window:AddTab('skins'),

    ['ui settings'] = Window:AddTab('ui settings'),
}

-- [[ MISC LOGIC VARIABLES ]] --
local PlantC4Event = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("PlantC4")
local ThrowGrenadeEvent = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("ThrowGrenade")
local planting, defusing = false, false
local CrashServerLoop = nil
local FW_Spectator_Thread = nil

-- [[ MULTIPLIERS TABLE (from stormy.solutions) ]] --
local Multipliers = {
    ["Head"] = 4,
    ["HeadHB"] = 4,
    ["UpperTorso"] = 1,
    ["LowerTorso"] = 1.25,
    ["LeftUpperArm"] = 1,
    ["LeftLowerArm"] = 1,
    ["LeftHand"] = 1,
    ["RightUpperArm"] = 1,
    ["RightLowerArm"] = 1,
    ["RightHand"] = 1,
    ["LeftUpperLeg"] = 0.75,
    ["LeftLowerLeg"] = 0.75,
    ["LeftFoot"] = 0.75,
    ["RightUpperLeg"] = 0.75,
    ["RightLowerLeg"] = 0.75,
    ["RightFoot"] = 0.75,
}

-- [[ DAMAGE CALCULATION (from stormy.solutions) ]] --
local function GetGunDamage(gun, hitPartName, origin, targetPos, hasArmor)
    local baseDamage = gun.DMG.Value
    local multiplier = Multipliers[hitPartName] or 1
    local damage = baseDamage * multiplier

    -- Armor penetration
    if hasArmor then
        if string.find(hitPartName, "Head") then
            damage = (damage / 100) * gun.ArmorPenetration.Value
        else
            damage = (damage / 100) * gun.ArmorPenetration.Value
        end
    end

    -- Range modifier
    local distance = (origin - targetPos).Magnitude
    local rangeMod = gun.RangeModifier.Value / 100
    damage = damage * (rangeMod ^ (distance / 500))

    return damage
end

-- [[ AUTOMATIC FIRE HELPER ]] --
local function CanShootTarget(gun, player, hitboxName, origin, minDamage)
    if not player.Character then return false, nil end
    local hitbox = player.Character:FindFirstChild(hitboxName)
    if not hitbox then return false, nil end

    local hasArmor = player.Character:FindFirstChild("Kevlar") ~= nil
    local damage = GetGunDamage(gun, hitboxName, origin, hitbox.Position, hasArmor)

    if damage >= minDamage then
        return true, hitbox
    end
    return false, nil
end

local function GetSite()
    local lp = game:GetService("Players").LocalPlayer
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return "A" end
    local c4plant = workspace.Map.SpawnPoints:FindFirstChild("C4Plant")
    local c4plant2 = workspace.Map.SpawnPoints:FindFirstChild("C4Plant2")
    if not c4plant or not c4plant2 then return "A" end
    
    local distA = (lp.Character.HumanoidRootPart.Position - c4plant2.Position).Magnitude
    local distB = (lp.Character.HumanoidRootPart.Position - c4plant.Position).Magnitude
    if distB < distA then return "B" else return "A" end
end

local function AutoPlantC4()
    local lp = game:GetService("Players").LocalPlayer
    local Camera = workspace.CurrentCamera
    pcall(function()
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character:FindFirstChild("Humanoid") and lp.Character.Humanoid.Health > 0 and workspace.Map.Gamemode.Value == "defusal" and workspace.Status.Preparation.Value == false and not planting then 
            planting = true
            local pos = lp.Character.HumanoidRootPart.CFrame 
            local pCamType = Camera.CameraType
            Camera.CameraType = Enum.CameraType.Fixed
            local c4plant = workspace.Map.SpawnPoints:FindFirstChild("C4Plant")
            if not c4plant then c4plant = workspace.Map.SpawnPoints:FindFirstChild("C4Plant2") end
            if not c4plant then planting = false return end
            
            lp.Character.HumanoidRootPart.CFrame = c4plant.CFrame
            task.wait(0.2)
            PlantC4Event:FireServer((pos + Vector3.new(0, -2.75, 0)) * CFrame.Angles(math.rad(90), 0, math.rad(180)), GetSite())
            task.wait(0.2)
            lp.Character.HumanoidRootPart.CFrame = pos
            lp.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            Camera.CameraType = pCamType
            planting = false
        end
    end)
end

local function AutoDefuseC4()
    local lp = game:GetService("Players").LocalPlayer
    local Camera = workspace.CurrentCamera
    pcall(function()
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character:FindFirstChild("Humanoid") and lp.Character.Humanoid.Health > 0 and workspace.Map.Gamemode.Value == "defusal" and not defusing and workspace:FindFirstChild("C4") then 
            defusing = true
            lp.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            local pos = lp.Character.HumanoidRootPart.CFrame 
            local pCamType = Camera.CameraType
            Camera.CameraType = Enum.CameraType.Fixed
            lp.Character.HumanoidRootPart.CFrame = workspace.C4.Handle.CFrame + Vector3.new(0, 2, 0)
            lp.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            task.wait(0.1)
            lp.Backpack.PressDefuse:FireServer(workspace.C4)
            lp.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            task.wait(0.25)
            if lp.Character and workspace:FindFirstChild("C4") and workspace.C4:FindFirstChild("Defusing") and workspace.C4.Defusing.Value == lp then
                lp.Backpack.Defuse:FireServer(workspace.C4)
            end
            lp.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            task.wait(0.2)
            lp.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            lp.Character.HumanoidRootPart.CFrame = pos
            lp.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            Camera.CameraType = pCamType
            defusing = false
        end
    end)
end

local function GetSpectators()
    local CurrentSpectators = {}
    local lp = game:GetService("Players").LocalPlayer
    local Camera = workspace.CurrentCamera
    for _, v in pairs(game:GetService("Players"):GetPlayers()) do 
        if v ~= lp then
            if not v.Character and v:FindFirstChild("CameraCF") and (v.CameraCF.Value.Position - Camera.CFrame.p).Magnitude < 10 then 
                table.insert(CurrentSpectators, v.Name)
            end
        end
    end
    return CurrentSpectators
end

local function CrashServer()
    local WeaponsData = game:GetService("ReplicatedStorage"):FindFirstChild("Weapons")
    if CrashServerLoop then
        CrashServerLoop:Disconnect()
        CrashServerLoop = nil
        return
    end
    local lp = game:GetService("Players").LocalPlayer
    if lp.Character then
        CrashServerLoop = game:GetService("RunService").RenderStepped:Connect(function()
            pcall(function()
                ThrowGrenadeEvent:FireServer(WeaponsData["Molotov"].Model, nil, 25, 35, Vector3.new(0,-100,0), nil, nil)
                ThrowGrenadeEvent:FireServer(WeaponsData["HE Grenade"].Model, nil, 25, 35, Vector3.new(0,-100,0), nil, nil)
                ThrowGrenadeEvent:FireServer(WeaponsData["Decoy Grenade"].Model, nil, 25, 35, Vector3.new(0,-100,0), nil, nil)
                ThrowGrenadeEvent:FireServer(WeaponsData["Smoke Grenade"].Model, nil, 25, 35, Vector3.new(0,-100,0), nil, nil)
                ThrowGrenadeEvent:FireServer(WeaponsData["Flashbang"].Model, nil, 25, 35, Vector3.new(0,-100,0), nil, nil)
            end)
        end)
    end
end
-- [[ END MISC LOGIC VARIABLES ]] --

local PlayersGroup = Tabs.visuals:AddLeftGroupbox('players')

PlayersGroup:AddToggle('ESP_Enabled', { Text = 'enabled', Default = false, Tooltip = 'enable esp' })
PlayersGroup:AddToggle('ESP_Boxes', { Text = '2dbox', Default = false, Tooltip = 'draw 2d boxes' }):AddColorPicker('ESP_BoxesColor', { Default = Color3.new(1, 1, 1), Title = '2dbox color' })
PlayersGroup:AddToggle('ESP_HealthBar', { Text = 'healthbar', Default = false, Tooltip = 'draw health bars' })
    :AddColorPicker('ESP_HealthGradientLow', { Default = Color3.fromRGB(255, 0, 0), Title = 'hp gradient low' })
    :AddColorPicker('ESP_HealthGradientHigh', { Default = Color3.fromRGB(0, 255, 0), Title = 'hp gradient high' })
PlayersGroup:AddToggle('ESP_Skeleton', { Text = 'skeleton', Default = false, Tooltip = 'draw skeleton' }):AddColorPicker('ESP_SkeletonColor', { Default = Color3.new(1, 1, 1), Title = 'skeleton color' })
PlayersGroup:AddToggle('ESP_Chams', { Text = 'chams', Default = false, Tooltip = 'draw full model chams' }):AddColorPicker('ESP_ChamsColor', { Default = Color3.new(1, 0, 0), Title = 'chams color' })
PlayersGroup:AddToggle('ESP_Nickname', { Text = 'nickname', Default = false, Tooltip = 'draw nickname' }):AddColorPicker('ESP_NicknameColor', { Default = Color3.new(1, 1, 1), Title = 'nickname color' })
PlayersGroup:AddToggle('ESP_Distance', { Text = 'distance', Default = false, Tooltip = 'draw distance' }):AddColorPicker('ESP_DistanceColor', { Default = Color3.new(1, 1, 1), Title = 'distance color' })
PlayersGroup:AddToggle('ESP_Weapon', { Text = 'weapon', Default = false, Tooltip = 'draw weapon' }):AddColorPicker('ESP_WeaponColor', { Default = Color3.new(1, 1, 1), Title = 'weapon color' })
PlayersGroup:AddToggle('ESP_Snapline', { Text = 'snapline', Default = false, Tooltip = 'line from your torso to enemy torso' })
    :AddColorPicker('ESP_SnaplineColor', { Default = Color3.fromRGB(255, 255, 255), Title = 'snapline color' })
PlayersGroup:AddDropdown('Chams_MaterialVisible', { Text = 'visible material', Default = 1, Values = {'flat', 'neon', 'forcefield'} })
PlayersGroup:AddDropdown('Chams_MaterialInvisible', { Text = 'invisible material', Default = 2, Values = {'flat', 'neon', 'forcefield'} })

local SettingsGroup = Tabs.visuals:AddLeftGroupbox('settings')
SettingsGroup:AddToggle('ESP_IgnoreTeam', { Text = 'ignore team', Default = false, Tooltip = 'hide teammates from esp' })
SettingsGroup:AddToggle('ESP_IgnoreDead', { Text = 'ignore dead', Default = true, Tooltip = 'hide dead players from esp' })
SettingsGroup:AddToggle('ESP_VisibleOnly', { Text = 'visible only', Default = false, Tooltip = 'only show visible players' })

local SelfVisualsGroup = Tabs.visuals:AddLeftGroupbox('self visuals')
SelfVisualsGroup:AddToggle('Self_Chams', { Text = 'enabled', Default = false, Tooltip = 'apply material + color to your own character' }):AddColorPicker('Self_ChamsColor', { Default = Color3.fromRGB(170, 0, 255), Title = 'self color' })
SelfVisualsGroup:AddDropdown('Self_Material', { Text = 'material', Default = 'neon', Values = {'neon', 'forcefield', 'flat'} })
SelfVisualsGroup:AddToggle('Self_AngelWings', { Text = 'angel wings', Default = false, Tooltip = 'adds custom angel wings to your character locally' })


local WeaponsGroup = Tabs.visuals:AddRightGroupbox('weapon esp')
WeaponsGroup:AddToggle('WeaponESP_Enabled', { Text = 'enabled', Default = false, Tooltip = 'enable dropped weapon esp' })
WeaponsGroup:AddToggle('WeaponESP_3DBox', { Text = '3dbox', Default = false }):AddColorPicker('WeaponESP_3DBoxColor', { Default = Color3.new(1, 1, 1) })
WeaponsGroup:AddToggle('WeaponESP_Name', { Text = 'name', Default = false }):AddColorPicker('WeaponESP_NameColor', { Default = Color3.new(1, 1, 1) })
WeaponsGroup:AddToggle('WeaponESP_Distance', { Text = 'distance', Default = false }):AddColorPicker('WeaponESP_DistanceColor', { Default = Color3.new(1, 1, 1) })
WeaponsGroup:AddToggle('WeaponESP_Ammo', { Text = 'ammo', Default = false }):AddColorPicker('WeaponESP_AmmoColor', { Default = Color3.new(1, 1, 1) })
WeaponsGroup:AddToggle('WeaponESP_Snapline', { Text = 'snapline', Default = false, Tooltip = 'line from your torso to dropped weapon' })
    :AddColorPicker('WeaponESP_SnaplineColor', { Default = Color3.fromRGB(255, 255, 255), Title = 'weapon snapline color' })

local BombGroup = Tabs.visuals:AddRightGroupbox('bomb')
BombGroup:AddToggle('BombESP_Enabled', { Text = 'enabled', Default = false, Tooltip = 'enable bomb esp' })
BombGroup:AddToggle('BombESP_Tracer', { Text = 'tracer', Default = false }):AddColorPicker('BombESP_TracerColor', { Default = Color3.fromRGB(255, 0, 0) })
BombGroup:AddToggle('BombESP_Name', { Text = 'name plant', Default = false }):AddColorPicker('BombESP_NameColor', { Default = Color3.fromRGB(255, 0, 0) })
BombGroup:AddToggle('BombESP_Notification', { Text = 'notification', Default = false, Tooltip = 'notify when bomb is planted' })

local VisualizeGroup = Tabs.visuals:AddRightGroupbox('visualize backtrack')
VisualizeGroup:AddToggle('Vis_Backtrack', { Text = 'show backtrack', Default = false }):AddColorPicker('Vis_BacktrackColor', { Default = Color3.fromRGB(0, 150, 255) })
VisualizeGroup:AddDropdown('Vis_BacktrackMaterial', { Text = 'material', Default = 1, Values = {'neon', 'flat', 'forcefield'} })
VisualizeGroup:AddSlider('Vis_BacktrackTime', { Text = 'backtrack time', Default = 200, Min = 50, Max = 400, Rounding = 0, Compact = true, Suffix = 'ms' })



local HitEffectsGroup = Tabs.visuals:AddRightGroupbox('hit effects')
HitEffectsGroup:AddToggle('HitFX_Chams', { Text = 'hit chams', Default = false }):AddColorPicker('HitFX_ChamsColor', { Default = Color3.fromRGB(170, 0, 255), Title = 'hit chams color' })
HitEffectsGroup:AddSlider('HitFX_ChamsDuration', { Text = 'chams duration', Default = 2, Min = 0.5, Max = 10, Rounding = 1, Compact = true, Suffix = 's' })
HitEffectsGroup:AddToggle('HitFX_Damage', { Text = 'draw damage', Default = false }):AddColorPicker('HitFX_DamageColor', { Default = Color3.fromRGB(255, 50, 50), Title = 'damage color' })
HitEffectsGroup:AddSlider('HitFX_TextDuration', { Text = 'text duration', Default = 2, Min = 0.5, Max = 10, Rounding = 1, Compact = true, Suffix = 's' })
HitEffectsGroup:AddSlider('HitFX_TextSize', { Text = 'text size', Default = 14, Min = 8, Max = 36, Rounding = 0, Compact = true })
HitEffectsGroup:AddDropdown('HitFX_Font', { Text = 'text font', Default = 'Code', Values = {'Code', 'GothamBold', 'SourceSans', 'SourceSansBold', 'Arial', 'ArialBold', 'Ubuntu', 'Roboto', 'RobotoMono'} })
HitEffectsGroup:AddToggle('HitFX_Notify', { Text = 'notification', Default = false })
HitEffectsGroup:AddSlider('HitFX_NotifyDuration', { Text = 'notify duration', Default = 2, Min = 0.5, Max = 10, Rounding = 1, Compact = true, Suffix = 's' })
HitEffectsGroup:AddInput('HitFX_NotifyText', { Default = 'hit {PLAYER} in {PART}', Numeric = false, Finished = false, Text = 'notify text', Tooltip = 'use {PLAYER} and {PART}' })

local TracersGroup = Tabs.visuals:AddRightGroupbox('bullet tracers')
TracersGroup:AddToggle('Tracers_Enabled', { Text = 'enabled', Default = false }):AddColorPicker('Tracers_Color', { Default = Color3.fromRGB(0, 150, 255), Title = 'tracer color' })
TracersGroup:AddSlider('Tracers_Duration', { Text = 'duration', Default = 1.5, Min = 0.1, Max = 5, Rounding = 1, Compact = true, Suffix = 's' })
TracersGroup:AddDropdown('Tracers_Material', { Text = 'material', Default = 'neon', Values = {'neon', 'forcefield', 'flat'} })


local VectorGroup = Tabs.legit:AddLeftGroupbox('vector aimbot')
VectorGroup:AddToggle('Vector_Enabled', { Text = 'enabled', Default = false, Tooltip = 'enable vector aimbot' }):AddKeyPicker('Vector_EnabledBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'vector aimbot bind' })
VectorGroup:AddToggle('Vector_UseBind', { Text = 'use bind', Default = true, Tooltip = 'aim only when holding bind' })
VectorGroup:AddToggle('Vector_ShowFOV', { Text = 'show fov', Default = false, Tooltip = 'draw fov circle' }):AddColorPicker('Vector_FOVColor', { Default = Color3.fromRGB(255, 255, 255), Title = 'fov color' })
VectorGroup:AddToggle('Vector_Wallcheck', { Text = 'wallcheck', Default = false, Tooltip = 'only aim at visible targets' })
VectorGroup:AddSlider('Vector_FOV', { Text = 'fov', Default = 120, Min = 10, Max = 500, Rounding = 0, Compact = true })
VectorGroup:AddSlider('Vector_Smoothness', { Text = 'smoothness', Default = 5, Min = 1, Max = 20, Rounding = 1, Compact = true })

local TargetingGroup = Tabs.legit:AddLeftGroupbox('targeting')
TargetingGroup:AddDropdown('Vector_Hitbox', { Text = 'hitboxes', Default = {'Head'}, Values = {'Head', 'UpperTorso', 'LowerTorso', 'HumanoidRootPart'}, Multi = true, Tooltip = 'select allowable target bones' })
TargetingGroup:AddDropdown('Vector_TargetMethod', { Text = 'target method', Default = 1, Values = {'nearest to crosshair', 'random from hitboxes', 'first from hitboxes'} })

local HumanizationGroup = Tabs.legit:AddLeftGroupbox('humanization')
HumanizationGroup:AddSlider('Vector_KillDelay', { Text = 'kill delay', Default = 0, Min = 0, Max = 1000, Rounding = 0, Compact = true, Suffix = 'ms' })

local CurveGroup = Tabs.legit:AddRightGroupbox('curve aiming')
CurveGroup:AddToggle('Vector_CurveEnabled', { Text = 'enabled', Default = false, Tooltip = 'uses bezier curves to simulate human aim' })
CurveGroup:AddSlider('Vector_CurveIntensity', { Text = 'curve intensity', Default = 5, Min = 1, Max = 20, Rounding = 1, Compact = true })

local RCSGroup = Tabs.legit:AddRightGroupbox('recoil control')
RCSGroup:AddToggle('Vector_RCSEnabled', { Text = 'enabled', Default = false, Tooltip = 'pulls crosshair down when aiming and shooting' })
RCSGroup:AddSlider('Vector_RCSX', { Text = 'rcs x (yaw)', Default = 100, Min = 0, Max = 200, Rounding = 0, Compact = true, Suffix = '%' })
RCSGroup:AddSlider('Vector_RCSY', { Text = 'rcs y (pitch)', Default = 100, Min = 0, Max = 200, Rounding = 0, Compact = true, Suffix = '%' })
RCSGroup:AddSlider('Vector_RCSSmoothness', { Text = 'rcs smoothness', Default = 5, Min = 1, Max = 20, Rounding = 1, Compact = true })

local RageBotGroup = Tabs.rage:AddLeftGroupbox('rage bot')
RageBotGroup:AddToggle('Silent_Enabled', { Text = 'enabled', Default = false, Tooltip = 'enable rage bot' }):AddKeyPicker('Silent_EnabledBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'rage bot bind' })
RageBotGroup:AddToggle('Silent_AutoWall', { Text = 'auto wall', Default = false, Tooltip = 'shoot through walls if possible' })
RageBotGroup:AddToggle('Silent_UseFOV', { Text = 'use fov', Default = true, Tooltip = 'only target players within fov circle' })
RageBotGroup:AddSlider('Silent_FOV', { Text = 'fov', Default = 100, Min = 10, Max = 500, Rounding = 0, Compact = true })
RageBotGroup:AddToggle('Silent_ShowFOV', { Text = 'show fov', Default = false, Tooltip = 'draw animated gradient fov circle' })
    :AddColorPicker('Silent_FOVColor1', { Default = Color3.new(1, 1, 1), Title = 'gradient color 1' })
    :AddColorPicker('Silent_FOVColor2', { Default = Color3.new(1, 1, 1), Title = 'gradient color 2' })
    :AddColorPicker('Silent_FOVColor3', { Default = Color3.new(1, 1, 1), Title = 'gradient color 3' })

local WeaponConfigGroup = Tabs.rage:AddLeftGroupbox('weapon config')
WeaponConfigGroup:AddDropdown('WC_Hitboxes', { Text = 'hitboxes', Default = {'Head'}, Values = {'Head', 'HeadHB', 'UpperTorso', 'LowerTorso', 'HumanoidRootPart', 'LeftUpperArm', 'RightUpperArm', 'LeftUpperLeg', 'RightUpperLeg'}, Multi = true, Tooltip = 'select target hitboxes for silent aim' })

local ExploitsGroup = Tabs.rage:AddLeftGroupbox('exploits')
ExploitsGroup:AddToggle('Exploit_Shotgun', { Text = 'shotgun', Default = false, Tooltip = 'shoots 4 bullets per shot' }):AddKeyPicker('Exploit_ShotgunBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'shotgun mod' })
ExploitsGroup:AddToggle('Exploit_RapidFire', { Text = 'rapid fire', Default = false, Tooltip = 'shoots extremely fast' }):AddKeyPicker('Exploit_RapidFireBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'rapid fire mod' })
ExploitsGroup:AddToggle('Exploit_FullAuto', { Text = 'full auto', Default = false, Tooltip = 'makes all weapons fully automatic' }):AddKeyPicker('Exploit_FullAutoBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'full auto mod' })
ExploitsGroup:AddToggle('Exploit_InstaEquip', { Text = 'instant equip', Default = false, Tooltip = 'equips weapons instantly' }):AddKeyPicker('Exploit_InstaEquipBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'instant equip mod' })
ExploitsGroup:AddToggle('Exploit_InstaReload', { Text = 'instant reload', Default = false, Tooltip = 'reloads weapons instantly' }):AddKeyPicker('Exploit_InstaReloadBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'instant reload mod' })
ExploitsGroup:AddToggle('Exploit_NoSpread', { Text = 'no spread', Default = false, Tooltip = 'removes bullet spread' }):AddKeyPicker('Exploit_NoSpreadBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'no spread mod' })
ExploitsGroup:AddToggle('Exploit_ThirdPerson', { Text = 'third person', Default = false, Tooltip = 'toggles ThirdPerson value in workspace' }):AddKeyPicker('Exploit_ThirdPersonBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'third person bind' })
ExploitsGroup:AddToggle('Exploit_Wallbang', { Text = 'wallbang', Default = false, Tooltip = 'bullets pass through all walls (requires silent aim)' }):AddKeyPicker('Exploit_WallbangBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'wallbang' })


local PeekAssistGroup = Tabs.rage:AddLeftGroupbox('peek assist')
PeekAssistGroup:AddToggle('Peek_Enabled', { Text = 'enabled', Default = false, Tooltip = 'enable peek assist' }):AddKeyPicker('Peek_Bind', { Default = 'None', SyncToggleState = true, Mode = 'Hold', Text = 'peek assist bind' })
PeekAssistGroup:AddDropdown('Peek_Type', { Text = 'peek type', Default = 'teleportation', Values = {'walk', 'teleportation'} })
PeekAssistGroup:AddToggle('Peek_Visualize', { Text = 'draw circle', Default = true }):AddColorPicker('Peek_CircleColor', { Default = Color3.fromRGB(170, 0, 255), Title = 'circle color', Transparency = 0.7 })
PeekAssistGroup:AddToggle('Peek_ReleaseOnShot', { Text = 'release on shot', Default = false, Tooltip = 'auto return after shooting' })

local AntiAimGroup = Tabs.rage:AddRightGroupbox('anti aim')
AntiAimGroup:AddToggle('AA_Enabled', { Text = 'enabled', Default = false }):AddKeyPicker('AA_EnabledBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'anti aim bind' })
AntiAimGroup:AddToggle('AA_Jitter', { Text = 'jitter', Default = false })
AntiAimGroup:AddToggle('AA_ExtendPitch', { Text = 'extend pitch', Default = false })
AntiAimGroup:AddDropdown('AA_YawBase', { Text = 'yaw base', Default = 1, Values = {'camera', 'targets', 'spin', 'random'} })
AntiAimGroup:AddDropdown('AA_Pitch', { Text = 'pitch', Default = 1, Values = {'none', 'up', 'down', 'zero', '180', 'random'} })
AntiAimGroup:AddDropdown('AA_BodyRoll', { Text = 'body roll', Default = 1, Values = {'off', '180'} })
AntiAimGroup:AddSlider('AA_YawOffset', { Text = 'yaw offset', Default = 0, Min = -180, Max = 180, Rounding = 0, Compact = true })
AntiAimGroup:AddSlider('AA_JitterOffset', { Text = 'jitter offset', Default = 0, Min = -180, Max = 180, Rounding = 0, Compact = true })
AntiAimGroup:AddSlider('AA_SpinSpeed', { Text = 'spin speed', Default = 4, Min = 1, Max = 48, Rounding = 0, Compact = true })

AntiAimGroup:AddDivider()
AntiAimGroup:AddLabel('manuals')
AntiAimGroup:AddToggle('AA_ManualLeft', { Text = 'left', Default = false }):AddKeyPicker('AA_ManualLeftBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'manual left' })
AntiAimGroup:AddToggle('AA_ManualRight', { Text = 'right', Default = false }):AddKeyPicker('AA_ManualRightBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'manual right' })

local FakelagGroup = Tabs.rage:AddRightGroupbox('fakelag')
FakelagGroup:AddToggle('FL_Enabled', { Text = 'enabled', Default = false })
FakelagGroup:AddDropdown('FL_Amount', { Text = 'amount', Default = 1, Values = {'static', 'dynamic'} })
FakelagGroup:AddSlider('FL_Limit', { Text = 'limit', Default = 8, Min = 1, Max = 16, Rounding = 0, Compact = true })
FakelagGroup:AddToggle('FL_Visualize', { Text = 'visualize lag', Default = false }):AddColorPicker('FL_VisualizeColor', { Default = Color3.fromRGB(255, 255, 255), Title = 'visualize lag' })

local AutoShootGroup = Tabs.rage:AddRightGroupbox('auto shoot')
AutoShootGroup:AddToggle('AutoShoot_Enabled', { Text = 'enabled', Default = false, Tooltip = 'automatically shoot at targets' })
AutoShootGroup:AddSlider('AutoShoot_ShootDelay', { Text = 'shoot delay', Default = 0, Min = 0, Max = 1000, Rounding = 0, Compact = true, Suffix = 'ms' })
AutoShootGroup:AddSlider('AutoShoot_SemiDelay', { Text = 'semi delay', Default = 100, Min = 1, Max = 1000, Rounding = 0, Compact = true, Suffix = 'ms' })
AutoShootGroup:AddDropdown('AutoShoot_Mode', { Text = 'fire mode', Default = 'standard', Values = {'standard', 'hitpart'} })
AutoShootGroup:AddToggle('AutoShoot_DoubleTap', { Text = 'double tap', Default = false, Tooltip = 'shoot twice per shot' })

local HitsoundGroup = Tabs.rage:AddRightGroupbox('hitsound')
HitsoundGroup:AddDropdown('Hitsound_Sound', { Text = 'sound', Default = 1, Values = {'none', 'skeet', 'neverlose', 'rust', 'bag', 'baimware'} })
HitsoundGroup:AddSlider('Hitsound_Volume', { Text = 'volume', Default = 3, Min = 1, Max = 10, Rounding = 1, Compact = true })

local MovementGroup = Tabs.misc:AddLeftGroupbox('movement')
MovementGroup:AddToggle('Misc_Noclip', { Text = 'noclip', Default = false }):AddKeyPicker('Misc_NoclipBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'noclip bind' })
MovementGroup:AddSlider('Misc_NoclipSpeed', { Text = 'noclip speed', Default = 50, Min = 10, Max = 200, Rounding = 0, Compact = true })
MovementGroup:AddDivider()
MovementGroup:AddToggle('Misc_SpeedHack', { Text = 'speed hack', Default = false }):AddKeyPicker('Misc_SpeedHackBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'speed hack bind' })
MovementGroup:AddSlider('Misc_SpeedValue', { Text = 'speed', Default = 30, Min = 10, Max = 150, Rounding = 0, Compact = true })
MovementGroup:AddDropdown('Misc_SpeedType', { Text = 'type', Default = 1, Values = {'velocity', 'cframe'} })
MovementGroup:AddDivider()
MovementGroup:AddToggle('Misc_AirStrafe', { Text = 'air strafe', Default = false }):AddKeyPicker('Misc_AirStrafeBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'air strafe' })
MovementGroup:AddSlider('Misc_AirStrafeSpeed', { Text = 'jump boost power', Default = 30, Min = 10, Max = 350, Rounding = 1, Compact = true })
MovementGroup:AddToggle('Misc_InfiniteCrouch', { Text = 'infinite crouch', Default = false })



local MiscExploitsGroup = Tabs.misc:AddLeftGroupbox('exploits')

MiscExploitsGroup:AddToggle('Misc_AutoPlant', { Text = 'auto plant', Default = false }):AddKeyPicker('Misc_AutoPlantBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'auto plant' })
Toggles.Misc_AutoPlant:OnChanged(function()
    if Toggles.Misc_AutoPlant.Value then
        task.spawn(function()
            while task.wait(0.5) do
                if Library.Unloaded or not Toggles.Misc_AutoPlant.Value then break end
                if AutoPlantC4 then AutoPlantC4() end
            end
        end)
    end
end)

MiscExploitsGroup:AddToggle('Misc_AutoDefuse', { Text = 'auto defuse', Default = false }):AddKeyPicker('Misc_AutoDefuseBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'auto defuse' })
Toggles.Misc_AutoDefuse:OnChanged(function()
    if Toggles.Misc_AutoDefuse.Value then
        task.spawn(function()
            while task.wait(0.5) do
                if Library.Unloaded or not Toggles.Misc_AutoDefuse.Value then break end
                if AutoDefuseC4 then AutoDefuseC4() end
            end
        end)
    end
end)

MiscExploitsGroup:AddToggleRed('Misc_CrashServer', { Text = 'crash server', Default = false })
Toggles.Misc_CrashServer:OnChanged(function()
    if Toggles.Misc_CrashServer.Value then
        if not CrashServerLoop and CrashServer then CrashServer() end
    else
        if CrashServerLoop then
            CrashServerLoop:Disconnect()
            CrashServerLoop = nil
        end
    end
end)

MiscExploitsGroup:AddToggle('Misc_FOVChanger', { Text = 'fov changer', Default = false }):AddKeyPicker('Misc_FOVChangerBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'fov changer' })
MiscExploitsGroup:AddSlider('Misc_FOVValue', { Text = 'fov value', Default = 90, Min = 10, Max = 150, Rounding = 0, Compact = true })
MiscExploitsGroup:AddToggle('Misc_IgnoreKillers', { Text = 'ignore killers', Default = false, Tooltip = 'disables kill parts (CanTouch/CanCollide = false)' })

local KillAllGroup = Tabs.misc:AddLeftGroupbox('kill all exploit')
KillAllGroup:AddToggle('Misc_OrbitalKillAll', { Text = 'enabled', Default = false }):AddKeyPicker('Misc_OrbitalBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'orbital kill all' })
KillAllGroup:AddSlider('Misc_OrbitalDelay', { Text = 'teleport delay', Default = 0.25, Min = 0.05, Max = 1.0, Rounding = 2, Compact = true })
KillAllGroup:AddToggle('Misc_OrbitalReturn', { Text = 'auto return', Default = true })

local OrbitalKillAllActive = false
Toggles.Misc_OrbitalKillAll:OnChanged(function()
    OrbitalKillAllActive = Toggles.Misc_OrbitalKillAll.Value
    if OrbitalKillAllActive then
        task.spawn(function()
            local Remote = game.ReplicatedStorage.Events:FindFirstChild('HitParl') or game.ReplicatedStorage.Events:FindFirstChild('HitPart')
            if not Remote then OrbitalKillAllActive = false return end
            
            local lp = game.Players.LocalPlayer
            local camera = workspace.CurrentCamera
            
            if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") or not lp.Character:FindFirstChild("Gun") then
                OrbitalKillAllActive = false
                Toggles.Misc_OrbitalKillAll:SetValue(false)
                return 
            end
            
            local gunPart = lp.Character:FindFirstChild("Gun")
            if typeof(gunPart) ~= "Instance" then 
                OrbitalKillAllActive = false 
                Toggles.Misc_OrbitalKillAll:SetValue(false) 
                return 
            end
            
            local originalCFrame = lp.Character.HumanoidRootPart.CFrame
            local originalCamType = camera.CameraType
            local originalCamCFrame = camera.CFrame
            
            -- Make camera scriptable initially
            camera.CameraType = Enum.CameraType.Scriptable
            
            -- We'll use this spin variable to dynamically rotate the camera over time
            local spinOffsetXY = 0
            local spinOffsetZ = 0
            
            -- Keep track of whether we are still running
            local runningConnections = {}
            local function cleanup()
                for _, conn in pairs(runningConnections) do conn:Disconnect() end
            end
            
            while OrbitalKillAllActive and not Library.Unloaded do
                for _,v in pairs(game:GetService("Players"):GetPlayers()) do
                    if not OrbitalKillAllActive or Library.Unloaded then break end
                    
                    if v ~= lp and v.Team ~= lp.Team then
                        if v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                            local targetHead = v.Character:FindFirstChild("Head") or v.Character:FindFirstChild("HeadHB")
                            if targetHead then
                                pcall(function()
                                    local delayAmt = Options.Misc_OrbitalDelay.Value
                                    
                                    -- The position where we want to teleport above/behind them
                                    local targetPos = targetHead.Position
                                    local tpCFrame = CFrame.new(targetPos) * CFrame.new(0, 15, -10)
                                    
                                    -- Set global target so Silent Aim intercepts the mouse click perfectly
                                    _G.KillAllSpecificTarget = targetHead
                                    
                                    -- Move Player
                                    lp.Character.HumanoidRootPart.CFrame = tpCFrame
                                    lp.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                                    
                                    -- Notice: We no longer move the camera here!
                                    -- Camera stays completely frozen at original position.
                                    
                                    -- Wait for server to replicate our teleport before shooting
                                    task.wait(delayAmt)
                                    if not OrbitalKillAllActive or Library.Unloaded then return end
                                    
                                    -- Aim the character's body just in case (but camera stays still)
                                    lp.Character.HumanoidRootPart.CFrame = CFrame.new(tpCFrame.Position, targetPos)
                                    
                                    -- Now shoot point blank via native click simulation
                                    if mouse1press and mouse1release then
                                        mouse1press()
                                        task.wait(0.05)
                                        mouse1release()
                                    else
                                        game:GetService("VirtualUser"):ClickButton1(Vector2.new(0, 0))
                                    end
                                    
                                    -- Small cooldown between kills
                                    task.wait(0.1)
                                end)
                            end
                        end
                    end
                end
                task.wait(0.1) -- Pause between sweeping all players again
            end
            
            -- Finish
            if Toggles.Misc_OrbitalReturn.Value and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = originalCFrame
                lp.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            end
            
            camera.CameraType = originalCamType
            camera.CFrame = originalCamCFrame
            _G.KillAllSpecificTarget = nil
            Toggles.Misc_OrbitalKillAll:SetValue(false)
            OrbitalKillAllActive = false
        end)
    else
        _G.KillAllSpecificTarget = nil
    end
end)

local ServerGroup = Tabs.misc:AddLeftGroupbox('server')
ServerGroup:AddButton('rejoin server', function()
    local TeleportService = game:GetService('TeleportService')
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
ServerGroup:AddButton('join new server', function()
    local TeleportService = game:GetService('TeleportService')
    local Http = game:GetService('HttpService')
    local servers = Http:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. game.PlaceId .. '/servers/Public?sortOrder=Asc&limit=100'))
    for _, server in pairs(servers.data or {}) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
            break
        end
    end
end)

-- Old Buy/Plant anywhere logic removed entirely

local AmbienceGroup = Tabs.visuals:AddRightGroupbox('ambience')
AmbienceGroup:AddToggle('Ambience_Enabled', { Text = 'enabled', Default = false }):AddKeyPicker('Ambience_EnabledBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'ambience' })
AmbienceGroup:AddToggle('Ambience_GlobalShadows', { Text = 'global shadows', Default = true })
AmbienceGroup:AddSlider('Ambience_ClockTime', { Text = 'time of day', Default = 14, Min = 0, Max = 24, Rounding = 1, Compact = true })
AmbienceGroup:AddSlider('Ambience_Brightness', { Text = 'brightness', Default = 2, Min = 0, Max = 10, Rounding = 1, Compact = true })
AmbienceGroup:AddLabel('ambient color'):AddColorPicker('Ambience_AmbientColor', { Default = Color3.fromRGB(127, 127, 127), Title = 'ambient color' })
AmbienceGroup:AddLabel('outdoor ambient color'):AddColorPicker('Ambience_OutdoorAmbientColor', { Default = Color3.fromRGB(127, 127, 127), Title = 'outdoor ambient color' })
AmbienceGroup:AddLabel('color shift top'):AddColorPicker('Ambience_ColorShift_Top', { Default = Color3.fromRGB(0, 0, 0), Title = 'color shift top' })
AmbienceGroup:AddLabel('color shift bottom'):AddColorPicker('Ambience_ColorShift_Bottom', { Default = Color3.fromRGB(0, 0, 0), Title = 'color shift bottom' })
AmbienceGroup:AddSlider('Ambience_FogStart', { Text = 'fog start', Default = 0, Min = 0, Max = 10000, Rounding = 0, Compact = true })
AmbienceGroup:AddSlider('Ambience_FogEnd', { Text = 'fog end', Default = 10000, Min = 0, Max = 10000, Rounding = 0, Compact = true })
AmbienceGroup:AddLabel('fog color'):AddColorPicker('Ambience_FogColor', { Default = Color3.fromRGB(192, 192, 192), Title = 'fog color' })

local AnimationGroup = Tabs.misc:AddRightGroupbox('animation player')
AnimationGroup:AddToggle('Anim_Enabled', { Text = 'enabled', Default = false }):AddKeyPicker('Anim_EnabledBind', { Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'animation play binds' })
AnimationGroup:AddDropdown('Anim_Selection', { Text = 'animation', Default = 1, Values = {'floss', 'default', 'lil nas x', 'dolphin', 'monkey'} })

local NameProtectGroup = Tabs.misc:AddRightGroupbox('name protect')
NameProtectGroup:AddToggle('Misc_NameProtectEnabled', { Text = 'enabled', Default = false })
NameProtectGroup:AddInput('Misc_NameProtectName', { Default = 'FakeName', Numeric = false, Finished = false, Text = 'custom name', Placeholder = 'Enter fake name' })

local RemoveEffectsGroup = Tabs.misc:AddRightGroupbox('remove effects')
RemoveEffectsGroup:AddToggle('Misc_RemoveFlash', { Text = 'remove flash', Default = false })
RemoveEffectsGroup:AddToggle('Misc_RemoveSmoke', { Text = 'remove smoke', Default = false })
RemoveEffectsGroup:AddToggle('Misc_RemoveBulletHoles', { Text = 'remove bullet holes', Default = false })
RemoveEffectsGroup:AddToggle('Misc_RemoveBlood', { Text = 'remove blood', Default = false })

local SpectatorsGroup = Tabs.misc:AddRightGroupbox('spectators')
SpectatorsGroup:AddToggle('Misc_ShowSpectators', { Text = 'show spectators', Default = false }):OnChanged(function()
    if Toggles.Misc_ShowSpectators.Value then
        if Library.SpectatorFrame then 
            Library.SpectatorFrame.Visible = true 
        end
        if not FW_Spectator_Thread then
            FW_Spectator_Thread = task.spawn(function()
                while task.wait(0.5) do
                    if Library.Unloaded or not Toggles.Misc_ShowSpectators.Value then break end
                    local specs = GetSpectators()
                    if Library.UpdateSpectators then
                        Library:UpdateSpectators(specs)
                    end
                end
                FW_Spectator_Thread = nil
            end)
        end
    else
        if Library.SpectatorFrame then 
            Library.SpectatorFrame.Visible = false 
        end
    end
end)

local CrosshairGroup = Tabs.misc:AddRightGroupbox('crosshair')
CrosshairGroup:AddToggle('CH_Enabled', { Text = 'enabled', Default = false })
    :AddColorPicker('CH_Color1', { Default = Color3.new(1, 1, 1), Title = 'gradient color 1' })
    :AddColorPicker('CH_Color2', { Default = Color3.new(1, 1, 1), Title = 'gradient color 2' })
    :AddColorPicker('CH_Color3', { Default = Color3.new(1, 1, 1), Title = 'gradient color 3' })
CrosshairGroup:AddToggle('CH_OnTargets', { Text = 'on targets', Default = false, Tooltip = 'crosshair follows aimbot target position' })
CrosshairGroup:AddSlider('CH_AnimSpeed', { Text = 'animation speed', Default = 1, Min = 0, Max = 5, Rounding = 1, Compact = true })

local DebugGroup = Tabs.misc:AddRightGroupbox('debug')
DebugGroup:AddToggle('Debug_RageBot', { Text = 'debug ragebot', Default = false })
DebugGroup:AddToggle('Debug_ManualAA', { Text = 'current manual', Default = false }):AddColorPicker('Debug_ManualActiveColor', { Default = Color3.fromRGB(170, 0, 255), Title = 'active color' })

local TeleportsGroup = Tabs.misc:AddRightGroupbox('teleports')
TeleportsGroup:AddDropdown('Misc_WaypointTP', { Text = 'waypoint tp', Default = 1, Values = {'-', 'Spawn T', 'Spawn CT', 'Bombsite A', 'Bombsite B'} }):OnChanged(function()
    local val = Options.Misc_WaypointTP.Value
    local lp = game:GetService("Players").LocalPlayer
    if val == "-" or not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    
    pcall(function()
        if val == "Spawn T" then
            lp.Character.HumanoidRootPart.CFrame = CFrame.new(workspace.Map.SpawnPoints["BuyArea"].Position + Vector3.new(0, 3, 0))
        elseif val == "Spawn CT" then
            lp.Character.HumanoidRootPart.CFrame = CFrame.new(workspace.Map.SpawnPoints["BuyArea2"].Position + Vector3.new(0, 3, 0))
        elseif val == "Bombsite A" then
            lp.Character.HumanoidRootPart.CFrame = CFrame.new(workspace.Map.SpawnPoints["C4Plant2"].Position + Vector3.new(0, 3, 0))
        elseif val == "Bombsite B" then
            lp.Character.HumanoidRootPart.CFrame = CFrame.new(workspace.Map.SpawnPoints["C4Plant"].Position + Vector3.new(0, 3, 0))
        end
        Options.Misc_WaypointTP:SetValue("-")
    end)
end)

local FW_Effects_Connection = game:GetService("RunService").RenderStepped:Connect(function()
    if Library.Unloaded then return end
    local lp = game:GetService("Players").LocalPlayer
    
    if Toggles.Misc_RemoveFlash and Toggles.Misc_RemoveFlash.Value then
        local blnd = lp.PlayerGui:FindFirstChild("Blnd")
        if blnd then blnd.Enabled = false end
    else
        local blnd = lp.PlayerGui:FindFirstChild("Blnd")
        if blnd then blnd.Enabled = true end
    end
    
    if Toggles.Misc_RemoveSmoke and Toggles.Misc_RemoveSmoke.Value then
        pcall(function()
            for _, v in pairs(workspace.Ray_Ignore.Smokes:GetChildren()) do
                if v.Name == "Smoke" then v:Destroy() end
            end
        end)
    end
    
    if Toggles.Misc_RemoveBulletHoles and Toggles.Misc_RemoveBulletHoles.Value then
        pcall(function()
            for _, v in pairs(workspace.Debris:GetChildren()) do
                if v.Name == "Bullet" then v:Destroy() end
            end
        end)
    end
    
    if Toggles.Misc_RemoveBlood and Toggles.Misc_RemoveBlood.Value then
        pcall(function()
            for _, v in pairs(workspace.Debris:GetChildren()) do
                if v.Name == "SurfaceGui" then v:Destroy() end
            end
        end)
    end
end)

Library:SetWatermarkVisibility(true)

Library:SetChangelog(
    -- changes (user-facing)
    "• added welcome screen with changelog\n" ..
    "• added unavailable toggle type\n" ..
    "• added player avatar + name in header\n" ..
    "• instant defuse & plant anywhere improved\n" ..
    "• added auto shoot with visibility checks\n" ..
    "• added peek assist release on shot\n" ..
    "• full ui overhaul (new font, rounded corners, strokes)\n" ..
    "• fixed notification animations\n" ..
    "• esp text matches menu style",
    -- internal changes
    "• migrated esp text from Drawing to TextLabel\n" ..
    "• removed registry override on ToggleInner (color fix)\n" ..
    "• slider fill changed from pixel to scale-based\n" ..
    "• added UIStroke to all esp labels for anti-aliasing"
)

local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1;

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter;
        FrameTimer = tick();
        FrameCounter = 0;
    end;

    local ping = 0
    pcall(function()
        ping = math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    end)
    if ping == 0 then
        pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
    end

    Library:SetWatermark(('solance | %s fps | %s ms'):format(
        math.floor(FPS),
        ping
    ));
end);

Library.KeybindFrame.Visible = true;

-- Self Visuals Logic
local SelfVisuals_OriginalMats = {}
local SelfVisuals_Connection = game:GetService("RunService").RenderStepped:Connect(function()
    if Library.Unloaded then return end
    local lp = game:GetService("Players").LocalPlayer
    local char = lp and lp.Character
    if not char then return end
    
    local enabled = Toggles.Self_Chams and Toggles.Self_Chams.Value
    
    if enabled then
        local selfColor = Options.Self_ChamsColor.Value
        local matName = Options.Self_Material and Options.Self_Material.Value or "neon"
        local material = matName == "forcefield" and Enum.Material.ForceField or matName == "flat" and Enum.Material.SmoothPlastic or Enum.Material.Neon
        
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                if not SelfVisuals_OriginalMats[part] then
                    SelfVisuals_OriginalMats[part] = { Material = part.Material, Color = part.Color, Transparency = part.Transparency }
                end
                pcall(function()
                    part.Material = material
                    part.Color = selfColor
                end)
            end
        end
    else
        -- Restore originals
        for part, data in pairs(SelfVisuals_OriginalMats) do
            pcall(function()
                if part and part.Parent then
                    part.Material = data.Material
                    part.Color = data.Color
                end
            end)
        end
        SelfVisuals_OriginalMats = {}
    end
end)

-- Angel Wings Logic
local WingsParticle = nil

local function CreateAngelWings(character)
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not torso or not humanoid then return end

    -- Position calculation depends on if it's R6 (Torso) or R15 (UpperTorso)
    local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
    local zOffset = isR15 and 0.5 or 0.5
    
    local attachment = Instance.new("Attachment")
    attachment.Name = "AngelWingsAttachment"
    attachment.Position = Vector3.new(0, 0, zOffset)
    attachment.Parent = torso

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "AngelWingsEmitter"
    emitter.Texture = "rbxassetid://120599009244025" 
    emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 8)})
    emitter.LightEmission = 0.5
    emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
    emitter.ZOffset = 1
    emitter.Rate = 5
    emitter.Speed = NumberRange.new(0)
    emitter.LockedToPart = true
    emitter.Parent = attachment

    WingsParticle = attachment
end

local function RemoveWings()
    if WingsParticle then
        WingsParticle:Destroy()
        WingsParticle = nil
    end
end

local lp = game:GetService("Players").LocalPlayer

Toggles.Self_AngelWings:OnChanged(function()
    if Toggles.Self_AngelWings.Value then
        if lp.Character then
            CreateAngelWings(lp.Character)
        end
    else
        RemoveWings()
    end
end)

lp.CharacterAdded:Connect(function(char)
    RemoveWings()
    if Toggles.Self_AngelWings and Toggles.Self_AngelWings.Value then
        task.spawn(function()
            task.wait(1)
            CreateAngelWings(char)
        end)
    end
end)

-- Silent Aim Debug State
local SilentDebugState = "idle"
local SilentDebugTarget = ""
local SilentDebugBone = ""
local SilentDebugLastUpdate = 0

local Mouse = game:GetService("Players").LocalPlayer:GetMouse()

local function Visuals_GetSilentAimTarget()
    local lp = game:GetService("Players").LocalPlayer
    local useFov = Toggles.Silent_UseFOV and Toggles.Silent_UseFOV.Value
    local MaxDist = useFov and (Options.Silent_FOV and Options.Silent_FOV.Value or 100) or math.huge
    local closestPlayer = nil
    local bestPart = nil
    local bestAimWorldPos = nil
    
    local hitboxes = {}
    if Options.WC_Hitboxes then
        for hb, selected in pairs(Options.WC_Hitboxes.Value) do
            if selected then table.insert(hitboxes, hb) end
        end
    end
    if #hitboxes == 0 then table.insert(hitboxes, "Head") end
    
    local mouseCenter = Vector2.new(Mouse.X, Mouse.Y + 36)
    
    for _, V in pairs(game:GetService("Players"):GetPlayers()) do
        if V == lp then continue end
        if V.Team == lp.Team then continue end
        if not V.Character or not V.Character:FindFirstChild("Humanoid") or V.Character.Humanoid.Health <= 0 then continue end
        
        for _, boneName in ipairs(hitboxes) do
            local bone = V.Character:FindFirstChild(boneName)
            if bone then
                local worldPos = bone.Position
                local Pos, Vis = workspace.CurrentCamera:WorldToScreenPoint(worldPos)
                if Vis then
                    local Dist = (Vector2.new(Pos.X, Pos.Y) - mouseCenter).Magnitude
                    if Dist < MaxDist then
                        MaxDist = Dist
                        closestPlayer = V
                        bestPart = bone
                        bestAimWorldPos = worldPos
                    end
                end
            end
        end
    end
    return closestPlayer, bestPart, bestAimWorldPos
end

-- Crosshair Drawing Objects
local CH_Arms = {}
local CH_ArmsOutline = {}
for i = 1, 4 do
    local outline = Drawing.new("Line")
    outline.Thickness = 4
    outline.Color = Color3.new(0, 0, 0)
    outline.Visible = false
    CH_ArmsOutline[i] = outline
    
    local arm = Drawing.new("Line")
    arm.Thickness = 2
    arm.Visible = false
    CH_Arms[i] = arm
end

-- Debug Drawing Objects
local DebugText = Drawing.new("Text")
DebugText.Size = 15
DebugText.Font = 3 -- Code font
DebugText.Center = true
DebugText.Outline = true
DebugText.Visible = false
DebugText.Color = Color3.new(1, 1, 1)

local ManualLeftText = Drawing.new("Text")
ManualLeftText.Size = 16
ManualLeftText.Font = 3
ManualLeftText.Center = false
ManualLeftText.Outline = true
ManualLeftText.Visible = false

local ManualRightText = Drawing.new("Text")
ManualRightText.Size = 16
ManualRightText.Font = 3
ManualRightText.Center = false
ManualRightText.Outline = true
ManualRightText.Visible = false

local function CH_LerpColor(c1, c2, t)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

game:GetService("RunService").RenderStepped:Connect(function()
    if Library.Unloaded then return end
    local cam = workspace.CurrentCamera
    local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    
    -- ═══ CROSSHAIR RENDER ═══
    local chEnabled = Toggles.CH_Enabled and Toggles.CH_Enabled.Value
    
    if chEnabled then
        local c1 = Options.CH_Color1.Value
        local c2 = Options.CH_Color2.Value
        local c3 = Options.CH_Color3.Value
        local animSpeed = Options.CH_AnimSpeed and Options.CH_AnimSpeed.Value or 1
        local angle = tick() * animSpeed
        
        -- On-targets: follow aimbot target
        local crossPos = screenCenter
        if Toggles.CH_OnTargets and Toggles.CH_OnTargets.Value then
            local targetScreenPos = nil
            
            -- Priority to Vector Aimbot
            if Toggles.Vector_Enabled and Toggles.Vector_Enabled.Value and VectorAimbot_CurrentTarget and VectorAimbot_CurrentBone then
                local bonePart = VectorAimbot_CurrentTarget.Character and VectorAimbot_CurrentTarget.Character:FindFirstChild(VectorAimbot_CurrentBone)
                if bonePart then
                    local pos, vis = cam:WorldToViewportPoint(bonePart.Position)
                    if vis then targetScreenPos = Vector2.new(pos.X, pos.Y) end
                end
            -- Fallback to Silent Aim
            elseif Toggles.Silent_Enabled and Toggles.Silent_Enabled.Value then
                local _, targetBone = Visuals_GetSilentAimTarget()
                if targetBone then
                    local pos, vis = cam:WorldToViewportPoint(targetBone.Position)
                    if vis then targetScreenPos = Vector2.new(pos.X, pos.Y) end
                end
            end
            
            if targetScreenPos then
                crossPos = targetScreenPos
            end
        end
        
        -- Crosshair shape: 4 arms with gap
        local gap = 6
        local armLen = 14
        
        -- Directions for 4 arms (up, right, down, left) rotated by angle
        local dirs = {
            Vector2.new(math.cos(angle - math.pi/2), math.sin(angle - math.pi/2)),
            Vector2.new(math.cos(angle), math.sin(angle)),
            Vector2.new(math.cos(angle + math.pi/2), math.sin(angle + math.pi/2)),
            Vector2.new(math.cos(angle + math.pi), math.sin(angle + math.pi)),
        }
        
        -- Color each arm with gradient: distribute 3 colors across 4 arms
        local armColors = {
            c1,
            CH_LerpColor(c1, c2, 0.75),
            c2,
            CH_LerpColor(c2, c3, 0.75),
        }
        
        for i = 1, 4 do
            local from = crossPos + dirs[i] * gap
            local to = crossPos + dirs[i] * (gap + armLen)
            
            CH_ArmsOutline[i].From = from
            CH_ArmsOutline[i].To = to
            CH_ArmsOutline[i].Visible = true
            
            CH_Arms[i].From = from
            CH_Arms[i].To = to
            CH_Arms[i].Color = armColors[i]
            CH_Arms[i].Visible = true
        end
    else
        for i = 1, 4 do
            CH_Arms[i].Visible = false
            CH_ArmsOutline[i].Visible = false
        end
    end
    
    -- ═══ DEBUG RAGEBOT RENDER ═══
    if Toggles.Debug_RageBot and Toggles.Debug_RageBot.Value then
        local yOffset = chEnabled and 28 or 18
        local debugPos = Vector2.new(screenCenter.X, screenCenter.Y + yOffset)
        
        local debugStr = ""
        if not (Toggles.Silent_Enabled and Toggles.Silent_Enabled.Value) then
            debugStr = "[ragebot] disabled"
        elseif SilentDebugState == "locked" then
            debugStr = "[ragebot] locked on " .. SilentDebugTarget .. " > " .. SilentDebugBone
        else
            debugStr = "[ragebot] waiting for target"
            -- Update state: check if there's a target in FOV right now
            if Toggles.Silent_Enabled.Value and tick() - SilentDebugLastUpdate > 0.5 then
                SilentDebugState = "waiting"
                SilentDebugTarget = ""
                SilentDebugBone = ""
            end
        end
        DebugText.Color = Color3.new(1, 1, 1)
        
        DebugText.Text = debugStr
        DebugText.Position = debugPos
        DebugText.Visible = true
    else
        DebugText.Visible = false
    end
    
    -- ═══ CURRENT MANUAL AA RENDER ═══
    if Toggles.Debug_ManualAA and Toggles.Debug_ManualAA.Value then
        local activeColor = Options.Debug_ManualActiveColor and Options.Debug_ManualActiveColor.Value or Color3.fromRGB(170, 0, 255)
        local inactiveColor = Color3.fromRGB(180, 180, 180)
        
        -- Get keybind names
        local leftBind = "none"
        local rightBind = "none"
        pcall(function()
            if Options.AA_ManualLeftBind and Options.AA_ManualLeftBind.Value then
                local v = tostring(Options.AA_ManualLeftBind.Value)
                if v and v ~= "" and v ~= "Unknown" then leftBind = v:lower() end
            end
        end)
        pcall(function()
            if Options.AA_ManualRightBind and Options.AA_ManualRightBind.Value then
                local v = tostring(Options.AA_ManualRightBind.Value)
                if v and v ~= "" and v ~= "Unknown" then rightBind = v:lower() end
            end
        end)
        
        local leftActive = Toggles.AA_ManualLeft and Toggles.AA_ManualLeft.Value
        local rightActive = Toggles.AA_ManualRight and Toggles.AA_ManualRight.Value
        
        local midY = cam.ViewportSize.Y / 2
        
        ManualLeftText.Text = "left [" .. leftBind .. "]"
        ManualLeftText.Position = Vector2.new(12, midY - 12)
        ManualLeftText.Color = leftActive and activeColor or inactiveColor
        ManualLeftText.Visible = true
        
        ManualRightText.Text = "right [" .. rightBind .. "]"
        ManualRightText.Position = Vector2.new(12, midY + 6)
        ManualRightText.Color = rightActive and activeColor or inactiveColor
        ManualRightText.Visible = true
    else
        ManualLeftText.Visible = false
        ManualRightText.Visible = false
    end
end)

-- Keybind Filter
task.spawn(function()
    while task.wait(0.1) do
        if Library.Unloaded then break end
        pcall(function()
            for _, gui in pairs(game:GetService("CoreGui"):GetChildren()) do
                if gui:IsA("ScreenGui") then
                    for _, obj in pairs(gui:GetDescendants()) do
                        if obj:IsA("TextLabel") and (string.find(obj.Text, "%[None%]") or string.find(obj.Text, "&lt;font.*&gt;%[None%]&lt;/font&gt;")) then
                            -- Hide the whole row if it's in a list, or just the label
                            if obj.Parent and obj.Parent:IsA("Frame") and obj.Parent.Name ~= gui.Name then
                                obj.Parent.Visible = false
                            else
                                obj.Visible = false
                            end
                        end
                    end
                end
            end
        end)
    end
end)

local ESP_Instances = {}
local WeaponESP_Instances = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = game:GetService("Workspace").CurrentCamera
local CurrentCamera = Camera
local ESP_RenderConnection = nil
local WeaponESP_RenderConnection = nil
local VectorAimbot_CurrentTarget = nil

-- Name Protect Logic
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() and self == LocalPlayer and (key == "Name" or key == "DisplayName") then
        if Toggles.Misc_NameProtectEnabled and Toggles.Misc_NameProtectEnabled.Value and Options.Misc_NameProtectName then
            local fakeName = Options.Misc_NameProtectName.Value
            if fakeName and fakeName ~= "" then
                return fakeName
            end
        end
    end
    return oldIndex(self, key)
end)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if not checkcaller() and method == "FireServer" and (self.Name == "HitPart" or self.Name == "HitParl") then
        _G.LastHitPartInstance = args[1]
        
        if Toggles.Tracers_Enabled and Toggles.Tracers_Enabled.Value then
            local hitPos = args[2] 
            local originPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position
            if typeof(hitPos) == "Vector3" and originPos then
                task.spawn(function()
                    local tracerColor = Options.Tracers_Color.Value
                    local tracerDuration = Options.Tracers_Duration.Value
                    local matName = Options.Tracers_Material and Options.Tracers_Material.Value or "neon"
                    local material = matName == "forcefield" and Enum.Material.ForceField or matName == "flat" and Enum.Material.SmoothPlastic or Enum.Material.Neon
                    
                    local direction = (hitPos - originPos)
                    local distance = direction.Magnitude
                    local midPoint = originPos + direction / 2
                    
                    local part = Instance.new("Part")
                    part.Anchored = true
                    part.CanCollide = false
                    part.CastShadow = false
                    part.Material = material
                    part.Color = tracerColor
                    part.Size = Vector3.new(0.1, 0.1, distance)
                    part.CFrame = CFrame.lookAt(midPoint, hitPos)
                    part.Transparency = 0
                    part.Parent = workspace
                    
                    task.wait(tracerDuration)
                    
                    local tween = game:GetService("TweenService"):Create(part, TweenInfo.new(0.5), {Transparency = 1})
                    tween:Play()
                    tween.Completed:Connect(function()
                        part:Destroy()
                    end)
                end)
            end
        end
    end

    return oldNamecall(self, ...)
end)

task.spawn(function()
    while task.wait(1) do
        if Library.Unloaded then break end
        
        if Toggles.Misc_NameProtectEnabled and Toggles.Misc_NameProtectEnabled.Value and Options.Misc_NameProtectName then
            local fakeName = Options.Misc_NameProtectName.Value
            if fakeName == nil or fakeName == "" then continue end
            
            local realName = LocalPlayer.Name
            local realDisplayName = LocalPlayer.DisplayName
            
            -- Safe scanning of PlayerGui to avoid errors on destroyed/locked instances
            local pgui = LocalPlayer:FindFirstChild("PlayerGui")
            if pgui then
                for _, obj in ipairs(pgui:GetDescendants()) do
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                        pcall(function()
                            if string.find(obj.Text, realName) or string.find(obj.Text, realDisplayName) then
                                obj.Text = string.gsub(obj.Text, realName, fakeName)
                                obj.Text = string.gsub(obj.Text, realDisplayName, fakeName)
                            end
                        end)
                    end
                end
            end
            
            -- Also scan Workspace for BillboardGuis overhead
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    pcall(function()
                        if string.find(obj.Text, realName) or string.find(obj.Text, realDisplayName) then
                            obj.Text = string.gsub(obj.Text, realName, fakeName)
                            obj.Text = string.gsub(obj.Text, realDisplayName, fakeName)
                        end
                    end)
                end
            end
        end
    end
end)

local function CreateESP(plr)
    if ESP_Instances[plr] then return end

    local esp = {
        boxOutline = Drawing.new("Quad"),
        box = Drawing.new("Quad"),
        healthBarOutline = Drawing.new("Line"),
        healthBar = Drawing.new("Line"),
        weaponText = Drawing.new("Text"),
        nicknameText = Drawing.new("Text"),
        distanceText = Drawing.new("Text"),
        bones = {}
    }
    
    for i = 1, 14 do
        local l = Drawing.new("Line")
        l.Thickness = 1
        l.Transparency = 1
        esp.bones[i] = l
    end
    
    esp.weaponText.Size = 13
    esp.weaponText.Font = 0  --- 3 code
    esp.weaponText.Center = true
    esp.weaponText.Outline = true
    esp.weaponText.Transparency = 1
    
    esp.nicknameText.Size = 13
    esp.nicknameText.Font = 0
    esp.nicknameText.Center = true
    esp.nicknameText.Outline = true
    esp.nicknameText.Transparency = 1
    
    esp.distanceText.Size = 13
    esp.distanceText.Font = 0
    esp.distanceText.Center = true
    esp.distanceText.Outline = true
    esp.distanceText.Transparency = 1
    
    esp.box.Thickness = 1
    esp.box.Filled = false
    esp.box.Transparency = 1
    
    esp.boxOutline.Thickness = 2
    esp.boxOutline.Filled = false
    esp.boxOutline.Color = Color3.new(0, 0, 0)
    esp.boxOutline.Transparency = 1
    
    esp.healthBar.Thickness = 1.5
    esp.healthBar.Transparency = 1
    
    esp.healthBarOutline.Thickness = 3
    esp.healthBarOutline.Color = Color3.new(0, 0, 0)
    esp.healthBarOutline.Transparency = 1

    esp.snapLine = Drawing.new("Line")
    esp.snapLine.Thickness = 1
    esp.snapLine.Transparency = 1

    esp.chamsParts = {}
    esp.chamsGlowParts = {}

    ESP_Instances[plr] = esp
end

local function RemoveESP(plr)
    if ESP_Instances[plr] then
        if ESP_Instances[plr].chamsParts then
            for _, b in pairs(ESP_Instances[plr].chamsParts) do
                b:Destroy()
            end
            ESP_Instances[plr].chamsParts = nil
        end
        if ESP_Instances[plr].chamsGlowParts then
            for _, b in pairs(ESP_Instances[plr].chamsGlowParts) do
                b:Destroy()
            end
            ESP_Instances[plr].chamsGlowParts = nil
        end
        for _, drawing in pairs(ESP_Instances[plr]) do
            if type(drawing) == "table" then
                for _, d in pairs(drawing) do d:Remove() end
            else
                drawing:Remove()
            end
        end
        ESP_Instances[plr] = nil
    end
end

local function CreateWeaponESP(item)
    if WeaponESP_Instances[item] then return end
    
    local esp = {
        nameText = Drawing.new("Text"),
        distanceText = Drawing.new("Text"),
        ammoText = Drawing.new("Text"),
        boxLines = {}
    }
    
    for i = 1, 12 do
        local l = Drawing.new("Line")
        l.Thickness = 1
        l.Transparency = 1
        esp.boxLines[i] = l
    end
    
    esp.nameText.Size = 13
    esp.nameText.Font = 0
    esp.nameText.Center = true
    esp.nameText.Outline = true
    esp.nameText.Transparency = 1
    
    esp.distanceText.Size = 13
    esp.distanceText.Font = 0
    esp.distanceText.Center = true
    esp.distanceText.Outline = true
    esp.distanceText.Transparency = 1
    
    esp.ammoText.Size = 13
    esp.ammoText.Font = 0
    esp.ammoText.Center = true
    esp.ammoText.Outline = true
    esp.ammoText.Transparency = 1

    esp.snapLine = Drawing.new("Line")
    esp.snapLine.Thickness = 1
    esp.snapLine.Transparency = 1
    
    WeaponESP_Instances[item] = esp
end

local function RemoveWeaponESP(item)
    if WeaponESP_Instances[item] then
        for _, drawing in pairs(WeaponESP_Instances[item]) do
            if type(drawing) == "table" then
                for _, d in pairs(drawing) do d:Remove() end
            else
                drawing:Remove()
            end
        end
        WeaponESP_Instances[item] = nil
    end
end

local function GetTorsoWorldPosition(character)
    if not character then return nil end
    local ut = character:FindFirstChild("UpperTorso")
    if ut and ut:IsA("BasePart") then return ut.Position end
    local t = character:FindFirstChild("Torso")
    if t and t:IsA("BasePart") then return t.Position end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then return hrp.Position end
    return nil
end

local function UpdateWeaponESPLogic()
    pcall(function()
        for item, esp in pairs(WeaponESP_Instances) do
            if not item or not item.Parent then
                RemoveWeaponESP(item)
                continue
            end

            esp.snapLine.Visible = false
        
        local isVisible = false
        local primaryPart = item:IsA("BasePart") and item or item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            local pos, onScreen = Camera:WorldToViewportPoint(primaryPart.Position)

            if Toggles.WeaponESP_Snapline.Value then
                local fromPos = GetTorsoWorldPosition(LocalPlayer.Character)
                if fromPos then
                    local lp = Camera:WorldToViewportPoint(fromPos)
                    local wp = Camera:WorldToViewportPoint(primaryPart.Position)
                    if lp.Z > 0 and wp.Z > 0 then
                        local from2 = Vector2.new(lp.X, lp.Y)
                        local to2 = Vector2.new(wp.X, wp.Y)
                        esp.snapLine.Visible = true
                        esp.snapLine.From = from2
                        esp.snapLine.To = to2
                        esp.snapLine.Color = Options.WeaponESP_SnaplineColor.Value
                    end
                end
            end

            if onScreen then
                isVisible = true
                
                -- name
                if Toggles.WeaponESP_Name.Value then
                    esp.nameText.Visible = true
                    esp.nameText.Text = string.lower(item.Name)
                    esp.nameText.Color = Options.WeaponESP_NameColor.Value
                    esp.nameText.Position = Vector2.new(pos.X, pos.Y - 14)
                else
                    esp.nameText.Visible = false
                end
                
                -- distance
                if Toggles.WeaponESP_Distance.Value then
                    esp.distanceText.Visible = true
                    local dist = 0
                    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                        dist = math.floor((LocalPlayer.Character.PrimaryPart.Position - primaryPart.Position).Magnitude)
                    end
                    esp.distanceText.Text = string.format("%d studs", dist)
                    esp.distanceText.Color = Options.WeaponESP_DistanceColor.Value
                    
                    local yOffset = pos.Y + 4
                    esp.distanceText.Position = Vector2.new(pos.X, yOffset)
                else
                    esp.distanceText.Visible = false
                end
                
                -- ammo
                if Toggles.WeaponESP_Ammo.Value then
                    esp.ammoText.Visible = true
                    local ammo = item:FindFirstChild("Ammo")
                    local stored = item:FindFirstChild("StoredAmmo")
                    local a = ammo and ammo.Value or 0
                    local s = stored and stored.Value or 0
                    esp.ammoText.Text = string.format("%d / %d", a, s)
                    esp.ammoText.Color = Options.WeaponESP_AmmoColor.Value
                    
                    local ammoY = pos.Y + 4
                    if Toggles.WeaponESP_Distance.Value then ammoY = ammoY + 16 end
                    esp.ammoText.Position = Vector2.new(pos.X, ammoY)
                else
                    esp.ammoText.Visible = false
                end
                
                -- 3dbox
                if Toggles.WeaponESP_3DBox.Value then
                    local size = item:IsA("BasePart") and item.Size or (item:IsA("Model") and item:GetExtentsSize() or primaryPart.Size)
                    local cf = item:IsA("BasePart") and item.CFrame or (item:IsA("Model") and item:GetPivot() or primaryPart.CFrame)
                    local corners3D = GetBoundingBox3D(cf, size)
                    local corners2D = {}
                    local allOnScreen = true
                    for i = 1, 8 do
                        local pt, os = Camera:WorldToViewportPoint(corners3D[i].Position)
                        corners2D[i] = Vector2.new(pt.X, pt.Y)
                        if not os then allOnScreen = false end
                    end
                    
                    if allOnScreen then
                        local edges = {
                            {1,2}, {2,3}, {3,4}, {4,1},
                            {5,6}, {6,7}, {7,8}, {8,5},
                            {1,5}, {2,6}, {3,7}, {4,8}
                        }
                        for i, e in ipairs(edges) do
                            esp.boxLines[i].Visible = true
                            esp.boxLines[i].From = corners2D[e[1]]
                            esp.boxLines[i].To = corners2D[e[2]]
                            esp.boxLines[i].Color = Options.WeaponESP_3DBoxColor.Value
                        end
                    else
                        for i = 1, 12 do esp.boxLines[i].Visible = false end
                    end
                else
                    for i = 1, 12 do esp.boxLines[i].Visible = false end
                end
            end
        end
        
        if not isVisible then
            esp.nameText.Visible = false
            esp.distanceText.Visible = false
            esp.ammoText.Visible = false
            for i = 1, 12 do esp.boxLines[i].Visible = false end
        end
    end
    end)
end

local function IsVisible(char)
    local origin = Camera.CFrame.Position
    local target = char.HumanoidRootPart.Position
    local direction = (target - origin)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, char}
    local result = workspace:Raycast(origin, direction, rayParams)
    return result == nil
end

local function ESP_ApplyChamsStyle(boxAd, extraPart, charPart, color, mode)
    if mode == 'glow' then mode = 'forcefield' end
    if mode ~= 'flat' and mode ~= 'neon' and mode ~= 'forcefield' then mode = 'flat' end
    if mode == 'flat' then
        boxAd.Visible = true
        boxAd.Color3 = color
        extraPart.CFrame = CFrame.new(0, 99999, 0)
    elseif mode == 'neon' then
        boxAd.Visible = false
        extraPart.CFrame = charPart.CFrame
        extraPart.Size = charPart.Size + Vector3.new(0.05, 0.05, 0.05)
        extraPart.Material = Enum.Material.Neon
        extraPart.Color = color
        extraPart.Transparency = 0
    else
        boxAd.Visible = false
        extraPart.CFrame = charPart.CFrame
        extraPart.Size = charPart.Size + Vector3.new(0.05, 0.05, 0.05)
        extraPart.Material = Enum.Material.ForceField
        extraPart.Color = Color3.new(color.R * 5, color.G * 5, color.B * 5)
        extraPart.Transparency = 0
    end
end

local function UpdateESP()
    for plr, esp in pairs(ESP_Instances) do
        local char = plr.Character
        local isVisible = false

        esp.snapLine.Visible = false
        
        local skipPlayer = false
        if Toggles.ESP_IgnoreTeam.Value and plr.Team == LocalPlayer.Team then
            skipPlayer = true
        end
        if Toggles.ESP_IgnoreDead.Value and (not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0) then
            skipPlayer = true
        end
        
        if not skipPlayer and char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") and char.Humanoid.Health > 0 and char:FindFirstChild("Head") then
            if Toggles.ESP_VisibleOnly.Value and not IsVisible(char) then
                skipPlayer = true
            end
        end

        if Toggles.ESP_Snapline.Value and not skipPlayer and char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") and char.Humanoid.Health > 0 and char:FindFirstChild("Head") then
            local fromPos = GetTorsoWorldPosition(LocalPlayer.Character)
            local toPos = GetTorsoWorldPosition(char)
            if fromPos and toPos then
                local lp = Camera:WorldToViewportPoint(fromPos)
                local tp = Camera:WorldToViewportPoint(toPos)
                if lp.Z > 0 and tp.Z > 0 then
                    local from2 = Vector2.new(lp.X, lp.Y)
                    local to2 = Vector2.new(tp.X, tp.Y)
                    esp.snapLine.Visible = true
                    esp.snapLine.From = from2
                    esp.snapLine.To = to2
                    esp.snapLine.Color = Options.ESP_SnaplineColor.Value
                end
            end
        end
        
        if not skipPlayer and char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") and char.Humanoid.Health > 0 and char:FindFirstChild("Head") then
            local HumPos, OnScreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
            if OnScreen then
                local head = Camera:WorldToViewportPoint(char.Head.Position)
                local DistanceY = math.clamp((Vector2.new(head.X, head.Y) - Vector2.new(HumPos.X, HumPos.Y)).magnitude, 2, math.huge)
                
                isVisible = true
                
                
                if Toggles.ESP_Boxes.Value then
                    esp.box.Visible = true
                    esp.boxOutline.Visible = true
                    
                    local PointA = Vector2.new(HumPos.X + DistanceY, HumPos.Y - DistanceY*2)
                    local PointB = Vector2.new(HumPos.X - DistanceY, HumPos.Y - DistanceY*2)
                    local PointC = Vector2.new(HumPos.X - DistanceY, HumPos.Y + DistanceY*2)
                    local PointD = Vector2.new(HumPos.X + DistanceY, HumPos.Y + DistanceY*2)

                    esp.box.PointA = PointA
                    esp.box.PointB = PointB
                    esp.box.PointC = PointC
                    esp.box.PointD = PointD
                    
                    esp.boxOutline.PointA = PointA
                    esp.boxOutline.PointB = PointB
                    esp.boxOutline.PointC = PointC
                    esp.boxOutline.PointD = PointD
                    
                        esp.box.Color = Options.ESP_BoxesColor.Value
                else
                    esp.box.Visible = false
                    esp.boxOutline.Visible = false
                end
                
                if Toggles.ESP_HealthBar.Value then
                    esp.healthBar.Visible = true
                    esp.healthBarOutline.Visible = true
                    
                    local d = (Vector2.new(HumPos.X - DistanceY, HumPos.Y - DistanceY*2) - Vector2.new(HumPos.X - DistanceY, HumPos.Y + DistanceY*2)).magnitude 
                    local healthoffset = (char.Humanoid.Health / char.Humanoid.MaxHealth) * d
                    
                    esp.healthBarOutline.From = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY*2)
                    esp.healthBarOutline.To = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y - DistanceY*2)
                    
                    esp.healthBar.From = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY*2)
                    esp.healthBar.To = Vector2.new(HumPos.X - DistanceY - 4, HumPos.Y + DistanceY*2 - healthoffset)
                    
                    local hpFrac = char.Humanoid.Health / char.Humanoid.MaxHealth
                    esp.healthBar.Color = Options.ESP_HealthGradientLow.Value:lerp(Options.ESP_HealthGradientHigh.Value, hpFrac)
                else
                    esp.healthBar.Visible = false
                    esp.healthBarOutline.Visible = false
                end
                
                if Toggles.ESP_Nickname.Value then
                    esp.nicknameText.Visible = true
                    esp.nicknameText.Text = string.lower(plr.Name)
                    esp.nicknameText.Color = Options.ESP_NicknameColor.Value
                    esp.nicknameText.Position = Vector2.new(HumPos.X, HumPos.Y - DistanceY*2 - 16)
                else
                    esp.nicknameText.Visible = false
                end
                
                if Toggles.ESP_Weapon.Value then
                    esp.weaponText.Visible = true
                    
                    local equippedTool = char:FindFirstChildOfClass("Tool")
                    local weaponName = "unknown"
                    
                    if equippedTool then
                        weaponName = string.lower(equippedTool.Name)
                    end
                    
                    esp.weaponText.Text = weaponName
                    esp.weaponText.Color = Options.ESP_WeaponColor.Value
                    esp.weaponText.Position = Vector2.new(HumPos.X, HumPos.Y + DistanceY*2 + 4)
                else
                    esp.weaponText.Visible = false
                end
                
                if Toggles.ESP_Distance.Value then
                    esp.distanceText.Visible = true
                    local dist = 0
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude)
                    end
                    esp.distanceText.Text = string.format("%d studs", dist)
                    esp.distanceText.Color = Options.ESP_DistanceColor.Value
                    
                    local distY = HumPos.Y + DistanceY*2 + 4
                    if Toggles.ESP_Weapon.Value then
                        distY = distY + 16
                    end
                    esp.distanceText.Position = Vector2.new(HumPos.X, distY)
                else
                    esp.distanceText.Visible = false
                end
                
                if Toggles.ESP_Skeleton.Value then
                    local R15 = (char.Humanoid.RigType == Enum.HumanoidRigType.R15)
                    local bonesVisible = 0
                    
                    if R15 then
                        if char:FindFirstChild("UpperTorso") and char:FindFirstChild("LowerTorso") and char:FindFirstChild("LeftUpperArm") and char:FindFirstChild("RightUpperArm") and char:FindFirstChild("LeftUpperLeg") and char:FindFirstChild("RightUpperLeg") then
                            bonesVisible = 14
                            local UT, LTorso = Camera:WorldToViewportPoint(char.UpperTorso.Position), Camera:WorldToViewportPoint(char.LowerTorso.Position)
                            local LUA, LLA, LH = Camera:WorldToViewportPoint(char.LeftUpperArm.Position), Camera:WorldToViewportPoint(char.LeftLowerArm.Position), Camera:WorldToViewportPoint(char.LeftHand.Position)
                            local RUA, RLA, RH = Camera:WorldToViewportPoint(char.RightUpperArm.Position), Camera:WorldToViewportPoint(char.RightLowerArm.Position), Camera:WorldToViewportPoint(char.RightHand.Position)
                            local LUL, LLL, LF = Camera:WorldToViewportPoint(char.LeftUpperLeg.Position), Camera:WorldToViewportPoint(char.LeftLowerLeg.Position), Camera:WorldToViewportPoint(char.LeftFoot.Position)
                            local RUL, RLL, RF = Camera:WorldToViewportPoint(char.RightUpperLeg.Position), Camera:WorldToViewportPoint(char.RightLowerLeg.Position), Camera:WorldToViewportPoint(char.RightFoot.Position)
                            
                            local function c(idx, p1, p2) esp.bones[idx].From = Vector2.new(p1.X, p1.Y) esp.bones[idx].To = Vector2.new(p2.X, p2.Y) end
                            c(1, head, UT) c(2, UT, LTorso)
                            c(3, UT, LUA) c(4, LUA, LLA) c(5, LLA, LH)
                            c(6, UT, RUA) c(7, RUA, RLA) c(8, RLA, RH)
                            c(9, LTorso, LUL) c(10, LUL, LLL) c(11, LLL, LF)
                            c(12, LTorso, RUL) c(13, RUL, RLL) c(14, RLL, RF)
                        end
                    else
                        if char:FindFirstChild("Torso") and char:FindFirstChild("Left Arm") and char:FindFirstChild("Right Arm") and char:FindFirstChild("Left Leg") and char:FindFirstChild("Right Leg") then
                            bonesVisible = 10
                            
                            local T_Height = char.Torso.Size.Y/2
                            local UT = Camera:WorldToViewportPoint((char.Torso.CFrame * CFrame.new(0, T_Height, 0)).p)
                            local LT = Camera:WorldToViewportPoint((char.Torso.CFrame * CFrame.new(0, -T_Height, 0)).p)

                            local LA_Height = char["Left Arm"].Size.Y/2
                            local LUA = Camera:WorldToViewportPoint((char["Left Arm"].CFrame * CFrame.new(0, LA_Height, 0)).p)
                            local LLA = Camera:WorldToViewportPoint((char["Left Arm"].CFrame * CFrame.new(0, -LA_Height, 0)).p)

                            local RA_Height = char["Right Arm"].Size.Y/2
                            local RUA = Camera:WorldToViewportPoint((char["Right Arm"].CFrame * CFrame.new(0, RA_Height, 0)).p)
                            local RLA = Camera:WorldToViewportPoint((char["Right Arm"].CFrame * CFrame.new(0, -RA_Height, 0)).p)

                            local LL_Height = char["Left Leg"].Size.Y/2
                            local LUL = Camera:WorldToViewportPoint((char["Left Leg"].CFrame * CFrame.new(0, LL_Height, 0)).p)
                            local LLL = Camera:WorldToViewportPoint((char["Left Leg"].CFrame * CFrame.new(0, -LL_Height, 0)).p)

                            local RL_Height = char["Right Leg"].Size.Y/2
                            local RUL = Camera:WorldToViewportPoint((char["Right Leg"].CFrame * CFrame.new(0, RL_Height, 0)).p)
                            local RLL = Camera:WorldToViewportPoint((char["Right Leg"].CFrame * CFrame.new(0, -RL_Height, 0)).p)
                            
                            local function c(idx, p1, p2) esp.bones[idx].From = Vector2.new(p1.X, p1.Y) esp.bones[idx].To = Vector2.new(p2.X, p2.Y) end
                            c(1, head, UT) c(2, UT, LT)
                            c(3, UT, LUA) c(4, LUA, LLA)
                            c(5, UT, RUA) c(6, RUA, RLA)
                            c(7, LT, LUL) c(8, LUL, LLL)
                            c(9, LT, RUL) c(10, RUL, RLL)
                        end
                    end
                    
                    for i = 1, 14 do
                        if i <= bonesVisible then
                            esp.bones[i].Visible = true
                            if isTarget and not Toggles.ESP_Boxes.Value then
                                esp.bones[i].Color = Options.ESP_TargetColor.Value
                            else
                                esp.bones[i].Color = Options.ESP_SkeletonColor.Value
                            end
                        else
                            esp.bones[i].Visible = false
                        end
                    end
                else
                    for i = 1, 14 do esp.bones[i].Visible = false end
                end
                
                if Toggles.ESP_Chams.Value then
                    local chamsColor = Options.ESP_ChamsColor.Value
                    local chamsMatMode = IsVisible(char)
                        and (Options.Chams_MaterialVisible and Options.Chams_MaterialVisible.Value or 'flat')
                        or (Options.Chams_MaterialInvisible and Options.Chams_MaterialInvisible.Value or 'neon')
                    
                    for _, part in pairs(char:GetChildren()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            if not esp.chamsParts[part] then
                                local b = Instance.new("BoxHandleAdornment")
                                b.Size = part.Size + Vector3.new(0.01, 0.01, 0.01)
                                b.AlwaysOnTop = true
                                b.ZIndex = 5
                                b.Adornee = part
                                b.Parent = Camera
                                esp.chamsParts[part] = b
                            end
                            esp.chamsParts[part].Size = part.Size + Vector3.new(0.01, 0.01, 0.01)

                            if not esp.chamsGlowParts[part] then
                                local gp = Instance.new("Part")
                                gp.Name = "ChamsExtraPart"
                                gp.CanCollide = false
                                gp.Anchored = true
                                gp.CastShadow = false
                                gp.CanQuery = false
                                gp.CanTouch = false
                                gp.Material = Enum.Material.Neon
                                gp.Size = part.Size + Vector3.new(0.05, 0.05, 0.05)
                                gp.Parent = Camera
                                esp.chamsGlowParts[part] = gp
                            end
                            ESP_ApplyChamsStyle(esp.chamsParts[part], esp.chamsGlowParts[part], part, chamsColor, chamsMatMode)
                        end
                    end
                    for part, b in pairs(esp.chamsParts) do
                        if not part or not part.Parent or part.Parent ~= char then
                            b:Destroy()
                            esp.chamsParts[part] = nil
                        end
                    end
                    for part, gp in pairs(esp.chamsGlowParts) do
                        if not part or not part.Parent or part.Parent ~= char then
                            gp:Destroy()
                            esp.chamsGlowParts[part] = nil
                        end
                    end
                else
                    for part, box in pairs(esp.chamsParts) do
                        box.Visible = false
                    end
                    for part, gp in pairs(esp.chamsGlowParts) do
                        gp.CFrame = CFrame.new(0, 99999, 0)
                    end
                end
            end
        end
        
        if not isVisible then
            esp.box.Visible = false
            esp.boxOutline.Visible = false
            esp.healthBar.Visible = false
            esp.healthBarOutline.Visible = false
            esp.weaponText.Visible = false
            esp.nicknameText.Visible = false
            esp.distanceText.Visible = false
            for i = 1, 14 do esp.bones[i].Visible = false end
            for part, box in pairs(esp.chamsParts) do
                box.Visible = false
            end
            for part, gp in pairs(esp.chamsGlowParts) do
                gp.CFrame = CFrame.new(0, 99999, 0)
            end
        end
    end
end

local BacktrackRecords = {}
local BacktrackGhosts = {}
local Backtrack_RenderConnection = nil

local function Backtrack_ServiceNeeded()
    return Toggles.Vis_Backtrack.Value
end

local function Backtrack_ClearAllGhosts()
    for plr, ghosts in pairs(BacktrackGhosts) do
        for _, g in pairs(ghosts) do g:Destroy() end
        BacktrackGhosts[plr] = nil
    end
end

local function Backtrack_Step()
    if not Backtrack_ServiceNeeded() then return end

    local currentTime = tick()
    local limit = currentTime - (Options.Vis_BacktrackTime.Value / 1000)

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local skip = false
            if Toggles.ESP_IgnoreTeam.Value and plr.Team == LocalPlayer.Team then skip = true end

            if not skip then
                local history = BacktrackRecords[plr] or {}
                local record = { tick = currentTime, parts = {} }
                for _, obj in pairs(plr.Character:GetChildren()) do
                    if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
                        table.insert(record.parts, { size = obj.Size, cframe = obj.CFrame, name = obj.Name })
                    end
                end
                table.insert(history, record)

                while #history > 0 and history[1].tick < limit do
                    table.remove(history, 1)
                end
                BacktrackRecords[plr] = history

                if Toggles.Vis_Backtrack.Value and #history > 0 then
                    local oldestRecord = history[1]
                    local ghosts = BacktrackGhosts[plr] or {}
                    local updatedNames = {}

                    for _, pData in pairs(oldestRecord.parts) do
                        updatedNames[pData.name] = true
                        local ghostPart = ghosts[pData.name]
                        if not ghostPart then
                            ghostPart = Instance.new("Part")
                            ghostPart.Anchored = true
                            ghostPart.CanCollide = false
                            ghostPart.CastShadow = false
                            ghostPart.CanQuery = false
                            ghostPart.CanTouch = false
                            ghostPart.Size = pData.size + Vector3.new(0.01, 0.01, 0.01)
                            ghostPart.Parent = workspace.Terrain
                            ghosts[pData.name] = ghostPart
                        end

                        ghostPart.CFrame = pData.cframe

                        local matStr = Options.Vis_BacktrackMaterial.Value:lower()
                        if matStr == "neon" then ghostPart.Material = Enum.Material.Neon elseif matStr == "forcefield" then ghostPart.Material = Enum.Material.ForceField else ghostPart.Material = Enum.Material.SmoothPlastic end
                        ghostPart.Color = Options.Vis_BacktrackColor.Value
                        if matStr == "forcefield" then ghostPart.Transparency = 0 else ghostPart.Transparency = 0.5 end
                    end

                    for name, gPart in pairs(ghosts) do
                        if not updatedNames[name] then
                            gPart:Destroy()
                            ghosts[name] = nil
                        end
                    end
                    BacktrackGhosts[plr] = ghosts
                elseif not Toggles.Vis_Backtrack.Value and BacktrackGhosts[plr] then
                    for _, p in pairs(BacktrackGhosts[plr]) do p:Destroy() end
                    BacktrackGhosts[plr] = nil
                end
            else
                if BacktrackGhosts[plr] then
                    for _, p in pairs(BacktrackGhosts[plr]) do p:Destroy() end
                    BacktrackGhosts[plr] = nil
                end
            end
        else
            BacktrackRecords[plr] = nil
            if BacktrackGhosts[plr] then
                for _, p in pairs(BacktrackGhosts[plr]) do p:Destroy() end
                BacktrackGhosts[plr] = nil
            end
        end
    end

    for plr, ghosts in pairs(BacktrackGhosts) do
        if not Players:FindFirstChild(plr.Name) then
            for _, g in pairs(ghosts) do g:Destroy() end
            BacktrackGhosts[plr] = nil
            BacktrackRecords[plr] = nil
        end
    end
end

local function Backtrack_SyncService()
    if Backtrack_ServiceNeeded() then
        if not Backtrack_RenderConnection then
            Backtrack_RenderConnection = RunService.RenderStepped:Connect(Backtrack_Step)
        end
    else
        if Backtrack_RenderConnection then
            Backtrack_RenderConnection:Disconnect()
            Backtrack_RenderConnection = nil
        end
        Backtrack_ClearAllGhosts()
        BacktrackRecords = {}
    end
end

Toggles.Vis_Backtrack:OnChanged(Backtrack_SyncService)

Toggles.ESP_Enabled:OnChanged(function()
    if Toggles.ESP_Enabled.Value then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then CreateESP(plr) end
        end
        if not ESP_RenderConnection then
            ESP_RenderConnection = RunService.RenderStepped:Connect(UpdateESP)
        end
    else
        for plr, _ in pairs(ESP_Instances) do RemoveESP(plr) end
        if ESP_RenderConnection then
            ESP_RenderConnection:Disconnect()
            ESP_RenderConnection = nil
        end
    end
end)

Toggles.WeaponESP_Enabled:OnChanged(function()
    if Toggles.WeaponESP_Enabled.Value then
        local debris = game:GetService("Workspace"):FindFirstChild("Debris")
        if not debris then return end
        for _, item in pairs(debris:GetChildren()) do
            if (item:IsA("Model") or item:IsA("BasePart")) and item:FindFirstChild("Ammo") then
                CreateWeaponESP(item)
            end
        end
        if not WeaponESP_RenderConnection then
            WeaponESP_RenderConnection = RunService.RenderStepped:Connect(UpdateWeaponESPLogic)
        end
    else
        for item, _ in pairs(WeaponESP_Instances) do RemoveWeaponESP(item) end
        if WeaponESP_RenderConnection then
            WeaponESP_RenderConnection:Disconnect()
            WeaponESP_RenderConnection = nil
        end
    end
end)

Players.PlayerAdded:Connect(function(plr)
    if Toggles.ESP_Enabled.Value then CreateESP(plr) end
end)

Players.PlayerRemoving:Connect(function(plr)
    RemoveESP(plr)
end)

local debris = game:GetService("Workspace"):FindFirstChild("Debris")
if debris then
    debris.ChildAdded:Connect(function(child)
        if Toggles.WeaponESP_Enabled.Value then
            task.delay(0.1, function()
                if (child:IsA("Model") or child:IsA("BasePart")) and (child:FindFirstChild("Ammo") or child:FindFirstChild("StoredAmmo")) then
                    CreateWeaponESP(child)
                end
            end)
        end
    end)

    debris.ChildRemoved:Connect(function(child)
        RemoveWeaponESP(child)
    end)
end

-- Bomb ESP
local BombESP_Data = {
    tracer = Drawing.new("Line"),
    tracerOutline = Drawing.new("Line"),
    nameText = Drawing.new("Text"),
}

BombESP_Data.tracer.Thickness = 1
BombESP_Data.tracer.Transparency = 1

BombESP_Data.tracerOutline.Thickness = 2
BombESP_Data.tracerOutline.Color = Color3.new(0, 0, 0)
BombESP_Data.tracerOutline.Transparency = 1

BombESP_Data.nameText.Size = 13
BombESP_Data.nameText.Font = 2
BombESP_Data.nameText.Center = true
BombESP_Data.nameText.Outline = true
BombESP_Data.nameText.Transparency = 1

local BombESP_RenderConnection = nil

local function UpdateBombESP()
    local c4 = workspace:FindFirstChild("C4")
    if not c4 or not Toggles.BombESP_Enabled.Value then
        BombESP_Data.tracer.Visible = false
        BombESP_Data.tracerOutline.Visible = false
        BombESP_Data.nameText.Visible = false
        return
    end
    
    local bombPart = c4:IsA("BasePart") and c4 or c4:FindFirstChildWhichIsA("BasePart")
    if not bombPart then
        BombESP_Data.tracer.Visible = false
        BombESP_Data.tracerOutline.Visible = false
        BombESP_Data.nameText.Visible = false
        return
    end
    
    local pos, onScreen = Camera:WorldToViewportPoint(bombPart.Position)
    if onScreen then
        -- Tracer
        if Toggles.BombESP_Tracer.Value then
            BombESP_Data.tracer.Visible = true
            BombESP_Data.tracerOutline.Visible = true
            BombESP_Data.tracer.From = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y)
            BombESP_Data.tracer.To = Vector2.new(pos.X, pos.Y)
            BombESP_Data.tracer.Color = Options.BombESP_TracerColor.Value
            BombESP_Data.tracerOutline.From = BombESP_Data.tracer.From
            BombESP_Data.tracerOutline.To = BombESP_Data.tracer.To
        else
            BombESP_Data.tracer.Visible = false
            BombESP_Data.tracerOutline.Visible = false
        end
        
        -- Name Plant
        if Toggles.BombESP_Name.Value then
            BombESP_Data.nameText.Visible = true
            
            local plantName = "C4"
            local map = workspace:FindFirstChild("Map")
            if map then
                local spawnPoints = map:FindFirstChild("SpawnPoints")
                if spawnPoints then
                    local c4PlantA = spawnPoints:FindFirstChild("C4Plant2")
                    local c4PlantB = spawnPoints:FindFirstChild("C4Plant")
                    if c4PlantA and c4PlantA:FindFirstChild("Planted") and c4PlantA.Planted.Value == true then
                        plantName = "C4 [a]"
                    elseif c4PlantB and c4PlantB:FindFirstChild("Planted") and c4PlantB.Planted.Value == true then
                        plantName = "C4 [b]"
                    end
                end
            end
            
            BombESP_Data.nameText.Text = plantName
            BombESP_Data.nameText.Color = Options.BombESP_NameColor.Value
            BombESP_Data.nameText.Position = Vector2.new(pos.X, pos.Y - 16)
        else
            BombESP_Data.nameText.Visible = false
        end
    else
        BombESP_Data.tracer.Visible = false
        BombESP_Data.tracerOutline.Visible = false
        BombESP_Data.nameText.Visible = false
    end
end

Toggles.BombESP_Enabled:OnChanged(function()
    if Toggles.BombESP_Enabled.Value then
        if not BombESP_RenderConnection then
            BombESP_RenderConnection = RunService.RenderStepped:Connect(UpdateBombESP)
        end
    else
        BombESP_Data.tracer.Visible = false
        BombESP_Data.tracerOutline.Visible = false
        BombESP_Data.nameText.Visible = false
        if BombESP_RenderConnection then
            BombESP_RenderConnection:Disconnect()
            BombESP_RenderConnection = nil
        end
    end
end)

-- Bomb Plant Notification
local function SetupBombNotification()
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local spawnPoints = map:FindFirstChild("SpawnPoints")
    if not spawnPoints then return end
    
    local c4PlantA = spawnPoints:FindFirstChild("C4Plant2")
    local c4PlantB = spawnPoints:FindFirstChild("C4Plant")
    
    if c4PlantA and c4PlantA:FindFirstChild("Planted") then
        c4PlantA.Planted.Changed:Connect(function(val)
            if val == true and Toggles.BombESP_Notification.Value then
                Library:NotifyMid("bomb has been planted, plant: A", 5)
            end
        end)
    end
    
    if c4PlantB and c4PlantB:FindFirstChild("Planted") then
        c4PlantB.Planted.Changed:Connect(function(val)
            if val == true and Toggles.BombESP_Notification.Value then
                Library:NotifyMid("bomb has been planted, plant: B", 5)
            end
        end)
    end
end

SetupBombNotification()

-- Silent Aimbot
local Mouse = LocalPlayer:GetMouse()

-- Rage FOV Circle (animated gradient)
local RageFOV_Segments = {}
local RAGE_FOV_NUM_SEGMENTS = 64
for i = 1, RAGE_FOV_NUM_SEGMENTS do
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Visible = false
    RageFOV_Segments[i] = line
end
local RageFOV_FillCircle = Drawing.new("Circle")
RageFOV_FillCircle.Thickness = 1
RageFOV_FillCircle.NumSides = 64
RageFOV_FillCircle.Filled = true
RageFOV_FillCircle.Transparency = 0.15
RageFOV_FillCircle.Visible = false

local RageFOV_OutlineCircle = Drawing.new("Circle")
RageFOV_OutlineCircle.Thickness = 3
RageFOV_OutlineCircle.NumSides = 64
RageFOV_OutlineCircle.Filled = false
RageFOV_OutlineCircle.Color = Color3.new(0, 0, 0)
RageFOV_OutlineCircle.Transparency = 0.5
RageFOV_OutlineCircle.Visible = false

local function LerpColor(c1, c2, t)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

local function GetGradientColor(t, c1, c2, c3)
    -- t goes 0..1, we cycle through c1->c2->c3->c1
    if t < 0.333 then
        return LerpColor(c1, c2, t / 0.333)
    elseif t < 0.666 then
        return LerpColor(c2, c3, (t - 0.333) / 0.333)
    else
        return LerpColor(c3, c1, (t - 0.666) / 0.334)
    end
end

game:GetService("RunService").RenderStepped:Connect(function()
    if Library.Unloaded then return end
    local cam = workspace.CurrentCamera
    local show = Toggles.Silent_ShowFOV and Toggles.Silent_ShowFOV.Value and Toggles.Silent_Enabled and Toggles.Silent_Enabled.Value
    
    if show then
        local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local radius = Options.Silent_FOV.Value
        local c1 = Options.Silent_FOVColor1.Value
        local c2 = Options.Silent_FOVColor2.Value
        local c3 = Options.Silent_FOVColor3.Value
        -- Slow rotation: full circle every 8 seconds
        local rotation = (tick() % 8) / 8
        
        -- Draw black outline (like 2d box)
        RageFOV_OutlineCircle.Position = center
        RageFOV_OutlineCircle.Radius = radius
        RageFOV_OutlineCircle.Visible = true
        
        -- Draw semi-transparent fill
        RageFOV_FillCircle.Position = center
        RageFOV_FillCircle.Radius = radius
        RageFOV_FillCircle.Color = LerpColor(LerpColor(c1, c2, 0.5), c3, 0.33)
        RageFOV_FillCircle.Visible = true
        
        -- Draw gradient segments around the circle
        -- Colors placed at 3 equal points (0°, 120°, 240°) and blend between them
        for i = 1, RAGE_FOV_NUM_SEGMENTS do
            local angle1 = (math.pi * 2 / RAGE_FOV_NUM_SEGMENTS) * (i - 1)
            local angle2 = (math.pi * 2 / RAGE_FOV_NUM_SEGMENTS) * i
            
            local p1 = center + Vector2.new(math.cos(angle1) * radius, math.sin(angle1) * radius)
            local p2 = center + Vector2.new(math.cos(angle2) * radius, math.sin(angle2) * radius)
            
            -- Position on circle 0..1, offset by rotation
            local t = ((i - 1) / RAGE_FOV_NUM_SEGMENTS + rotation) % 1
            
            -- 3 colors at positions 0, 0.333, 0.666
            -- c1 at center (0.0), c2 on one side (0.333), c3 on other side (0.666)
            local segColor
            if t < 0.333 then
                segColor = LerpColor(c1, c2, t / 0.333)
            elseif t < 0.666 then
                segColor = LerpColor(c2, c3, (t - 0.333) / 0.333)
            else
                segColor = LerpColor(c3, c1, (t - 0.666) / 0.334)
            end
            
            RageFOV_Segments[i].From = p1
            RageFOV_Segments[i].To = p2
            RageFOV_Segments[i].Color = segColor
            RageFOV_Segments[i].Visible = true
        end
    else
        RageFOV_OutlineCircle.Visible = false
        RageFOV_FillCircle.Visible = false
        for i = 1, RAGE_FOV_NUM_SEGMENTS do
            RageFOV_Segments[i].Visible = false
        end
    end
end)

local function GetSilentAimTarget()
    -- OVERRIDE for Kill All Exploit:
    if _G.KillAllSpecificTarget then
        -- Find the player belonging to this target head
        local pPlayer = game:GetService("Players"):GetPlayerFromCharacter(_G.KillAllSpecificTarget.Parent)
        if pPlayer then
            return pPlayer, _G.KillAllSpecificTarget
        end
    end
    
    local useFov = Toggles.Silent_UseFOV and Toggles.Silent_UseFOV.Value
    local MaxDist = useFov and (Options.Silent_FOV and Options.Silent_FOV.Value or 100) or math.huge
    local closestPlayer = nil
    local bestPart = nil
    local bestAimWorldPos = nil
    
    local hitboxes = {}
    if Options.WC_Hitboxes then
        for hb, selected in pairs(Options.WC_Hitboxes.Value) do
            if selected then table.insert(hitboxes, hb) end
        end
    end
    if #hitboxes == 0 then table.insert(hitboxes, "Head") end
    
    local mouseCenter = Vector2.new(Mouse.X, Mouse.Y + 36)
    
    for _, V in pairs(Players.GetPlayers(Players)) do
        if V == LocalPlayer then continue end
        if V.Team == LocalPlayer.Team then continue end
        if not V.Character or not V.Character.FindFirstChild(V.Character, "Humanoid") or V.Character.Humanoid.Health <= 0 then continue end
        
        for _, boneName in ipairs(hitboxes) do
            local bone = V.Character.FindFirstChild(V.Character, boneName)
            if bone then
                local worldPos = bone.Position
                local Pos, Vis = CurrentCamera.WorldToScreenPoint(CurrentCamera, worldPos)
                if Vis then
                    local Dist = (Vector2.new(Pos.X, Pos.Y) - mouseCenter).Magnitude
                    if Dist < MaxDist then
                        MaxDist = Dist
                        closestPlayer = V
                        bestPart = bone
                        bestAimWorldPos = worldPos
                    end
                end
            end
        end
    end
    return closestPlayer, bestPart, bestAimWorldPos
end

-- Vector Aimbot
local VectorAimbot_FOVCircle = Drawing.new("Circle")
VectorAimbot_FOVCircle.Thickness = 1
VectorAimbot_FOVCircle.NumSides = 64
VectorAimbot_FOVCircle.Filled = false
VectorAimbot_FOVCircle.Transparency = 0.7
VectorAimbot_FOVCircle.Visible = false

local VectorAimbot_IsAiming = false
local VectorAimbot_CurrentBone = nil
local VectorAimbot_LastKillTick = 0
local VectorAimbot_RCS_AccumulatedPitch = 0
local VectorAimbot_RCS_AccumulatedYaw = 0

local function VectorAimbot_IsVisible(targetChar)
    local origin = Camera.CFrame.Position
    local boneName = VectorAimbot_CurrentBone or "Head"
    local part = targetChar:FindFirstChild(boneName) or targetChar:FindFirstChild("Head")
    if not part then return false end
    local target = part.Position
    local direction = (target - origin)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetChar}
    local result = workspace:Raycast(origin, direction, rayParams)
    return result == nil
end

local function VectorAimbot_GetSelectedBones()
    local bones = {}
    local selected = Options.Vector_Hitbox.Value
    for bone, isSelected in pairs(selected) do
        if isSelected then
            table.insert(bones, bone)
        end
    end
    if #bones == 0 then
        table.insert(bones, "Head")
    end
    return bones
end

local function VectorAimbot_GetTargetAndBone()
    local closestDist = Options.Vector_FOV.Value
    local closestPlayer = nil
    local bestBone = nil
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local hitboxes = VectorAimbot_GetSelectedBones()
    local method = Options.Vector_TargetMethod.Value
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if Toggles.ESP_IgnoreTeam.Value and plr.Team == LocalPlayer.Team then continue end
            
            if Toggles.Vector_Wallcheck.Value then
                if not VectorAimbot_IsVisible(plr.Character) then continue end
            end
            
            local targetBoneStr = nil
            local targetBoneDist = math.huge
            
            if method == 'nearest to crosshair' then
                for _, bName in pairs(hitboxes) do
                    local bPart = plr.Character:FindFirstChild(bName)
                    if not bPart then continue end
                    local pos, onScreen = Camera:WorldToViewportPoint(bPart.Position)
                    if onScreen then
                        local d = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                        if d < targetBoneDist then
                            targetBoneDist = d
                            targetBoneStr = bName
                        end
                    end
                end
            elseif method == 'random from hitboxes' then
                targetBoneStr = hitboxes[math.random(1, #hitboxes)]
                local bPart = plr.Character:FindFirstChild(targetBoneStr)
                if bPart then
                    local pos, onScreen = Camera:WorldToViewportPoint(bPart.Position)
                    if onScreen then
                        targetBoneDist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    end
                end
            else
                targetBoneStr = hitboxes[1] or "Head"
                local bPart = plr.Character:FindFirstChild(targetBoneStr)
                if bPart then
                    local pos, onScreen = Camera:WorldToViewportPoint(bPart.Position)
                    if onScreen then
                        targetBoneDist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    end
                end
            end
            
            if targetBoneStr and targetBoneDist < closestDist then
                closestDist = targetBoneDist
                closestPlayer = plr
                bestBone = targetBoneStr
            end
        end
    end
    
    return closestPlayer, bestBone
end

local UIS = game:GetService("UserInputService")
local VectorAimbot_Mouse1Down = false

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        VectorAimbot_Mouse1Down = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        VectorAimbot_Mouse1Down = false
        VectorAimbot_RCS_AccumulatedPitch = 0
        VectorAimbot_RCS_AccumulatedYaw = 0
    end
end)

local VectorAimbot_RenderConnection = RunService.RenderStepped:Connect(function(dt)
    -- FOV circle
    if Toggles.Vector_ShowFOV.Value and Toggles.Vector_Enabled.Value then
        VectorAimbot_FOVCircle.Visible = true
        VectorAimbot_FOVCircle.Radius = Options.Vector_FOV.Value
        VectorAimbot_FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        VectorAimbot_FOVCircle.Color = Options.Vector_FOVColor.Value
    else
        VectorAimbot_FOVCircle.Visible = false
    end
    
    if not Toggles.Vector_Enabled.Value then return end
    
    local aims = not Toggles.Vector_UseBind.Value or VectorAimbot_Mouse1Down
    if not aims then
        VectorAimbot_CurrentTarget = nil
        VectorAimbot_CurrentBone = nil
        return
    end
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return end
    
    if tick() - VectorAimbot_LastKillTick < (Options.Vector_KillDelay.Value / 1000) then
        return
    end
    
    if VectorAimbot_CurrentTarget and VectorAimbot_CurrentTarget.Character and VectorAimbot_CurrentTarget.Character:FindFirstChild("Humanoid") then
        if VectorAimbot_CurrentTarget.Character.Humanoid.Health <= 0 then
            VectorAimbot_LastKillTick = tick()
            VectorAimbot_CurrentTarget = nil
            VectorAimbot_CurrentBone = nil
        end
    end
    
    if VectorAimbot_CurrentTarget and Toggles.Vector_Wallcheck.Value then
        if not VectorAimbot_IsVisible(VectorAimbot_CurrentTarget.Character) then
            VectorAimbot_CurrentTarget = nil
            VectorAimbot_CurrentBone = nil
        end
    end
    
    if not VectorAimbot_CurrentTarget then
        VectorAimbot_CurrentTarget, VectorAimbot_CurrentBone = VectorAimbot_GetTargetAndBone()
    end
    
    if not VectorAimbot_CurrentTarget then return end
    
    local targetChar = VectorAimbot_CurrentTarget.Character
    if not targetChar then
        VectorAimbot_CurrentTarget = nil
        return
    end
    
    local bonePart = targetChar:FindFirstChild(VectorAimbot_CurrentBone) or targetChar:FindFirstChild("Head")
    if not bonePart then
        VectorAimbot_CurrentTarget = nil
        return
    end
    
    local smoothness = Options.Vector_Smoothness.Value
    local lerpAlpha = math.clamp(1 / smoothness, 0.01, 1)
    
    local targetPos = bonePart.Position
    
    if Toggles.Vector_CurveEnabled.Value then
        local dist = (Camera.CFrame.Position - targetPos).Magnitude
        local curveVal = Options.Vector_CurveIntensity.Value
        local shiftX = math.sin(tick() * curveVal) * (dist * 0.05)
        local shiftY = math.cos(tick() * curveVal * 0.7) * (dist * 0.05)
        targetPos = targetPos + (Camera.CFrame.RightVector * shiftX) + (Camera.CFrame.UpVector * shiftY)
    end
    
    local targetCF = CFrame.new(Camera.CFrame.Position, targetPos)
    
    if Toggles.Vector_RCSEnabled.Value and VectorAimbot_Mouse1Down then
        local rcsStrengthY = (Options.Vector_RCSY.Value / 100) * 45 * dt
        local rcsStrengthX = (Options.Vector_RCSX.Value / 100) * 45 * dt
        local smoothRCS = math.clamp(1 / Options.Vector_RCSSmoothness.Value, 0.01, 1)
        
        VectorAimbot_RCS_AccumulatedPitch = VectorAimbot_RCS_AccumulatedPitch + rcsStrengthY
        VectorAimbot_RCS_AccumulatedYaw = VectorAimbot_RCS_AccumulatedYaw + (math.random(-10, 10)/100 * rcsStrengthX)
        
        targetCF = targetCF * CFrame.Angles(math.rad(-VectorAimbot_RCS_AccumulatedPitch * smoothRCS), math.rad(VectorAimbot_RCS_AccumulatedYaw * smoothRCS), 0)
    end
                                                                                                                    
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, lerpAlpha)
end)

local MagicBullet_Connection = nil -- Unused now but kept for Library:OnUnload cleanup compatibility

-- Wallbang Geometry Cache
local WallbangCache = {}
local WallbangCacheReady = false

local function BuildWallbangCache()
    WallbangCache = {}
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    
    for _, child in pairs(map:GetChildren()) do
        local geo = (child.Name == "Geometry") and child or child:FindFirstChild("Geometry")
        if geo then
            for _, part in pairs(geo:GetDescendants()) do
                if part:IsA("BasePart") then
                    local name = part.Name:lower()
                    local parentName = part.Parent and part.Parent.Name:lower() or ""
                    if not name:match("nowallbang") and not parentName:match("nowallbang") then
                        table.insert(WallbangCache, part)
                    end
                end
            end
        end
    end
    
    WallbangCacheReady = #WallbangCache > 0
end

-- Build cache now + rebuild on map change
BuildWallbangCache()
task.spawn(function()
    while task.wait(3) do
        if Library.Unloaded then break end
        BuildWallbangCache()
    end
end)

-- Metatable Hooks (Weapon Mods, Silent Aimbot, Wallbang)
local mt = getrawmetatable(game)
local oldIndex = mt.__index
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__index = newcclosure(function(t, k)
    if not checkcaller() then
        if k == "Clips" then
            local tName = pcall(function() return oldIndex(t, "Name") end) and oldIndex(t, "Name") or ""
            if tName == "Map" then
                return t
            end
        end
        
        if k == "Value" and typeof(t) == "Instance" and (t:IsA("NumberValue") or t:IsA("BoolValue")) then
            if not Library.Unloaded then
                if t:IsA("BoolValue") and t.Name == "Auto" and Toggles.Exploit_FullAuto.Value then
                    local originalValue = oldIndex(t, k)
                    if originalValue == false then return true end
                end
                
                if t:IsA("NumberValue") then
                    if Toggles.Exploit_Shotgun.Value and t.Name == "BulletsPerTrail" then return 4 end
                    if Toggles.Exploit_RapidFire.Value and t.Name == "FireRate" then return 0.001 end
                    if Toggles.Exploit_InstaEquip.Value and t.Name == "EquipTime" then return 0.001 end
                    if Toggles.Exploit_InstaReload.Value and t.Name == "ReloadTime" then return 0.001 end
                    if Toggles.Exploit_NoSpread.Value and (t.Name == "Spread" or (t.Parent and t.Parent.Name == "Spread")) then return 0.001 end
                end
            end
        end
    end
    return oldIndex(t, k)
end)

mt.__namecall = newcclosure(function(self, ...)
    local Args, Method = {...}, getnamecallmethod()
    
    if not checkcaller() and not Library.Unloaded then
        -- Silent Aimbot + Wallbang + Kill All
        if Method == "FindPartOnRayWithIgnoreList" then
            if Toggles.Silent_Enabled and Toggles.Silent_Enabled.Value then
                local ray = Args[1]
                if typeof(ray) == "Ray" and ray.Direction.Magnitude > 15 then
                    
                    -- Normal Silent Aim (single target)
                    local CP, TargetBone, aimWorldPos = GetSilentAimTarget()
                    -- Update debug state
                    if CP and CP.Character and TargetBone then
                        SilentDebugState = "locked"
                        SilentDebugTarget = CP.Name
                        SilentDebugBone = TargetBone.Name
                        SilentDebugLastUpdate = tick()
                        local aimAt = aimWorldPos or TargetBone.Position
                        Args[1] = Ray.new(CurrentCamera.CFrame.Position, (aimAt - CurrentCamera.CFrame.Position).Unit * 1000)
                        
                        -- Wallbang: inject all penetrable geometry into ignore list
                        if Toggles.Exploit_Wallbang and Toggles.Exploit_Wallbang.Value and WallbangCacheReady then
                            local ignoreList = Args[2]
                            if type(ignoreList) == "table" then
                                for _, part in ipairs(WallbangCache) do
                                    table.insert(ignoreList, part)
                                end
                                Args[2] = ignoreList
                            end
                        end
                        
                        return oldNamecall(self, unpack(Args))
                    end
                end
            end
        end
    end
    
    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

-- Anti Aim Logic
local function YROTATION(CFramePos)
    local x, y, z = CFramePos:ToOrientation()
    return CFrame.new(CFramePos.Position) * CFrame.Angles(0, y, 0)
end

local Jitter = false
local Spin = 0
local DisableAA = false
local LagTick = 0
local FakelagFolder = workspace:FindFirstChild("FakelagFolder") or Instance.new("Folder")
FakelagFolder.Name = "FakelagFolder"
FakelagFolder.Parent = workspace

local AntiAim_Connection = RunService.RenderStepped:Connect(function(dt)
    if not LocalPlayer.Character then return end
    local char = LocalPlayer.Character
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    -- Update Spin
    Spin = (Spin + Options.AA_SpinSpeed.Value) % 360

    -- Apply Anti-Aim
    Jitter = not Jitter
    local CamLook = Camera.CFrame.LookVector

    if Toggles.AA_Enabled.Value and not DisableAA then
        hum.AutoRotate = false
        local Angle = -math.atan2(CamLook.Z, CamLook.X) + math.rad(-90)
        local yawBase = Options.AA_YawBase.Value

        if yawBase == "spin" then
            Angle = Angle + math.rad(Spin)
        elseif yawBase == "random" then
            Angle = Angle + math.rad(math.random(0, 360))
        end

        local baseYaw = Options.AA_YawOffset.Value
        if Toggles.AA_ManualLeft and Toggles.AA_ManualLeft.Value then
            baseYaw = -90
        elseif Toggles.AA_ManualRight and Toggles.AA_ManualRight.Value then
            baseYaw = 90
        end

        local Offset = math.rad(-baseYaw - ((Toggles.AA_Jitter.Value and Jitter) and Options.AA_JitterOffset.Value or 0))
        local CFramePos = CFrame.new(root.Position) * CFrame.Angles(0, Angle + Offset, 0)


        if yawBase == "targets" then
            local part
            local closest = 9999
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 and plr.Team ~= LocalPlayer.Team then
                    if plr.Character:FindFirstChild("HumanoidRootPart") then
                        local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                        local magnitude = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                        if closest > magnitude then
                            part = plr.Character.HumanoidRootPart
                            closest = magnitude
                        end
                    end
                end
            end
            if part ~= nil then
                CFramePos = CFrame.new(root.Position, part.Position) * CFrame.Angles(0, Offset, 0)
            end
        end
        
        root.CFrame = YROTATION(CFramePos)
        
        if Options.AA_BodyRoll.Value == "180" then
            root.CFrame = root.CFrame * CFrame.Angles(math.rad(180), 1, 0)
            hum.HipHeight = 4
        else
            if hum.HipHeight == 4 then
                hum.HipHeight = 2 
            end
        end

        local PitchStr = Options.AA_Pitch.Value
        local Pitch = PitchStr == "none" and CamLook.Y or PitchStr == "up" and 1 or PitchStr == "down" and -1 or PitchStr == "zero" and 0 or PitchStr == "random" and math.random(-10, 10)/10 or 2.5
        
        if Toggles.AA_ExtendPitch.Value and (PitchStr == "up" or PitchStr == "down") then
            Pitch = (Pitch*2)/1.6
        end
        
        game:GetService("ReplicatedStorage").Events.ControlTurn:FireServer(Pitch, char:FindFirstChild("Climbing") and true or false)
    else
        -- Restore normal movement when AA is off
        if not hum.AutoRotate then
            hum.AutoRotate = true
        end
        if hum.HipHeight == 4 then
            hum.HipHeight = 2
        end
    end
    -- When AA is off, do not set AutoRotate every frame — that fights the Animate/locomotion system and can freeze leg cycles.
end)

local function SyncHumanoidAutoRotateForAA()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Toggles.AA_Enabled.Value and not DisableAA then
        hum.AutoRotate = false
    else
        hum.AutoRotate = true
    end
end

Toggles.AA_Enabled:OnChanged(SyncHumanoidAutoRotateForAA)
LocalPlayer.CharacterAdded:Connect(function(char)
    local function deferSync()
        task.defer(SyncHumanoidAutoRotateForAA)
    end
    if char:FindFirstChildOfClass("Humanoid") then deferSync() end
    char.ChildAdded:Connect(function(child)
        if child:IsA("Humanoid") then deferSync() end
    end)
end)
task.defer(SyncHumanoidAutoRotateForAA)

-- FakeLag Coroutine
task.spawn(function()
    while task.wait(1/16) do
        if Library.Unloaded then break end
        
        LagTick = math.clamp(LagTick + 1, 0, Options.FL_Limit.Value)
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("UpperTorso") and Toggles.FL_Enabled.Value then
            local limitThreshold = Options.FL_Amount.Value == "static" and Options.FL_Limit.Value or math.random(1, Options.FL_Limit.Value)
            if LagTick == limitThreshold then
                if game:GetService("NetworkClient") then
                    pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge) end)
                end
                FakelagFolder:ClearAllChildren()
                LagTick = 0
                
                if Toggles.FL_Visualize.Value then
                    for _, hitbox in pairs(LocalPlayer.Character:GetChildren()) do
                        if hitbox:IsA("BasePart") and hitbox.Name ~= "HumanoidRootPart" then
                            local part = Instance.new("Part")
                            part.CFrame = hitbox.CFrame
                            part.Anchored = true
                            part.CanCollide = false
                            part.CastShadow = false
                            part.Material = Enum.Material.ForceField
                            part.Color = Options.FL_VisualizeColor.Value
                            part.Name = hitbox.Name
                            part.Transparency = 0
                            part.Size = hitbox.Size
                            part.Parent = FakelagFolder
                        end
                    end
                end
            else
                if game:GetService("NetworkClient") then
                    pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(1) end)
                end
            end
        else
            FakelagFolder:ClearAllChildren()
            if game:GetService("NetworkClient") then
                pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge) end)
            end
        end
    end
end)

Toggles.FL_Enabled:OnChanged(function()
    if not Toggles.FL_Enabled.Value then
        FakelagFolder:ClearAllChildren()
        if game:GetService("NetworkClient") then
            pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge) end)
        end
    end
end)

-- Noclip (Flight) with Anti-Cheat Bypass
local UIS = game:GetService("UserInputService")
local NoclipConnection = nil

local function StartNoclip()
    if NoclipConnection then return end
    
    NoclipConnection = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        -- Disable collision every physics frame (anti-cheat bypass)
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        -- Freeze in place (anti-gravity)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp then hrp.Velocity = Vector3.new(0, 0, 0) end
        if hum then hum:ChangeState(Enum.HumanoidStateType.Flying) end
    end)
end

local function StopNoclip()
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
end

-- Noclip movement coroutine
task.spawn(function()
    while task.wait(1/60) do
        if Library.Unloaded then
            StopNoclip()
            break
        end
        
        if not (Toggles.Misc_Noclip and Toggles.Misc_Noclip.Value) then
            StopNoclip()
            continue
        end
        
        local char = LocalPlayer.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp then continue end
        
        StartNoclip()
        
        -- Freeze gravity
        hrp.Velocity = Vector3.new(0, 0, 0)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Flying) end
        
        -- Camera-relative movement
        local cam = workspace.CurrentCamera
        local speed = Options.Misc_NoclipSpeed.Value
        local moveDir = Vector3.new(0, 0, 0)
        
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        
        if moveDir.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + moveDir.Unit * (speed / 60)
        end
    end
end)

-- Speedhack Coroutine
task.spawn(function()
    while task.wait(1/60) do
        if Library.Unloaded then break end
        
        local char = LocalPlayer.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then continue end
        
        if Toggles.Misc_SpeedHack and Toggles.Misc_SpeedHack.Value and hum.MoveDirection.Magnitude > 0 then
            local speed = Options.Misc_SpeedValue.Value
            local speedType = Options.Misc_SpeedType.Value
            
            if speedType == "velocity" then
                hrp.Velocity = hum.MoveDirection * speed + Vector3.new(0, hrp.Velocity.Y, 0)
            elseif speedType == "cframe" then
                hrp.CFrame = hrp.CFrame + hum.MoveDirection * (speed / 60)
            end
        end
    end
end)


-- Get Client table from the game's local script environment (for infinite crouch)
local Client = nil
pcall(function()
    for _, obj in pairs(game:GetService("Players").LocalPlayer.PlayerScripts:GetDescendants()) do
        if obj:IsA("LocalScript") then
            local env = getsenv(obj)
            if env and type(env) == "table" then
                for k, v in pairs(env) do
                    if type(v) == "table" and rawget(v, "crouchcooldown") ~= nil then
                        Client = v
                        break
                    end
                end
            end
            if Client then break end
        end
    end
end)

-- Animation Player Logic
local Dance = Instance.new("Animation")
Dance.AnimationId = "rbxassetid://5917459365"
local LoadedAnim = nil

local AnimationIds = {
    ["floss"] = "rbxassetid://5917459365",
    ["default"] = "rbxassetid://3732699835",
    ["lil nas x"] = "rbxassetid://5938396308",
    ["dolphin"] = "rbxassetid://5938365243",
    ["monkey"] = "rbxassetid://3716636630"
}

local function StopAnimation()
    pcall(function()
        if LoadedAnim then
            LoadedAnim:Stop()
            LoadedAnim = nil
        end
    end)
end

local function PlayAnimation()
    StopAnimation()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if animator then
        LoadedAnim = animator:LoadAnimation(Dance)
    else
        LoadedAnim = hum:LoadAnimation(Dance)
    end
    if LoadedAnim then
        LoadedAnim.Priority = Enum.AnimationPriority.Action
        LoadedAnim:Play()
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    StopAnimation()
    if Toggles.Anim_Enabled and Toggles.Anim_Enabled.Value then
        task.spawn(function()
            -- Wait until humanoid fully initializes upon respawn
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then
                -- Add a slight delay so default game animations don't override our custom one instantly
                task.wait(0.2)
                if Toggles.Anim_Enabled.Value then
                    PlayAnimation()
                end
            end
        end)
    end
end)

Toggles.Anim_Enabled:OnChanged(function()
    if Toggles.Anim_Enabled.Value then
        PlayAnimation()
    else
        StopAnimation()
    end
end)

Options.Anim_Selection:OnChanged(function()
    local sel = Options.Anim_Selection.Value
    if AnimationIds[sel] then
        Dance.AnimationId = AnimationIds[sel]
    end
    if Toggles.Anim_Enabled.Value then
        PlayAnimation()
    end
end)

-- Hitsound Logic
local HitsoundIds = {
    ["skeet"] = "rbxassetid://5447626464",
    ["neverlose"] = "rbxassetid://6607204501",
    ["rust"] = "rbxassetid://5043539486",
    ["bag"] = "rbxassetid://364942410",
    ["baimware"] = "rbxassetid://6607339542"
}

local Hitsound_Connection = nil
pcall(function()
    if LocalPlayer:FindFirstChild("Additionals") and LocalPlayer.Additionals:FindFirstChild("TotalDamage") then
        Hitsound_Connection = LocalPlayer.Additionals.TotalDamage:GetPropertyChangedSignal("Value"):Connect(function()
            if LocalPlayer.Additionals.TotalDamage.Value == 0 then return end

            -- Hitsound
            local selected = Options.Hitsound_Sound.Value
            if selected ~= "none" then
                local soundId = HitsoundIds[selected]
                if soundId then
                    local sound = Instance.new("Sound")
                    sound.Parent = game:GetService("SoundService")
                    sound.SoundId = soundId
                    sound.Volume = Options.Hitsound_Volume.Value
                    sound.PlayOnRemove = true
                    sound:Destroy()
                end
            end

            -- Find who we hit using true network data (100% accurate)
            local hitCharacter = nil
            local hitPlayer = nil
            local hitPartName = "Body"
            
            pcall(function()
                if _G.LastHitPartInstance and typeof(_G.LastHitPartInstance) == "Instance" then
                    hitPartName = _G.LastHitPartInstance.Name
                    
                    -- Safety Check: Ensure the hit part belongs to a character model, not the Map/Workspace
                    local potentialChar = _G.LastHitPartInstance.Parent
                    if potentialChar and (potentialChar:FindFirstChildOfClass("Humanoid") or (potentialChar.Parent and potentialChar.Parent:FindFirstChildOfClass("Humanoid"))) then
                        if potentialChar.Parent:FindFirstChildOfClass("Humanoid") then
                            potentialChar = potentialChar.Parent
                        end
                        hitCharacter = potentialChar
                        hitPlayer = game:GetService("Players"):GetPlayerFromCharacter(hitCharacter)
                    end
                end
            end)
            
            -- Fallback to crosshair cast if the hit wasn't from a gun or character not found
            if not hitCharacter then
                pcall(function()
                    local closestDist = math.huge
                    for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character then
                            local head = plr.Character:FindFirstChild("Head")
                            if head then
                                local screenPos, onScreen = CurrentCamera:WorldToScreenPoint(head.Position)
                                if onScreen then
                                    local screenCenter = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y / 2)
                                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                                    if dist < closestDist then
                                        closestDist = dist
                                        hitPlayer = plr
                                        hitCharacter = plr.Character
                                    end
                                end
                            end
                        end
                    end
                    
                    if hitCharacter then
                        local screenCenter = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y / 2)
                        local closestBoneDist = math.huge
                        for _, bp in pairs(hitCharacter:GetChildren()) do
                            if bp:IsA("BasePart") then
                                local sp, vis = CurrentCamera:WorldToScreenPoint(bp.Position)
                                if vis then
                                    local d = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
                                    if d < closestBoneDist then
                                        closestBoneDist = d
                                        hitPartName = bp.Name
                                    end
                                end
                            end
                        end
                    end
                end)
            end

            -- Only proceed with VISUAL effects if we hit a VALID player character
            -- This prevents coloring the whole Map/Workspace when accidentally hitting a wall or floor.
            local isValidChar = hitCharacter and (hitCharacter:FindFirstChildOfClass("Humanoid") or hitPlayer ~= nil)
            
            -- Size safeguard: if there are more than 60 parts, it's definitely not a player (probably the map)
            if isValidChar and #hitCharacter:GetChildren() > 60 then
                isValidChar = false
            end

            -- Hit Chams
            if isValidChar and Toggles.HitFX_Chams and Toggles.HitFX_Chams.Value then
                local chamsDuration = Options.HitFX_ChamsDuration.Value
                task.spawn(function()
                    for _, hitbox in pairs(hitCharacter:GetChildren()) do
                        if hitbox:IsA("BasePart") then
                            task.spawn(function()
                                local part = Instance.new("Part")
                                part.CFrame = hitbox.CFrame
                                part.Anchored = true
                                part.CanCollide = false
                                part.Material = Enum.Material.ForceField
                                part.Color = Options.HitFX_ChamsColor.Value
                                part.Size = hitbox.Size
                                part.Parent = workspace.Debris
                                local tween = game:GetService("TweenService"):Create(part, TweenInfo.new(chamsDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
                                tween:Play()
                                task.wait(chamsDuration)
                                part:Destroy()
                            end)
                        end
                    end
                end)
            end

            -- Draw Damage (text "Hit" on enemy head)
            if isValidChar and Toggles.HitFX_Damage and Toggles.HitFX_Damage.Value then
                local textDuration = Options.HitFX_TextDuration.Value
                local textSize = Options.HitFX_TextSize.Value
                local fontName = Options.HitFX_Font.Value
                local font = Enum.Font[fontName] or Enum.Font.Ubuntu
                task.spawn(function()
                    local head = hitCharacter:FindFirstChild("Head")
                    if not head then return end

                    local billboard = Instance.new("BillboardGui")
                    billboard.Size = UDim2.new(0, 100, 0, 40)
                    billboard.StudsOffset = Vector3.new(0, 2, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Adornee = head
                    billboard.Parent = head

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = "Hit"
                    label.Font = font
                    label.TextSize = textSize
                    label.TextColor3 = Options.HitFX_DamageColor.Value
                    label.TextStrokeTransparency = 0.5
                    label.TextTransparency = 0
                    label.Parent = billboard

                    local fadeTween = game:GetService("TweenService"):Create(label, TweenInfo.new(textDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                        TextTransparency = 1, TextStrokeTransparency = 1
                    })
                    fadeTween:Play()
                    task.wait(textDuration)
                    billboard:Destroy()
                end)
            end

            -- Notification
            if Toggles.HitFX_Notify and Toggles.HitFX_Notify.Value then
                local notifyText = Options.HitFX_NotifyText.Value or "hit {PLAYER} in {PART}"
                local notifyDuration = Options.HitFX_NotifyDuration.Value or 2
                local playerName = hitPlayer and hitPlayer.Name or "Unknown"
                
                -- Only show notification if we actually hit a player, or hide "Unknown" spam
                if playerName ~= "Unknown" then
                    notifyText = string.gsub(notifyText, "{PLAYER}", playerName)
                    notifyText = string.gsub(notifyText, "{PART}", hitPartName)
                    Library:NotifyMid(notifyText, notifyDuration)
                end
            end
        end)
    end
end)

Toggles.Exploit_ThirdPerson:OnChanged(function()
    local tpValue = workspace:FindFirstChild('ThirdPerson')
    if tpValue and tpValue:IsA("BoolValue") then
        tpValue.Value = Toggles.Exploit_ThirdPerson.Value
    end
end)

Toggles.AA_ManualLeft:OnChanged(function()
    if Toggles.AA_ManualLeft.Value and Toggles.AA_ManualRight.Value then
        Toggles.AA_ManualRight:SetValue(false)
    end
end)

Toggles.AA_ManualRight:OnChanged(function()
    if Toggles.AA_ManualRight.Value and Toggles.AA_ManualLeft.Value then
        Toggles.AA_ManualLeft:SetValue(false)
    end
end)

-- Peek Assist Logic
local PeekPoint = nil
local PeekVisual = nil
local Peek_AutoReturned = false

local function ExecutePeekReturn()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local root = LocalPlayer.Character.HumanoidRootPart
    local hum = LocalPlayer.Character:FindFirstChild("Humanoid")

    if PeekPoint then
        if Options.Peek_Type.Value == "teleportation" then
            root.CFrame = CFrame.new(PeekPoint + Vector3.new(0, 0.2, 0))
        elseif Options.Peek_Type.Value == "walk" and hum then
            task.spawn(function()
                local returnEnd = tick() + 2
                while (root.Position - PeekPoint).Magnitude > 1.5 and tick() < returnEnd do
                    hum:MoveTo(PeekPoint)
                    task.wait()
                end
            end)
        end
    end

    -- Fade Out Visual
    if PeekVisual then
        local p = PeekVisual
        PeekVisual = nil
        task.spawn(function()
            local ts = game:GetService("TweenService")
            local tween = ts:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1, Size = Vector3.new(0, 0, 0)})
            tween:Play()
            tween.Completed:Wait()
            p:Destroy()
        end)
    end
    PeekPoint = nil
end

Toggles.Peek_Enabled:OnChanged(function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local root = LocalPlayer.Character.HumanoidRootPart
    local hum = LocalPlayer.Character:FindFirstChild("Humanoid")

    if Toggles.Peek_Enabled.Value then
        Peek_AutoReturned = false
        PeekPoint = root.Position
        
        -- Create Visual
        if Toggles.Peek_Visualize.Value then
            if PeekVisual then PeekVisual:Destroy() end
            PeekVisual = Instance.new("Part")
            PeekVisual.Size = Vector3.new(0.1, 4, 4) -- X is thickness for Cylinder
            PeekVisual.CFrame = CFrame.new(PeekPoint - Vector3.new(0, 2.95, 0)) * CFrame.Angles(0, 0, math.rad(90))
            PeekVisual.Anchored = true
            PeekVisual.CanCollide = false
            PeekVisual.Material = Enum.Material.Neon
            PeekVisual.Shape = Enum.PartType.Cylinder
            PeekVisual.Color = Options.Peek_CircleColor.Value
            PeekVisual.Transparency = Options.Peek_CircleColor.Transparency
            PeekVisual.Parent = workspace.Debris
        end
    else
        ExecutePeekReturn()
    end
end)

local Peek_LastState = false
local Peek_Connection
Peek_Connection = RunService.Heartbeat:Connect(function()
    if Library.Unloaded then
        if Peek_Connection then Peek_Connection:Disconnect() end
        return
    end
    -- Sync KeyPicker to Toggle (Library doesn't do this for Hold mode)
    local Current_Peek = Options.Peek_Bind and Options.Peek_Bind:GetState() or false
    
    if Current_Peek ~= Peek_LastState then
        Peek_LastState = Current_Peek
        if not Current_Peek then
            Peek_AutoReturned = false -- Reset when key is released
        end
        
        if not Peek_AutoReturned then
            Toggles.Peek_Enabled:SetValue(Current_Peek)
        end
    end

    if Toggles.Peek_Enabled.Value and PeekPoint and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        local dist = (root.Position - PeekPoint).Magnitude
        
        if dist > 15 then -- Max distance 15 studs
            local direction = (root.Position - PeekPoint).Unit
            if dist > 15.5 then
                root.CFrame = CFrame.new(PeekPoint + direction * 15)
            end
            if hum then
                hum.WalkSpeed = 4 -- Slow down
            end
        else
            if hum then
                hum.WalkSpeed = 16 -- Normal
            end
        end
    end
end)

-- Misc Logic (Movement & Viewmodel)
local BhopBodyVelocity = Instance.new("BodyVelocity")
BhopBodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)

local function YROTATION_BHOP(cframe)
    local x, y, z = cframe:ToOrientation()
    return CFrame.new(cframe.Position) * CFrame.Angles(0, y, 0)
end

local CharAdded_Connection
CharAdded_Connection = LocalPlayer.CharacterAdded:Connect(function(char)
    if Library.Unloaded then
        if CharAdded_Connection then CharAdded_Connection:Disconnect() end
        return
    end
    repeat RunService.RenderStepped:Wait() until char:FindFirstChild("Gun") or Library.Unloaded
end)

-- Counter Blox viewmodel: `Arms` is a Model under CurrentCamera. Inside: weapon parts (Handle2, Mag2, etc.) + arms (ECArms, PTArms, SPArms).
local function Viewmodel_CollectMaterialParts(camera)
    local arms = camera and camera:FindFirstChild("Arms")
    if not arms or not arms:IsA("Model") then return {}, nil end
    
    local list = {}
    local armContainers = {["ECArms"] = true, ["PTArms"] = true, ["SPArms"] = true}
    
    -- We want only the WEAPON parts. 
    -- These are usually MeshParts/BaseParts directly under Arms, or inside non-arm models/folders.
    for _, v in pairs(arms:GetChildren()) do
        if v:IsA("BasePart") then
            table.insert(list, v)
        elseif not armContainers[v.Name] then
            -- Fallback for weapon parts inside folders/models
            for _, d in pairs(v:GetDescendants()) do
                if d:IsA("BasePart") then
                    table.insert(list, d)
                end
            end
        end
    end
    return list, arms
end

local Viewmodel_MaterialIds = { 'default', 'forcefield', 'neon', 'glass', 'plastic', 'wood' }

local function Viewmodel_GetMaterialMode()
    local v = Options.Viewmodel_WeaponMaterial and Options.Viewmodel_WeaponMaterial.Value
    if type(v) == 'number' then
        return Viewmodel_MaterialIds[v] or 'default'
    end
    if type(v) == 'string' then
        for _, id in ipairs(Viewmodel_MaterialIds) do
            if id == v then return id end
        end
        local lower = string.lower(v)
        for _, id in ipairs(Viewmodel_MaterialIds) do
            if string.lower(id) == lower then return id end
        end
    end
    return 'default'
end

local Misc_Connection = RunService.RenderStepped:Connect(function(dt)
    if not LocalPlayer.Character then return end
    local char = LocalPlayer.Character
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end


    -- Air Strafe (Continuous Smooth Jump Boost - Position Based)
    if Toggles.Misc_AirStrafe.Value and hum and root then
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Freefall then
            local dir = hum.MoveDirection
            if dir.Magnitude == 0 then dir = root.CFrame.LookVector end
            dir = Vector3.new(dir.X, 0, dir.Z).Unit
            
            local targetSpeed = Options.Misc_AirStrafeSpeed.Value
            
            -- Instead of altering root.Velocity (which Anti-Cheat hooks into natively),
            -- we translate the CFrame horizontally. This acts like speedhack but only while jumping.
            -- Using dt * targetSpeed applies smooth movement.
            if targetSpeed > 10 then
                root.CFrame = root.CFrame + (dir * ((targetSpeed / 3) * dt))
            end
        end
    end
    
    -- FOV Changer
    if Toggles.Misc_FOVChanger.Value then
        workspace.CurrentCamera.FieldOfView = Options.Misc_FOVValue.Value
    end
    
    -- Bring C4 (Defuse)
    -- Logic replaced by Auto Defuse

    -- Plant Anywhere
    -- Logic replaced by Auto Plant

    -- Buy Anywhere
    -- Logic replaced by Auto Plant/Defuse

    -- Infinite Crouch
    if Toggles.Misc_InfiniteCrouch.Value and Client then
        pcall(function()
            Client.crouchcooldown = 0
        end)
    end
end)

-- Viewmodel runs at Last render priority so Counter Blox viewmodel code does not overwrite Material/Color after us.
local function Viewmodel_RenderStep()
    local camera = workspace.CurrentCamera
    if Toggles.Viewmodel_Enabled and Toggles.Viewmodel_Enabled.Value then
        if not camera then return end
        local parts, arms = Viewmodel_CollectMaterialParts(camera)
        if not arms then return end

        -- 1. Remove Hands Logic
        if Toggles.Viewmodel_RemoveHands.Value then
            local pt = arms:FindFirstChild("PTArms")
            if pt then
                for _, sideName in ipairs({"Left Arm", "Right Arm"}) do
                    local side = pt:FindFirstChild(sideName)
                    if side then
                        for _, mesh in ipairs(side:GetDescendants()) do
                            if mesh.Name == "Mesh" or mesh:IsA("SpecialMesh") or mesh:IsA("MeshPart") then
                                pcall(function() mesh:Destroy() end)
                            end
                        end
                    end
                end
            end
        end

        -- 2. Material & Color Logic
        local selectedMaterial = Viewmodel_GetMaterialMode()
        local weaponColor = Options.Viewmodel_WeaponColor.Value or Color3.new(1, 1, 1)

        for _, part in ipairs(parts) do
            -- Cache originals
            if not part:GetAttribute("OriginalMaterial") then
                part:SetAttribute("OriginalMaterial", part.Material.Name)
            end
            if part:GetAttribute("OrigR") == nil then
                local c = part.Color
                part:SetAttribute("OrigR", c.R)
                part:SetAttribute("OrigG", c.G)
                part:SetAttribute("OrigB", c.B)
            end

            -- Apply Material
            if selectedMaterial ~= 'default' then
                pcall(function()
                    part.Material = Enum.Material[selectedMaterial:sub(1,1):upper() .. selectedMaterial:sub(2)]
                    if selectedMaterial == 'forcefield' then part.Material = Enum.Material.ForceField end
                end)
            end

            -- Apply Color
            part.Color = weaponColor
        end
    else
        -- Restore Original Viewmodel State
        if not camera then return end
        local parts = Viewmodel_CollectMaterialParts(camera)
        for _, part in ipairs(parts) do
            local origMatName = part:GetAttribute("OriginalMaterial")
            if origMatName then
                pcall(function() part.Material = Enum.Material[origMatName] end)
            end
            local r = part:GetAttribute("OrigR")
            if r ~= nil then
                pcall(function()
                    part.Color = Color3.new(r, part:GetAttribute("OrigG"), part:GetAttribute("OrigB"))
                end)
            end
        end
    end
end

RunService:BindToRenderStep("SolanceViewmodel", Enum.RenderPriority.Last.Value, function()
    if Library.Unloaded then return end
    if not LocalPlayer.Character then return end
    local char = LocalPlayer.Character
    if not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
    pcall(Viewmodel_RenderStep)
end)


-- Ignore Killers Logic
local IgnoreKillers_Originals = {}
local IgnoreKillers_Connection = nil

local function IsKillPart(part)
    if not part:IsA("BasePart") then return false end
    local name = part.Name:lower()
    local parentName = part.Parent and part.Parent.Name:lower() or ""
    
    -- Counter Blox usually puts kill parts in a folder called 'Killers' or names them 'Killer'
    if name == "killer" or parentName == "killers" or name:match("^kill") then
        return true
    end
    
    -- detect by having a Script/LocalScript child with Touched-related content
    for _, child in pairs(part:GetChildren()) do
        if child:IsA("Script") or child:IsA("LocalScript") then
            local cname = child.Name:lower()
            if cname:find("kill") or cname:find("damage") or cname:find("hurt") then
                return true
            end
        end
    end
    return false
end

local function NeutralizeKillPart(part)
    if IgnoreKillers_Originals[part] then return end
    IgnoreKillers_Originals[part] = {
        CanCollide = part.CanCollide,
        CanTouch = part.CanTouch
    }
    part.CanCollide = false
    part.CanTouch = false
end

local function RestoreKillParts()
    for part, original in pairs(IgnoreKillers_Originals) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = original.CanCollide
                part.CanTouch = original.CanTouch
            end)
        end
    end
    IgnoreKillers_Originals = {}
end

Toggles.Misc_IgnoreKillers:OnChanged(function()
    if Toggles.Misc_IgnoreKillers.Value then
        -- scan existing parts in Map
        local map = workspace:FindFirstChild("Map")
        if map then
            for _, desc in pairs(map:GetDescendants()) do
                if IsKillPart(desc) then
                    NeutralizeKillPart(desc)
                end
            end
            -- watch for new kill parts
            IgnoreKillers_Connection = map.DescendantAdded:Connect(function(desc)
                task.wait()
                if Toggles.Misc_IgnoreKillers.Value and IsKillPart(desc) then
                    NeutralizeKillPart(desc)
                end
            end)
        end
    else
        if IgnoreKillers_Connection then
            IgnoreKillers_Connection:Disconnect()
            IgnoreKillers_Connection = nil
        end
        RestoreKillParts()
    end
end)

-- Penetration Math Logic
local function GetPenetrationDamage(origin, targetPos)
    local maxDist = (targetPos - origin).Magnitude
    local direction = (targetPos - origin).Unit
    local currentPos = origin
    local totalThickness = 0
    local hits = 0
    
    local ignoreList = {LocalPlayer.Character, workspace.CurrentCamera, workspace:FindFirstChild("Debris")}
    
    for _ = 1, 10 do
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = ignoreList
        params.IgnoreWater = true
        
        local remainingDist = maxDist - (currentPos - origin).Magnitude
        if remainingDist <= 0.1 then break end
        
        local forwardResult = workspace:Raycast(currentPos, direction * remainingDist, params)
        if not forwardResult then break end
        
        local hitPart = forwardResult.Instance
        if not hitPart.CanCollide or hitPart.Transparency >= 1 then
            table.insert(ignoreList, hitPart)
            continue
        end
        
        -- Check for impenetrable map parts specifically defined by CB
        local isNoWallBang = hitPart.Name:lower():match("nowallbang") or (hitPart.Parent and hitPart.Parent.Name:lower():match("nowallbang"))
        if isNoWallBang then
            return 0 -- Instantly block bullets here
        end
        
        hits = hits + 1
        
        local backParams = RaycastParams.new()
        backParams.FilterType = Enum.RaycastFilterType.Whitelist
        backParams.FilterDescendantsInstances = {hitPart}
        
        local backOrigin = targetPos
        local backDir = -direction * remainingDist
        local backResult = workspace:Raycast(backOrigin, backDir, backParams)
        
        local exitPos = backResult and backResult.Position or targetPos
        local thickness = (exitPos - forwardResult.Position).Magnitude
        totalThickness = totalThickness + thickness
        
        currentPos = exitPos + (direction * 0.1)
        table.insert(ignoreList, hitPart)
    end
    
    if hits == 0 then return 100 end
    if hits > 4 then return 0 end
    
    local damageModifier = 100 - (totalThickness * 15)
    return math.clamp(damageModifier, 0, 100)
end

-- Auto Shoot Logic
task.spawn(function()
    local isShooting = false
    local targetFoundTime = 0
    local aimbotHadTarget = false
    local lastClickTime = 0
    
    local function releaseMouse()
        if isShooting then
            mouse1release()
            isShooting = false
        end
    end
    
    while task.wait() do
        if Library.Unloaded then
            releaseMouse()
            break
        end
        
        local isAlive = false
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then
            isAlive = true
        end

        local menuOpen = Library.Toggled == true or false

        if not isAlive or menuOpen then
            releaseMouse()
            aimbotHadTarget = false
            -- We skip the rest of the logic if dead or menu open
            continue
        end
        
        if Toggles.AutoShoot_Enabled and Toggles.AutoShoot_Enabled.Value then
            local target, targetBone = VectorAimbot_GetTargetAndBone()
            local hasTarget = (target ~= nil)
            
            -- Visibility and AutoWall Check
            if hasTarget and target.Character then
                local bonePart = target.Character:FindFirstChild(targetBone or VectorAimbot_CurrentBone or "Head")
                local canShoot = false
                
                if bonePart then
                    local damage = GetPenetrationDamage(workspace.CurrentCamera.CFrame.Position, bonePart.Position)
                    
                    if damage == 100 then
                        canShoot = true
                    elseif damage > 0 and Toggles.Silent_AutoWall and Toggles.Silent_AutoWall.Value then
                        canShoot = true
                    end
                end
                
                if not canShoot then
                    hasTarget = false
                    target = nil
                end
            end
            
            if hasTarget and not aimbotHadTarget then
                targetFoundTime = tick()
                aimbotHadTarget = true
            elseif not hasTarget and aimbotHadTarget then
                aimbotHadTarget = false
                releaseMouse()
                
                -- Release on Shot synergy
                if Toggles.Peek_Enabled.Value and Toggles.Peek_ReleaseOnShot.Value then
                    Peek_AutoReturned = true
                    Toggles.Peek_Enabled:SetValue(false)
                end
            end
            
            if hasTarget then
                local delayPassed = (tick() - targetFoundTime) >= (Options.AutoShoot_ShootDelay.Value / 1000)
                if delayPassed then
                    local isAuto = false
                    if Toggles.Exploit_FullAuto and Toggles.Exploit_FullAuto.Value then
                        isAuto = true
                    else
                        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                        if tool then
                            local autoVal = tool:FindFirstChild("Auto")
                            if autoVal and autoVal:IsA("BoolValue") then
                                isAuto = autoVal.Value
                            end
                        end
                    end
                    
                    if isAuto then
                        if not isShooting then
                            mouse1press()
                            isShooting = true
                        end
                    else
                        releaseMouse()
                        if (tick() - lastClickTime) >= (Options.AutoShoot_SemiDelay.Value / 1000) then
                            mouse1press()
                            task.wait(0.01)
                            mouse1release()
                            lastClickTime = tick()
                            
                            -- persistence check: if target died, reset state to find next target immediately
                            if target and target.Character and target.Character:FindFirstChild("Humanoid") then
                                if target.Character.Humanoid.Health <= 0 then
                                    aimbotHadTarget = false
                                end
                            end
                        end
                    end
                end
            else
                releaseMouse()
            end
        else
            releaseMouse()
            aimbotHadTarget = false
        end
    end
end)

-- Ambience / Lighting Customizer
local OriginalLighting = {}
local lightingCached = false

local function CacheLighting()
    if lightingCached then return end
    OriginalLighting.GlobalShadows = game.Lighting.GlobalShadows
    OriginalLighting.ClockTime = game.Lighting.ClockTime
    OriginalLighting.Brightness = game.Lighting.Brightness
    OriginalLighting.Ambient = game.Lighting.Ambient
    OriginalLighting.OutdoorAmbient = game.Lighting.OutdoorAmbient
    OriginalLighting.ColorShift_Top = game.Lighting.ColorShift_Top
    OriginalLighting.ColorShift_Bottom = game.Lighting.ColorShift_Bottom
    OriginalLighting.FogColor = game.Lighting.FogColor
    OriginalLighting.FogStart = game.Lighting.FogStart
    OriginalLighting.FogEnd = game.Lighting.FogEnd
    lightingCached = true
end

local Ambience_Connection = RunService.RenderStepped:Connect(function()
    if Toggles.Ambience_Enabled.Value then
        CacheLighting()
        game.Lighting.GlobalShadows = Toggles.Ambience_GlobalShadows.Value
        game.Lighting.ClockTime = Options.Ambience_ClockTime.Value
        game.Lighting.Brightness = Options.Ambience_Brightness.Value
        game.Lighting.Ambient = Options.Ambience_AmbientColor.Value
        game.Lighting.OutdoorAmbient = Options.Ambience_OutdoorAmbientColor.Value
        game.Lighting.ColorShift_Top = Options.Ambience_ColorShift_Top.Value
        game.Lighting.ColorShift_Bottom = Options.Ambience_ColorShift_Bottom.Value
        game.Lighting.FogColor = Options.Ambience_FogColor.Value
        game.Lighting.FogStart = Options.Ambience_FogStart.Value
        game.Lighting.FogEnd = Options.Ambience_FogEnd.Value
    elseif lightingCached then
        game.Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        game.Lighting.ClockTime = OriginalLighting.ClockTime
        game.Lighting.Brightness = OriginalLighting.Brightness
        game.Lighting.Ambient = OriginalLighting.Ambient
        game.Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        game.Lighting.ColorShift_Top = OriginalLighting.ColorShift_Top
        game.Lighting.ColorShift_Bottom = OriginalLighting.ColorShift_Bottom
        game.Lighting.FogColor = OriginalLighting.FogColor
        game.Lighting.FogStart = OriginalLighting.FogStart
        game.Lighting.FogEnd = OriginalLighting.FogEnd
        lightingCached = false
    end
end)

Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    if ESP_RenderConnection then ESP_RenderConnection:Disconnect() end
    if WeaponESP_RenderConnection then WeaponESP_RenderConnection:Disconnect() end
    if BombESP_RenderConnection then BombESP_RenderConnection:Disconnect() end
    if SilentAimbot_RenderConnection then SilentAimbot_RenderConnection:Disconnect() end
    if VectorAimbot_RenderConnection then VectorAimbot_RenderConnection:Disconnect() end
    if MagicBullet_Connection then MagicBullet_Connection:Disconnect() end
    if AntiAim_Connection then AntiAim_Connection:Disconnect() end
    if Misc_Connection then Misc_Connection:Disconnect() end
    pcall(function() RunService:UnbindFromRenderStep("SolanceViewmodel") end)
    if Ambience_Connection then Ambience_Connection:Disconnect() end
    if Hitsound_Connection then Hitsound_Connection:Disconnect() end
    StopAnimation()
    if Particle_RenderConnection then Particle_RenderConnection:Disconnect() end
    if FW_Effects_Connection then FW_Effects_Connection:Disconnect() end
    if CrashServerLoop then CrashServerLoop:Disconnect() end
    if lightingCached then
        game.Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        game.Lighting.ClockTime = OriginalLighting.ClockTime
        game.Lighting.Brightness = OriginalLighting.Brightness
        game.Lighting.Ambient = OriginalLighting.Ambient
        game.Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        game.Lighting.ColorShift_Top = OriginalLighting.ColorShift_Top
        game.Lighting.ColorShift_Bottom = OriginalLighting.ColorShift_Bottom
        game.Lighting.FogColor = OriginalLighting.FogColor
        game.Lighting.FogStart = OriginalLighting.FogStart
        game.Lighting.FogEnd = OriginalLighting.FogEnd
    end
    for plr, _ in pairs(ESP_Instances) do RemoveESP(plr) end
    for item, _ in pairs(WeaponESP_Instances) do RemoveWeaponESP(item) end
    if Backtrack_RenderConnection then Backtrack_RenderConnection:Disconnect() end
    for _, ghosts in pairs(BacktrackGhosts) do
        for _, g in pairs(ghosts) do g:Destroy() end
    end
    BacktrackGhosts = {}
    BombESP_Data.tracer:Remove()
    BombESP_Data.tracerOutline:Remove()
    BombESP_Data.nameText:Remove()
    VectorAimbot_FOVCircle:Remove()
    
    for toggleName, _ in pairs({Exploit_Shotgun = true, Exploit_RapidFire = true, Exploit_FullAuto = true, Exploit_InstaEquip = true, Exploit_InstaReload = true, Exploit_NoSpread = true, Exploit_Wallbang = true}) do
        if Toggles[toggleName] then Toggles[toggleName]:SetValue(false) end
    end
    
    if oldIndex then hookmetamethod(game, "__index", oldIndex) end
    if oldNamecall then hookmetamethod(game, "__namecall", oldNamecall) end
    getgenv().Solance_CounterBlox_Loaded = nil
    
    Library.Unloaded = true
end)

local SkinsGroup = Tabs.skins:AddLeftGroupbox('inventory changer')

local FW_Skin_cbClient = nil
local FW_Skin_oldInventory = nil

task.spawn(function()
    pcall(function()
        local clientScript = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("Client", 5)
        if clientScript and getsenv then
            FW_Skin_cbClient = AntiReverse.AllowCall(function()
                return getsenv(clientScript)
            end)
            if FW_Skin_cbClient then
                FW_Skin_oldInventory = FW_Skin_cbClient.CurrentInventory
            end
        end
    end)
end)

SkinsGroup:AddButton('Default', function()
    if not FW_Skin_cbClient then return Library:NotifyMid("Executor does not support getsenv!", 3) end
    if FW_Skin_oldInventory then
        FW_Skin_cbClient.CurrentInventory = FW_Skin_oldInventory
        local InventoryLoadout = game:GetService("Players").LocalPlayer.PlayerGui.GUI:FindFirstChild("Inventory&Loadout")
        if InventoryLoadout and InventoryLoadout.Visible then
            InventoryLoadout.Visible = false
            InventoryLoadout.Visible = true
        end
        Library:NotifyMid("Restored default inventory.", 2)
    end
end)

SkinsGroup:AddButton('Unlock All', function()
    if not FW_Skin_cbClient then return Library:NotifyMid("Executor does not support getsenv!", 3) end
    local WeaponsData = game:GetService("ReplicatedStorage"):FindFirstChild("Weapons")
    local AllSkinsTable = {}
    
    pcall(function()
        if game:GetService("ReplicatedStorage"):FindFirstChild("Skins") and WeaponsData then
            for i,v in pairs(game:GetService("ReplicatedStorage").Skins:GetChildren()) do
                if v:IsA("Folder") and WeaponsData:FindFirstChild(v.Name) then
                    table.insert(AllSkinsTable, {v.Name.."_Stock"})
                    for i2,v2 in pairs(v:GetChildren()) do
                        if v2.Name ~= "Stock" then
                            table.insert(AllSkinsTable, {v.Name.."_"..v2.Name})
                        end
                    end
                end
            end
        end
        if game:GetService("ReplicatedStorage"):FindFirstChild("Gloves") then
            for i,v in pairs(game:GetService("ReplicatedStorage").Gloves:GetChildren()) do
                if v:IsA("Folder") and v.Name ~= "Models" then
                    for i2,v2 in pairs(v:GetChildren()) do
                        table.insert(AllSkinsTable, {v.Name.."_"..v2.Name})
                    end
                end
            end
        end
        FW_Skin_cbClient.CurrentInventory = AllSkinsTable
        
        -- Force inventory UI refresh regardless of visibility
        local InventoryLoadout = game:GetService("Players").LocalPlayer.PlayerGui.GUI:FindFirstChild("Inventory&Loadout")
        if InventoryLoadout then
            local wasVisible = InventoryLoadout.Visible
            InventoryLoadout.Visible = false
            task.wait()
            InventoryLoadout.Visible = true
            task.wait()
            if not wasVisible then
                InventoryLoadout.Visible = false
            end
        end
        
        -- Try to call client refresh functions
        pcall(function()
            if FW_Skin_cbClient.LoadInventory then
                FW_Skin_cbClient.LoadInventory()
            end
            if FW_Skin_cbClient.RefreshInventory then
                FW_Skin_cbClient.RefreshInventory()
            end
            if FW_Skin_cbClient.UpdateInventory then
                FW_Skin_cbClient.UpdateInventory()
            end
        end)
        
        Library:NotifyMid("Unlocked all skins! Open inventory to apply.", 3)
    end)
end)

local MenuGroup = Tabs['ui settings']:AddLeftGroupbox('menu')
MenuGroup:AddButton('unload', function() Library:Unload() end)
MenuGroup:AddLabel('menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'menu keybind' })

MenuGroup:AddToggle('UI_Watermark', { Text = 'watermark', Default = true }):OnChanged(function()
    Library:SetWatermarkVisibility(Toggles.UI_Watermark.Value)
end)

MenuGroup:AddToggle('UI_Keybinds', { Text = 'keybinds', Default = false }):OnChanged(function()
    Library.KeybindFrame.Visible = Toggles.UI_Keybinds.Value
end)

MenuGroup:AddToggle('UI_ProtectNameInUI', { Text = 'protect name in ui', Default = true }):OnChanged(function()
    Library:UpdateWelcomeName()
end)

if Toggles.Misc_NameProtectEnabled then
    Toggles.Misc_NameProtectEnabled:OnChanged(function()
        Library:UpdateWelcomeName()
    end)
end

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('solance')
SaveManager:SetFolder('solance/counterblox')
SaveManager:BuildConfigSection(Tabs['ui settings'])
ThemeManager:ApplyToTab(Tabs['ui settings'])
local ScreenGroup = Tabs.misc:AddRightGroupbox('aspect ratio')
ScreenGroup:AddToggle('Screen_AspectRatio', { Text = 'enabled', Default = false, Tooltip = 'stretch screen resolution locally' })
ScreenGroup:AddSlider('Screen_AspectRatioValue', { Text = 'ratio value', Default = 0.6, Min = 0.1, Max = 2.0, Rounding = 2, Compact = true })

local oldNewindex
oldNewindex = hookmetamethod(game, "__newindex", function(object, propertyName, propertyValue)
    if object == workspace.CurrentCamera and propertyName == "CFrame" and typeof(propertyValue) == "CFrame" then
        if Toggles.Screen_AspectRatio and Toggles.Screen_AspectRatio.Value then
            local ratio = Options.Screen_AspectRatioValue and Options.Screen_AspectRatioValue.Value or 0.6
            propertyValue = propertyValue * CFrame.new(0, 0, 0, 1, 0, 0, 0, ratio, 0, 0, 0, 1)
        end
    end
    return oldNewindex(object, propertyName, propertyValue)
end)

-- SaveManager:LoadAutoloadConfig() -- Отключил автозагрузку конфигов во избежания авто-бана
