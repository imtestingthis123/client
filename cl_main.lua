local serverLabs = {}
local labShell = {model = nil, prop = nil, coords = nil, heading = nil}
local doorSizes = {
  ["single"] = { w = 1.5, h = 2.5, d = 1 },
  ["double"] = { w = 3.0, h = 2.5, d = 1 },
}
local securityType = {
  [1] = "none",
  [2] = "key",
  [3] = "pincode",
}
local listOfDrugs = {}
for k, v in pairs(Config.Drugs) do
  for drugname in pairs(v.DrugProducts) do
    listOfDrugs[drugname] = true
  end
end

LabFunctions.DeleteShell = function()
  if not labShell.prop then return end
  DeleteEntity(labShell.prop)
  labShell.prop = nil
end

LabFunctions.SpawnShell = function()
  local timeout = 1000
  while not labShell.model or ( not HasModelLoaded(labShell.model) and timeout > 0 )do
    RequestModel(labShell.model)
    timeout = timeout - 1
    Citizen.Wait(100)
  end

  if timeout <= 0 then return end
  local shell = CreateObject(labShell.model, labShell.coords.x, labShell.coords.y, labShell.coords.z, false, false, false)
  SetEntityHeading(shell, labShell.heading - 180)
  FreezeEntityPosition(shell, true)
  SetEntityInvincible(shell, true)

  return shell
end

RegisterNetEvent('pandadrugs:cl:UpdateLab', function(labID, isOwned, owner, upgrades)

  serverLabs[labID] = {
    isOwned = isOwned,
    owner = owner,
    upgrades = upgrades,
  }


end)

RegisterNetEvent('pandadrugs:cl:UpdateAllLabs', function(_serverLabs)
  serverLabs = _serverLabs
  for drugName, details in pairs(Config.Drugs) do
    for locationName in pairs(details.Locations) do
      local labID = drugName .. ":" .. locationName
      LabFunctions.CreateEntranceDoor(labID)
    end
  end
end)

RegisterNetEvent('pandadrugs:cl:CreateShell', function(shell, shellCoords)
  local coords = vector3(shellCoords.x, shellCoords.y, shellCoords.z)
  local heading = shellCoords.w
  labShell.model = shell
  labShell.coords = coords
  labShell.heading = heading
end)


LabFunctions.TeleportToLab = function(coords)

  TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_open", 0.1)
  Wait(1000)
  if not coords then return end
  local playerPed = PlayerPedId()
  local playerCoords = SetEntityCoords(playerPed, coords.x, coords.y, coords.z-1.0)
  local playerHeading = SetEntityHeading(playerPed, coords.w - 180.0)
  SetGameplayCamRelativeHeading(playerHeading)
  Wait(800)
  DoScreenFadeIn(2000)
end

LabFunctions.GetConfig = function(labid)
  local drugName, _ = SplitId(labid)
  return Config.Drugs[drugName]
end

LabFunctions.GetLab = function(labid)
  local drugName, locationName = SplitId(labid)
  return Config.Drugs[drugName]["Locations"][locationName]
end

LabFunctions.Sell = function(labid)
  local retval = exports[Config.ResourceNames.input]:ShowInput({
    header = "Sell Lab",
    submitText = "Confirm",
    inputs = {
      {
        type = "number",
        text = "Enter ID of player you wish to sell to",
        name = "id",
      },
      {
        type = "number",
        name = "price",
        text = "Enter a price to sell the lab for",
      },
    }
  })
  local price = tonumber(retval.price)
  local id = tonumber(retval.id)
  TriggerServerEvent('pandadrugs:sv:SellLab', {id = id, price = price, labid = labid})
end

LabFunctions.IsOwned = function(labid)
  local IsOwned = serverLabs[labid] and serverLabs[labid].isOwned
  return IsOwned
end

LabFunctions.IsOwner = function(labid)
  local Player = QBCore.Functions.GetPlayerData()
  local CitizenID = Player.citizenid
  local Owner = serverLabs[labid] and serverLabs[labid].owner
  return CitizenID == Owner
end

LabFunctions.SyncUpgrades = function(serverlab)

  local labid = serverlab.id
  local upgrades = serverlab.upgrades
  serverLabs[labid].upgrades = upgrades
end

local exitDoor = nil
LabFunctions.CreateEntranceDoor = function(labid)
  local labData = LabFunctions.GetLab(labid)
  local DoorData = {
        {
            icon = 'fas fa-door-open',
            label = 'Enter Lab',
            action = function()
              LabFunctions.CheckSecurity(labid, function(canEnter)
                if not canEnter then return end
                TriggerServerEvent("pandadrugs:sv:Enter", labid)
                DoScreenFadeOut(1000)
                if labData.Shell then
                  labShell.prop = LabFunctions.SpawnShell()
                end
                LabFunctions.TeleportToLab(labData.Doors.Exit.coords)

                if not exitDoor or exitDoor ~= labid then
                  LabFunctions.DestroyExit(labid)
                  exitDoor = LabFunctions.CreateExitDoor(labid)
                end

              end)
            end,
            canInteract = function()
                return LabFunctions.IsOwned(labid)
            end,
        },
        {
            icon = 'fas fa-shopping-cart',
            label = 'Purchase Lab',
            action = function()
                exports[Config.ResourceNames.menu]:openMenu({
                    {
                      header = "Purchase Lab",
                      icon = "fas fa-shopping-cart",
                      isMenuHeader = true,
                    },
                    {
                      header = "Lab",
                      txt = "Price: $"..labData.Price,
                      disabled = true,
                    },
                    {
                      header = "Confirm Purchase",
                      icon = "fas fa-check",
                      params = {
                        isServer = true,
                        event = "pandadrugs:sv:BuyLab",
                        args = {labid = labid},
                      },
                    },
                    {
                      header = "Cancel",
                      icon = "fas fa-times",
                      event = "pandadrugs:menu:close",
                    },
                  })
            end,
            canInteract = function(entity)
                return not LabFunctions.IsOwned(labid)
            end,
        },
        {
            icon = 'fas fa-dollar-sign',
            label = 'Sell Lab',
            action = function(entity)
              LabFunctions.Sell(labid)
            end,
            canInteract = function(entity)
              local isOwner = LabFunctions.IsOwner(labid)
              return LabFunctions.IsOwner(labid)
            end,
        }
    }
    local ThisDoor = labData.Doors["Entrance"]
    local Coords = ThisDoor.coords
    local DoorSize = doorSizes[ThisDoor.size]
    exports[Config.ResourceNames.target]:AddBoxZone(labid..':Entrance', Coords, DoorSize.d, DoorSize.w, {
        name = labid..':Entrance',
        heading = Coords.w,
        debugPoly = false,
        minZ = Coords.z - 1,
        maxZ = Coords.z + 2,
      },
      {
        options = DoorData,
        distance = 2.5,
      }
    )
end

LabFunctions.CreateUpgradeMenu = function(labid)
  local configLab = LabFunctions.GetConfig(labid)
  local configUpgrades = configLab.Upgrades
  local labData = serverLabs[labid]
  local upgrades = labData.upgrades
  local UpgradeData = {}
  for upgradeName, upgrade in pairs(upgrades) do
    local id = #UpgradeData + 1
    local nextUpgrade = upgrade + 1
    if nextUpgrade <= #configUpgrades[upgradeName]  then
      UpgradeData[id] =  {
        header = "("..upgrade..")"..upgradeName .. " - $".. configUpgrades[upgradeName][nextUpgrade].price,
        icon = 'fas fa-arrow-up',
        label = tostring(upgradeName),
        params = {
          isServer = true,
          event = "pandadrugs:sv:UpgradeLab",
          args = {labid = labid, upgradeName = upgradeName},
        },
      }
    else
      UpgradeData[id] =  {
        header = "("..upgrade..")"..upgradeName .. " - Maxed",
        icon = 'fas fa-arrow-up',
        label = tostring(upgradeName),
        disabled = true,
      }
    end

  end
  exports[Config.ResourceNames.menu]:openMenu(UpgradeData)
end

LabFunctions.GetCurrentLab = function ()
  local Player = QBCore.Functions.GetPlayerData()
  local lab = Player.metadata["insideLab"].labID
  if not lab then return end
  local drugName, locationName = SplitId(lab)
  return Config.Drugs[drugName]["Locations"][locationName]
end

LabFunctions.CreateExitDoor = function(labid)
  Wait(1000)
  local labData = LabFunctions.GetLab(labid)
  local DoorData = {
      {
          icon = 'fas fa-door-open',
          label = 'Exit Lab',
          action = function()
            local currentLab = LabFunctions.GetCurrentLab() or nil
            DoScreenFadeOut(1000)
            LabFunctions.TeleportToLab(currentLab and currentLab.Doors and currentLab.Doors.Entrance and currentLab.Doors.Entrance.coords or labData.Doors.Entrance.coords)
            TriggerServerEvent("pandadrugs:sv:Exit", labid)
            if labData.Shell then
              LabFunctions.DeleteShell()
            end
          end,
      },
      {
          icon = 'fas fa-calculator',
          label = 'Set Pincode',
          action = function()
              local retData = exports[Config.ResourceNames.input]:ShowInput({
                  header = "Set Pin",
                  submitText = "Confirm",
                  inputs = {
                    {
                      type = "number",
                      name = "pin",
                      text = "Enter a new pin for the lab",
                    },
                  },
                })
              if not retData or not retData.pin then return end
              newPin = tonumber(retData.pin)
              TriggerServerEvent("pandadrugs:sv:SetPin", labid, newPin)
          end,
          canInteract = function()
              local Player = QBCore.Functions.GetPlayerData()
              local CitizenID = Player.citizenid
              return LabFunctions.GetSecurity(labid) == "pincode" and LabFunctions.IsOwner(labid, CitizenID)
          end
      },
      {
          icon = 'fas fa-key',
          label = 'Buy Key',
          action = function(entity)
              TriggerServerEvent('pandadrugs:sv:BuyKey', labid)
          end,
          canInteract = function(entity)
              return  LabFunctions.GetSecurity(labid) == "key" and LabFunctions.IsOwner(labid)
          end
      },
      {
          icon = 'fas fa-arrow-up',
          label = 'Upgrade Lab',
          action = function(entity)
            LabFunctions.CreateUpgradeMenu(labid)

          end,
          canInteract = function(entity)
            local isOwner = LabFunctions.IsOwner(labid)
              return isOwner
          end
      }
  }

    local ThisDoor = labData.Doors["Exit"]
    local Coords = ThisDoor.coords
    local DoorSize = doorSizes[ThisDoor.size]

    exports[Config.ResourceNames.target]:AddBoxZone(labid..':Exit', Coords, DoorSize.d, DoorSize.w, {
      name = labid..':Exit',
      heading = Coords.w,
      debugPoly = false,
      minZ = Coords.z - 1,
      maxZ = Coords.z + 2,
    },
    {
      options = DoorData,
      distance = 2.5,
    }
  )
  LabFunctions.CreateTester(labid)
  return labid
end

LabFunctions.CreateTester = function(labid)

  local labData = LabFunctions.GetLab(labid)
  local TesterLocation = labData.TesterLocation
  local TesterData = {
    {
      icon = 'fas fa-flask',
      label = 'Test Drugs',
      action = function()
        local Player = QBCore.Functions.GetPlayerData()
        local Inv = Player.items
        local Drugs = {}
        for k, v in pairs(Inv) do
          if listOfDrugs[v.name] == true then
            Drugs[#Drugs+1] = v
          end
        end


        table.sort(Drugs, function(a, b)
          return a.slot < b.slot
        end)


        SetNuiFocus(true, true)
        SendNUIMessage({
          action = "openTester",
          drugItems = Drugs,
        })
      end,
    },
  }

  exports[Config.ResourceNames.target]:AddBoxZone(labid..':Tester', TesterLocation.xyz, 1.5, 1.5, {
    name = labid..':Tester',
    heading = TesterLocation.w,
    debugPoly = false,
    minZ = TesterLocation.z - 1,
    maxZ = TesterLocation.z + 2,
  },
  {
    options = TesterData,
    distance = 2.5,
  })
end

LabFunctions.DestroyTester = function(labid)
  exports[Config.ResourceNames.target]:RemoveZone(labid..':Tester')
end

LabFunctions.DestroyExit = function(labid)
  exports[Config.ResourceNames.target]:RemoveZone(labid..':Exit')
  LabFunctions.DestroyTester(labid)
end

LabFunctions.DestroyEntrance = function(labid)
  exports[Config.ResourceNames.target]:RemoveZone(labid..':Entrance')
end

LabFunctions.HasKey = function(labid, cb)
  QBCore.Functions.TriggerCallback('pandadrugs:cb:HasKey', function(hasKey)
      if not hasKey then return QBCore.Functions.Notify("You don't have the key for this lab", "error") end
      if cb then cb(true) end
  end, labid)
end

LabFunctions.GetSecurity = function(labid)
  local security = serverLabs[labid] and serverLabs[labid].upgrades and serverLabs[labid].upgrades and serverLabs[labid].upgrades["Security Upgrade"]
  return securityType[security]
end

LabFunctions.CheckSecurity = function(labid, cb)
  local security = LabFunctions.GetSecurity(labid)
  if not security or security == 'none' then return cb(true) end
  if security == "pincode" then
    SetNuiFocus(true, true)
    SendNUIMessage({
      action = "openPincodeMenu",
      labid = labid,
    })
  elseif security == "key" then
    LabFunctions.HasKey(labid, cb)
  end
end

RegisterNetEvent('pandadrugs:cl:EnsureExit', function(labID)
  if exitDoor and exitDoor == labID then return end

  LabFunctions.DestroyExit(labID)
  Wait(1000)
  LabFunctions.CreateExitDoor(labID)
end)

AddEventHandler('onResourceStop', function(resourceName)
  if (GetCurrentResourceName() ~= resourceName) then
    return
  end
  for labID, labData in pairs(serverLabs) do
    LabFunctions.DestroyEntrance(labID)
    LabFunctions.DestroyExit(labID)
  end
  Factory.DestroyAll()
  Target.RemoveAll()
end)

RegisterNetEvent('pandadrugs:cl:UpgradeLab', LabFunctions.SyncUpgrades)
RegisterNetEvent('pandadrugs:cl:BuyKeysMenu', BuyKeysMenu)

RegisterCommand("resetfade", function()
  DoScreenFadeIn(1000)
end)

RegisterCommand("getoffset", function()
  local playerPed = PlayerPedId()
  local playerCoords = GetEntityCoords(playerPed)
  if not labShell.prop then return end
  local shellCoords = GetEntityCoords(labShell.prop)
  local offset = vector3(playerCoords.x - shellCoords.x, playerCoords.y - shellCoords.y, playerCoords.z - shellCoords.z)
  local corrected = vector4(-offset.x, -offset.y, -offset.z, 0.0)
  print(corrected)
end, false)

TriggerServerEvent('pandadrugs:sv:ClientLoaded')