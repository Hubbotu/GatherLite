local name, _GatherLite = ...

-- tracker data
_GatherLite.tracker = {
    spellType = nil,
    spellID = nil,
    target = nil,
    ended = nil
};

-- addon events handler
_GatherLite.mainFrame:SetScript('OnEvent', function(self, event, ...)

    -- addon is loaded
    if event == "ADDON_LOADED" and select(1, ...) == _GatherLite.name then
        if GatherLiteGlobalSettings == nil then
            GatherLiteGlobalSettings = {
                database = {
                    mining = {},
                    herbalism = {},
                    treasure = {}
                }
            };
        end

        GatherLiteConfigCharacter = GatherLite:CopyDefaults(_GatherLite.defaultConfigs, GatherLiteConfigCharacter);

        GatherLite:print(GatherLite:Colorize(_GatherLite.version, "blue"), "has been loaded");
        GatherLite:print("use |cFF00FF00/gather|r or |cFF00FF00/gatherlite|r to access addon settings");
        GatherLite:debug("Found", "|cFF00FF00" .. GatherLite:tablelength(GatherLiteGlobalSettings.database.mining) .. "|r", "mining nodes");
        GatherLite:debug("Found", "|cFF00FF00" .. GatherLite:tablelength(GatherLiteGlobalSettings.database.herbalism) .. "|r", "herbalism nodes");
        if not _GatherLite.isClassic then
            GatherLite:debug("Found", "|cFF00FF00" .. GatherLite:tablelength(GatherLiteGlobalSettings.database.artifacts) .. "|r", "artifact nodes");
        end
        GatherLite:debug("Found", "|cFF00FF00" .. GatherLite:tablelength(GatherLiteGlobalSettings.database.fish) .. "|r", "fishing spots");
        GatherLite:debug("Found", "|cFF00FF00" .. GatherLite:tablelength(GatherLiteGlobalSettings.database.treasure) .. "|r", "treasures");
        GatherLite:updateMiniMapPosition();

        -- register synchronization
        GatherLite:RegisterComm(_GatherLite.name .. "Sync", "p2pSync")
        GatherLite:RegisterComm(_GatherLite.name .. "Node", "p2pNode")

        -- start synchronization after 5 seconds to guild
        GatherLite:ScheduleTimer(function()
            if IsInGuild() then
                for i, type in ipairs(GatherLiteGlobalSettings.database) do
                    GatherLite:SendCommMessage(_GatherLite.name .. "Sync", GatherLite:Serialize(GatherLiteGlobalSettings.database[type]), "GUILD")
                end
            end
        end, 5)

        -- sync database with guild every 30 minutes
        GatherLite:ScheduleRepeatingTimer(function()
            if IsInGuild() then
                for i, type in ipairs(GatherLiteGlobalSettings.database) do
                    GatherLite:SendCommMessage(_GatherLite.name .. "Sync", GatherLite:Serialize(GatherLiteGlobalSettings.database[type]), "GUILD")
                end
            end
        end, 1800)

        GatherLite:ScheduleRepeatingTimer("checkNodePositions", 1);

        self:UnregisterEvent("ADDON_LOADED");
    end

    -- loot window opened
    if event == "LOOT_OPENED" then
        if (_GatherLite.tracker.spellID and _GatherLite.tracker.ended and GetTime() - _GatherLite.tracker.ended < 1) then
            GatherLite:debug("loot window opened")
            GatherLite:foundNode();
            _GatherLite.tracker.target = nil;
            _GatherLite.tracker.spellID = nil;
            _GatherLite.tracker.spellType = nil;
        elseif (_GatherLite.tracker.spellID and IsFishingLoot()) then
            GatherLite:debug("loot window opened")
            GatherLite:foundNode();
            _GatherLite.tracker.target = nil;
            _GatherLite.tracker.spellID = nil;
            _GatherLite.tracker.spellType = nil;
        end
    end

    -- spell has ended
    if (event == "UNIT_SPELLCAST_SENT") or (event == "UNIT_SPELLCAST_SUCCEEDED") or (event == "UNIT_SPELLCAST_INTERRUPTED") or (event == "UNIT_SPELLCAST_FAILED") then
        local spell = select(4, ...)
        local target = select(2, ...)

        if (event == "UNIT_SPELLCAST_SENT") then
            local spellType = GatherLite:findSpellType(spell)
            if (spellType) then
                GatherLite:debug("Started " .. GetSpellInfo(spell), spell)
                _GatherLite.tracker.target = target
                _GatherLite.tracker.spellID = spell
                _GatherLite.tracker.spellType = spellType
            end ;
        elseif (event == "UNIT_SPELLCAST_SUCCEEDED") then
            _GatherLite.tracker.ended = GetTime()
        elseif ((event == "UNIT_SPELLCAST_INTERRUPTED") or (event == "UNIT_SPELLCAST_FAILED")) then
            -- Spell failed, cancel the tracking
            _GatherLite.tracker.target = nil
            _GatherLite.tracker.spellID = nil
            _GatherLite.tracker.spellType = nil
        end
    end
end)