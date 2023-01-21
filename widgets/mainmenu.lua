local awful = require("awful")
local beautiful = require("beautiful")
local hotkeys_popup = require("awful.hotkeys_popup")
local utils = require("utils")

local awesomemenu = {
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

local mainmenu = awful.menu({
  items = {
    { "awesome", awesomemenu, beautiful.awesome_icon },
    { "open terminal", terminal },
  },
})

return mainmenu
