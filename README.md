# Goal
## It's been a while since I've looked at my awesomeWM config.  I want to improve some things, and I think there's value in starting completely from scratch and being deliberate about what functionality I add and what "fluff" I leave out.  I think it might be fun or interesting to do a series of videos "from scratch" explaining my choices, trade-offs, and all the while, documenting my colossal ignorance for future generations.
## Awesome is my favorite X window manager and has been my daily WM of choice for 3 or 4 years.
- It has a reputation of being "intimidating" in the ricing scene, but really it doesn't have to be.
- The [API documentation](https://awesomewm.org/apidoc/) is fantastic (Admittedly, it's often geared towards developers which can sometimes also contribute to the intimidation factor.)
- I want to help demystify some of the magic of Awesome and hopefully add another resource to the list that can help make awesome more approachable.
- I don't claim to be some kind of Awesome expert or a "rice" wizard, but I love finding ways to improve my workflow and increase functionality.
- awesome is amazing.  It's insanely configurable, fast, extensible.  Your imagination is probably going to be the only roadblock.
- Even right out of the box it's highly useable.
- If you're just looking to get work done, honestly, double check the keybindings close this tab, and get to work.  It works like a dream right out of the box.
## I like this incremental approach to learning something from scratch.
- The "Copy someone else's config and tweaking it" has merit, but building a solid foundation, learning step by step tends to work better for me in the long run.  This is especially true when my preferred functionality differs fundamentally from the config I'm copying.
- However, looking at a [Beautiful Rice](https://github.com/rxyhn/yoru) and trying to figure out how to get from the default rc.lua to something polished and highly functional can be incredibly daunting.
## For this series, I'm going to try to ONLY use awesome's built in tools
- I love Rofi, I love polybar, I love conky, etc.  They're all amazing.  But in this series, I'm just going to highlight what awesome already has built in.  I may show how easy it is to launch one of those tools from Awesome, but that won't really be my focus.
## We can have our cake and eat it too.
- Normally I think "Function" is more important than "Form", but awesome is flexible enough to guarantee you can have both.
- I believe there is intrinsic value in building something you believe is beautiful.
- However, I am not highly creative in any visual medium, so my focus will be squeezing the most function I can out of awesome.
## Keep modules, widgets, and signals decoupled & reusable
- Maybe you have a working config, but you find something in another user's dotfiles that is too tightly coupled for you to copy/paste into your own code config.  The complexity of someone else's system might not accomodate the 90% of your own config you're happy with.
- If someone wants to borrow a piece of your code, make sure it's copy/pastable.
** Awesome Config out of the box
## I won't go over every line of code in the default rc.lua file since the docs already have a [fantastic breakdown](https://awesome.org/apidoc/documentation/05-Awesomerc.md.html)
- I will, however, touch on some of them as I explain what awesome offers right out of the box.
## Core Components Relationship diagram
## Screens
## Tags
- A tag can be attached to multiple clients
- A client can be attached to multiple tags
- A tag can only be in 1 screen any given time, but can be moved
- All clients attached to a tag must be in the same screen as the tag
## Clients
- Rules
## Keybindings
## Hotkeys Popup (Help)
## Client List ()
## Launcher
## Taglist
## Tasklist
## Systray
## Layouts
  - Tiling
  -
  - Floating
## General Widget Magic
## Signals
** Credits & Thanks
- [System Crafters's Emacs From Scratch](https://www.youtube.com/playlist?list=PLEoMzSkcN8oPH1au7H6B7bBJ4ZO7BXjSZ)
- [Neovim From Scratch](https://github.com/LunarVim/Neovim-from-scratch)
- & most importantly - [KryptoDigital's Yoshi's Lounge](https://on.soundcloud.com/TjDjm)
