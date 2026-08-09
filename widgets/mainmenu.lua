local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local hotkeys_popup = require("awful.hotkeys_popup")

local mainmenu = {}

-- State
local menu_popup = nil
local menu_visible = false
local selected_index = 1
local keygrabber = nil

-- Configuration
local config = {
  width = 220,
  item_height = 36,
  separator_height = 12,
  margin = 8,
  icon_width = 28,
}

-- Menu items definition
-- type: "item" | "separator" | "submenu"
local menu_items = {
  { type = "item", icon = "󰀻", label = "Apps", action = "submenu", submenu = "apps" },
  { type = "separator" },
  { type = "item", icon = "󰙀", label = "File Manager", command = "thunar" },
  { type = "item", icon = "", label = "Terminal", command = "ghostty" },
  { type = "item", icon = "󰒓", label = "Settings", command = "gnome-control-center" },
  { type = "item", icon = "󰋜", label = "Hotkeys", action = "hotkeys" },
  { type = "separator" },
  { type = "item", icon = "󰌾", label = "Lock", action = "lock" },
  { type = "item", icon = "󰗼", label = "Logout", action = "logout" },
  { type = "item", icon = "", label = "Restart", action = "restart" },
  { type = "item", icon = "󰐥", label = "Shutdown", command = "systemctl poweroff" },
}

-- Get selectable items (exclude separators)
local function get_selectable_items()
  local items = {}
  for i, item in ipairs(menu_items) do
    if item.type == "item" then
      table.insert(items, { index = i, item = item })
    end
  end
  return items
end

-- Execute menu item action
local function execute_item(item)
  mainmenu.hide()

  if item.command then
    awful.spawn(item.command)
  elseif item.action == "hotkeys" then
    hotkeys_popup.show_help(nil, awful.screen.focused())
  elseif item.action == "lock" then
    awesome:lock()
  elseif item.action == "logout" then
    awesome.quit()
  elseif item.action == "restart" then
    awesome.restart()
  elseif item.action == "submenu" then
    -- TODO: implement submenus
    -- For now, open the launcher as "Apps"
    local launcher = require("launcher")
    launcher.show()
  end
end

-- Create a menu item widget
local function create_menu_item(item, index)
  local selectable_items = get_selectable_items()
  local is_selected = false

  -- Find if this index matches the selected selectable item
  for si, sel in ipairs(selectable_items) do
    if sel.index == index and si == selected_index then
      is_selected = true
      break
    end
  end

  local icon_widget = wibox.widget({
    text = item.icon or "",
    font = "JetBrainsMono Nerd Font 16",
    halign = "center",
    forced_width = config.icon_width,
    widget = wibox.widget.textbox,
  })

  local label_widget = wibox.widget({
    text = item.label,
    font = "JetBrainsMono Nerd Font 11",
    widget = wibox.widget.textbox,
  })

  -- Arrow for submenus
  local arrow_widget = nil
  if item.action == "submenu" then
    arrow_widget = wibox.widget({
      text = "󰅂",
      font = "JetBrainsMono Nerd Font 12",
      halign = "right",
      widget = wibox.widget.textbox,
    })
  end

  local item_widget = wibox.widget({
    {
      {
        icon_widget,
        {
          label_widget,
          nil,
          arrow_widget,
          layout = wibox.layout.align.horizontal,
        },
        spacing = 8,
        layout = wibox.layout.fixed.horizontal,
      },
      left = config.margin,
      right = config.margin,
      widget = wibox.container.margin,
    },
    bg = is_selected and (beautiful.primary_color or "#d65d0e") or "transparent",
    fg = is_selected and (beautiful.bg_normal or "#282828") or (beautiful.fg_normal or "#ebdbb2"),
    shape = beautiful.shape_small,
    forced_height = config.item_height,
    widget = wibox.container.background,
  })

  -- Mouse interactions
  item_widget:add_button(awful.button({}, 1, function()
    execute_item(item)
  end))

  item_widget:connect_signal("mouse::enter", function()
    -- Update selection to this item
    for si, sel in ipairs(selectable_items) do
      if sel.index == index then
        selected_index = si
        mainmenu.refresh()
        break
      end
    end
  end)

  return item_widget
end

-- Create a separator widget
local function create_separator()
  return wibox.widget({
    {
      {
        orientation = "horizontal",
        forced_height = 1,
        color = (beautiful.fg_normal or "#ebdbb2") .. "33",
        widget = wibox.widget.separator,
      },
      left = config.margin + config.icon_width + 8,
      right = config.margin,
      top = (config.separator_height - 1) / 2,
      bottom = (config.separator_height - 1) / 2,
      widget = wibox.container.margin,
    },
    forced_height = config.separator_height,
    widget = wibox.container.background,
  })
end

-- Create the menu widget
local function create_menu_widget()
  local layout = wibox.layout.fixed.vertical()

  for i, item in ipairs(menu_items) do
    if item.type == "separator" then
      layout:add(create_separator())
    else
      layout:add(create_menu_item(item, i))
    end
  end

  -- Calculate height
  local height = config.margin * 2
  for _, item in ipairs(menu_items) do
    if item.type == "separator" then
      height = height + config.separator_height
    else
      height = height + config.item_height
    end
  end

  return wibox.widget({
    {
      layout,
      margins = config.margin,
      widget = wibox.container.margin,
    },
    bg = (beautiful.bg_normal or "#282828") .. "F5",
    shape = beautiful.shape,
    forced_width = config.width,
    forced_height = height,
    widget = wibox.container.background,
  })
end

-- Refresh menu display
function mainmenu.refresh()
  if menu_popup then
    menu_popup.widget = create_menu_widget()
  end
end

-- Start keyboard grabber
local function start_keygrabber()
  local selectable_items = get_selectable_items()

  keygrabber = awful.keygrabber({
    autostart = true,
    stop_key = "Escape",
    stop_callback = function()
      if menu_popup then
        menu_popup.visible = false
      end
      menu_visible = false
      keygrabber = nil
    end,
    keypressed_callback = function(_, _, key, _)
      if key == "Return" then
        local sel = selectable_items[selected_index]
        if sel then
          execute_item(sel.item)
        end
      elseif key == "Up" or key == "k" then
        selected_index = selected_index - 1
        if selected_index < 1 then
          selected_index = #selectable_items
        end
        mainmenu.refresh()
      elseif key == "Down" or key == "j" then
        selected_index = selected_index + 1
        if selected_index > #selectable_items then
          selected_index = 1
        end
        mainmenu.refresh()
      end
    end,
  })
end

-- Show the menu
function mainmenu.show()
  if menu_visible then
    return
  end

  -- Reset selection
  selected_index = 1

  local coords = mouse.coords()
  local s = awful.screen.focused()

  if not menu_popup then
    menu_popup = awful.popup({
      widget = create_menu_widget(),
      screen = s,
      ontop = true,
      visible = false,
      bg = "#00000000",
      shape = beautiful.shape,
      border_width = beautiful.border_width or 1,
      border_color = beautiful.primary_color or "#d65d0e",
    })
  end

  -- Position at mouse cursor
  menu_popup.x = coords.x
  menu_popup.y = coords.y
  menu_popup.screen = s

  -- Keep on screen
  local geo = menu_popup:geometry()
  local screen_geo = s.geometry

  if geo.x + geo.width > screen_geo.x + screen_geo.width then
    menu_popup.x = screen_geo.x + screen_geo.width - geo.width - 10
  end
  if geo.y + geo.height > screen_geo.y + screen_geo.height then
    menu_popup.y = screen_geo.y + screen_geo.height - geo.height - 10
  end

  menu_popup.widget = create_menu_widget()
  menu_popup.visible = true
  menu_visible = true

  start_keygrabber()
end

-- Hide the menu
function mainmenu.hide()
  if not menu_visible then
    return
  end

  menu_visible = false

  local kg = keygrabber
  keygrabber = nil
  if kg then
    kg:stop()
  end

  if menu_popup then
    menu_popup.visible = false
  end
end

-- Toggle the menu
function mainmenu.toggle()
  if menu_visible then
    mainmenu.hide()
  else
    mainmenu.show()
  end
end

-- For backwards compatibility, return a table that can be used with :toggle()
-- This makes it work with the existing rc.lua that calls mymainmenu:toggle()
local mt = {}
mt.__index = mainmenu
mt.__call = function(_, ...)
  return mainmenu.toggle(...)
end

setmetatable(mainmenu, mt)

return mainmenu
