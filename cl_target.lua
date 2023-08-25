
Target = {}

Target.TargetProps = {}
Target.Count = 0

function Target.Get(id)
    return Target.TargetProps[id]
end

function Target.Set(id, key, data)
    local self = Target.Get(id)
    if self == nil then return end
    Target.TargetProps[id][key] = data
end

function Target.GetTargetProps()
    return Target.TargetProps
end

function Target.Create(model, position, rotationOffset, size, bucket)
    local self = {}
    self.id = CreateUniqueId(8, "TargetProp:")
    self.targetId = nil
    self.model = model
    self.position = position
    self.size = size or vector3(1.0, 1.0, 1.0)
    self.rotationOffset = rotationOffset
    self.bucket = bucket
    self.prop = nil
    self.options = {}
    self.spawned = false
    self._labels = {}
    local options = {}
    Target.TargetProps[self.id] = self
    Target.Count = Target.Count + 1

    return self.id
end

function Target.GetOptionIndex(id, optionId)
    local self = Target.Get(id)
    if self == nil then return end
    return self._labels[optionId]
end

function Target.AddOption(id, label, icon, event, args, isServer)
    local self = Target.Get(id)
    if self == nil then return end
    local option = {}
    option.type = isServer and 'server' or 'client'
    option.event = event
    option.icon = icon
    option.label = label
    option.args = args
    local optionIndex = #self.options + 1
    local optionId = option.label
    self.options[optionIndex] = option
    self._labels[optionId] = optionIndex
    Target.Set(id, 'options', self.options)
    Target.Set(id, '_labels', self._labels)
    Target.Refresh(id)
    return optionId
end

function Target.RemoveOption(id, optionId)
    local self = Target.Get(id)
    if not self then return end
    local optionIndex = Target.GetOptionIndex(id, optionId)
    if not optionIndex then return end
    self.options[optionIndex] = nil
    Target.Set(id, 'options', self.options)
    Target.Refresh(id)
end

function Target.RemoveAllOptions(id)
    Target.Set(id, 'options', {})
    Target.Set(id, '_labels', {})
    Target.Refresh(id)
end

function Target.CreateBoxZone(id)
    local self = Target.Get(id)
    if not self then return end
    local x, y, z = self.position.x, self.position.y, self.position.z
    local sx, sy, sz = self.size.x, self.size.y, self.size.z
    exports[Config.ResourceNames.target]:AddBoxZone(self.id, vector3(x, y, z), sx, sy, {
        name = self.id,
        heading = self.rotationOffset.z,
        debugPoly = false,
        minZ = z - sz/2,
        maxZ = z + sz/2,
        }, {
        options = self.options,
        distance = 2.5,
        })
    return self.id
end


function Target.SpawnProp(id)
    local self = Target.Get(id)
    if not self then return end
    local model = self.model
    if type(model) == 'string' then
        model = GetHashKey(model)
    end
    local position = self.position
    local rotationOffset = self.rotationOffset
    local bucket = self.bucket
    local timeout = 1000
    while not HasModelLoaded(model) and timeout > 0 do
        RequestModel(model)
        timeout = timeout - 1
        Wait(10)
    end
    if timeout <= 0 then return end
    local prop =  CreateObject(model, position.x, position.y, position.z, false, false)
    SetEntityRotation(prop, rotationOffset.x, rotationOffset.y, rotationOffset.z, 2, true)
    SetEntityCollision(prop, true, true)
    FreezeEntityPosition(prop, true)
    Target.Set(id, 'prop', prop)
    return prop
end

function Target.RemoveProp(id)

    local self = Target.Get(id)
    if self == nil then return end
    local prop = self.prop
    if prop then
        exports[Config.ResourceNames.target]:RemoveTargetEntity(self.id)
        SetEntityAsNoLongerNeeded()
        DeleteEntity(prop)
    end
end

function Target.ChangeProp(id, model)
    local self = Target.Get(id)
    if not self then return end
    local prop = self.prop
    if prop then
        DeleteEntity(prop)
    end
    self.model = model
    Target.Refresh(id)
end


function Target.BuildProp(id)
    local self = Target.Get(id)
    if not self then return end
    if self.prop then Target.RemoveProp(id) end
    self.prop = Target.SpawnProp(id)

    local target = exports[Config.ResourceNames.target]:AddTargetEntity(self.prop, {
        options = self.options,
        distance = 2.5
    })
    Target.Set(id, 'targetId', target)
end

function Target.BuildBox(id)
    local self = Target.Get(id)
    if not self then return end
    local target = self.targetId
    if target then
        exports[Config.ResourceNames.target]:RemoveZone(target)
    end
    self.targetId = Target.CreateBoxZone(id)
    Target.Set(id, 'targetId', self.targetId)
end
function Target.RemoveBox(id)

    local self = Target.Get(id)
    if not self then return end
    exports[Config.ResourceNames.target]:RemoveZone(self.id)
end

function Target.Build(id)
    local self = Target.Get(id)
    if not self then return end
    if self.model then
        Target.BuildProp(id)
    else
        Target.BuildBox(id)
    end
    self.spawned = true
    Target.Set(id, 'spawned', true)
end

function Target.Remove(id)
    local self = Target.Get(id)
    if not self then return end
    if self.prop then
        Target.RemoveProp(id)
    else
        Target.RemoveBox(id)
    end
end

function Target.RemoveAll()
    for id, _ in pairs(Target.TargetProps) do
        Target.Remove(id)
    end
end

function Target.Refresh(id)
    local self = Target.Get(id)
    if self == nil then return end
    if self.targetId or self.prop then
        Target.Remove(id)
    end
    Wait(1000)
    Target.Build(id)
end

function Target.Destroy(id)
    Target.Remove(id)
    Target.TargetProps[id] = nil
end


