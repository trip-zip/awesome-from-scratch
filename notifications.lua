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
local modal = require("modal")

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

  -- VIP contacts. A notification whose title or message mentions one of these names
  -- gets the style below, is bumped to critical, and never times out. Matching is
  -- plain text and case-insensitive, so punctuation in a name is safe.
  --
  -- Empty by default. Put the handful of people you must not miss in here.
  vip_contacts = {},
  vip_style = {
    bg = "#ff69b4",
    fg = "#000000",
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
M.unread_count = 0
M.max_history = 50
M.active_notifications = {} -- Track currently active notifications

-- Snooze storage and configuration
M.snoozed_notifications = {} -- Store snoozed notifications with their timers
M.snooze_durations = {
  { label = "5 minutes", seconds = 5 * 60 },
  { label = "15 minutes", seconds = 15 * 60 },
  { label = "1 hour", seconds = 60 * 60 },
  { label = "3 hours", seconds = 3 * 60 * 60 },
}

-- Does this notification mention one of the VIP contacts?
--
-- Note the `1, true` on find: that is a plain-text search. Without it, a name
-- containing a `-` or `.` would be read as a Lua pattern and match the wrong things.
local function is_vip(notification)
  local haystack = ((notification.title or "") .. " " .. (notification.message or "")):lower()

  for _, name in ipairs(M.config.vip_contacts) do
    if haystack:find(name:lower(), 1, true) then
      return true
    end
  end
  return false
end

-- Helper function to add notification to history
local function add_to_history(notification)
  local history_item = {
    title = notification.title,
    message = notification.message,
    app_name = notification.app_name,
    timestamp = os.time(),
    urgency = notification.urgency,
    icon = notification.icon,
    id = notification.id or tostring(os.time() .. math.random()),
    is_read = false,
  }

  table.insert(M.history, 1, history_item)
  M.unread_count = M.unread_count + 1

  -- Store reference to active notification
  if notification.resident then
    M.active_notifications[history_item.id] = notification
  end

  -- Trim history if too long
  while #M.history > M.max_history do
    local removed = table.remove(M.history)
    if not removed.is_read then
      M.unread_count = math.max(0, M.unread_count - 1)
    end
    if M.active_notifications[removed.id] then
      M.active_notifications[removed.id] = nil
    end
  end
end

-- Helper function to play notification sound
local function play_sound(urgency)
  if not M.config.enable_sounds then
    return
  end

  local sound_file = M.config.sound_files[urgency] or M.config.sound_files.normal
  if sound_file and gears.filesystem.file_readable(sound_file) then
    awful.spawn.easy_async("paplay " .. sound_file, function() end)
  end
end

-- Snooze a notification for a given duration
local function snooze_notification(notif_data, duration_seconds, duration_label)
  local snooze_id = tostring(os.time()) .. "_" .. math.random(1000, 9999)

  -- Create timer to re-fire the notification
  local timer = gears.timer({
    timeout = duration_seconds,
    single_shot = true,
    callback = function()
      -- Re-create the notification
      naughty.notification({
        title = notif_data.title,
        message = notif_data.message .. "\n\n<i>(Snoozed " .. duration_label .. " ago)</i>",
        app_name = notif_data.app_name,
        urgency = notif_data.urgency or "normal",
        icon = notif_data.icon,
      })

      -- Remove from snoozed list
      M.snoozed_notifications[snooze_id] = nil
    end,
  })

  -- Store and start
  M.snoozed_notifications[snooze_id] = {
    data = notif_data,
    timer = timer,
    duration_label = duration_label,
    snooze_time = os.time(),
  }
  timer:start()

  -- Show confirmation
  naughty.notification({
    title = "Snoozed",
    message = '"' .. (notif_data.title or "Notification") .. '" will remind you in ' .. duration_label,
    timeout = 2,
    urgency = "low",
  })
end

-- Snooze duration picker: a small modal anchored near the mouse. The modal
-- controller supplies click-outside dismissal, so the old "connect a one-shot
-- button::press handler after a 0.1s delay" workaround is gone.
local picker_notif_data = nil
local snooze_picker -- the modal controller, created below
local picker_anchor = { x = 0, y = 0 }

-- One placement function: installed on the popup so resizes re-run it, and
-- called from on_show so a fresh anchor takes effect
local function place_picker(d)
  d.x = picker_anchor.x - 80
  d.y = picker_anchor.y + 10
  awful.placement.no_offscreen(d, { honor_workarea = true, margins = 10 })
end

local function build_picker_widget()
  local buttons_layout = wibox.layout.fixed.vertical()
  buttons_layout.spacing = 4

  for _, duration in ipairs(M.snooze_durations) do
    local btn = wibox.widget({
      {
        {
          {
            text = "󰥔", -- nf-md-clock_outline
            font = beautiful.font_size(12),
            forced_width = 20,
            widget = wibox.widget.textbox,
          },
          {
            text = " " .. duration.label,
            widget = wibox.widget.textbox,
          },
          layout = wibox.layout.fixed.horizontal,
        },
        margins = 10,
        widget = wibox.container.margin,
      },
      bg = beautiful.bg_normal,
      fg = beautiful.fg_normal,
      shape = beautiful.shape_small or gears.shape.rectangle,
      widget = wibox.container.background,
    })

    btn:add_button(awful.button({}, 1, function()
      snooze_picker.hide()
      snooze_notification(picker_notif_data, duration.seconds, duration.label)
    end))

    -- Hover effect
    btn:connect_signal("mouse::enter", function()
      btn.bg = beautiful.primary_color
      btn.fg = beautiful.bg_normal
    end)
    btn:connect_signal("mouse::leave", function()
      btn.bg = beautiful.bg_normal
      btn.fg = beautiful.fg_normal
    end)

    buttons_layout:add(btn)
  end

  return wibox.widget({
    {
      {
        {
          markup = "<b>Snooze for...</b>",
          widget = wibox.widget.textbox,
        },
        buttons_layout,
        spacing = 8,
        layout = wibox.layout.fixed.vertical,
      },
      margins = 12,
      widget = wibox.container.margin,
    },
    bg = beautiful.bg_normal .. "F8",
    shape = beautiful.shape or gears.shape.rectangle,
    widget = wibox.container.background,
  })
end

snooze_picker = modal.new({
  name = "snooze_picker",
  build_popup = function()
    return awful.popup({
      widget = build_picker_widget(),
      screen = awful.screen.focused(),
      ontop = true,
      visible = false,
      bg = "#00000000",
      border_width = beautiful.border_width or 1,
      border_color = beautiful.primary_color,
      shape = beautiful.shape or gears.shape.rectangle,
      placement = place_picker,
    })
  end,
  on_show = function(popup)
    picker_anchor = mouse.coords()
    popup.widget = build_picker_widget()
    place_picker(popup)
  end,
})

local function show_snooze_picker(notif_data)
  picker_notif_data = notif_data
  snooze_picker.hide() -- no-op when already hidden
  snooze_picker.show()
end

-- Notification center configuration (following launcher/dashboard patterns)
local nc_config = {
  width = 480,
  max_visible = 15,
  margin = 16,
  spacing = 8,
}

-- Notification center state
local expanded_groups = {} -- Track which app groups are expanded (default: collapsed)

-- Forward declaration for refresh
local refresh_popup

-- Helper: Group notifications by app_name
local function group_notifications_by_app()
  local groups = {}
  local group_order = {}

  for _, notif in ipairs(M.history) do
    local app = notif.app_name or "Unknown"
    if not groups[app] then
      groups[app] = {
        app_name = app,
        notifications = {},
        unread_count = 0,
        latest_timestamp = notif.timestamp,
      }
      table.insert(group_order, app)
    end
    table.insert(groups[app].notifications, notif)
    if not notif.is_read then
      groups[app].unread_count = groups[app].unread_count + 1
    end
    -- Track latest timestamp for sorting
    if notif.timestamp > groups[app].latest_timestamp then
      groups[app].latest_timestamp = notif.timestamp
    end
  end

  -- Sort groups by latest notification timestamp (most recent first)
  table.sort(group_order, function(a, b)
    return groups[a].latest_timestamp > groups[b].latest_timestamp
  end)

  return groups, group_order
end

-- Helper function to format time ago
local function format_time_ago(timestamp)
  local time_diff = os.time() - timestamp
  if time_diff < 60 then
    return "now"
  elseif time_diff < 3600 then
    return math.floor(time_diff / 60) .. "m ago"
  elseif time_diff < 86400 then
    return math.floor(time_diff / 3600) .. "h ago"
  else
    return os.date("%b %d", timestamp)
  end
end

-- Helper: Create group header widget
local function create_group_header(group)
  local is_expanded = expanded_groups[group.app_name]
  local chevron = is_expanded and "▼" or "▶"
  local unread_badge = group.unread_count > 0
      and " <span foreground='" .. beautiful.primary_color .. "'>(" .. group.unread_count .. ")</span>"
    or ""

  local header = wibox.widget({
    {
      {
        -- Chevron + App name + count
        {
          markup = chevron
            .. "  <b>"
            .. gears.string.xml_escape(group.app_name)
            .. "</b>"
            .. " <span foreground='"
            .. beautiful.fg_normal
            .. "88'>"
            .. #group.notifications
            .. " notifications</span>"
            .. unread_badge,
          widget = wibox.widget.textbox,
        },
        nil,
        {
          text = format_time_ago(group.latest_timestamp),
          font = beautiful.font_size(9),
          widget = wibox.widget.textbox,
        },
        layout = wibox.layout.align.horizontal,
      },
      margins = 10,
      widget = wibox.container.margin,
    },
    bg = beautiful.bg_focus,
    fg = beautiful.fg_normal,
    shape = beautiful.shape_small or gears.shape.rounded_rect,
    widget = wibox.container.background,
  })

  -- Click to toggle expand/collapse
  header:add_button(awful.button({}, 1, function()
    expanded_groups[group.app_name] = not expanded_groups[group.app_name]
    refresh_popup()
  end))

  -- Hover effect
  local default_bg = beautiful.bg_focus
  header:connect_signal("mouse::enter", function()
    header.bg = beautiful.primary_color
  end)
  header:connect_signal("mouse::leave", function()
    header.bg = default_bg
  end)

  return header
end

-- Helper: Create notification item widget
local function create_notification_item(notif)
  local time_ago = format_time_ago(notif.timestamp)
  local is_unread = not notif.is_read

  local item_bg = is_unread and beautiful.bg_normal or beautiful.bg_minimize
  if notif.urgency == "critical" and is_unread then
    item_bg = beautiful.bg_urgent
  end

  -- Snooze button
  local fg_color = beautiful.fg_normal
  local snooze_btn = wibox.widget({
    {
      {
        text = "󰥔", -- nf-md-clock_outline
        font = beautiful.font_size(14),
        halign = "center",
        valign = "center",
        widget = wibox.widget.textbox,
      },
      margins = 6,
      widget = wibox.container.margin,
    },
    bg = beautiful.bg_focus,
    fg = fg_color,
    shape = gears.shape.rectangle,
    forced_width = 32,
    forced_height = 32,
    widget = wibox.container.background,
  })

  snooze_btn:add_button(awful.button({}, 1, function()
    show_snooze_picker(notif)
  end))

  snooze_btn:connect_signal("mouse::enter", function()
    snooze_btn.bg = beautiful.primary_color
  end)
  snooze_btn:connect_signal("mouse::leave", function()
    snooze_btn.bg = "transparent"
  end)

  local item = wibox.widget({
    {
      {
        {
          -- Row 1: Title + time
          {
            {
              markup = (is_unread and "<span foreground='" .. beautiful.primary_color .. "'>● </span>" or "")
                .. "<b>"
                .. gears.string.xml_escape(notif.title or "Notification")
                .. "</b>",
              widget = wibox.widget.textbox,
            },
            nil,
            {
              text = time_ago,
              font = beautiful.font_size(9),
              widget = wibox.widget.textbox,
            },
            layout = wibox.layout.align.horizontal,
          },
          -- Row 2: Message (truncated)
          {
            markup = gears.string.xml_escape(notif.message or ""),
            ellipsize = "end",
            widget = wibox.widget.textbox,
          },
          spacing = 2,
          layout = wibox.layout.fixed.vertical,
        },
        nil,
        snooze_btn,
        layout = wibox.layout.align.horizontal,
      },
      left = 20, -- Indent under group header
      right = 10,
      top = 8,
      bottom = 8,
      widget = wibox.container.margin,
    },
    bg = item_bg,
    shape = beautiful.shape_small or gears.shape.rounded_rect,
    widget = wibox.container.background,
  })

  -- Click to mark as read (but not when clicking snooze button)
  item:add_button(awful.button({}, 1, function()
    if not notif.is_read then
      notif.is_read = true
      M.unread_count = math.max(0, M.unread_count - 1)
      awesome.emit_signal("notification::unread_count", M.unread_count)
      refresh_popup()
    end
  end))

  -- Hover effect
  item:connect_signal("mouse::enter", function()
    item.bg = beautiful.bg_focus
  end)
  item:connect_signal("mouse::leave", function()
    item.bg = item_bg
  end)

  return item
end

-- Helper: Create header widget
local function create_header()
  local unread_text = M.unread_count > 0 and " (" .. M.unread_count .. " unread)" or ""

  -- Clear Read button
  local clear_read_btn = wibox.widget({
    {
      {
        text = "Clear Read",
        align = "center",
        widget = wibox.widget.textbox,
      },
      margins = 4,
      widget = wibox.container.margin,
    },
    bg = beautiful.bg_minimize,
    fg = beautiful.fg_normal,
    shape = beautiful.shape_small or gears.shape.rounded_rect,
    forced_width = 80,
    forced_height = 26,
    widget = wibox.container.background,
  })

  clear_read_btn:add_button(awful.button({}, 1, function()
    local new_history = {}
    for _, notif in ipairs(M.history) do
      if not notif.is_read then
        table.insert(new_history, notif)
      else
        if M.active_notifications[notif.id] then
          M.active_notifications[notif.id] = nil
        end
      end
    end
    M.history = new_history
    awesome.emit_signal("notification::unread_count", M.unread_count)
    refresh_popup()
  end))

  -- Clear All button
  local clear_all_btn = wibox.widget({
    {
      {
        text = "Clear All",
        align = "center",
        widget = wibox.widget.textbox,
      },
      margins = 4,
      widget = wibox.container.margin,
    },
    bg = "#cc241d",
    fg = beautiful.fg_urgent,
    shape = beautiful.shape_small or gears.shape.rounded_rect,
    forced_width = 80,
    forced_height = 26,
    widget = wibox.container.background,
  })

  clear_all_btn:add_button(awful.button({}, 1, function()
    M.history = {}
    M.unread_count = 0
    M.active_notifications = {}
    awesome.emit_signal("notification::unread_count", M.unread_count)
    refresh_popup()
  end))

  return wibox.widget({
    {
      markup = "<b>Notifications</b>" .. unread_text,
      font = beautiful.font_size(14),
      widget = wibox.widget.textbox,
    },
    nil,
    {
      clear_read_btn,
      clear_all_btn,
      spacing = 8,
      layout = wibox.layout.fixed.horizontal,
    },
    layout = wibox.layout.align.horizontal,
  })
end

-- Main widget creator
local function create_popup_widget()
  local layout = wibox.layout.fixed.vertical()
  layout.spacing = nc_config.spacing

  -- Header
  layout:add(create_header())

  -- Separator
  layout:add(wibox.widget({
    orientation = "horizontal",
    forced_height = 1,
    color = beautiful.bg_focus,
    widget = wibox.widget.separator,
  }))

  -- Notification list or empty state
  if #M.history == 0 then
    layout:add(wibox.widget({
      {
        {
          text = "No notifications",
          align = "center",
          valign = "center",
          widget = wibox.widget.textbox,
        },
        fg = beautiful.fg_normal .. "88",
        widget = wibox.container.background,
      },
      forced_height = 100,
      widget = wibox.container.constraint,
    }))
  else
    -- Group notifications by app
    local groups, group_order = group_notifications_by_app()

    local list_layout = wibox.layout.fixed.vertical()
    list_layout.spacing = nc_config.spacing

    local total_items = 0
    for _, app_name in ipairs(group_order) do
      if total_items >= nc_config.max_visible then
        break
      end

      local group = groups[app_name]

      -- Add group header
      list_layout:add(create_group_header(group))
      total_items = total_items + 1

      -- Add notifications if group is expanded
      if expanded_groups[app_name] then
        for i, notif in ipairs(group.notifications) do
          if total_items >= nc_config.max_visible then
            break
          end
          list_layout:add(create_notification_item(notif))
          total_items = total_items + 1
        end
      end
    end

    layout:add(list_layout)
  end

  -- Wrap in margin and background
  return wibox.widget({
    {
      layout,
      margins = nc_config.margin,
      widget = wibox.container.margin,
    },
    bg = beautiful.bg_normal .. "F8",
    shape = beautiful.shape or gears.shape.rounded_rect,
    forced_width = nc_config.width,
    widget = wibox.container.background,
  })
end

-- Show the notification center
-- The notification center opens centered under the click point (mouse coords
-- for multi-monitor reliability), tucked just below the bar. Same placement
-- shape as the snooze picker: one function, installed on the popup and called
-- from on_show.
local center_anchor = { x = 0, y = 0 }

local function place_center(d)
  local wa = d.screen.workarea
  d.x = center_anchor.x - d.width / 2
  d.y = wa.y + (beautiful.useless_gap or 4)
  awful.placement.no_offscreen(d, { honor_workarea = true, margins = beautiful.useless_gap or 4 })
end

-- The notification center is a modal like the launcher and dashboard: the
-- controller owns visibility, Escape, click-outside/tag-change dismissal, and
-- the notification_center::visible signal.
local center = modal.new({
  name = "notification_center",
  build_popup = function()
    return awful.popup({
      widget = create_popup_widget(),
      screen = awful.screen.focused(),
      ontop = true,
      visible = false,
      bg = "#00000000",
      border_width = beautiful.border_width or 1,
      border_color = beautiful.primary_color,
      shape = beautiful.shape or gears.shape.rounded_rect,
      placement = place_center,
    })
  end,
  on_show = function(popup)
    center_anchor = mouse.coords()
    popup.widget = create_popup_widget()
    place_center(popup)
  end,
})

M.show_notification_center = center.show
M.hide_notification_center = center.hide
M.toggle_notification_center = center.toggle

-- Refresh popup content (safe to call any time; does nothing while hidden)
refresh_popup = function()
  if center.popup and center.is_visible() then
    center.popup.widget = create_popup_widget()
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
      bg = beautiful.bg_urgent,
      fg = beautiful.fg_urgent,
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
      app_name = { "Firefox", "Chrome", "Chromium", "Brave", "firefox", "chrome", "chromium", "brave" },
    },
    properties = {
      position = M.config.positions.bottom_right,
    },
    callback = function(n)
      if is_vip(n) then
        n.bg = M.config.vip_style.bg
        n.fg = M.config.vip_style.fg
        n.urgency = "critical"
        n.timeout = 0 -- Don't auto-dismiss

        n:append_actions(naughty.action({ name = "Reply" }))
        n:append_actions(naughty.action({ name = "Snooze" }))
      else
        -- Standard browser notification actions
        n:append_actions(naughty.action({ name = "Open" }))
        n:append_actions(naughty.action({ name = "Snooze" }))
      end
    end,
  })

  -- Discord/Slack/Teams notifications
  ruled.notification.append_rule({
    rule_any = {
      app_name = { "discord", "Discord", "slack", "Slack", "teams", "Teams", "Microsoft Teams" },
    },
    properties = {
      position = M.config.positions.top_right,
      timeout = 10,
    },
    callback = function(n)
      n:append_actions(naughty.action({ name = "Open" }))
      n:append_actions(naughty.action({ name = "Mark Read" }))
      n:append_actions(naughty.action({ name = "Snooze" }))
    end,
  })

  -- Email notifications
  ruled.notification.append_rule({
    rule_any = {
      app_name = { "Thunderbird", "Evolution", "Geary", "thunderbird", "evolution", "geary", "Mail", "mail" },
      category = { "email", "email.arrived" },
    },
    properties = {
      position = M.config.positions.bottom_left,
      timeout = 8,
    },
    callback = function(n)
      n:append_actions(naughty.action({ name = "Read" }))
      n:append_actions(naughty.action({ name = "Archive" }))
      n:append_actions(naughty.action({ name = "Snooze" }))
    end,
  })

  -- Calendar/Reminder notifications
  ruled.notification.append_rule({
    rule_any = {
      app_name = { "Calendar", "calendar", "gnome-calendar", "Reminders", "reminders" },
      category = { "calendar", "reminder" },
    },
    properties = {
      position = M.config.positions.top_middle,
      timeout = 0, -- Don't auto-dismiss reminders
    },
    callback = function(n)
      n:append_actions(naughty.action({ name = "Snooze" }))
      n:append_actions(naughty.action({ name = "Dismiss" }))
    end,
  })

  -- Media player notifications
  ruled.notification.append_rule({
    rule_any = {
      app_name = { "Spotify", "spotify", "vlc", "mpv", "rhythmbox", "Rhythmbox" },
      category = { "media", "music" },
    },
    properties = {
      position = M.config.positions.bottom_middle,
      timeout = 4,
    },
    -- No actions for media - they're just informational
  })

  -- System/Device notifications
  ruled.notification.append_rule({
    rule_any = {
      app_name = { "System", "system", "udiskie", "NetworkManager" },
      category = { "device", "device.added", "device.removed", "network" },
    },
    properties = {
      position = M.config.positions.top_middle,
      timeout = 5,
    },
    callback = function(n)
      n:append_actions(naughty.action({ name = "Dismiss" }))
    end,
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
    callback = function(n)
      n:append_actions(naughty.action({ name = "Dismiss" }))
    end,
  })

  -- Download notifications
  ruled.notification.append_rule({
    rule_any = {
      category = { "transfer", "transfer.complete" },
    },
    properties = {
      position = M.config.positions.bottom_right,
      timeout = 6,
    },
    callback = function(n)
      n:append_actions(naughty.action({ name = "Open Folder" }))
      n:append_actions(naughty.action({ name = "Dismiss" }))
    end,
  })
end)

-- Mark this notification's history entry as read (matched by id, with a
-- title+message fallback for notifications that never got one)
local function mark_read_in_history(n)
  for _, h in ipairs(M.history) do
    local id_match = n.id ~= nil and h.id == n.id
    local content_match = h.title == n.title and h.message == n.message
    if id_match or content_match then
      if not h.is_read then
        h.is_read = true
        M.unread_count = math.max(0, M.unread_count - 1)
        awesome.emit_signal("notification::unread_count", M.unread_count)
      end
      break
    end
  end
end

-- The action-button row under a notification, or nil if it has no actions
local function build_actions_widget(n)
  if not n.actions or #n.actions == 0 then
    return nil
  end

  return {
    {
      notification = n,
      base_layout = wibox.widget({
        spacing = 8,
        layout = wibox.layout.flex.horizontal,
      }),
      widget_template = {
        {
          {
            id = "text_role",
            halign = "center",
            valign = "center",
            widget = wibox.widget.textbox,
          },
          margins = { left = 12, right = 12, top = 6, bottom = 6 },
          widget = wibox.container.margin,
        },
        bg = beautiful.notification_action_bg_normal,
        fg = beautiful.notification_action_fg_normal,
        shape = gears.shape.rectangle,
        shape_border_width = beautiful.notification_action_border_width or 1,
        shape_border_color = beautiful.notification_action_border_color,
        widget = wibox.container.background,
      },
      widget = naughty.list.actions,
    },
    margins = { left = 8, right = 8, bottom = 8 },
    widget = wibox.container.margin,
  }
end

-- The full notification layout: icon | title/message, actions underneath
local function build_widget_template(n)
  return {
    {
      {
        -- Icon
        {
          {
            naughty.widget.icon,
            forced_width = beautiful.notification_icon_size or 48,
            forced_height = beautiful.notification_icon_size or 48,
            widget = wibox.container.constraint,
          },
          margins = 8,
          widget = wibox.container.margin,
        },
        -- Title + Message
        {
          {
            {
              naughty.widget.title,
              font = beautiful.font_size(11, "Bold"),
              widget = wibox.container.background,
            },
            {
              naughty.widget.message,
              widget = wibox.container.background,
            },
            spacing = 4,
            layout = wibox.layout.fixed.vertical,
          },
          margins = { top = 8, bottom = 8, right = 8 },
          widget = wibox.container.margin,
        },
        layout = wibox.layout.fixed.horizontal,
      },
      -- Actions (if present)
      build_actions_widget(n),
      spacing = 4,
      layout = wibox.layout.fixed.vertical,
    },
    -- Container with semi-transparent bg and orange border
    bg = n.bg or beautiful.notification_bg or beautiful.bg_normal,
    fg = n.fg or beautiful.notification_fg or beautiful.fg_normal,
    shape = beautiful.notification_shape or beautiful.shape,
    border_width = beautiful.notification_border_width or 1,
    border_color = beautiful.notification_border_color or beautiful.primary_color,
    widget = wibox.container.background,
  }
end

-- Should this notification be displayed right now? (DND and focus mode)
local function should_display(n)
  if M.config.dnd_mode and n.urgency ~= "critical" then
    return false
  end

  if M.config.focus_mode then
    local c = client.focus
    if c and c.fullscreen and n.urgency ~= "critical" then
      return false
    end
  end

  return true
end

-- Handle notification display. Actions are attached by the
-- ruled.notification rules above - this handler only records, filters, and
-- renders.
naughty.connect_signal("request::display", function(n)
  -- Set resident for important notifications
  if n.urgency == "critical" or n.app_name == "System" then
    n.resident = true
  end

  -- Always record, even when DND swallows the popup
  add_to_history(n)
  awesome.emit_signal("notification::unread_count", M.unread_count)

  if not should_display(n) then
    return
  end

  play_sound(n.urgency or "normal")

  n.widget_template = build_widget_template(n)
  naughty.layout.box({ notification = n })
end)

-- Handle action button clicks
naughty.connect_signal("invoked", function(n, a)
  if a.name == "Open" or a.name == "Reply" then
    -- Find notification's app and activate it
    for _, c in ipairs(client.get()) do
      if c.class and n.app_name and c.class:lower():match(n.app_name:lower()) then
        c:activate({ context = "notification_action", raise = true })
        break
      end
    end
  elseif a.name == "Snooze" then
    show_snooze_picker({
      title = n.title,
      message = n.message,
      app_name = n.app_name,
      urgency = n.urgency,
      icon = n.icon,
    })
  elseif a.name == "Dismiss" or a.name == "Mark Read" or a.name == "Read" or a.name == "Archive" then
    -- Every acknowledge-style action does the same local thing: the history
    -- entry is read. What "Archive" means is up to the sending app.
    mark_read_in_history(n)
  elseif a.name == "Open Folder" then
    -- Open the Downloads folder with whatever the system prefers
    awful.spawn("xdg-open " .. os.getenv("HOME") .. "/Downloads")
  end
end)

-- Toggle functions
function M.set_dnd_mode(state)
  if M.config.dnd_mode == state then
    return
  end
  M.config.dnd_mode = state
  -- Anything mirroring DND state (e.g. the dashboard toggle) listens for this.
  awesome.emit_signal("notifications::dnd_changed", state)
end

function M.toggle_dnd_mode()
  M.set_dnd_mode(not M.config.dnd_mode)
  naughty.notification({
    title = "DND Mode",
    message = M.config.dnd_mode and "Enabled" or "Disabled",
    timeout = 2,
  })
end

function M.toggle_focus_mode()
  M.config.focus_mode = not M.config.focus_mode
  naughty.notification({
    title = "Focus Mode",
    message = M.config.focus_mode and "Enabled" or "Disabled",
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

-- Function to generate sample notifications for testing
function M.generate_sample_notifications()
  local samples = {
    { title = "System Update", message = "3 packages can be upgraded", app_name = "System", urgency = "normal" },
    { title = "Low Battery", message = "Battery at 15%", app_name = "Power Manager", urgency = "critical" },
    { title = "New Message", message = "You have a new message from John", app_name = "Discord", urgency = "normal" },
    { title = "Download Complete", message = "awesome-wm-config.tar.gz", app_name = "Firefox", urgency = "low" },
    { title = "Calendar Reminder", message = "Meeting in 15 minutes", app_name = "Calendar", urgency = "normal" },
  }

  for i, sample in ipairs(samples) do
    gears.timer.start_new(i * 0.5, function()
      naughty.notification(sample)
      return false
    end)
  end
end

return M
