local beautiful = require("beautiful")
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local wrappers = require("widgets.wrappers")
local utils = require("utils")

local term = wrappers.image_widget("/terminal.svg", beautiful.fg_normal)
local browse = wrappers.image_widget("/chrome.svg", beautiful.fg_normal)
local chat = wrappers.image_widget("/slack.svg", beautiful.fg_normal)
local db = wrappers.image_widget("/server.svg", beautiful.fg_normal)
local games = wrappers.image_widget("/play.svg", beautiful.fg_normal)

local term_widget = wrappers.square_icon(term, beautiful.bg_normal)
local browse_widget = wrappers.square_icon(browse, beautiful.bg_normal)
local chat_widget = wrappers.square_icon(chat, beautiful.bg_normal)
local db_widget = wrappers.square_icon(db, beautiful.bg_normal)
local games_widget = wrappers.square_icon(games, beautiful.bg_normal)

return function(s)
  awful.tag({ "1", "2", "3", "4", "5" }, s, awful.layout.layouts[1])

  return wibox.widget({
    term_widget,
    browse_widget,
    chat_widget,
    db_widget,
    games_widget,
    widget = wibox.layout.fixed.horizontal,
  })
end
