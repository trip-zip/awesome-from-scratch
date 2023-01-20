local beautiful = require("beautiful")
local wibox = require("wibox")
local wrappers = require("widgets.wrappers")

local term = wrappers.image_widget("/terminal.svg", beautiful.fg_normal)
local browse = wrappers.image_widget("/chrome.svg", beautiful.fg_normal)
local chat = wrappers.image_widget("/slack.svg", beautiful.fg_normal)
local db = wrappers.image_widget("/git-branch.svg", beautiful.fg_normal)
local term_widget = wrappers.square_icon(term, beautiful.bg_normal)
local browse_widget = wrappers.square_icon(browse, beautiful.bg_normal)
local chat_widget = wrappers.square_icon(chat, beautiful.bg_normal)
local db_widget = wrappers.square_icon(db, beautiful.bg_normal)

return wibox.widget({
  term_widget,
  browse_widget,
  chat_widget,
  db_widget,
  widget = wibox.layout.fixed.horizontal
})
