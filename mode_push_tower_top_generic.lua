local Helper = require(GetScriptDirectory() .. "/helper");

function GetDesire()
  return Helper.GetPushDesire(GetBot(), LANE_TOP);
end

function OnStart()

  local npcBot = GetBot();
  npcBot:Action_Chat("Pushing Top", true);

end

function Think()
  Helper.PushThink(GetBot(), LANE_TOP);
end