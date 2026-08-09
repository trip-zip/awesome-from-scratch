local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local hotkeys_popup = require("awful.hotkeys_popup")
local modal = require("modal")

local mainmenu = {}

-- State
local selected_index = 1

-- Configuration
local config = {
  width = 220,
  item_height = 36,
  separator_height = 12,
  margin = 8,
  icon_width = 28,
}

-- The applications the menu launches - one obvious place to change them
local apps = {
  file_manager = "thunar",
  terminal = "ghostty",
  settings = "gnome-control-center",
}

-- Menu items definition
-- type: "item" | "separator"
local menu_items = {
  { type = "item", icon = "󰀻", label = "Apps", action = "launcher" },
  { type = "separator" },
  { type = "item", icon = "󰙀", label = "File Manager", command = apps.file_manager },
  { type = "item", icon = "", label = "Terminal", command = apps.terminal },
  { type = "item", icon = "󰒓", label = "Settings", command = apps.settings },
  { type = "item", icon = "󰋜", label = "Hotkeys", action = "hotkeys" },
  { type = "separator" },
  { type = "item", icon = "󰌾", label = "Lock", action = "lock" },
  { type = "item", icon = "󰗼", label = "Logout", action = "logout" },
  { type = "item", icon = "", label = "Restart", action = "restart" },
  { type = "item", icon = "󰐥", label = "Shutdown", command = "systemctl poweroff" },
}

-- Selectable items (everything except separators), computed once. Each item
-- learns its own ordinal, so selection checks are a direct comparison instead
-- of a scan per widget.
local selectable_items = {}
for _, item in ipairs(menu_items) do
  if item.type == "item" then
    table.insert(selectable_items, item)
    item.selectable_index = #selectable_items
  end
end

-- Execute menu item action
local function execute_item(item)
  mainmenu.hide()

  if item.command then
    awful.spawn(item.command)
  elseif item.action == "hotkeys" then
    hotkeys_popup.show_help(nil, awful.screen.focused())
  elseif item.action == "lock" then
    awesome.lock()
  elseif item.action == "logout" then
    awesome.quit()
  elseif item.action == "restart" then
    awesome.restart()
  elseif item.action == "launcher" then
    require("launcher").show()
  end
end

-- Create a menu item widget
local function create_menu_item(item)
  local is_selected = item.selectable_index == selected_index

  local icon_widget = wibox.widget({
    text = item.icon or "",
    font = beautiful.font_size(16),
    halign = "center",
    forced_width = config.icon_width,
    widget = wibox.widget.textbox,
  })

  local label_widget = wibox.widget({
    text = item.label,
    font = beautiful.font_size(11),
    widget = wibox.widget.textbox,
  })

  local item_widget = wibox.widget({
    {
      {
        icon_widget,
        label_widget,
        spacing = 8,
        layout = wibox.layout.fixed.horizontal,
      },
      left = config.margin,
      right = config.margin,
      widget = wibox.container.margin,
    },
    bg = is_selected and beautiful.primary_color or "transparent",
    fg = is_selected and beautiful.bg_normal or beautiful.fg_normal,
    shape = beautiful.shape_small,
    forced_height = config.item_height,
    widget = wibox.container.background,
  })

  -- Mouse interactions
  item_widget:add_button(awful.button({}, 1, function()
    execute_item(item)
  end))

  item_widget:connect_signal("mouse::enter", function()
    if item.selectable_index == selected_index then
      return
    end
    selected_index = item.selectable_index
    mainmenu.refresh()
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
        color = beautiful.fg_normal .. "33",
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

  for _, item in ipairs(menu_items) do
    if item.type == "separator" then
      layout:add(create_separator())
    else
      layout:add(create_menu_item(item))
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
    bg = beautiful.bg_normal .. "F5",
    shape = beautiful.shape,
    forced_width = config.width,
    forced_height = height,
    widget = wibox.container.background,
  })
end

-- Where the menu opens: the mouse position at show time. One placement
-- function, installed on the popup (so awful.popup re-applies it whenever
-- the popup is resized, covering the not-yet-measured first show) and called
-- from on_show (so a new anchor takes effect even when the size is unchanged).
local anchor = { x = 0, y = 0 }

local function place(d)
  d.x = anchor.x
  d.y = anchor.y
  awful.placement.no_offscreen(d, { honor_workarea = true, margins = 10 })
end

-- The modal controller owns visibility, the keygrabber, and Escape; this
-- module only describes content, cursor placement, and navigation keys.
local controller = modal.new({
  name = "mainmenu",
  build_popup = function()
    return awful.popup({
      widget = create_menu_widget(),
      screen = awful.screen.focused(),
      ontop = true,
      visible = false,
      bg = "#00000000",
      shape = beautiful.shape,
      border_width = beautiful.border_width or 1,
      border_color = beautiful.primary_color,
      placement = place,
    })
  end,
  on_show = function(popup)
    selected_index = 1
    anchor = mouse.coords()
    popup.widget = create_menu_widget()
    place(popup)
  end,
  keypressed = function(_, key)
    if key == "Return" then
      local item = selectable_items[selected_index]
      if item then
        execute_item(item)
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

-- Refresh menu display
function mainmenu.refresh()
  if controller.popup then
    controller.popup.widget = create_menu_widget()
  end
end

mainmenu.show = controller.show
mainmenu.hide = controller.hide
mainmenu.toggle = controller.toggle
mainmenu.is_visible = controller.is_visible

return mainmenu
