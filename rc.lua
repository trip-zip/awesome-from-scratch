-- awesome_mode: api-level=4:screen=on
-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- @DOC_REQUIRE_SECTION@
-- Standard awesome library
local awful = require("awful")
local utils = require("utils")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
-- Declarative object management
local ruled = require("ruled")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
-- @DOC_ERROR_HANDLING@
naughty.connect_signal("request::display_error", function(message, startup)
  naughty.notification({
    urgency = "critical",
    title = "Oops, an error happened" .. (startup and " during startup!" or "!"),
    message = message,
  })
end)
-- }}}

-- {{{ Variable definitions
-- @DOC_LOAD_THEME@
-- Themes define colours, icons, font and wallpapers.
local theme_path = string.format("%s/.config/awesome/theme/", os.getenv("HOME"))
beautiful.init(theme_path .. "/theme.lua")

-- @DOC_DEFAULT_APPLICATIONS@
-- This is used later as the default terminal and editor to run.
terminal = "wezterm"
editor = os.getenv("EDITOR") or "nvim"
editor_cmd = "wezterm start -- " .. editor
filemanager = "thunar" --While I'm in here, may as well make this a variable

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"
-- }}}

-- {{{ Menu
-- @DOC_MENU@
-- Create a launcher widget and a main menu

myawesomemenu = {
  {
    "hotkeys",
    function()
      hotkeys_popup.show_help(nil, awful.screen.focused())
    end,
  },
  { "manual", terminal .. " -e man awesome" },
  { "edit config", editor_cmd .. " " .. awesome.conffile },
  { "Configs", utils.list_configs() },
  { "restart", awesome.restart },
  {
    "quit",
    function()
      awesome.quit()
    end,
  },
}

mymainmenu = awful.menu({
  items = {
    { "awesome", myawesomemenu, beautiful.awesome_icon },
    { "open terminal", terminal },
  },
})

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Tag layout
-- @DOC_LAYOUT@
-- Table of layouts to cover with awful.layout.inc, order matters.
tag.connect_signal("request::default_layouts", function()
  awful.layout.append_default_layouts({
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
  })
end)
-- }}}

-- {{{ Wallpaper
-- @DOC_WALLPAPER@
screen.connect_signal("request::wallpaper", function(s)
  awful.wallpaper({
    screen = s,
    widget = {
      {
        image = beautiful.wallpaper,
        upscale = true,
        downscale = true,
        widget = wibox.widget.imagebox,
      },
      valign = "center",
      halign = "center",
      tiled = false,
      widget = wibox.container.tile,
    },
  })
end)
-- }}}

-- {{{ Wibar

-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- @DOC_FOR_EACH_SCREEN@
screen.connect_signal("request::desktop_decoration", function(s)
  -- Each screen has its own tag table.
  awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

  -- Create a promptbox for each screen
  s.mypromptbox = awful.widget.prompt()

  -- Create an imagebox widget which will contain an icon indicating which layout we're using.
  -- We need one layoutbox per screen.
  s.mylayoutbox = awful.widget.layoutbox({
    screen = s,
    buttons = {
      awful.button({}, 1, function()
        awful.layout.inc(1)
      end),
      awful.button({}, 3, function()
        awful.layout.inc(-1)
      end),
      awful.button({}, 4, function()
        awful.layout.inc(-1)
      end),
      awful.button({}, 5, function()
        awful.layout.inc(1)
      end),
    },
  })

  -- Create a taglist widget
  s.mytaglist = awful.widget.taglist({
    screen = s,
    filter = awful.widget.taglist.filter.all,
    buttons = {
      awful.button({}, 1, function(t)
        t:view_only()
      end),
      awful.button({ modkey }, 1, function(t)
        if client.focus then
          client.focus:move_to_tag(t)
        end
      end),
      awful.button({}, 3, awful.tag.viewtoggle),
      awful.button({ modkey }, 3, function(t)
        if client.focus then
          client.focus:toggle_tag(t)
        end
      end),
      awful.button({}, 4, function(t)
        awful.tag.viewprev(t.screen)
      end),
      awful.button({}, 5, function(t)
        awful.tag.viewnext(t.screen)
      end),
    },
  })

  -- @TASKLIST_BUTTON@
  -- Create a tasklist widget
  s.mytasklist = awful.widget.tasklist({
    screen = s,
    filter = awful.widget.tasklist.filter.currenttags,
    buttons = {
      awful.button({}, 1, function(c)
        c:activate({ context = "tasklist", action = "toggle_minimization" })
      end),
      awful.button({}, 3, function()
        awful.menu.client_list({ theme = { width = 250 } })
      end),
      awful.button({}, 4, function()
        awful.client.focus.byidx(-1)
      end),
      awful.button({}, 5, function()
        awful.client.focus.byidx(1)
      end),
    },
  })

  s.systray = wibox.widget.systray()
  s.systray.visible = false

  -- @DOC_WIBAR@
  -- Create the wibox
  s.mywibox = awful.wibar({
    position = "top",
    screen = s,
    -- @DOC_SETUP_WIDGETS@
    widget = {
      layout = wibox.layout.align.horizontal,
      { -- Left widgets
        layout = wibox.layout.fixed.horizontal,
        mylauncher,
        s.mytaglist,
        s.mypromptbox,
      },
      s.mytasklist, -- Middle widget
      { -- Right widgets
        layout = wibox.layout.fixed.horizontal,
        s.systray,
        mytextclock,
        s.mylayoutbox,
      },
    },
    buttons = {
      awful.button({}, 2, function()
        s.systray.visible = not s.systray.visible
      end)
    }
  })
end)

-- {{{ Mouse bindings
-- @DOC_ROOT_BUTTONS@
awful.mouse.append_global_mousebindings({
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewprev),
    awful.button({ }, 5, awful.tag.viewnext),
})
-- }}}

require ("keybindings")

-- {{{ Rules
-- Rules to apply to new clients.
-- @DOC_RULES@
ruled.client.connect_signal("request::rules", function()
  -- @DOC_GLOBAL_RULE@
  -- All clients will match this rule.
  ruled.client.append_rule({
    id = "global",
    rule = {},
    properties = {
      focus = awful.client.focus.filter,
      raise = true,
      screen = awful.screen.preferred,
      placement = awful.placement.no_overlap + awful.placement.no_offscreen,
    },
    callback = function(c)
      c:to_secondary_section()
    end,
  })

  -- @DOC_FLOATING_RULE@
  -- Floating clients.
  ruled.client.append_rule({
    id = "floating",
    rule_any = {
      instance = { "copyq", "pinentry" },
      class = {
        "Arandr",
        "Blueman-manager",
        "Gpick",
        "Kruler",
        "Sxiv",
        "Tor Browser",
        "Wpa_gui",
        "veromix",
        "xtightvncviewer",
      },
      -- Note that the name property shown in xprop might be set slightly after creation of the client
      -- and the name shown there might not match defined rules here.
      name = {
        "Event Tester", -- xev.
      },
      role = {
        "AlarmWindow", -- Thunderbird's calendar.
        "ConfigManager", -- Thunderbird's about:config.
        "pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
      },
    },
    properties = { floating = true },
  })

  -- @DOC_DIALOG_RULE@
  -- Add titlebars to normal clients and dialogs
  ruled.client.append_rule({
    -- @DOC_CSD_TITLEBARS@
    id = "titlebars",
    rule_any = { type = { "normal", "dialog" } },
    properties = { titlebars_enabled = true },
  })

  -- Set Firefox to always map on the tag named "2" on screen 1.
  -- ruled.client.append_rule {
  --     rule       = { class = "Firefox"     },
  --     properties = { screen = 1, tag = "2" }
  -- }
end)
-- }}}

-- {{{ Titlebars
-- @DOC_TITLEBARS@
-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
  -- buttons for the titlebar
  local buttons = {
    awful.button({}, 1, function()
      c:activate({ context = "titlebar", action = "mouse_move" })
    end),
    awful.button({}, 3, function()
      c:activate({ context = "titlebar", action = "mouse_resize" })
    end),
  }

  awful.titlebar(c).widget = {
    { -- Left
      layout = wibox.layout.fixed.horizontal,
      awful.titlebar.widget.closebutton(c),
      awful.titlebar.widget.floatingbutton(c),
      awful.titlebar.widget.maximizedbutton(c),
    },
    { -- Middle
      { -- Title
        halign = "center",
        widget = awful.titlebar.widget.titlewidget(c),
      },
      buttons = buttons,
      layout = wibox.layout.flex.horizontal,
    },
    { -- Right
      -- awful.titlebar.widget.floatingbutton(c),
      -- awful.titlebar.widget.maximizedbutton(c),
      -- awful.titlebar.widget.stickybutton(c),
      -- awful.titlebar.widget.ontopbutton(c),
      -- awful.titlebar.widget.closebutton(c),
      layout = wibox.layout.fixed.horizontal(),
    },
    layout = wibox.layout.align.horizontal,
  }
end)
-- }}}

-- {{{ Notifications

ruled.notification.connect_signal("request::rules", function()
  -- All notifications will match this rule.
  ruled.notification.append_rule({
    rule = {},
    properties = {
      screen = awful.screen.preferred,
      implicit_timeout = 5,
    },
  })
end)

naughty.connect_signal("request::display", function(n)
  naughty.layout.box({ notification = n })
end)

-- }}}
