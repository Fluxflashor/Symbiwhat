--[[ 
    @Package       Symbiwhat
    @Description   Never forget what spell someone will give you!
    @Author        Robert "Fluxflashor" Veitch <Robert@Fluxflashor.net>
    @Repo          http://github.com/Fluxflashor/Symbiwhat
    @File          Core.lua
    ]]

local SYMBIWHAT, Symbiwhat = ...;
local EventFrame = CreateFrame("FRAME", "Symbiwhat_EventFrame");

Symbiwhat.AddonName = SYMBIWHAT;
Symbiwhat.Author = GetAddOnMetadata(SYMBIWHAT, "Author");
Symbiwhat.Version = GetAddOnMetadata(SYMBIWHAT, "Version");
Symbiwhat.ChatPrefix = "|cfffa8000Symbiwhat|r:"

Symbiwhat.TestMode = false;

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

local DRUID_SYMBIOSIS_GAINS = {
    {spec = "Balance", spell_table = { 
            {class_name = "Deathknight", spell_name = "Anti-Magic Shell", spell_id = 110570},
            {class_name = "Hunter", spell_name = "Misdirection", spell_id = 110588},
            {class_name = "Mage", spell_name = "Mirror Image", spell_id = 110621},
            {class_name = "Monk", spell_name = "Grapple Weapon", spell_id = 126458},
            {class_name = "Paladin", spell_name = "Hammer of Justice", spell_id = 110698},
            {class_name = "Priest", spell_name = "Mass Dispel", spell_id = 110709},
            {class_name = "Rogue", spell_name = "Cloak of Shadows", spell_id = 110788},
            {class_name = "Shaman", spell_name = "Purge", spell_id = 110802},
            {class_name = "Warlock", spell_name = "Unending Resolve", spell_id = 122291},
            {class_name = "Warrior", spell_name = "Intervene", spell_id = 122292}
        }
    },
    {spec = "Feral", spell_table = { 
            {class_name = "Deathknight", spell_name = "Death Coil", spell_id = 122283},
            {class_name = "Hunter", spell_name = "Play Dead", spell_id = 110597},
            {class_name = "Mage", spell_name = "Frost Nova", spell_id = 110693},
            {class_name = "Monk", spell_name = "Clash", spell_id = 126449},
            {class_name = "Paladin", spell_name = "Divine Shield", spell_id = 110700},
            {class_name = "Priest", spell_name = "Dispersion", spell_id = 110715},
            {class_name = "Rogue", spell_name = "Redirect", spell_id = 110730},
            {class_name = "Shaman", spell_name = "Feral Spirit", spell_id = 110807},
            {class_name = "Warlock", spell_name = "Soul Swap", spell_id = 110810},
            {class_name = "Warrior", spell_name = "Shattering Blow", spell_id = 112997}
        }
    },
    {spec = "Guardian", spell_table = { 
            {class_name = "Deathknight", spell_name = "Bone Shield", spell_id = 122285},
            {class_name = "Hunter", spell_name = "Ice Trap", spell_id = 110600},
            {class_name = "Mage", spell_name = "Frost Armor", spell_id = 110694},
            {class_name = "Monk", spell_name = "Elusive Brew", spell_id = 126453},
            {class_name = "Paladin", spell_name = "Consecration", spell_id = 110701},
            {class_name = "Priest", spell_name = "Fear Ward", spell_id = 110717},
            {class_name = "Rogue", spell_name = "Feint", spell_id = 122289},
            {class_name = "Shaman", spell_name = "Lightning Shield", spell_id = 110803},
            {class_name = "Warlock", spell_name = "Life Tap", spell_id = 122290},
            {class_name = "Warrior", spell_name = "Spell Reflection", spell_id = 113002}
        }
    },
    {spec = "Restoration", spell_table = { 
            {class_name = "Deathknight", spell_name = "Icebound Fortitude", spell_id = 110575},
            {class_name = "Hunter", spell_name = "Deterrence", spell_id = 110617},
            {class_name = "Mage", spell_name = "Ice Block", spell_id = 110696},
            {class_name = "Monk", spell_name = "Fortifying Brew", spell_id = 126456},
            {class_name = "Paladin", spell_name = "Cleanse", spell_id = 122288},
            {class_name = "Priest", spell_name = "Leap of Faith", spell_id = 110718},
            {class_name = "Rogue", spell_name = "Evasion", spell_id = 110791},
            {class_name = "Shaman", spell_name = "Spiritwalker's Grace", spell_id = 110806},
            {class_name = "Warlock", spell_name = "Demonic Circle: Teleport", spell_id = 112970},
            {class_name = "Warrior", spell_name = "Intimidating Roar", spell_id = 113004}
        }
    }
}


function Symbiwhat:MessageUser(message)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("%s %s", Symbiwhat.ChatPrefix, message));
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


function Symbiwhat:Initialize()
    EventFrame:RegisterEvent("ADDON_LOADED");
    EventFrame:SetScript("OnEvent", function(self, event, ...) Symbiwhat:EventHandler(self, event, ...); end);
    GameTooltip:SetScript("OnTooltipSetSpell", SymbiwhatOnGameTooltipSetSpell);
end

function Symbiwhat:RegisterEvents()
    --EventFrame:RegisterEvent();
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
end


Symbiwhat:Initialize();