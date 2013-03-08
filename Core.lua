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

Symbiwhat.TestMode = true;

function Symbiwhat:MessageUser(message)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("%s %s", Symbiwhat.ChatPrefix, message));
end


function Symbiwhat:Initialize()
    EventFrame:RegisterEvent("ADDON_LOADED");
    EventFrame:SetScript("OnEvent", function(self, event, ...) Symbiwhat:EventHandler(self, event, ...); end);
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
        Symbiwhat:RegisterEvents(
end
Symbiwhat:Initialize();