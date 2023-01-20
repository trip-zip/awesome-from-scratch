###### Table of Contents
* Section 0 - Default Config
* Section 1 - Theme Variables
* Section 2 - Keybindings
* Section 3 - Wibar
* Section 4 - Notifications
* Section 5 - Titlebars
* Section 6 - Logout Screen
* ??



## Wibar
* Let's try to make this wibar something worth having at the top of the screen permanently.
* I think the polybar themes that [adi1090x made](https://github.com/adi1090x/polybar-themes) are really great looking, I'll try (and fail) to copy one of those more or less.
* They use the [IcoMoon icons](https://github.com/Keyamoon/IcoMoon-Free).  I recommend you grab the free pack and download those.  Otherwise use your favorite icon set.
* Side note: I've found that in terms of centering and aligning icons in awesomewm, I nearly always prefer to use svgs over nerd fonts.  The svgs have more consistent height/width and I know exactly what I'm resizing and getting into.
* You CAN hypothetically do all this with nerd font icons and textboxes...but circle back to this setup when you spend 10 hours trying to halign a textbox but the right side never quite has the margin you want...I'm here for you.  Shhh.  The glyphs can't hurt you anymore...it's OK.

### Theme Variables
* First, let's just take a look at the wibar theme variables.
```
theme.wibar_align = nil
theme.wibar_bg = nil
theme.wibar_bgimage = nil
theme.wibar_border_color = nil
theme.wibar_border_width = nil
theme.wibar_cursor = nil
theme.wibar_favor_vertical = nil
theme.wibar_fg = nil
theme.wibar_height = nil
theme.wibar_margins = nil
theme.wibar_ontop = nil
theme.wibar_opacity = nil
theme.wibar_shape = nil
theme.wibar_stretch = nil
theme.wibar_type = nil
theme.wibar_width = nil
```
* We get some pretty easy controls out of the box.
* I'm going to tweak just a few and set the rest as their default so it's clear what the value is, not just `nil`.  I mean, some default are actually `nil`, but it can be useful to know which ones are actually `nil` vs which ones have real values associated with them hidden behind the scenes.  I'll comment which ones are the default values.
* These are the only variables I want to set for now.  I like a little bit larger wibar.
```
theme.wibar_bg = color.bg
theme.wibar_fg = color.fg
theme.wibar_height = theme.useless_gap * 5 or dpi(32)
theme.wibar_margins = theme.useless_gap * 2
theme.wibar_shape = gears.shape.rectangle
```
* Typically I like using a factor of my useless_gap as the basis for lots of these margin/size/position settings because it looks more intentional in my opinion.  That kind of breaks down if you want to mess with your gaps TOO much...so it might make sense to set your wibar_height to something sensible and unchanging.  But for me, I usually only switch between gaps of 6, 8, or 10px, which all look acceptable on my screen.  Just be aware of what you want there.
* Multiplying the useless_gap by 2 makes sure the left and right margin of the wibar come out to the same as the gap between clients and the outside borders of the screen.
* The downside is that there is too large of a gap between the wibar and the clients.  So it doesn't look identical from a gap perspective.
* So if you REALLY want it to feel precise, you can set the wibar_margins like this:

```
theme.wibar_margins = {
    top = theme.useless_gap * 2,
    left = theme.useless_gap * 2,
    right = theme.useless_gap * 2,
}
```

### Refactoring the layout

* I'll to move all the wibar stuff out to its own file to stop cluttering the main rc.lua
* Let's remove all the widgets from the wibar so we can add each piece as we want it.
* Pro Tip: If you're working with new widgets and layouts, it can sometimes be very useful to add borders so you can see how the layout will go.


### I want a widget container that I can add icons/text into so each widget in the bar looks identical
* I think a simple setup like:
wibox.container.background -- For coloring a background shape easily
-> wibox.container.margin  -- For fitting the image/text 
  -> wibox.widget.imagebox -- The final image
should be enough for now.
* We can shape and set colors.
* Maybe even pass in the widget and the background color as a function, then it'll return the widget styled and ready to place in the Wibar
* But basically, this is a quick mockup of what I want it to do.  Just a real simple wibar that contains some squares with icons
```
  local wibar = awful.wibar({
    expand = "none",
    position = "top",
    screen = s,
    widget = {
      {
        {
          {
            {
              {
                image = recolor(theme_path .. "/launcher.svg", beautiful.bg_normal),
                widget = wibox.widget.imagebox,
                halign = "center",
                valign = "center",
              },
              bg = beautiful.bg_normal,
              widget = wibox.container.background,
            },
            margins = beautiful.wibar_height / 4,
            widget = wibox.container.margin,
          },
          bg = beautiful.bg_normal,
          fg = beautiful.fg_normal,
          shape = gears.shape.rectangle,
          widget = wibox.container.background,
        },
        layout = wibox.layout.align.horizontal,
      },
      {
        {
          {
            {
              image = recolor(theme_path .. "/volume.svg", beautiful.bg_normal),
              widget = wibox.widget.imagebox,
              halign = "center",
              valign = "center",
            },
            bg = ,
            widget = wibox.container.background,
          },
          margins = beautiful.wibar_height / 4,
          widget = wibox.container.margin,
        },
        bg = beautiful.bg_normal,
        fg = beautiful.fg_normal,
        shape = gears.shape.rectangle,
        widget = wibox.container.background,
      },
      {
        {
          {
            {
              {
                image = recolor(theme_path .. "/power.svg", beautiful.bg_normal),
                widget = wibox.widget.imagebox,
                halign = "center",
                valign = "center",
              },
              bg = ,
              widget = wibox.container.background,
            },
            margins = beautiful.wibar_height / 4,
            widget = wibox.container.margin,
          },
          bg = beautiful.bg_normal,
          fg = beautiful.fg_normal,
          shape = gears.shape.rectangle,
          widget = wibox.container.background,
        },
        layout = wibox.layout.align.horizontal,
      },
      layout = wibox.layout.align.horizontal,
    },
  })
```
* We can add more of them to whichever side looks good and abstract the margin and imagebox widgets out so we can just reuse it everywhere we need.

### Quick Refactor
#### Widget
* This is kind of the core widget right here.  This layout is what I want my wibar widgets to really be.  A bunch of simple icons fit neatly into a margin so it's spaced evenly, then wrapped in a background so they can have their own colors.
```
{
  {
    {
      image = recolor(theme_path .. "/volume.svg", beautiful.fg_normal),
      widget = wibox.widget.imagebox,
      halign = "center",
      valign = "center",
    },
    margins = beautiful.wibar_height / 4,
    widget = wibox.container.margin,
  },
  bg = beautiful.bg_normal,
  fg = beautiful.fg_normal,
  shape = gears.shape.rectangle,
  widget = wibox.container.background,
},
```

* I will create each widget as the imagebox, then set its value based on a simple shell script. EZ PZ
* First, let's make a little function that returns a background widget.  This one will be the launcher, tag icons, and power menu button, and probably volume/wifi/etc.
```
local square_icon = function(w, color)
  return wibox.widget({
      {
        w,
        margins = beautiful.wibar_height / 4,
        widget = wibox.container.margin,
      },
      bg = color,
      fg = beautiful.fg_normal,
      shape = gears.shape.rectangle,
      widget = wibox.container.background,
  })
end
```
* It accepts a widget of any kind, but I'm leaning towards the imagebox widgets for this first layout.
```
local image_widget = function(image, color)
  return wibox.widget({
    image = recolor(icon_dir .. image, color),
    widget = wibox.widget.imagebox,
    halign = "center",
    valign = "center",
  })
end
```
* Now we can create a new file for each widget type to keep the implementation separate for each one.  But in its more simple form, creating a clean looking wibar widget just looks like this:
```
local launcher = image_widget("/grid.svg", beautiful.bg_normal)
local launcher_widget = square_icon(launcher, beautiful.primary_color)
```
* Then you add the launcher_widget to the wibar.  Any functionality we want to affix to the launcher widget will be easily applied.

#### Widgets directory
* Let's create a little widgets directory and put all our newly created widgets there.  We *could* put them in a "wibar" type widget, but I think they're simple enough that I might want to use some of these in another place.
* Each of the specific widgets like launcher and volume can get their own widget file, but things like the square_icon and the image_widget wrapper can just be in a wrappers.lua file to be reused by these widgets and more later on.
