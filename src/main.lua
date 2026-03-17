-- =============================================================================
-- BOILERPLATE (do not modify)
-- =============================================================================

local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods['SGG_Modding-ModUtil']
chalk = mods['SGG_Modding-Chalk']
reload = mods['SGG_Modding-ReLoad']

config = chalk.auto('config.lua')
public.config = config

local NIL = {}
local backups = {}

local function backup(tbl, key)
    if not backups[tbl] then backups[tbl] = {} end
    if backups[tbl][key] == nil then
        local v = tbl[key]
        backups[tbl][key] = v == nil and NIL or (type(v) == "table" and DeepCopyTable(v) or v)
    end
end

local function restore()
    for tbl, keys in pairs(backups) do
        for key, v in pairs(keys) do
            tbl[key] = v == NIL and nil or (type(v) == "table" and DeepCopyTable(v) or v)
        end
    end
end

local function isEnabled()
    return config.Enabled
end

-- =============================================================================
-- MODULE DEFINITION
-- =============================================================================

public.definition = {
    id       = "DeathCutScene",
    name     = "Skip Death Cutscene",
    category = "QoLSettings",
    group    = "QoL",
    tooltip  = "Skip the death cutscene. The death screen will still appear, but you will be immediately returned to the main menu.",
    default  = true,
}

-- =============================================================================
-- MODULE LOGIC
-- =============================================================================

local function apply()
end

local function disable()
    restore()
end

local function registerHooks()
    modutil.mod.Path.Context.Wrap("DeathPresentation", function()
        modutil.mod.Path.Wrap("wait", function(base, duration, tag, persist)
            if not isEnabled() then
                return base(duration, tag, persist)
            end
            return
        end)
    end)
end

-- =============================================================================
-- PUBLIC API (do not modify)
-- =============================================================================

public.definition.enable = function()
    apply()
end

public.definition.disable = function()
    disable()
end

-- =============================================================================
-- LIFECYCLE (do not modify)
-- =============================================================================

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(function()
        import_as_fallback(rom.game)
        registerHooks()
        if config.Enabled then apply() end
    end)
end)
-- =============================================================================
-- STANDALONE UI (do not modify)
-- =============================================================================
-- When adamant-core is NOT installed, renders a minimal ImGui toggle.
-- When adamant-core IS installed, the core handles UI — this is skipped.

rom.gui.add_to_menu_bar(function()
    if mods['adamant-Core'] then return end
    if rom.ImGui.BeginMenu("adamant") then
        local val, chg = rom.ImGui.Checkbox(public.definition.name, config.Enabled)
        if chg then
            config.Enabled = val
            if val then apply() else disable() end
        end
        if rom.ImGui.IsItemHovered() and public.definition.tooltip ~= "" then
            rom.ImGui.SetTooltip(public.definition.tooltip)
        end
        rom.ImGui.EndMenu()
    end
end)
