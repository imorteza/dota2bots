----------------------------------------------------------------------------------------------------

local Abilities = {
  "keeper_of_the_light_illuminate",
  "keeper_of_the_light_mana_leak",
  "keeper_of_the_light_chakra_magic",
  "keeper_of_the_light_recall",
  "keeper_of_the_light_blinding_light",
  "keeper_of_the_light_spirit_form",
  "keeper_of_the_light_illuminate_end",
  "keeper_of_the_light_spirit_form_illuminate",
  "keeper_of_the_light_spirit_form_illuminate_end",
};

local Helper = require(GetScriptDirectory() .. "/helper");

function AbilityUsageThink()

  local npcBot = GetBot();

  Helper.InspectBotMode(npcBot);

  local wave = npcBot:GetAbilityByName(Abilities[1]);
  local leak = npcBot:GetAbilityByName(Abilities[2]);
  local mana = npcBot:GetAbilityByName(Abilities[3]);
  local ult = npcBot:GetAbilityByName(Abilities[6]);

  local creeps = npcBot:GetNearbyCreeps(1500, true)
  local enemyHeroes = npcBot:GetNearbyHeroes(600, true, BOT_MODE_NONE)

  local function considerManaLeak()
    if leak:IsFullyCastable() and npcBot:GetMana() - leak:GetManaCost() > mana:GetManaCost() then
      local enemyHero = Helper.GetHeroWith(npcBot, 'min', 'GetHealth', leak:GetCastRange(), true);
      if enemyHero ~= nil then
        return npcBot:Action_UseAbilityOnEntity(leak, enemyHero);
      end
    end
  end

  if npcBot:IsChanneling() then
    if #enemyHeroes >= 2 or npcBot:GetActiveMode() == BOT_MODE_RETREAT then
      return npcBot:Action_UseAbility(wave);
    else
      return;
    end
  end

  if #enemyHeroes >= 2 or npcBot:GetActiveMode() == BOT_MODE_RETREAT then
    return considerManaLeak();
  end

  if wave:IsFullyCastable() and npcBot:GetMana() > mana:GetManaCost() and npcBot:GetActiveMode() ~= BOT_MODE_RETREAT then
    if #creeps >= 3 then
      local neutralCreeps = 0;
      local castTarget = nil;
      for _, creep in pairs(creeps) do
        if (creep ~= nil) then
          if string.find(creep:GetUnitName(), 'neutral') then
            neutralCreeps = neutralCreeps + 1;
          else
            castTarget = creep;
          end
        end
      end
      if castTarget ~= nil and #creeps - neutralCreeps > 0 then
        return npcBot:Action_UseAbilityOnLocation(wave, castTarget:GetLocation());
      end
    end
  end

  considerManaLeak();

  -- if ult:IsFullyCastable() and npcBot:GetMana() - ult:GetManaCost() > waveAndManaCombo then
  --   npcBot:Action_UseAbility(ult);
  -- end
  if mana:IsFullyCastable() then
    local target = Helper.GetHeroWith(npcBot, 'min', 'GetMana', mana:GetCastRange(), false);
    return npcBot:Action_UseAbilityOnEntity(mana, target);
  end

end

----------------------------------------------------------------------------------------------------

function ItemUsageThink()

  local npcBot = GetBot();

  if npcBot:IsChanneling() then
    return;
  end

  local teammates = npcBot:GetNearbyHeroes(900, false, BOT_MODE_NONE);
  local enemies = npcBot:GetNearbyHeroes(900, true, BOT_MODE_NONE);

  for i = 0,5 do
    local item = npcBot:GetItemInSlot(i);

    if (item) and string.find(item:GetName(), "item_necronomicon") and enemies ~= nil and #enemies >= 1 then
      if (item:IsFullyCastable()) then
        npcBot:Action_UseAbility(item);
      end
    end

    if (item) and string.find(item:GetName(), "item_dagon") and enemies ~= nil and #enemies >= 1 then
      if (item:IsFullyCastable()) then
        local weakestEnemy = Helper.GetHeroWith(npcBot, 'min', 'GetHealth', item:GetCastRange(), true);
        if (weakestEnemy ~= nil) then
          npcBot:Action_UseAbilityOnEntity(item, weakestEnemy);
        end
      end
    end

    if (item) and (item:GetName() == "item_tpscroll" or item:GetName() == "item_travel_boots") and item:IsFullyCastable() then

      local tower = nil;
      local laneFront = nil;

      if npcBot:GetActiveMode() == BOT_MODE_DEFEND_TOWER_BOT then
        tower = Helper.GetOutermostTower(GetTeam(), LANE_BOT);
        laneFront = GetLaneFrontLocation(GetTeam(), LANE_BOT, 0.0);
      end

      if npcBot:GetActiveMode() == BOT_MODE_DEFEND_TOWER_MID then
        tower = Helper.GetOutermostTower(GetTeam(), LANE_MID);
        laneFront = GetLaneFrontLocation(GetTeam(), LANE_MID, 0.0);
      end

      if npcBot:GetActiveMode() == BOT_MODE_DEFEND_TOWER_TOP then
        tower = Helper.GetOutermostTower(GetTeam(), LANE_TOP);
        laneFront = GetLaneFrontLocation(GetTeam(), LANE_TOP, 0.0);
      end

      if tower ~= nil then
        local distanceToTower = GetUnitToLocationDistance(npcBot, tower:GetLocation());
        local distanceToLaneFront = GetUnitToLocationDistance(npcBot, laneFront);
        if distanceToTower >= 5000.0 and distanceToLaneFront > 5000.0 then
          local offset = Vector(-500, -500);
          if (GetTeam() == TEAM_DIRE) then
            offset = Vector(500, 500)
          end
          return npcBot:Action_UseAbilityOnLocation(item, tower:GetLocation() + offset);
        end
      end
    end

    if (item) and (item:GetName() == "item_mekansm" or item:GetName() == "item_pipe") then
      if item:IsFullyCastable() and teammates ~= nil and #teammates >=2 then
        if npcBot:GetHealth() <= 400 then
          npcBot:Action_UseAbility(item);
        end
        for _, hero in pairs(teammates) do
          if (hero:GetHealth() <= 400) then
            npcBot:Action_UseAbility(item);
            break;
          end
        end
      end
    end

    if (item) and item:GetName() == "item_phase_boots" then
      if (item:IsFullyCastable()) then
        npcBot:Action_UseAbility(item);
      end
    end

    if (item) and item:GetName() == "item_shivas_guard" then
      if (item:IsFullyCastable() and enemies ~= nil and #enemies >= 2) then
        npcBot:Action_UseAbility(item);
      end
    end

    if (item) and (item:GetName() == "item_invis_sword" or item:GetName() == "item_silver_edge") then
      if item:IsFullyCastable() and
        npcBot:GetActiveMode() == BOT_MODE_RETREAT and
        npcBot:DistanceFromFountain() > 1500 then
        npcBot:Action_UseAbility(item);
      end
    end

    if (item) and item:GetName() == "item_courier" then
      if (item:IsFullyCastable()) then
        npcBot:Action_UseAbility(item);
      end
    end

    if (item) and item:GetName() == "item_flask" then
      if (item:IsFullyCastable() and npcBot:GetHealth() <= 200) then
        npcBot:Action_UseAbilityOnEntity(item, npcBot);
      end
    end

    if (item) and item:GetName() == "item_clarity" then
      if (item:IsFullyCastable() and npcBot:GetMana() <= 200) then
        npcBot:Action_UseAbilityOnEntity(item, npcBot);
      end
    end
  end

end