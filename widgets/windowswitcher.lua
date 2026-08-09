local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local windowswitcher = {}

-- State
local popup = nil
local visible = false
local clients = {}
local selected_index = 1
local keygrabber = nil

-- Configuration
local config = {
  width = 400,
  icon_size = 32,
  item_height = 44,
  max_items = 10,
  margin = 12,
}

-- Get window icon or fallback
local function get_client_icon(c)
  if c.icon then
    return c.icon
  end
  return nil
end

-- Create a single client item widget
local function create_client_item(c, index)
  local is_selected = index == selected_index

  local icon_widget
  local icon = get_client_icon(c)
  if icon then
    icon_widget = wibox.widget({
      image = icon,
      resize = true,
      forced_width = config.icon_size,
      forced_height = config.icon_size,
      widget = wibox.widget.imagebox,
    })
  else
    -- Fallback: colored initial
    local initial = (c.class or c.name or "?"):sub(1, 1):upper()
    icon_widget = wibox.widget({
      {
        {
          text = initial,
          font = beautiful.font_size(14, "Bold"),
          halign = "center",
          valign = "center",
          widget = wibox.widget.textbox,
        },
        fg = "#282828",
        widget = wibox.container.background,
      },
      bg = beautiful.primary_color,
      shape = gears.shape.rectangle,
      forced_width = config.icon_size,
      forced_height = config.icon_size,
      widget = wibox.container.background,
    })
  end

  -- Truncate long titles
  local title = c.name or c.class or "Unknown"
  if #title > 40 then
    title = title:sub(1, 37) .. "..."
  end

  local item = wibox.widget({
    {
      {
        icon_widget,
        {
          {
            text = title,
            font = beautiful.font_size(11),
            ellipsize = "end",
            widget = wibox.widget.textbox,
          },
          {
            text = c.class or "",
            font = beautiful.font_size(9),
            widget = wibox.widget.textbox,
          },
          spacing = 2,
          layout = wibox.layout.fixed.vertical,
        },
        spacing = 10,
        layout = wibox.layout.fixed.horizontal,
      },
      margins = 6,
      widget = wibox.container.margin,
    },
    bg = is_selected and beautiful.primary_color or "transparent",
    fg = is_selected and beautiful.bg_normal or beautiful.fg_normal,
    shape = beautiful.shape_small,
    forced_height = config.item_height,
    widget = wibox.container.background,
  })

  return item
end

-- Create the client list widget
local function create_client_list()
  local layout = wibox.layout.fixed.vertical()
  layout.spacing = 4

  for i, c in ipairs(clients) do
    if i <= config.max_items then
      layout:add(create_client_item(c, i))
    end
  end

  return layout
end

-- Create the main popup widget
local function create_popup_widget()
  if #clients == 0 then
    return wibox.widget({
      {
        text = "No windows",
        font = beautiful.font_size(12),
        halign = "center",
        widget = wibox.widget.textbox,
      },
      fg = beautiful.fg_normal .. "88",
      widget = wibox.container.background,
    })
  end

  return wibox.widget({
    {
      {
        -- Header
        {
          text = "Switch Window",
          font = beautiful.font_size(12, "Bold"),
          halign = "center",
          widget = wibox.widget.textbox,
        },
        {
          orientation = "horizontal",
          forced_height = 2,
          color = beautiful.primary_color,
          widget = wibox.widget.separator,
        },
        -- Client list
        {
          create_client_list(),
          top = 8,
          widget = wibox.container.margin,
        },
        spacing = 8,
        layout = wibox.layout.fixed.vertical,
      },
      margins = config.margin,
      widget = wibox.container.margin,
    },
    bg = beautiful.bg_normal .. "F8",
    shape = beautiful.shape,
    forced_width = config.width,
    widget = wibox.container.background,
  })
end

-- Refresh the popup display
local function refresh()
  if popup then
    popup.widget = create_popup_widget()
  end
end

-- Collect all clients
local function collect_clients()
  clients = {}
  local seen = {}

  -- awful keeps a most-recent-first stack of focused clients; walking it
  -- first gives real Alt-Tab ordering, with the current window at index 1.
  for _, c in ipairs(awful.client.focus.history.list) do
    if (c:isvisible() or c.minimized) and not seen[c] then
      seen[c] = true
      table.insert(clients, c)
    end
  end

  -- Clients that were never focused (e.g. spawned in the background) go last.
  for _, c in ipairs(client.get()) do
    if (c:isvisible() or c.minimized) and not seen[c] then
      seen[c] = true
      table.insert(clients, c)
    end
  end
end

-- Show the window switcher
function windowswitcher.show()
  if visible then
    return
  end

  collect_clients()
  if #clients == 0 then
    return
  end

  -- Start at second item (first is current window)
  selected_index = math.min(2, #clients)

  local s = awful.screen.focused()

  if not popup then
    popup = awful.popup({
      widget = create_popup_widget(),
      screen = s,
      placement = awful.placement.centered,
      ontop = true,
      visible = false,
      bg = "#00000000",
      border_width = beautiful.border_width or 1,
      border_color = beautiful.primary_color,
      shape = beautiful.shape,
    })
  end

  popup.screen = s
  awful.placement.centered(popup, { parent = s })
  popup.widget = create_popup_widget()
  popup.visible = true
  visible = true

  -- Start keygrabber with modifier key events enabled
  keygrabber = awful.keygrabber({
    autostart = true,
    stop_key = nil,
    mask_modkeys = false, -- Receive modifier key events
    keypressed_callback = function(_, mod, key, _)
      if key == "Tab" then
        -- Check if Shift is held for reverse
        local shift_held = false
        for _, m in ipairs(mod) do
          if m == "Shift" then
            shift_held = true
            break
          end
        end

        if shift_held then
          selected_index = selected_index - 1
          if selected_index < 1 then
            selected_index = #clients
          end
        else
          selected_index = selected_index + 1
          if selected_index > #clients then
            selected_index = 1
          end
        end
        refresh()
      elseif key == "Return" then
        -- Enter also activates
        windowswitcher.activate()
      elseif key == "Escape" then
        windowswitcher.hide()
      end
    end,
    keyreleased_callback = function(_, _, key, _)
      -- Activate when Super key is released
      if key == "Super_L" or key == "Super_R" then
        windowswitcher.activate()
      end
    end,
    stop_callback = function()
      -- Keygrabber stopped externally
      if visible then
        windowswitcher.hide()
      end
    end,
  })
end

-- Hide without activating
function windowswitcher.hide()
  if not visible then
    return
  end

  visible = false

  if keygrabber then
    keygrabber:stop()
    keygrabber = nil
  end

  if popup then
    popup.visible = false
  end
end

-- Activate selected window and hide
function windowswitcher.activate()
  if not visible then
    return
  end

  local c = clients[selected_index]

  windowswitcher.hide()

  if c then
    if c.minimized then
      c.minimized = false
    end
    c:jump_to()
  end
end

-- Toggle
function windowswitcher.toggle()
  if visible then
    windowswitcher.hide()
  else
    windowswitcher.show()
  end
end

return windowswitcher
