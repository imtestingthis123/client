local cache = {
  peds = {},
}

DrugEffects = {}

DrugEffects["SprintSpeed"] = function(speed, duration)
  CreateThread(function()
  if speed > 1.49 then speed = 1.49 end
    SetRunSprintMultiplierForPlayer(PlayerId(), speed)
    Wait(duration or 10000)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
  end)
end

DrugEffects["JumpPower"] = function(power, duration)
  CreateThread(function()
    local active = true
    local timeOut = duration or 10000
    local time = duration
    SetTimeout(duration, function()
      active = false
    end)
    while active do
      if IsControlJustPressed(0, 22) then
        SetEntityVelocity(PlayerPedId(), 0.0, 0.0, 0.0 + power)
      end
      Wait(1)
    end
  end)

end

DrugEffects["Health"] = function(increaseAmount, duration)
  local Healing = true
  local increasePerSecond = increaseAmount / (duration / 1000)
  CreateThread(function()
    SetTimeout(duration, function()
      Healing = false
    end)
    while Healing do
      local health = GetEntityHealth(PlayerPedId())
      if health < 200 then
        SetEntityHealth(PlayerPedId(), health + increasePerSecond)
      else
        Healing = false
      end
      Wait(1000)
    end
  end)
end

DrugEffects["Armor"] = function(increaseAmount, duration)
  local Armouring = true
  local increasePerSecond = increaseAmount / (duration / 1000)
  SetTimeout(duration, function()
    Armouring = false
  end)
  CreateThread(function()
    while Armouring do
      local armor = GetPedArmour(PlayerPedId())
      if armor < 100 then
        SetPedArmour(PlayerPedId(), armor + increasePerSecond)
      else
        Armouring = false
      end
      Wait(1000)
    end
  end)
end

DrugEffects["Peds"] = function(pedData, duration)
  local quantity = pedData.quantity or 5
  local _model = pedData.model or "a_c_hen"
  local maxDistance = pedData.maxDistance or 10.0

  local model = GetHashKey(_model)
  local timeOut = 2000

  RequestModel(model)
  while not HasModelLoaded(model) and timeOut > 0 do
    Wait(0)
  end

  if timeOut <= 0 then return end

  local delay = 1500
  Wait(delay)
  CreateThread(function()
    for i = 1, quantity, 1 do
      if maxDistance < 10 then maxDistance = 10 end
      if maxDistance > 30 then maxDistance = 30 end
      local coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), math.random(-3.0, 3.0), math.random(10.0, maxDistance), 5.0)
      local pedHead = GetEntityHeading(PlayerPedId())
      local cPed = CreatePed(26, model, coords, 0.0, false, false)
      SetEntityCompletelyDisableCollision(cPed, true, true)
      SetEntityCollision(cPed, false, false)
      SetModelAsNoLongerNeeded(model)
      SetEntityAsMissionEntity(cPed, true, true)
      SetEntityInvincible(cPed, true)
      SetBlockingOfNonTemporaryEvents(cPed, true)
      SetPedFleeAttributes(cPed, 0, 0)
      SetPedCombatAttributes(cPed, 17, 1)
      SetEntityHeading(cPed, pedHead + math.random(0.0, 360.0))
      cache.peds[#cache.peds + 1] = cPed
      Wait((duration-delay)/quantity)
    end
  end)
  Wait(duration)
  for i = 1, #cache.peds, 1 do
    DeleteEntity(cache.peds[i])
  end
end

DrugEffects["FX"] = function(fx, time)
  CreateThread(function()
    DoScreenFadeOut(1000)
    Wait(1000)
    AnimpostfxPlay(fx, time, true)
    DoScreenFadeIn(1000)
    Wait(time)
    DoScreenFadeOut(1000)
    Wait(1000)
    AnimpostfxStop(fx)
    DoScreenFadeIn(1000)
  end)
end

RegisterNetEvent('DrugEffects:StartEffect', function(effect, data, duration)
  DrugEffects[effect](data, duration)
end)

function StartEffect(itemName, effects, metadata)
  local purity = metadata.purity or Config.Drugs[metadata.drugName].DrugProducts[itemName].fallbackInfo.purity or 0.1
  for effectName in pairs(DrugEffects) do
    if effects[effectName] then
        TriggerEvent("DrugEffects:StartEffect", effectName, effects[effectName], effects.Duration * (1 + purity))
    end
  end
end

local effects = {
"BeastIntroScene",
"BeastLaunch",
"BeastTransition",
"BikerFilter",
"BikerFilterOut",
"BikerFormation",
"BikerFormationOut",
"CamPushInFranklin",
"CamPushInMichael",
"CamPushInNeutral",
"CamPushInTrevor",
"ChopVision",
"CrossLine",
"CrossLineOut",
"DeadlineNeon",
"DeathFailFranklinIn",
"DeathFailMichaelIn",
"DeathFailMPDark",
"DeathFailMPIn",
"DeathFailNeutralIn",
"DeathFailOut",
"DeathFailTrevorIn",
"DefaultFlash",
"DMT_flight",
"DMT_flight_intro",
"Dont_tazeme_bro",
"DrugsDrivingIn",
"DrugsDrivingOut",
"DrugsMichaelAliensFight",
"DrugsMichaelAliensFightIn",
"DrugsMichaelAliensFightOut",
"DrugsTrevorClownsFight",
"DrugsTrevorClownsFightIn",
"DrugsTrevorClownsFightOut",
"ExplosionJosh3",
"FocusIn",
"FocusOut",
"HeistCelebEnd",
"HeistCelebPass",
"HeistCelebPassBW",
"HeistCelebToast",
"HeistLocate",
"HeistTripSkipFade",
"InchOrange",
"InchOrangeOut",
"InchPickup",
"InchPickupOut",
"InchPurple",
"InchPurpleOut",
"LostTimeDay",
"LostTimeNight",
"MenuMGHeistIn",
"MenuMGHeistIntro",
"MenuMGHeistOut",
"MenuMGHeistTint",
"MenuMGIn",
"MenuMGSelectionIn",
"MenuMGSelectionTint",
"MenuMGTournamentIn",
"MenuMGTournamentTint",
"MinigameEndFranklin",
"MinigameEndMichael",
"MinigameEndNeutral",
"MinigameEndTrevor",
"MinigameTransitionIn",
"MinigameTransitionOut",
"MP_Bull_tost",
"MP_Bull_tost_Out",
"MP_Celeb_Lose",
"MP_Celeb_Lose_Out",
"MP_Celeb_Preload",
"MP_Celeb_Preload_Fade",
"MP_Celeb_Win",
"MP_Celeb_Win_Out",
"MP_corona_switch",
"MP_intro_logo",
"MP_job_load",
"MP_Killstreak",
"MP_Killstreak_Out",
"MP_Loser_Streak_Out",
"MP_OrbitalCannon",
"MP_Powerplay",
"MP_Powerplay_Out",
"MP_race_crash",
"MP_SmugglerCheckpoint",
"MP_TransformRaceFlash",
"MP_WarpCheckpoint",
"PauseMenuOut",
"pennedIn",
"PennedInOut",
"PeyoteEndIn",
"PeyoteEndOut",
"PeyoteIn",
"PeyoteOut",
"PPFilter",
"PPFilterOut",
"PPGreen",
"PPGreenOut",
"PPOrange",
"PPOrangeOut",
"PPPink",
"PPPinkOut",
"PPPurple",
"PPPurpleOut",
"RaceTurbo",
"Rampage",
"RampageOut",
"SniperOverlay",
"SuccessFranklin",
"SuccessMichael",
"SuccessNeutral",
"SuccessTrevor",
"switch_cam_1",
"switch_cam_2",
"SwitchHUDFranklinIn",
"SwitchHUDFranklinOut",
"SwitchHUDIn",
"SwitchHUDMichaelIn",
"SwitchHUDMichaelOut",
"SwitchHUDOut",
"SwitchHUDTrevorIn",
"SwitchHUDTrevorOut",
"SwitchOpenFranklin",
"SwitchOpenFranklinIn",
"SwitchOpenFranklinOut",
"SwitchOpenMichaelIn",
"SwitchOpenMichaelMid",
"SwitchOpenMichaelOut",
"SwitchOpenNeutralFIB5",
"SwitchOpenNeutralOutHeist",
"SwitchOpenTrevorIn",
"SwitchOpenTrevorOut",
"SwitchSceneFranklin",
"SwitchSceneMichael",
"SwitchSceneNeutral",
"SwitchSceneTrevor",
"SwitchShortFranklinIn",
"SwitchShortFranklinMid",
"SwitchShortMichaelIn",
"SwitchShortMichaelMid",
"SwitchShortNeutralIn",
"SwitchShortNeutralMid",
"SwitchShortTrevorIn",
"SwitchShortTrevorMid",
"TinyRacerGreen",
"TinyRacerGreenOut",
"TinyRacerIntroCam",
"TinyRacerPink",
"TinyRacerPinkOut",
"WeaponUpgrade",
}

RegisterNetEvent("onResourceStop", function()
  if GetCurrentResourceName() ~= "pandadrugs" then return end
  for i = 1, #cache.peds, 1 do
    DeleteEntity(cache.peds[i])
  end
end)

RegisterCommand("fx", function(source, args)
  AnimpostfxStopAll()
  local fx = effects[tonumber(args[1])]
  local time = tonumber(args[2]) or 10000
  if not fx then return end
  if not time then time = 10000 end
  AnimpostfxPlay(fx, time, true)
end)