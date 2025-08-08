-- Advanced Notification System for AwesomeWM
-- This module provides comprehensive notification handling with:
-- - Rule-based filtering and styling
-- - Interactive notifications with actions
-- - Custom positioning and layouts
-- - App-specific handling
-- - Notification center/history

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local ruled = require("ruled")
local naughty = require("naughty")
local beautiful = require("beautiful")

-- Module table
local M = {}

-- Configuration
M.config = {
  -- Default timeout for notifications (seconds)
  default_timeout = 5,
  
  -- Position presets
  positions = {
    top_right = "top_right",
    top_left = "top_left",
    bottom_right = "bottom_right",
    bottom_left = "bottom_left",
    top_middle = "top_middle",
    bottom_middle = "bottom_middle",
  },
  
  -- Special contacts for custom styling
  special_contacts = {
    wife = { "Wife", "Honey", "Love" }, -- Add actual contact names
  },
  
  -- DND mode settings
  dnd_mode = false,
  focus_mode = false,
  
  -- Sound settings
  enable_sounds = true,
  sound_files = {
    normal = "/usr/share/sounds/freedesktop/stereo/message.oga",
    critical = "/usr/share/sounds/freedesktop/stereo/complete.oga",
  },
}

-- Notification history storage
M.history = {}
M.max_history = 50

-- Helper function to check if notification matches special contact
local function is_special_contact(notification, contact_group)
  if not notification.message then return false end
  
  for _, name in ipairs(M.config.special_contacts[contact_group] or {}) do
    if notification.message:match(name) or 
       (notification.title and notification.title:match(name)) then
      return true
    end
  end
  return false
end

-- Helper function to add notification to history
local function add_to_history(notification)
  table.insert(M.history, 1, {
    title = notification.title,
    message = notification.message,
    app_name = notification.app_name,
    timestamp = os.time(),
    urgency = notification.urgency,
    icon = notification.icon,
  })
  
  -- Trim history if too long
  while #M.history > M.max_history do
    table.remove(M.history)
  end
end

-- Helper function to play notification sound
local function play_sound(urgency)
  if not M.config.enable_sounds then return end
  
  local sound_file = M.config.sound_files[urgency] or M.config.sound_files.normal
  if sound_file then
    awful.spawn.easy_async("paplay " .. sound_file, function() end)
  end
end

-- Create notification center widget
M.notification_center = awful.popup({
  ontop = true,
  visible = false,
  shape = function(cr, width, height)
    gears.shape.rounded_rect(cr, width, height, beautiful.border_radius or 8)
  end,
  border_width = beautiful.border_width or 2,
  border_color = beautiful.border_focus or beautiful.bg_focus,
  maximum_width = 500,
  maximum_height = 600,
  offset = { y = beautiful.wibar_height or 30 },
  widget = {},
})

-- Update notification center content
local function update_notification_center()
  local rows = { layout = wibox.layout.fixed.vertical, spacing = 5 }
  
  -- Header
  local header = wibox.widget({
    {
      {
        text = "Notification History",
        font = beautiful.font_name .. " Bold 14",
        widget = wibox.widget.textbox,
      },
      {
        text = "(" .. #M.history .. " notifications)",
        widget = wibox.widget.textbox,
      },
      layout = wibox.layout.fixed.horizontal,
      spacing = 10,
    },
    {
      {
        text = "Clear All",
        widget = wibox.widget.textbox,
      },
      widget = wibox.container.background,
      bg = beautiful.bg_minimize,
      shape = gears.shape.rounded_rect,
      forced_width = 80,
      forced_height = 30,
      buttons = awful.button({}, 1, function()
        M.history = {}
        update_notification_center()
      end),
    },
    layout = wibox.layout.align.horizontal,
  })
  
  table.insert(rows, wibox.container.margin(header, 10, 10, 10, 5))
  table.insert(rows, wibox.widget({
    widget = wibox.widget.separator,
    orientation = "horizontal",
    thickness = 1,
    color = beautiful.border_color,
  }))
  
  -- Notification items
  if #M.history == 0 then
    table.insert(rows, wibox.container.margin(wibox.widget({
      text = "No notifications",
      align = "center",
      widget = wibox.widget.textbox,
    }), 10, 10, 50, 50))
  else
    for i, notif in ipairs(M.history) do
      if i > 20 then break end -- Limit displayed items
      
      local time_str = os.date("%H:%M", notif.timestamp)
      local item = wibox.widget({
        {
          {
            {
              markup = "<b>" .. (notif.title or "Notification") .. "</b>",
              widget = wibox.widget.textbox,
            },
            {
              text = notif.app_name or "",
              opacity = 0.6,
              widget = wibox.widget.textbox,
            },
            {
              text = time_str,
              opacity = 0.6,
              widget = wibox.widget.textbox,
            },
            layout = wibox.layout.align.horizontal,
          },
          {
            text = notif.message or "",
            widget = wibox.widget.textbox,
            wrap = "word",
          },
          layout = wibox.layout.fixed.vertical,
          spacing = 2,
        },
        widget = wibox.container.background,
        bg = beautiful.bg_normal,
        shape = gears.shape.rounded_rect,
        forced_height = 80,
      })
      
      -- Add urgency indicator
      if notif.urgency == "critical" then
        item.bg = beautiful.bg_urgent
      end
      
      table.insert(rows, wibox.container.margin(item, 10, 10, 5, 5))
    end
  end
  
  -- Scrollable container
  M.notification_center:setup({
    rows,
    layout = wibox.layout.fixed.vertical,
  })
end

-- Toggle notification center visibility
function M.toggle_notification_center()
  update_notification_center()
  
  if M.notification_center.visible then
    M.notification_center.visible = false
  else
    M.notification_center:move_next_to(mouse.current_widget_geometry or 
      { x = screen.primary.geometry.width - 250, y = 0 })
    M.notification_center.visible = true
  end
end

-- Setup notification rules
ruled.notification.connect_signal("request::rules", function()
  -- Default rule for all notifications
  ruled.notification.append_rule({
    rule = {},
    properties = {
      screen = awful.screen.preferred,
      implicit_timeout = M.config.default_timeout,
      position = M.config.positions.top_right,
    },
  })
  
  -- Critical notifications
  ruled.notification.append_rule({
    rule = { urgency = "critical" },
    properties = {
      bg = beautiful.bg_urgent or "#ff0000",
      fg = beautiful.fg_urgent or "#ffffff",
      timeout = 0, -- Never timeout
      border_color = "#ff0000",
      position = M.config.positions.top_middle,
    },
    callback = function(n)
      play_sound("critical")
    end,
  })
  
  -- Low priority notifications
  ruled.notification.append_rule({
    rule = { urgency = "low" },
    properties = {
      bg = beautiful.bg_minimize or beautiful.bg_normal,
      fg = beautiful.fg_minimize or beautiful.fg_normal,
      timeout = 3,
      opacity = 0.8,
    },
  })
  
  -- Browser notifications
  ruled.notification.append_rule({
    rule_any = { 
      app_name = { "Firefox", "Chrome", "Chromium", "Brave" },
    },
    properties = {
      position = M.config.positions.bottom_right,
    },
    callback = function(n)
      -- Check if it's from wife/special contact
      if is_special_contact(n, "wife") then
        n.bg = "#ff69b4" -- Pink background for wife's messages
        n.fg = "#000000"
        n.urgency = "critical"
        n.timeout = 0 -- Don't auto-dismiss
        
        -- Add quick reply action
        n:append_actions(naughty.action({
          name = "Reply",
          icon = beautiful.awesome_icon,
        }))
      end
    end,
  })
  
  -- Discord/Slack notifications
  ruled.notification.append_rule({
    rule_any = {
      app_name = { "discord", "Discord", "slack", "Slack" },
    },
    properties = {
      position = M.config.positions.top_left,
      timeout = 10,
    },
    callback = function(n)
      -- Add actions for messaging apps
      n:append_actions(naughty.action({
        name = "Open",
      }))
      n:append_actions(naughty.action({
        name = "Mark Read",
      }))
    end,
  })
  
  -- Email notifications
  ruled.notification.append_rule({
    rule_any = {
      app_name = { "Thunderbird", "Evolution", "Geary" },
      category = { "email", "email.arrived" },
    },
    properties = {
      position = M.config.positions.bottom_left,
      timeout = 8,
    },
    callback = function(n)
      n:append_actions(naughty.action({
        name = "Read",
      }))
      n:append_actions(naughty.action({
        name = "Archive",
      }))
    end,
  })
  
  -- Media player notifications
  ruled.notification.append_rule({
    rule_any = {
      app_name = { "Spotify", "spotify", "vlc", "mpv" },
      category = { "media", "music" },
    },
    properties = {
      position = M.config.positions.bottom_middle,
      timeout = 4,
    },
  })
  
  -- System notifications
  ruled.notification.append_rule({
    rule_any = {
      category = { "device", "device.added", "device.removed" },
    },
    properties = {
      position = M.config.positions.top_middle,
      timeout = 5,
    },
  })
  
  -- Battery notifications
  ruled.notification.append_rule({
    rule_any = {
      category = { "battery", "power" },
    },
    properties = {
      urgency = "critical",
      position = M.config.positions.top_middle,
      bg = "#ffa500",
      fg = "#000000",
    },
  })
end)

-- Handle notification display
naughty.connect_signal("request::display", function(n)
  -- Add to history
  add_to_history(n)
  
  -- Check DND mode
  if M.config.dnd_mode and n.urgency ~= "critical" then
    return -- Don't display non-critical notifications in DND mode
  end
  
  -- Check focus mode
  if M.config.focus_mode then
    local c = client.focus
    if c and c.fullscreen and n.urgency ~= "critical" then
      return -- Don't show notifications over fullscreen apps
    end
  end
  
  -- Play sound
  play_sound(n.urgency or "normal")
  
  -- Create custom notification layout with actions
  if n.actions and #n.actions > 0 then
    -- Create action buttons
    local actions = wibox.widget({
      notification = n,
      widget = naughty.list.actions,
    })
    
    -- Custom widget template with actions
    n.widget_template = {
      {
        {
          {
            {
              {
                naughty.widget.icon,
                forced_width = 48,
                forced_height = 48,
                widget = wibox.container.constraint,
              },
              margins = 5,
              widget = wibox.container.margin,
            },
            {
              {
                naughty.widget.title,
                font = beautiful.font_name .. " Bold 11",
                widget = wibox.container.scroll.horizontal,
                step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
                speed = 50,
              },
              {
                naughty.widget.message,
                widget = wibox.container.scroll.horizontal,
                step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
                speed = 50,
              },
              layout = wibox.layout.fixed.vertical,
            },
            layout = wibox.layout.fixed.horizontal,
          },
          actions,
          layout = wibox.layout.fixed.vertical,
        },
        margins = 10,
        widget = wibox.container.margin,
      },
      widget = wibox.container.background,
      shape = gears.shape.rounded_rect,
      bg = n.bg or beautiful.bg_normal,
      fg = n.fg or beautiful.fg_normal,
      border_width = beautiful.notification_border_width or 2,
      border_color = n.border_color or beautiful.border_normal,
    }
  end
  
  -- Display the notification
  naughty.layout.box({ notification = n })
end)

-- Handle action invocation
naughty.connect_signal("destroyed", function(n, reason)
  if reason == naughty.notification_closed_reason.dismissed_by_user then
    -- User dismissed the notification
  end
end)

-- Toggle functions
function M.toggle_dnd_mode()
  M.config.dnd_mode = not M.config.dnd_mode
  naughty.notify({
    title = "DND Mode",
    text = M.config.dnd_mode and "Enabled" or "Disabled",
    timeout = 2,
  })
end

function M.toggle_focus_mode()
  M.config.focus_mode = not M.config.focus_mode
  naughty.notify({
    title = "Focus Mode",
    text = M.config.focus_mode and "Enabled" or "Disabled",
    timeout = 2,
  })
end

-- Test notification function
function M.test_notification(urgency, app_name)
  naughty.notification({
    title = "Test Notification",
    message = "This is a test notification with urgency: " .. (urgency or "normal"),
    urgency = urgency or "normal",
    app_name = app_name or "Test App",
    actions = {
      naughty.action({ name = "Accept" }),
      naughty.action({ name = "Decline" }),
    },
  })
end

-- Export old function for compatibility
M.toggle_notif_list = M.toggle_notification_center

return M