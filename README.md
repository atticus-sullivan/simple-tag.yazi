# simple-tag

<!--toc:start-->

- [simple-tag](#simple-tag)
  - [Requirements](#requirements)
  - [Installation](#installation)
    - [Add setup function in `yazi/init.lua`.](#add-setup-function-in-yaziinitlua)
    - [Add fetcher `yazi.toml`](#add-fetcher-yazitoml)
    - [Add `keymap.toml`](#add-keymaptoml)
  - [For developers](#for-developers)
  <!--toc:end-->

## Overview

simple-tag is a Yazi plugin that allows you to add tags to files and folders. Each tag is associated with a unique key.

> Disclaimer: This is not mactag and does not utilize mactag.

## Requirements

> [!IMPORTANT]
> Minimum supported version: Yazi v25.2.7.

- [Yazi](https://github.com/sxyazi/yazi)
- Tested on Linux

## Installation

Install the plugin:

```sh
ya pack -a boydaihungst/simple-tag
```

> [!IMPORTANT]
> Tags are automatically cleared when files/folders are deleted or moved to trash within Yazi.
> However, if deleted outside Yazi and then recreated, their tags will be restored.
> It also apply with renaming files/folders.

## Prevews

- Tag Hints, will show up when ever you need to input and select tags.
  Only custom Icons or colors are shown.

![image](https://github.com/user-attachments/assets/7aa9f179-a29f-4c80-b50d-51938ded6958)

- Toggle Tags (Custom Icons & Colors):

![toggle normal](https://github.com/user-attachments/assets/ce942a86-f9ea-4639-9543-c00e8b624597)

- Tag Icon/Text/Hidden Indicator:

![toggle ui](https://github.com/user-attachments/assets/4208d1ef-31ce-40ef-92bc-2952a8319ee1)

- Filter Files by Tags Modes:

  - Mode = and (Default), match all of the selected tags:

  - Mode = or, match at least one of the selected tags:

- Visual Selection Modes:

  - Replace selection:

  - Unite selection:

  - Subtract selection:

  - Intersect selection:

  - Exclude selection:

## Configuration

### Add setup function in `yazi/init.lua`.

The setup function is required, while preferences are optional.

```lua
require("simple-tag"):setup({
  -- UI display mode (icon, text, hidden)
  ui_mode = "icon", -- (Optional)

  -- Disable tag key hints (popup in bottom right corner)
  hints_disabled = false, -- (Optional)

  -- linemode order: adjusts icon/text position. Fo example, if you want icon to be on the mose left of linemode then set linemode_order larger than 1000.
  -- More info: https://github.com/sxyazi/yazi/blob/077faacc9a84bb5a06c5a8185a71405b0cb3dc8a/yazi-plugin/preset/components/linemode.lua#L4-L5
  linemode_order = 500, -- (Optional)

  -- You can backup/restore this folder. But don't use backed up folder in the different OS.
  -- save_path =  -- full path to save tags folder (Optional)
  --       - Linux/MacOS: os.getenv("HOME") .. "/.config/yazi/tags"
  --       - Windows: os.getenv("APPDATA") .. "\\yazi\\config\\tags"

  -- Set tag colors
  colors = { -- (Optional)
	  -- Set this same value with `theme.toml` > [manager] > hovered > reversed
	  -- Default theme use "reversed = true".
	  -- More info: https://github.com/sxyazi/yazi/blob/077faacc9a84bb5a06c5a8185a71405b0cb3dc8a/yazi-config/preset/theme-dark.toml#L25
	  reversed = true, -- (Optional)

	  -- More colors: https://yazi-rs.github.io/docs/configuration/theme#types.color
    -- format: [tag key] = "color"
	  ["*"] = "#bf68d9", -- (Optional)
	  ["$"] = "green",
	  ["!"] = "#cc9057",
	  ["1"] = "cyan",
	  ["p"] = "red",
  },

  -- Set tag icons. Only show when ui_mode = "icon".
  -- Any text or nerdfont icons should work
  -- Default icon from mactag.yazi: ●; , , 󱈤
  -- More icon from nerd fonts: https://www.nerdfonts.com/cheat-sheet
  icons = { -- (Optional)
    -- default icon
		default = "󰚋",

    -- format: [tag key] = "tag icon"
		["*"] = "*",
		["$"] = "",
		["!"] = "",
		["p"] = "",
  },

})
```

### Fetcher Configuration in `yazi.toml`

Use one of the following methods:

```toml
[plugin]

  fetchers = [
    { id = "simple-tag", name = "*", run = "simple-tag" },
    { id = "simple-tag", name = "*/", run = "simple-tag" },
  ]
# or
  prepend_fetchers = [
    { id = "simple-tag", name = "*", run = "simple-tag" },
    { id = "simple-tag", name = "*/", run = "simple-tag" },
  ]
# or
  append_fetchers = [
    { id = "simple-tag", name = "*", run = "simple-tag" },
    { id = "simple-tag", name = "*/", run = "simple-tag" },
  ]

```

### Keybindings in `keymap.toml`

> [!IMPORTANT]
> Ensure there are no conflicts with [default Keybindings](https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/keymap-default.toml).

Since Yazi prioritizes the first matching key, `prepend_keymap` takes precedence over defaults.
Or you can use `keymap` to replace all other keys

```toml
[manager]
  prepend_keymap = [
    # Tagging plugin

    #─────────────────────────── TOGGLE TAG(S) ────────────────────────────
    # Toggle a tag (press any tag key)
    # A tag hint window will show up.
    # Simply press any tag key to toggle that tag for selected or hovered files/folders.
    { on = [ "t", "t", "k" ], run = "plugin simple-tag -- toggle-tag", desc = "Toggle a tag (press any key)" },

    # Fast Toggle tag(s) with fixed keys=!1q. key=!1q also work
    # NOTE: For key=" (Quotation mark), then use key=\" (Backslash + Quotation mark) instead.
    { on = [ "`" ], run = "plugin simple-tag -- toggle-tag --keys=!1q", desc = "Toggle tag(s) with fixed tag key(s) = (! and 1 and q)" },
    { on = [ "`" ], run = "plugin simple-tag -- toggle-tag --keys=*", desc = "Toggle tag with fixed tag key = *" },
    { on = [ "`" ], run = "plugin simple-tag -- toggle-tag --key=*", desc = "Toggle tag with fixed tag key = *" },

    # Toggle tag(s) with value from input box.
    # A tag hint window and an input box will show up.
    # Simply input tag key(s) to toggle that tags for selected or hovered files/folders.
    # Do not input any delimiter.
    { on = [ "t", "t", "i" ], run = "plugin simple-tag -- toggle-tag --input", desc = "Toggle tag(s) with value from (input box)" },


    #─────────────────────────── ADD TAG(S) ───────────────────────────────
    # Add a tag (press any tag key)
    # A tag hint window will show up.
    # Simply press any new tag key to add to selected or hovered files/folders.
    { on = [ "t", "a", "k" ], run = "plugin simple-tag -- add-tag", desc = "Add a tag (press any key)" },

    # Fast Add tag(s) with fixed keys=!1q. key=!1q also work
    { on = [ "t", "a", "f" ], run = "plugin simple-tag -- add-tag --keys=!1q", desc = "Add tag(s) with fixed tag keys = (! and 1 and q)" },
    { on = [ "t", "a", "f" ], run = "plugin simple-tag -- add-tag --keys=*", desc = "Add tag with fixed tag key = *" },
    { on = [ "t", "a", "f" ], run = "plugin simple-tag -- add-tag --key=*", desc = "Add tag with fixed tag key = *" },

    # Add tag(s) with value from input box.
    # A tag hint window and an input box will show up.
    # Simply input new tag key(s) to add to selected or hovered files/folders.
    # Do not input any delimiter.
    { on = [ "t", "a", "i" ], run = "plugin simple-tag -- add-tag --input", desc = "Add tag(s) with value from (input box)" },


    #─────────────────────────── REMOVE/DELETE TAG(S) ───────────────────────────
    # Remove a tag (press any tag key)
    # A tag hint window will show up.
    # Simply press any tag key to be removed from selected or hovered files/folders.
    { on = [ "t", "d", "k" ], run = "plugin simple-tag -- remove-tag", desc = "Remove a tag (press any key)" },

    # Fast Remove tag(s) with fixed keys=!1q. key=!1q also work
    { on = [ "t", "d", "f" ], run = "plugin simple-tag -- remove-tag --keys=!1q", desc = "Remove tag(s) with fixed tag keys = (! and 1 and q)" },
    { on = [ "t", "d", "f" ], run = "plugin simple-tag -- remove-tag --keys=*", desc = "Remove tag with fixed tag key = *" },
    { on = [ "t", "d", "f" ], run = "plugin simple-tag -- remove-tag --key=*", desc = "Remove tag with fixed tag key = *" },

    # Remove tag(s) with value from input box.
    # A tag hint window and an input box will show up.
    # Simply input tag key(s) to be removed from selected or hovered files/folders.
    # Do not input any delimiter.
    { on = [ "t", "d", "i" ], run = "plugin simple-tag -- remove-tag --input", desc = "Remove tag(s) with value from (input box)" },


    #─────────────────────────── REPLACE ALL OLD TAG(S) WITH NEW TAG(S) ───────────────────────────
    # Replace a tag (press any tag key)
    # A tag hint window will show up.
    # Simply press any new tag key for selected or hovered files/folders.
    { on = [ "t", "r", "k" ], run = "plugin simple-tag -- replace-tag", desc = "Replace with a new tag (press any key)" },

    # Fast Replace tag(s) with fixed keys=!1q. key=!1q also work
    { on = [ "t", "r", "f" ], run = "plugin simple-tag -- replace-tag --keys=!1q", desc = "Replace tag(s) with fixed tag keys = (! and 1 and q)" },
    { on = [ "t", "r", "f" ], run = "plugin simple-tag -- replace-tag --keys=*", desc = "Replace tag(s) with fixed tag key = *" },
    { on = [ "t", "r", "f" ], run = "plugin simple-tag -- replace-tag --key=*", desc = "Replace tag(s) with fixed tag key = *" },

    # Replace tag(s) with value from input box.
    # A tag hint window and an input box will show up.
    # Simply input new tag key(s) for selected or hovered files/folders.
    # Do not input any delimiter.
    { on = [ "t", "r", "i" ], run = "plugin simple-tag -- replace-tag --input", desc = "Replace tag(s) with value from (input box)" },


    #─────────────────────────── EDIT TAG(S) ───────────────────────────
    # Edit a tag for hovered or selected files/folders
    # An input box with current tagged keys and a tag hint window will show up for each hovered or selected files/folders.
    # Simply edit tag key(s) for selected or hovered files/folders.
    # If you cancel any input box, all changes will be discarded.
    { on = [ "t", "e" ], run = "plugin simple-tag -- edit-tag ", desc = "Edit tag(s) (input box)" },


    #  ───────────────────────────── CLEAR TAG(S) ─────────────────────────────
    # Clear all tags from selected or hovered files/folders
    { on = [ "t", "c" ], run = "plugin simple-tag -- clear", desc = "Clear all tags from selected or hovered files" },


    #  ───────────────────────────── CHANGE UI ─────────────────────────────
    # Switch tag indicator between icon > tag key > hidden.
    # Useful when u don't remember the tag key
    { on = [ "t", "u", "s" ], run = "plugin simple-tag -- toggle-ui", desc = "Toggle tag indicator (icon > tag key > hidden)" },

    # Fixed tag indicator mode = hidden (Available modes: hidden|icon|text)
    { on = [ "t", "u", "h" ], run = "plugin simple-tag -- toggle-ui --mode=hidden", desc = "Hide all tags indicator" },

    #  ─────────────────────── FILTER FILES/FOLDERS BY TAGS: ───────────────────────
    # Available filter modes:
    # and → Filter files which contain all of selected tags (Default if mode isn't specified).
    # or → Filter files which contain at least one of selected tags.

    # Filter files/folders by tags
    # NOTE: For yazi < v25.3.7
    #       This use a hacky way to filter files, so it may not work if
    #       there are too many files matched the selected  tags.
    #       Work just file if there are less than 5000 files.
    #       Well,  it depends on your system and the length of file's name.
    # NOTE: For yazi version >= v25.3.7, then this limitation is gone, you can search as many files as you want.

    # Filter files/folders by a tag (press any tag key)
    # A tag hint window will show up.
    # Simply press any new tag key to filter files/folders containing that tag in current directory.
    { on = [ "t", "f" ], run = "plugin simple-tag -- filter", desc = "Filter files/folders by a tag (press any key)" },

    # Fast Filter files/folders with fixed keys=!1q. key=!1q also work
    # { on = [ "t", "f" ], run = "plugin simple-tag -- filter --key=!", desc = "Filter files/folders by a fixed tag = !" },
    # { on = [ "t", "f" ], run = "plugin simple-tag -- filter --keys=!1q", desc = "Filter files/folders by multiple fixed tag(s) (! and 1 and q)" },

    # Filter files/folders by tag(s) with value from input box.
    # An input box and a tag hint window will show up.
    # Simply input tag key(s) to filter files/folders of current directory.
    # Do not input any delimiter.
    # For example: Input value or --keys=!1q -> filter any files/folders contain all of these tags (! and 1 and q) in current directory.
    { on = [ "t", "F" ], run = "plugin simple-tag -- filter --input", desc = "Filter files/folders by tag(s) (input box)" },

    # Filter files/folders by tag(s) with --mode=or.
    # --mode=or -> Input value or --keys = !1q -> filter any files/folders contain at least one of these tags (! or 1 or q)
    { on = [ "t", "F" ], run = "plugin simple-tag -- filter --input --mode=or", desc = "Filter files/folders by contain tags (input box)" },
    # { on = [ "t", "F" ], run = "plugin simple-tag -- filter --keys=!1q --mode=or", desc = "Filter files/folders by multiple fixed tag(s) (! or 1 or q)" },


    #  ─────────────────────── VISUAL SELECT FILES/FOLDERS BY TAGS: ───────────────────────

    # Avaiable selection modes:
    # replace → Replace selected list with tagged files/folders (Default if mode isn't specified)
    # unite → Combine all files/folders from already selected files/folders and files/folders with selected tag.
    # intersect → Keep only the overlapping files/folders.
    # subtract → Deselect files/folders which has selected tag
    # exclude → Keep only the non-overlapping files/folders.
    # undo → Undo/Redo selection (5 mode above)

    # Default mode = replace -> replace the whole selection list with tagged files/folders
    # which_key will popup to choose selection mode
    # A tag hint window will show up.
    # Simply select selection mode then press any tag key to select files/folders containing that tag in current directory.
    { on = [ "t", "s" ], run = "plugin simple-tag -- toggle-select", desc = "Selection only tagged files/folders (press any tag key to select)" },

    # Fast select any files/folders with fixed tag key = q.
    # You can remove "--mode=replace" as it's the default mode.
    { on = [ "t", "q" ], run = "plugin simple-tag -- toggle-select --mode=replace --tag=q", desc = "Selection only files/folders with tag key = q" },

    # Fixed selection mode = unite.
    # This won't show which_key popup
    # A tag hint window will show up.
    # just press any tag key to unite selection files/folders containing that tag in current directory.
    { on = [ "t", "s", "u" ], run = "plugin simple-tag -- toggle-select --mode=unite", desc = "Add tagged files/folders to selection (press any tag key to select)" },

    # Undo/Redo selection (only works after using 6 modes above)
    { on = [ "t", "u" ], run = "plugin simple-tag -- toggle-select --mode=undo", desc = "Undo selection action" },
]
```

### Customizing the Theme for tag hints window

To modify the tag hints window appearance, edit `.../yazi/theme.toml`:
You can also use Falvors file instead.

```toml

[spot]
  border = { fg = "#4fa6ed" }
  title  = { fg = "#4fa6ed" }
```

## For Developers

You can trigger this plugin programmatically:

```lua
-- In your plugin:
  local simple_tag = require("simple-tag")
-- Available actions: toggle-tag, toggle-ui, clear, toggle-select, filter, add-tag, remove-tag, replace-tag, edit-tag
  local action = "toggle-select"
	local args = ya.quote(action)
	args = args .. " " .. ya.quote("--mode=unite")
-- another arguments
-- args = args .. " " .. ya.quote("--tag=q")
	ya.manager_emit("plugin", {
		simple_tag._id,
		args,
	})


-- Special action: "files-deleted" -> clear all tags from these files/folders
  local args = ya.quote("files-deleted")
-- A array of string url
  local files_to_clear_tags = selected_or_hovered_files()
  for _, url in ipairs(files_to_clear_tags) do
	  args = args .. " " .. ya.quote(url)
  end
  ya.manager_emit("plugin", {
		simple_tag._id,
	  args,
  })

```
