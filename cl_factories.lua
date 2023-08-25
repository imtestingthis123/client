QBCore = QBCore or exports['qb-core']:GetCoreObject()
Factory = {}
Factories = {}

function Factory.Get(id)
    return Factories[id]
end

function Factory.Set(id, key, data)
    local self = Factory.Get(id)
    if self == nil then return end
    Factories[id][key] = data
end

function Factory.GetFactories()
    return Factories
end

function Factory.GetConfigFactory(drugName, configId)
    return Config.Drugs[drugName] and Config.Drugs[drugName].Factories[configId]
end

function Factory.Destroy(id)
    local self = Factory.Get(id)
    if self == nil then return end
    Target.Destroy(self.target)
    Factories[id] = nil
end

function Factory.DestroyAll()
    for id, _ in pairs(Factories) do
        Factory.Destroy(id)
    end
end

function Factory.GetConfigRecipies(id)
    local self = Factory.Get(id)
    if not Config.Drugs[self.drugName] then return end
    if not Config.Drugs[self.drugName].Factories then return end
    if not Config.Drugs[self.drugName].Factories[self.configId] then return end
    if not Config.Drugs[self.drugName].Factories[self.configId].recipes then return end
    return Config.Drugs[self.drugName].Factories[self.configId].recipes
end

function Factory.GetConfigRecipieData(id)
    local self = Factory.Get(id)
    local recipeList = Factory.GetConfigRecipies(id)
    local retTable = {}
    for _, v in pairs(recipeList) do
        retTable[v] = Config.Drugs[self.drugName].Recipes[v]
    end
    return retTable
end

function Factory.GetConfigFactories(drugName)
    return Config.Drugs[drugName] and Config.Drugs[drugName].Factories
end

function Factory.GetConfigUpgrades(drugName)
    return Config.Drugs[drugName] and Config.Drugs[drugName].Upgrades
end

function Factory.GetConfigUpgrade(drugName, configId)
    local config = Factory.GetConfigUpgrades(drugName)
    return config[configId]
end

function Factory.Create(serverFactory)
    local self = {}
    self.id = serverFactory.id
    self.drugName = serverFactory.drugName
    self.configId = serverFactory.configId
    self.upgrades = serverFactory.upgrades
    local factoryConfig = Factory.GetConfigFactory(self.drugName, self.configId)
    assert(factoryConfig, "Factory Config doesnt exist")
    local model = factoryConfig.prop
    local coords = factoryConfig.coords

    local rotation = factoryConfig.rotation or vector3(0.0, 0.0, 0.0)
    local size = factoryConfig.size
    local bucket = serverFactory.bucket
    self.target = Target.Create(model, coords, rotation, size, bucket)
    Factories[self.id] = self

    Factory.AddConfigOptions(self.id, self.drugName)

    Target.Refresh(self.target)
    return self.id
end

function Factory.AddConfigOptions(id, drugName)
    local self = Factory.Get(id)
    assert(self, "Factory doesnt exist")
    local factoryConfig = Factory.GetConfigFactory(self.drugName, self.configId)
    assert(factoryConfig, "Factory Config doesnt exist")
    local recipes = Factory.GetConfigRecipieData(id)
    assert(recipes, "Factory Recipes doesnt exist")
    for k, v in pairs(recipes) do
        local label = v.label
        local icon = v.icon
        Target.AddOption(self.target, label, icon, "pandadrug:cl:UseFactory", {id = self.id, recipe = k}, false)
    end
end

RegisterNetEvent("pandadrug:cl:UseFactory", function(data)
    local self = Factory.Get(data.args.id)
    local drugName = self.drugName
    local Upgrades = self.upgrades
    local speedMultiplier = Upgrades["Production Speed"] or 1
    local recipe = data.args.recipe
    local recipes = Factory.GetConfigRecipieData(data.args.id)
    local recipeData = recipes[recipe]
    local manufacturingTime = recipeData.manufacturingTime or 10000
    local duration = manufacturingTime * speedMultiplier
    local reqItems = recipeData.requiredItems
    local Player = QBCore.Functions.GetPlayerData()
    local items = {}
    for k, v in pairs(Player.items) do
        if not items[v.name] then
            items[v.name] = v.amount
        else
            items[v.name] = items[v.name] + v.amount
        end
    end
    for k, v in pairs(reqItems) do
        local item = k
        local amount = v
        if items[item] == nil then
            return QBCore.Functions.Notify("You dont have the required items on you.", "error")
        end
        if items[item] < amount then
            return QBCore.Functions.Notify("You dont have the required amount of items on you.", "error")
        end
    end
    print("Using factory", duration, manufacturingTime, speedMultiplier, recipe)
    QBCore.Functions.Progressbar('usefactory', 'Working...', duration, false, true, {
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'anim@gangops@facility@servers@',
        anim = 'hotwire',
        flags = 16,
    }, {}, {}, function()
        ClearPedTasksImmediately(PlayerPedId())
        TriggerServerEvent("pandadrug:sv:UseFactory", self.id, recipe)
    end, function()
        QBCore.Functions.Notify("Canceled", "error")
    end)

end)

RegisterNetEvent("pandadrug:cl:CreateFactory", function(serverFactory)
    local id = serverFactory.id
    local drugName = serverFactory.drugName
    local configId = serverFactory.configId
    local factoryConfig = Factory.GetConfigFactory(drugName, configId)
    local factoryId = Factory.Create(serverFactory)
end)

RegisterNetEvent("pandadrug:cl:UpgradeFactory", function(serverFactory)
    local id = serverFactory.id
    local drugName = serverFactory.drugName
    local configId = serverFactory.configId
    local factoryUpgrades = serverFactory.upgrades
    local upgrades = {}
    for k, v in pairs(factoryUpgrades) do
        upgrades[k] = v

    end
    Factory.Set(id, 'upgrades', upgrades)
end)