---------------------------------------------------------------------------
--- App Launcher
--
-- A native application launcher with fuzzy search.
-- No rofi, no dmenu - 100% AwesomeWM widgets.
--
-- @author awesome-from-scratch
-- @copyright 2025
---------------------------------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local menubar = require("menubar")

local launcher = {}

-- State
local launcher_popup = nil
local launcher_visible = false
local search_text = ""
local selected_index = 1
local filtered_apps = {}
local all_apps = {}

-- Configuration
local config = {
    width = 500,
    max_results = 8,
    icon_size = 40,
    item_height = 50,
    margin = 16,
    shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, 12)
    end,
}

--- Fuzzy match function
-- Returns a score (higher is better match), or nil if no match
local function fuzzy_match(pattern, str)
    if not pattern or pattern == "" then
        return 1 -- Empty pattern matches everything
    end

    pattern = pattern:lower()
    str = str:lower()

    -- Exact substring match (highest priority)
    if str:find(pattern, 1, true) then
        -- Earlier match = higher score
        local pos = str:find(pattern, 1, true)
        return 1000 - pos
    end

    -- Fuzzy match
    local score = 0
    local pattern_idx = 1
    local last_match = 0

    for i = 1, #str do
        if pattern_idx <= #pattern and str:sub(i, i) == pattern:sub(pattern_idx, pattern_idx) then
            -- Bonus for consecutive matches
            if i == last_match + 1 then
                score = score + 10
            else
                score = score + 1
            end
            -- Bonus for matching at word boundaries
            if i == 1 or str:sub(i - 1, i - 1):match("[%s%-_]") then
                score = score + 5
            end
            pattern_idx = pattern_idx + 1
            last_match = i
        end
    end

    -- Return score only if entire pattern was matched
    if pattern_idx > #pattern then
        return score
    end

    return nil
end

--- Load applications from .desktop files
local function load_apps()
    all_apps = {}

    -- Use menubar's app loading (already handles .desktop parsing)
    menubar.utils.compute_categories()

    for _, app in ipairs(menubar.menu_entries) do
        if app.Name and app.cmdline then
            table.insert(all_apps, {
                name = app.Name,
                exec = app.cmdline,
                icon = app.icon_path,
                comment = app.comment or "",
            })
        end
    end

    -- Sort alphabetically by default
    table.sort(all_apps, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
end

--- Filter apps based on search text
local function filter_apps()
    filtered_apps = {}

    if search_text == "" then
        -- Show all apps (limited)
        for i = 1, math.min(config.max_results, #all_apps) do
            table.insert(filtered_apps, all_apps[i])
        end
    else
        -- Fuzzy filter and sort by match score
        local scored = {}
        for _, app in ipairs(all_apps) do
            local name_score = fuzzy_match(search_text, app.name)
            local comment_score = fuzzy_match(search_text, app.comment)
            local score = math.max(name_score or 0, (comment_score or 0) * 0.5)

            if score > 0 then
                table.insert(scored, { app = app, score = score })
            end
        end

        table.sort(scored, function(a, b)
            return a.score > b.score
        end)

        for i = 1, math.min(config.max_results, #scored) do
            table.insert(filtered_apps, scored[i].app)
        end
    end

    -- Reset selection
    selected_index = math.min(selected_index, math.max(1, #filtered_apps))
end

--- Create an app item widget
local function create_app_item(app, index)
    local is_selected = index == selected_index

    local icon_widget
    if app.icon then
        icon_widget = wibox.widget({
            image = app.icon,
            resize = true,
            forced_width = config.icon_size,
            forced_height = config.icon_size,
            widget = wibox.widget.imagebox,
        })
    else
        icon_widget = wibox.widget({
            {
                text = "",
                font = "JetBrainsMono Nerd Font 24",
                halign = "center",
                valign = "center",
                widget = wibox.widget.textbox,
            },
            forced_width = config.icon_size,
            forced_height = config.icon_size,
            fg = beautiful.fg_normal,
            widget = wibox.container.background,
        })
    end

    local item = wibox.widget({
        {
            {
                icon_widget,
                {
                    {
                        text = app.name,
                        font = "JetBrainsMono Nerd Font 12",
                        widget = wibox.widget.textbox,
                    },
                    {
                        text = app.comment ~= "" and app.comment or app.exec:match("^%S+"),
                        font = "JetBrainsMono Nerd Font 10",
                        widget = wibox.widget.textbox,
                    },
                    spacing = 2,
                    layout = wibox.layout.fixed.vertical,
                },
                spacing = 12,
                layout = wibox.layout.fixed.horizontal,
            },
            margins = 8,
            widget = wibox.container.margin,
        },
        bg = is_selected and (beautiful.primary_color or "#d65d0e") or "transparent",
        fg = is_selected and beautiful.bg_normal or beautiful.fg_normal,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, 6)
        end,
        forced_height = config.item_height,
        widget = wibox.container.background,
    })

    -- Click to launch
    item:buttons(gears.table.join(
        awful.button({}, 1, function()
            launcher.hide()
            awful.spawn(app.exec)
        end)
    ))

    -- Hover
    item:connect_signal("mouse::enter", function()
        selected_index = index
        launcher.refresh()
    end)

    return item
end

--- Create the search input widget
local function create_search_input()
    return wibox.widget({
        {
            {
                {
                    text = "",
                    font = "JetBrainsMono Nerd Font 18",
                    widget = wibox.widget.textbox,
                },
                fg = beautiful.primary_color or "#d65d0e",
                widget = wibox.container.background,
            },
            {
                id = "search_text",
                text = search_text == "" and "Search applications..." or search_text,
                font = "JetBrainsMono Nerd Font 14",
                widget = wibox.widget.textbox,
            },
            spacing = 12,
            layout = wibox.layout.fixed.horizontal,
        },
        {
            {
                orientation = "horizontal",
                forced_height = 2,
                color = beautiful.primary_color or "#d65d0e",
                widget = wibox.widget.separator,
            },
            top = 8,
            widget = wibox.container.margin,
        },
        layout = wibox.layout.fixed.vertical,
    })
end

--- Create the results list widget
local function create_results_list()
    local items = {}

    for i, app in ipairs(filtered_apps) do
        table.insert(items, create_app_item(app, i))
    end

    if #items == 0 then
        return wibox.widget({
            {
                text = "No applications found",
                font = "JetBrainsMono Nerd Font 12",
                halign = "center",
                widget = wibox.widget.textbox,
            },
            fg = beautiful.fg_normal .. "88",
            widget = wibox.container.background,
        })
    end

    return wibox.widget({
        table.unpack(items),
        spacing = 4,
        layout = wibox.layout.fixed.vertical,
    })
end

--- Create the main launcher widget
local function create_launcher_widget()
    return wibox.widget({
        {
            {
                create_search_input(),
                {
                    create_results_list(),
                    top = 16,
                    widget = wibox.container.margin,
                },
                layout = wibox.layout.fixed.vertical,
            },
            margins = config.margin,
            widget = wibox.container.margin,
        },
        bg = (beautiful.bg_normal or "#282828") .. "F8",
        shape = config.shape,
        widget = wibox.container.background,
    })
end

--- Refresh the launcher display
function launcher.refresh()
    if launcher_popup then
        filter_apps()
        launcher_popup.widget = create_launcher_widget()
    end
end

--- Launch selected app
local function launch_selected()
    if #filtered_apps > 0 and filtered_apps[selected_index] then
        launcher.hide()
        awful.spawn(filtered_apps[selected_index].exec)
    end
end

--- Key grabber for launcher input
local keygrabber = nil

local function start_keygrabber()
    keygrabber = awful.keygrabber({
        autostart = true,
        stop_key = "Escape",
        stop_callback = function()
            launcher.hide()
        end,
        keypressed_callback = function(_, _, key, _)
            if key == "Return" then
                launch_selected()
            elseif key == "Up" then
                selected_index = math.max(1, selected_index - 1)
                launcher.refresh()
            elseif key == "Down" then
                selected_index = math.min(#filtered_apps, selected_index + 1)
                launcher.refresh()
            elseif key == "BackSpace" then
                search_text = search_text:sub(1, -2)
                launcher.refresh()
            elseif key == "Tab" then
                -- Tab completion - fill in selected app name
                if #filtered_apps > 0 then
                    search_text = filtered_apps[selected_index].name
                    launcher.refresh()
                end
            elseif #key == 1 then
                -- Single character - add to search
                search_text = search_text .. key
                launcher.refresh()
            end
        end,
    })
end

--- Show the launcher
function launcher.show()
    if launcher_visible then
        return
    end

    -- Load apps if not already loaded
    if #all_apps == 0 then
        load_apps()
    end

    -- Reset state
    search_text = ""
    selected_index = 1
    filter_apps()

    local s = awful.screen.focused()

    if not launcher_popup then
        launcher_popup = awful.popup({
            widget = create_launcher_widget(),
            screen = s,
            placement = awful.placement.centered,
            ontop = true,
            visible = false,
            bg = "#00000000",
            border_width = beautiful.border_width or 1,
            border_color = beautiful.primary_color or "#d65d0e",
            shape = config.shape,
        })
    end

    launcher_popup.screen = s
    awful.placement.centered(launcher_popup, { parent = s })
    launcher_popup.widget = create_launcher_widget()
    launcher_popup.visible = true
    launcher_visible = true

    start_keygrabber()

    awesome.emit_signal("launcher::visible", true)
end

--- Hide the launcher
function launcher.hide()
    if not launcher_visible then
        return
    end

    if keygrabber then
        keygrabber:stop()
        keygrabber = nil
    end

    if launcher_popup then
        launcher_popup.visible = false
    end

    launcher_visible = false
    awesome.emit_signal("launcher::visible", false)
end

--- Toggle the launcher
function launcher.toggle()
    if launcher_visible then
        launcher.hide()
    else
        launcher.show()
    end
end

--- Check if launcher is visible
function launcher.is_visible()
    return launcher_visible
end

--- Reload applications
function launcher.reload()
    load_apps()
end

return launcher
