-- BullWar: stance-aware Fury / Arms warrior helper for the 1.12 client (OctoWoW).
-- BW.Main / BW.AoE pick the Fury or Arms logic from your talents (/bw spec to override).
-- No SuperWoW needed. Each key press does at most one thing (one cast or one
-- stance change; the optional auto Bloodrage is the only extra), so you stay in control. Macros call the BW.* functions.
--
--   /run BW.Main()   Fury: Shout > Demo (elites) > Execute > Bloodthirst > Whirlwind > Overpower (in gaps) > Heroic Strike
--                    Arms: Shout > Demo (elites) > Execute > Overpower > Mortal Strike > Rend > Whirlwind trip > Slam > Heroic Strike
--   /run BW.AoE()    Fury: Shout > Whirlwind > Demoralizing Shout > Overpower (in gaps) > Cleave > Bloodthirst
--                    Arms: Shout > Sweeping Strikes > Whirlwind > Demoralizing Shout > Cleave > Mortal Strike
--   /run BW.Charge()      out of combat: Battle Stance + Charge; in combat: Berserker Stance + Intercept
--   /run BW.Overpower()   go to Battle Stance (only if it wastes little rage) and Overpower
--   /run BW.Pummel()      Pummel, leaving Defensive Stance first if needed
--   /run BW.Do("Thunder Clap", "Battle Stance")       any spell with its stance
--   /run BW.Do("Berserker Rage", "Berserker Stance", 1)  third argument 1 = switch even if rage is lost
--
-- Hold Shift while pressing to force a stance switch that would waste rage.
-- Slash: /bw  (show settings), /bw hs 60, /bw cleave 40, /bw slack 10, /bw op on|off, /bw demo elite|on|off, /bw br on|off,
--        /bw spec auto|arms|fury, /bw ww on|off, /bw slam auto|on|off

BW = {}

local DEFAULTS = { hs = 60, cleave = 40, slack = 10, op = true, demo = "elite", br = false,
  spec = "auto", ww = true, slam = "auto" }
local DB

local BATTLE, DEFENSIVE, BERSERKER = "Battle Stance", "Defensive Stance", "Berserker Stance"
local TEX_SHOUT = "Ability_Warrior_BattleShout"
local TEX_HS = "Ability_Rogue_Ambush"
local TEX_CLEAVE = "Ability_Warrior_Cleave"
local TEX_DEMO = "Ability_Warrior_WarCry"
local TEX_REND = "Ability_Gouge"

local spellIdx = {}
local attacking = false
local attackTry = 0
local opUntil = 0
local rendTry = 0 -- last Rend attempt on the current target

-- helpers -------------------------------------------------------------------

local function ScanSpells()
  spellIdx = {}
  local i = 1
  while true do
    local name = GetSpellName(i, BOOKTYPE_SPELL)
    if not name then break end
    spellIdx[name] = i -- ranks are listed low to high, so the highest rank wins
    i = i + 1
  end
end

-- seconds until the spell is off cooldown (global cooldown ignored)
local function Remaining(name)
  local i = spellIdx[name]
  if not i then return 999 end
  local start, dur = GetSpellCooldown(i, BOOKTYPE_SPELL)
  if not start or start == 0 or dur <= 1.5 then return 0 end
  local left = start + dur - GetTime()
  if left < 0 then left = 0 end
  return left
end

local function Known(name) return spellIdx[name] ~= nil end
local function Ready(name) return Known(name) and Remaining(name) == 0 end
local function Rage() return UnitMana("player") end

local function Stance()
  for i = 1, GetNumShapeshiftForms() do
    local _, name, active = GetShapeshiftFormInfo(i)
    if active then return name end
  end
  return nil
end

-- rage kept through a stance change (Tactical Mastery)
local function Retain()
  for i = 1, GetNumTalents(1) do
    local name, _, _, _, rank = GetTalentInfo(1, i)
    if name == "Tactical Mastery" then return rank * 5 end
  end
  return 0
end

local function TalentRank(tab, wanted)
  for i = 1, GetNumTalents(tab) do
    local name, _, _, _, rank = GetTalentInfo(tab, i)
    if name == wanted then return rank end
  end
  return 0
end

local function TreePoints(tab)
  local n = 0
  for i = 1, GetNumTalents(tab) do
    local _, _, _, _, rank = GetTalentInfo(tab, i)
    n = n + rank
  end
  return n
end

-- "arms" or "fury": /bw spec arms|fury|auto (auto = the tree with more points)
local function Spec()
  if DB.spec == "arms" or DB.spec == "fury" then return DB.spec end
  if TreePoints(1) > TreePoints(2) then return "arms" end
  return "fury"
end

local function CanSwitch()
  return IsShiftKeyDown() or Rage() <= Retain() + DB.slack
end

local lastWarn = 0
local function Warn(msg)
  if GetTime() - lastWarn > 1 then
    UIErrorsFrame:AddMessage("BullWar: " .. msg, 1, 0.6, 0)
    lastWarn = GetTime()
  end
end

local function Cast(name)
  CastSpellByName(name)
  return true
end

-- switch stance; returns true if this press was used (switched or blocked)
local function GoStance(target, force)
  if Stance() == target then return false end
  if not force and not CanSwitch() then
    Warn("switching would waste " .. (Rage() - Retain()) .. " rage (Shift = force)")
    return true
  end
  return Cast(target)
end

local function HasBuff(tex)
  for i = 1, 32 do
    local t = UnitBuff("player", i)
    if not t then return false end
    if string.find(t, tex) then return true end
  end
  return false
end

-- is an on-next-swing attack (Heroic Strike / Cleave) already queued?
-- Needs that ability somewhere on an action bar.
local function Queued(tex)
  for s = 1, 120 do
    local t = GetActionTexture(s)
    if t and string.find(t, tex) and IsCurrentAction(s) then return true end
  end
  return false
end

local function TargetHasDebuff(tex)
  for i = 1, 16 do
    local t = UnitDebuff("target", i)
    if not t then return false end
    if string.find(t, tex) then return true end
  end
  return false
end

local function HasEnemy()
  return UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")
end

-- AttackTarget() toggles, so only call it when auto attack is off.
-- The short guard stops a quick double press from toggling it back off
-- before PLAYER_ENTER_COMBAT arrives.
local function StartAttack()
  if not attacking and HasEnemy() and GetTime() - attackTry > 0.5 then
    AttackTarget()
    attackTry = GetTime()
  end
end

local function TargetPct()
  local m = UnitHealthMax("target")
  if not m or m == 0 then return 100 end
  return UnitHealth("target") / m * 100
end

-- margin: seconds of the dodge window that must be left (time to switch stance)
local function OPReady(margin)
  return GetTime() < opUntil - (margin or 0) and Ready("Overpower") and Rage() >= 5
end

local function NeedShout()
  return Known("Battle Shout") and Rage() >= 10 and not HasBuff(TEX_SHOUT)
end

-- Demoralizing Shout on the target? demo = "off" | "elite" (elite/rare only) | "on"
local function NeedDemo()
  if DB.demo == "off" or not HasEnemy() or Rage() < 10 or not Known("Demoralizing Shout") then return false end
  if TargetHasDebuff(TEX_DEMO) or TargetPct() < 40 then return false end
  if DB.demo == "on" then return true end
  local c = UnitClassification("target")
  return c == "elite" or c == "rareelite" or c == "worldboss" or c == "rare"
end

-- go to Battle Stance for Overpower only when Berserker has nothing better
-- to do right now and the switch loses little rage
-- (Bloodthirst works in Battle Stance too, so only Whirlwind has to be waited for.)
local function GoOverpower(idleWW)
  return DB.op and OPReady(1) and CanSwitch() and Remaining("Whirlwind") > idleWW
end

-- optional: Bloodrage on cooldown in combat (off the global cooldown)
local function UseBloodrage()
  if DB.br and UnitAffectingCombat("player") and Ready("Bloodrage") and Rage() <= 50
    and UnitHealth("player") / UnitHealthMax("player") > 0.6 then
    CastSpellByName("Bloodrage")
  end
end

-- public buttons ------------------------------------------------------------

local function FuryMain()
  StartAttack()
  UseBloodrage()
  local st, r = Stance(), Rage()
  local inCombat = UnitAffectingCombat("player")
  local exec = HasEnemy() and TargetPct() <= 20

  if not exec and NeedShout() then return Cast("Battle Shout") end
  if st == DEFENSIVE and CanSwitch() then return Cast(BERSERKER) end
  if NeedDemo() then return Cast("Demoralizing Shout") end
  if exec and r >= 10 and st ~= DEFENSIVE then return Cast("Execute") end
  if st == BATTLE and OPReady() then return Cast("Overpower") end
  -- go home to Berserker Stance once little rage would be lost
  if st ~= BERSERKER and inCombat and CanSwitch() then return Cast(BERSERKER) end

  if r >= 30 and Ready("Bloodthirst") then return Cast("Bloodthirst") end

  if st == BERSERKER then
    -- Whirlwind, but do not starve a Bloodthirst that is about to come back
    if r >= 25 and Ready("Whirlwind") and (Remaining("Bloodthirst") > 1.5 or r >= 55) then
      return Cast("Whirlwind")
    end
    if GoOverpower(2) then return Cast(BATTLE) end
    if r >= DB.hs and not Queued(TEX_HS) then return Cast("Heroic Strike") end
  elseif inCombat and r >= 15 and not Queued(TEX_HS) then
    -- stuck outside Berserker with too much rage to switch: spend it, then switch
    return Cast("Heroic Strike")
  end
end

local function FuryAoE()
  StartAttack()
  UseBloodrage()
  local st, r = Stance(), Rage()
  local inCombat = UnitAffectingCombat("player")
  local zerk = (st == BERSERKER)

  if NeedShout() then return Cast("Battle Shout") end
  if st == BATTLE and OPReady() then return Cast("Overpower") end
  if not zerk and inCombat and CanSwitch() then return Cast(BERSERKER) end
  if zerk and r >= 25 and Ready("Whirlwind") then return Cast("Whirlwind") end
  if HasEnemy() and r >= 10 and Known("Demoralizing Shout") and not TargetHasDebuff(TEX_DEMO) then
    return Cast("Demoralizing Shout")
  end
  if zerk and GoOverpower(3) then return Cast(BATTLE) end
  -- Cleave, keeping 25 rage for a Whirlwind that is about to come back
  local cleaveOK = (not zerk and inCombat and r >= 20)
    or (r >= DB.cleave and (Remaining("Whirlwind") > 2 or r >= 45))
  if cleaveOK and not Queued(TEX_CLEAVE) then return Cast("Cleave") end
  if r >= 30 and Ready("Bloodthirst") and (not zerk or Remaining("Whirlwind") > 3) then
    return Cast("Bloodthirst")
  end
end


-- Arms (two-hander): home is Battle Stance for Overpower and Rend.
-- Short trips to Berserker Stance for Whirlwind when they lose little rage.

local function UseSlam()
  if DB.slam == "on" then return true end
  if DB.slam == "off" then return false end
  return TalentRank(1, "Improved Slam") > 0
end

local function NeedRend()
  return HasEnemy() and Known("Rend") and Rage() >= 10 and TargetPct() > 30
    and not TargetHasDebuff(TEX_REND) and GetTime() - rendTry > 20
end

-- go to Berserker for one Whirlwind: Mortal Strike not due soon, little rage lost
local function GoWhirlwind()
  return DB.ww and Ready("Whirlwind") and Rage() >= 25 and CanSwitch()
    and Remaining("Mortal Strike") > 2 and CheckInteractDistance("target", 3)
end

local function ArmsMain()
  StartAttack()
  UseBloodrage()
  local st, r = Stance(), Rage()
  local inCombat = UnitAffectingCombat("player")
  local exec = HasEnemy() and TargetPct() <= 20

  if not exec and NeedShout() then return Cast("Battle Shout") end
  if NeedDemo() then return Cast("Demoralizing Shout") end
  if exec and r >= 10 and st ~= DEFENSIVE then return Cast("Execute") end

  if st == BERSERKER then
    -- the Whirlwind trip: use it, then go home
    if r >= 25 and Ready("Whirlwind") then return Cast("Whirlwind") end
  end
  if st == BATTLE and OPReady() then return Cast("Overpower") end
  if st ~= BATTLE and inCombat and CanSwitch() then return Cast(BATTLE) end

  if r >= 30 and Ready("Mortal Strike") then return Cast("Mortal Strike") end
  if st ~= BERSERKER and inCombat and NeedRend() then
    rendTry = GetTime()
    return Cast("Rend")
  end
  if st == BATTLE and inCombat and GoWhirlwind() then return Cast(BERSERKER) end

  -- fillers, keeping 30 rage for a Mortal Strike that is about to come back
  local keep = 0
  if Known("Mortal Strike") and Remaining("Mortal Strike") < 2.5 then keep = 30 end
  if inCombat and UseSlam() and r >= 15 + keep then return Cast("Slam") end
  if st == BATTLE then
    if r >= DB.hs and not Queued(TEX_HS) then return Cast("Heroic Strike") end
  elseif inCombat and r >= 15 and not Queued(TEX_HS) then
    return Cast("Heroic Strike") -- stuck away from home with surplus rage
  end
end

local function ArmsAoE()
  StartAttack()
  UseBloodrage()
  local st, r = Stance(), Rage()
  local inCombat = UnitAffectingCombat("player")
  local sweep = inCombat and Known("Sweeping Strikes") and Ready("Sweeping Strikes") and r >= 20

  if NeedShout() then return Cast("Battle Shout") end
  if st == BATTLE and OPReady() then return Cast("Overpower") end
  -- Sweeping Strikes first (Battle Stance), then Whirlwind (Berserker Stance)
  if sweep then
    if st == BATTLE then return Cast("Sweeping Strikes") end
    if CanSwitch() then return Cast(BATTLE) end
  end
  if st == BERSERKER and r >= 25 and Ready("Whirlwind") then return Cast("Whirlwind") end
  if st ~= BERSERKER and inCombat and Ready("Whirlwind") and r >= 25 and CanSwitch() then
    return Cast(BERSERKER)
  end
  if HasEnemy() and r >= 10 and Known("Demoralizing Shout") and not TargetHasDebuff(TEX_DEMO) then
    return Cast("Demoralizing Shout")
  end
  local cleaveOK = r >= DB.cleave and (Remaining("Whirlwind") > 2 or r >= 45)
  if cleaveOK and not Queued(TEX_CLEAVE) then return Cast("Cleave") end
  if r >= 30 and Ready("Mortal Strike") and Remaining("Whirlwind") > 3 then return Cast("Mortal Strike") end
end

function BW.Main()
  if Spec() == "arms" then return ArmsMain() end
  return FuryMain()
end

function BW.AoE()
  if Spec() == "arms" then return ArmsAoE() end
  return FuryAoE()
end

function BW.Charge()
  if not UnitAffectingCombat("player") then
    if GoStance(BATTLE, true) then return end
    Cast("Charge")
  else
    if GoStance(BERSERKER, true) then return end
    Cast("Intercept")
  end
end

function BW.Overpower()
  if Stance() ~= BATTLE then
    if GetTime() >= opUntil and not IsShiftKeyDown() then
      Warn("no dodge to Overpower")
      return
    end
    return GoStance(BATTLE)
  end
  Cast("Overpower")
end

function BW.Pummel()
  if Stance() == DEFENSIVE then return GoStance(BERSERKER, true) end
  Cast("Pummel")
end

function BW.Do(spell, stance, force)
  if stance and GoStance(stance, force) then return end
  Cast(spell)
end

-- events --------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("SPELLS_CHANGED")
f:RegisterEvent("LEARNED_SPELL_IN_TAB")
f:RegisterEvent("PLAYER_ENTER_COMBAT")
f:RegisterEvent("PLAYER_LEAVE_COMBAT")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
f:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
f:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == "BullWar" then
    BullWarDB = BullWarDB or {}
    for k, v in pairs(DEFAULTS) do
      if BullWarDB[k] == nil then BullWarDB[k] = v end
    end
    DB = BullWarDB
  elseif event == "PLAYER_ENTERING_WORLD" or event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" then
    ScanSpells()
  elseif event == "PLAYER_ENTER_COMBAT" then
    attacking = true
  elseif event == "PLAYER_LEAVE_COMBAT" then
    attacking = false
  elseif event == "PLAYER_TARGET_CHANGED" then
    opUntil = 0
    rendTry = 0
  elseif arg1 then
    -- "You attack. X dodges." / "Your Bloodthirst was dodged by X."
    -- only dodges by the current target open Overpower on it
    local tname = UnitName("target")
    if tname and string.find(arg1, "dodge") and string.find(arg1, tname, 1, true) then
      opUntil = GetTime() + 5
    end
    if event == "CHAT_MSG_SPELL_SELF_DAMAGE" and string.find(arg1, "^Your Overpower") then opUntil = 0 end
  end
end)

-- slash ---------------------------------------------------------------------

SLASH_BULLWAR1 = "/bw"
SlashCmdList["BULLWAR"] = function(msg)
  local _, _, key, val = string.find(msg or "", "^(%a+)%s*(%S*)")
  if key == "hs" or key == "cleave" or key == "slack" then
    local n = tonumber(val)
    if n then DB[key] = n end
  elseif key == "op" then
    DB.op = (val == "on")
  elseif key == "br" then
    DB.br = (val == "on")
  elseif key == "ww" then
    DB.ww = (val == "on")
  elseif key == "spec" and (val == "arms" or val == "fury" or val == "auto") then
    DB.spec = val
  elseif key == "slam" and (val == "on" or val == "off" or val == "auto") then
    DB.slam = val
  elseif key == "demo" and (val == "on" or val == "off" or val == "elite") then
    DB.demo = val
  end
  DEFAULT_CHAT_FRAME:AddMessage(string.format("BullWar: spec %s (setting %s), Arms Whirlwind trips %s, Slam %s (%s)",
    Spec(), DB.spec, DB.ww and "on" or "off", UseSlam() and "on" or "off", DB.slam))
  DEFAULT_CHAT_FRAME:AddMessage(string.format(
    "BullWar: HS at %d rage, Cleave at %d, stance slack %d (Tactical Mastery keeps %d), Overpower %s, single-target Demo %s, auto Bloodrage %s",
    DB.hs, DB.cleave, DB.slack, Retain(), DB.op and "on" or "off", DB.demo, DB.br and "on" or "off"))
end
