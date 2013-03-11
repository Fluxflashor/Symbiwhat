--[[ 
    @Package       Symbiwhat
    @Description   Never forget what spell someone will give you!
    @Author        Robert "Fluxflashor" Veitch <Robert@Fluxflashor.net>
    @Repo          http://github.com/Fluxflashor/Symbiwhat
    @File          Core.lua
    ]]

local SYMBIWHAT, Symbiwhat = ...;
local EventFrame = CreateFrame("FRAME", "Symbiwhat_EventFrame");
local ScanningFrame = CreateFrame('GameTooltip', 'MyTooltip', UIParent, 'GameTooltipTemplate');

Symbiwhat.AddonName = SYMBIWHAT;
Symbiwhat.Author = GetAddOnMetadata(SYMBIWHAT, "Author");
Symbiwhat.Version = GetAddOnMetadata(SYMBIWHAT, "Version");
Symbiwhat.ChatPrefix = "|cfffa8000Symbiwhat|r:"

Symbiwhat.TestMode = false;
Symbiwhat.TooltipCache = { };
Symbiwhat.InspectRequest = { ["requesting"] = false, ["data_ready"] = false, ["unit"] = "", ["druid_spell_name"] = "" };

local symbiosis_spell_id = 110309;

local function ClCr(class_name)
    class_name = string.upper(class_name)
    class_chat_color = string.format("|c%s", RAID_CLASS_COLORS[class_name]["colorStr"])
    return class_chat_color
end

local CLASS_CHAT_COLORS = {
    ["Deathknight"] = ClCr("Deathknight"),
    ["Druid"] = ClCr("Druid"),
    ["Hunter"] = ClCr("Hunter"),
    ["Mage"] = ClCr("Mage"),
    ["Monk"] = ClCr("Monk"),
    ["Paladin"] = ClCr("Paladin"),
    ["Priest"] = ClCr("Priest"),
    ["Rogue"] = ClCr("Rogue"),
    ["Shaman"] = ClCr("Shaman"),
    ["Warlock"] = ClCr("Warlock"),
    ["Warrior"] = ClCr("Warrior")
}

local SYM_CLASS_IDS = {
    ["Warrior"] = 10,
    ["Paladin"] = 5,
    ["Hunter"] = 2,
    ["Rogue"] = 7,
    ["Priest"] = 6,
    ["Deathknight"] = 1,
    ["Shaman"] = 8,
    ["Mage"] = 3,
    ["Warlock"] = 9,
    ["Monk"] = 4
    --["Druid"] = 11
}

local SYM_DRUID_SPEC_IDS = {
    [102] = 1,
    [103] = 2,
    [104] = 3,
    [105] = 4
}

local DRUID_SYMBIOSIS_GAINS = {
    {spec = "Balance", spell_table = { 
            {class_name = "Deathknight", spell_name = GetSpellInfo(110570)},
            {class_name = "Hunter", spell_name = GetSpellInfo(110588)},
            {class_name = "Mage", spell_name = GetSpellInfo(110621)},
            {class_name = "Monk", spell_name = GetSpellInfo(126458)},
            {class_name = "Paladin", spell_name = GetSpellInfo(110698)},
            {class_name = "Priest", spell_name = GetSpellInfo(110709)},
            {class_name = "Rogue", spell_name = GetSpellInfo(110788)},
            {class_name = "Shaman", spell_name = GetSpellInfo(110802)},
            {class_name = "Warlock", spell_name = GetSpellInfo(122291)},
            {class_name = "Warrior", spell_name = GetSpellInfo(122292)}
        }
    },
    {spec = "Feral", spell_table = { 
            {class_name = "Deathknight", spell_name = GetSpellInfo(122283)},
            {class_name = "Hunter", spell_name = GetSpellInfo(110597)},
            {class_name = "Mage", spell_name = GetSpellInfo(110693)},
            {class_name = "Monk", spell_name = GetSpellInfo(126449)},
            {class_name = "Paladin", spell_name = GetSpellInfo(110700)},
            {class_name = "Priest", spell_name = GetSpellInfo(110715)},
            {class_name = "Rogue", spell_name = GetSpellInfo(110730)},
            {class_name = "Shaman", spell_name = GetSpellInfo(110807)},
            {class_name = "Warlock", spell_name = GetSpellInfo(110810)},
            {class_name = "Warrior", spell_name = GetSpellInfo(112997)}
        }
    },
    {spec = "Guardian", spell_table = { 
            {class_name = "Deathknight", spell_name = GetSpellInfo(122285)},
            {class_name = "Hunter", spell_name = GetSpellInfo(110600)},
            {class_name = "Mage", spell_name = GetSpellInfo(110694)},
            {class_name = "Monk", spell_name = GetSpellInfo(126453)},
            {class_name = "Paladin", spell_name = GetSpellInfo(110701)},
            {class_name = "Priest", spell_name = GetSpellInfo(110717)},
            {class_name = "Rogue", spell_name = GetSpellInfo(122289)},
            {class_name = "Shaman", spell_name = GetSpellInfo(110803)},
            {class_name = "Warlock", spell_name = GetSpellInfo(122290)},
            {class_name = "Warrior", spell_name = GetSpellInfo(113002)}
        }
    },
    {spec = "Restoration", spell_table = { 
            {class_name = "Deathknight", spell_name = GetSpellInfo(110575)},
            {class_name = "Hunter", spell_name = GetSpellInfo(110617)},
            {class_name = "Mage", spell_name = GetSpellInfo(110696)},
            {class_name = "Monk", spell_name = GetSpellInfo(126456)},
            {class_name = "Paladin", spell_name = GetSpellInfo(122288)},
            {class_name = "Priest", spell_name = GetSpellInfo(110718)},
            {class_name = "Rogue", spell_name = GetSpellInfo(110791)},
            {class_name = "Shaman", spell_name = GetSpellInfo(110806)},
            {class_name = "Warlock", spell_name = GetSpellInfo(112970)},
            {class_name = "Warrior", spell_name = GetSpellInfo(113004)}
        }
    }
}

--    1        2        3      4       5         6          7      8       9     10     11
-- Warrior, Paladin, Hunter, Rogue, Priest, DeathKnight, Shaman, Mage, Warlock, Monk, Druid
local CLASS_SYMBIOSIS_BUFF_IDS = {110506, 110501, 110497, 110503, 110502, 110498, 110504, 110499, 110505, 110500, 110309}

function Symbiwhat:MessageUser(message)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("%s %s", Symbiwhat.ChatPrefix, message));
end

function Symbiwhat:DebugMessage(message)
    if Symbiwhat.TestMode then
          Symbiwhat:MessageUser(message)
    end
end

function Symbiwhat:DoesTargetHaveBuff(target, spell_id)

    spell_name = GetSpellInfo(spell_id)
        
    if UnitBuff(target, spell_name) then
        return true
    end

    return false
end


function Symbiwhat:GetDescriptionFromSpell(target, spell_name)
    
    ScanningFrame:SetOwner(UIParent, 'ANCHOR_NONE');
    ScanningFrame:SetUnitBuff(target, spell_name);
    spell_description = MyTooltipTextLeft2:GetText();
    ScanningFrame:Hide();

    return spell_description;
end


function Symbiwhat:GetClassOfGroupMemberWithOriginatingSymbiosis(group_type, unit)

    num_group_members = GetNumGroupMembers();
    for i=0, num_group_members-1, 1 do
        target = group_type..i;
        if UnitIsConnected(target) then
            _, target_class_name, target_class_id = UnitClass(target);
            target_buff_id = CLASS_SYMBIOSIS_BUFF_IDS[target_class_id];
            target_buff_name = GetSpellInfo(target_buff_id);

            if Symbiwhat:DoesTargetHaveBuff(target, target_buff_id) then
                _, _, _, _, _, _, _, buff_source = UnitBuff(target, target_buff_name);
    
                if (buff_source == unit) then
                    -- return the class name with only the first letter capitalised
                    Symbiwhat:DebugMessage(target_class_name)
                    return target_class_name:lower():gsub("^%l", string.upper)
                end
            end
        end
    end
end


function Symbiwhat:GetDruidSpecialization(unit)
    if CanInspect(unit) then
        NotifyInspect(unit)
    end
end


local function SymbiwhatOnGameTooltipSetSpell(tooltip, ...)
    -- for some reason SetScript on tooltips doesnt allow functions inside of vars

    _, _, spell_id = tooltip:GetSpell();

    if spell_id == symbiosis_spell_id then
        specialization_id = GetSpecialization();

        tooltip:AddLine("Below is a list of abilities you will get for your specialization based on the target you cast Symbiosis on.\n",_,_,_,1)

        for i=1, getn(DRUID_SYMBIOSIS_GAINS[specialization_id].spell_table), 1 do

            current_class_name = DRUID_SYMBIOSIS_GAINS[specialization_id].spell_table[i].class_name;
            current_spell_name = DRUID_SYMBIOSIS_GAINS[specialization_id].spell_table[i].spell_name;
            current_class_color = CLASS_CHAT_COLORS[current_class_name];

            tooltip:AddDoubleLine(string.format("%s%s", current_class_color, current_class_name), string.format("%s%s", current_class_color, current_spell_name));
        end 

    end
end


local function SymbiwhatOnGameTooltipSetUnit(tooltip, ...)
    
    _, unit = tooltip:GetUnit();
    tooltip_text = "";

    if (UnitIsPlayer(unit)) then
    
        --Symbiwhat:DebugMessage(unit);
        _, _, class_id = UnitClass(unit);
        class_buff_id = CLASS_SYMBIOSIS_BUFF_IDS[class_id];
        class_buff_name = GetSpellInfo(class_buff_id);
        --Symbiwhat:DebugMessage(class_buff_name);
        
        if (class_id ~= 11) then 

            if Symbiwhat:DoesTargetHaveBuff(unit, class_buff_id) then

                buff_description = Symbiwhat:GetDescriptionFromSpell(unit, class_buff_name);

                tooltip_text = buff_description;
            end
        -- druid only stuff below.. this is a bit trickier.
        else

            if Symbiwhat:DoesTargetHaveBuff(unit, class_buff_id) then

                if UnitIsFriend("player", unit) then
    
                    if UnitInParty(unit) then
                        -- if the friendly druid is in my party, loop over
                        -- the members in the party and find out who has the 
                        -- buff_source of symbiosis. Get the class name
                        -- to find out which buff the druid gained.
                        spell_name = Symbiwhat.InspectRequest["druid_spell_name"];
                        if UnitIsConnected(unit) then
    
                            if Symbiwhat.InspectRequest["requesting"] then
                                if Symbiwhat.InspectRequest["data_ready"] then
                                    druid_wow_spec_id = GetInspectSpecialization(unit);
                                    Symbiwhat:DebugMessage(druid_wow_spec_id)
                                    druid_our_spec_id = SYM_DRUID_SPEC_IDS[druid_wow_spec_id];
                                    Symbiwhat:DebugMessage(druid_our_spec_id);
                                    Symbiwhat:DebugMessage(SYM_CLASS_IDS[Symbiwhat.InspectRequest["class"]]);
                                    Symbiwhat.InspectRequest["druid_spell_name"] = DRUID_SYMBIOSIS_GAINS[druid_our_spec_id].spell_table[SYM_CLASS_IDS[Symbiwhat.InspectRequest["class"]]].spell_name;
                                    spell_name = Symbiwhat.InspectRequest["druid_spell_name"];
                                    Symbiwhat.InspectRequest["requesting"] = false;
                                end
                            else
                                if unit ~= Symbiwhat.InspectRequest["unit"] then
                                    if CanInspect(unit) then
                                        Symbiwhat:DebugMessage("Requesting Talent Data From Realm");
                                        Symbiwhat.InspectRequest["data_ready"] = false;
                                        NotifyInspect(unit);
                                        spell_name = "Querying server for Druid's talent data..";
                                        Symbiwhat.InspectRequest["requesting"] = true;
                                        Symbiwhat.InspectRequest["unit"] = unit;
                                        Symbiwhat.InspectRequest["class"] = Symbiwhat:GetClassOfGroupMemberWithOriginatingSymbiosis("party", unit);
                                    else
                                        Symbiwhat:DebugMessage("Cannot inspect unit.");
                                    end
                                end
                            end
                        end
                        --Symbiwhat.InspectRequest["class"] = Symbiwhat:GetClassOfGroupMemberWithOriginatingSymbiosis("party", unit);
                        --druid_specialization_id = Symbiwhat:GetDruidSpecialization(unit); --tmp
                        --spell_name = DRUID_SYMBIOSIS_GAINS[druid_specialization_id].spell_table[SYM_CLASS_IDS[given_symbiosis_class]].spell_name;
    
                        tooltip_text = "Temporarily granted the ability "..spell_name;
                        Symbiwhat:DebugMessage(spell_name)
                    end

                else
                    if IsActiveBattlefieldArena() then
                
                    end
                end
            end
        end
        tooltip:AddLine(tooltip_text,_,_,_,1);
    end
end


function Symbiwhat:Initialize()
    EventFrame:RegisterEvent("ADDON_LOADED");
    EventFrame:SetScript("OnEvent", function(self, event, ...) Symbiwhat:EventHandler(self, event, ...); end);
    GameTooltip:SetScript("OnTooltipSetSpell", SymbiwhatOnGameTooltipSetSpell);
    GameTooltip:SetScript("OnTooltipSetUnit", SymbiwhatOnGameTooltipSetUnit);
end

function Symbiwhat:RegisterEvents()
    EventFrame:RegisterEvent("INSPECT_READY");
end


function Symbiwhat:EventHandler(self, event, ...)
    if (event == "ADDON_LOADED") then
        local LoadedAddonName = ...;
        if (Symbiwhat.TestMode) then
            Symbiwhat:MessageUser(string.format("LoadedAddonName is %s", LoadedAddonName));
        end
        if (LoadedAddonName == AddonName) then
            if (Symbiwhat.Version == "@project-version@") then
                Symbiwhat.Version = "Development";
            end
            if (Symbiwhat.Author == "@project-author@") then
                Symbiwhat.Author = "Fluxflashor (Local)";
            end
            Symbiwhat:MessageUser(string.format("Loaded Version is %s. Author is %s.", Symbiwhat.Version, Symbiwhat.Author));
            if (Symbiwhat.TestMode) then
                Symbiwhat:MessageUser(string.format("%s is %s.", LoadedAddonName, AddonName));
            end
            if (Symbiwhat.AddOnDisabled) then
                if (Symbiwhat.TestMode) then
                    Symbiwhat:MessageUser("Unregistering Events.");
                end
                if (not Symbiwhat.SuppressWarnings) then
                    Symbiwhat:WarnUser("Symbiwhat is disabled.");
                end
                Symbiwhat:Enable(false);
            end
        end
        Symbiwhat:RegisterEvents();
    end
    if (event == "INSPECT_READY") then
        Symbiwhat:DebugMessage("Inspect Request Ready..")
        Symbiwhat.InspectRequest["data_ready"] = true
        -- update the tooltip for a druid inspect.

    end
end


Symbiwhat:Initialize();