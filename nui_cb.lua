RegisterNUICallback("checkPincode", function(data, cb)
    local labid = data.labid
    local labData = LabFunctions.GetLab(labid)
    local exitDoor = labData.Doors and labData.Doors.Exit
    local coords = exitDoor and exitDoor.coords
    local pincode = data.pincode
    QBCore.Functions.TriggerCallback('pandadrugs:cb:GetPin', function(success)
        cb(success)
        Wait(500)
        if success then
            SetNuiFocus(false, false)
            LabFunctions.TeleportToLab(coords)
            LabFunctions.CreateExitDoor(labid)
            TriggerServerEvent("pandadrugs:sv:Enter", labid)
        end
    end, labid, pincode)
end)

RegisterNUICallback("close", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("testDrug", function(data, cb)
    QBCore.Functions.TriggerCallback('pandadrugs:cb:TestDrug', function(success)
        cb(success)
    end, data.drug)
end)