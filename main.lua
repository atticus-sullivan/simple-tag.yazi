--- @since 25.2.7

local PackageName = "simple-tag"
local M = {}


-- stylua: ignore
local CAND_TAG_KEYS = {
	-- number + special characters
	{ on = "0" }, { on = "1" }, { on = "2" }, { on = "3" }, { on = "4" },
	{ on = "5" }, { on = "6" }, { on = "7" }, { on = "8" }, { on = "9" },
	{ on = "-" }, { on = "=" }, { on = "!" }, { on = "@" }, { on = "#" },
	{ on = "$" }, { on = "%" }, { on = "^" }, { on = "&" }, { on = "*" },
	{ on = "(" }, { on = ")" }, { on = "_" }, { on = "+" }, { on = "`" },
	{ on = "~" },	{ on = "[" },	{ on = "{" },	{ on = "]" },	{ on = "}" },
	{ on = "\\" },	{ on = "|" },	{ on = ";" },	{ on = ":" },	{ on = "'" },
	{ on = "\"" },	{ on = "," },	{ on = "<" },	{ on = "." },	{ on = ">" },
	{ on = "/" },	{ on = "?" },
	-- word
	{ on = "q" }, { on = "w" }, { on = "e" }, { on = "r" }, { on = "t" },
	{ on = "y" }, { on = "u" }, { on = "i" }, { on = "o" }, { on = "p" },
	{ on = "a" }, { on = "s" }, { on = "d" }, { on = "f" }, { on = "g" },
	{ on = "h" }, { on = "j" }, { on = "k" }, { on = "l" }, { on = "z" },
	{ on = "x" }, { on = "c" }, { on = "v" }, { on = "b" }, { on = "n" },
	{ on = "m" }
}

local CAND_MODES = {
	-- number + special characters
	{ on = "1", desc = "Select Only tagged files" },
	{ on = "2", desc = "Select tagged files (Unite mode)" },
	{ on = "3", desc = "Select tagged files (Subtract mode)" },
	{ on = "4", desc = "Select tagged files (Intersect mode)" },
	{ on = "5", desc = "Select tagged files (Exclude mode)" },
	{ on = "6", desc = "Select tagged files (Undo mode)" },
}
local DEFAULT_TAG_ICON = "󰚋"
local DEFAULT_LINEMODE_ORDER = 500

local STATE_KEY = {
	ui_mode = "ui_mode",
	preserve_selected_files = "preserve_selected_files",
	colors = "colors",
	save_path = "save_path",
	tags_database = "tags_database",
	icons = "icons",
	linemode_order = "linemode_order",
}

---@enum UI_MODE
local UI_MODE = {
	hidden = "hidden",
	icon = "icon",
	text = "text",
}

local UI_MODE_ORDERED = {
	UI_MODE.hidden,
	UI_MODE.icon,
	UI_MODE.text,
}

---@enum SELECTION_MODE
local SELECTION_MODE = {
	UNITE = "unite",
	SUBTRACT = "subtract",
	INTERSECT = "intersect",
	EXCLUDE = "exclude",
	UNDO = "undo",
	REPLACE = "replace",
}

local set_state = ya.sync(function(state, key, value)
	state[key] = value
end)

local get_state = ya.sync(function(state, key)
	return state[key]
end)

local function success(s, ...)
	if not get_state(STATE_KEY.no_notify) then
		ya.notify({ title = PackageName, content = string.format(s, ...), timeout = 3, level = "info" })
	end
end

---@enum NOTIFY_MSG
local NOTIFY_MSG = {
	TAG_KEY_INVALID = "Tag key should be a single character",
}

local function fail(s, ...)
	ya.notify({ title = PackageName, content = string.format(s, ...), timeout = 3, level = "error" })
end

---@enum PUBSUB_KIND
local PUBSUB_KIND = {
	tags_tbl_changed = PackageName .. "-tags-changed",
	-- "@" persist state
	ui_mode_changed = "@" .. PackageName .. "-ui-mode-changed",
	files_deleted = "delete",
}

--- broadcast through pub sub to other instances
---@param _ table state
---@param pubsub_kind PUBSUB_KIND
---@param data any
---@param to number default = 0 to all instances
local broadcast = ya.sync(function(_, pubsub_kind, data, to)
	ps.pub_to(to or 0, pubsub_kind, data)
end)

local function pathJoin(...)
	-- Detect OS path separator ('\' for Windows, '/' for Unix)
	local separator = package.config:sub(1, 1)
	local parts = { ... }
	local filteredParts = {}
	-- Remove empty strings or nil values
	for _, part in ipairs(parts) do
		if part and part ~= "" then
			table.insert(filteredParts, part)
		end
	end
	-- Join the remaining parts with the separator
	local path = table.concat(filteredParts, separator)
	-- Normalize any double separators (e.g., "folder//file" → "folder/file")
	path = path:gsub(separator .. "+", separator)

	return path
end

local function tbl_deep_clone(original)
	if type(original) ~= "table" then
		return original
	end

	local copy = {}
	for key, value in pairs(original) do
		copy[tbl_deep_clone(key)] = tbl_deep_clone(value)
	end

	return copy
end

-- Helper function: Convert an array into a set (table for fast lookup)
local function tbl_to_set(array)
	local set = {}
	for _, v in ipairs(array) do
		local _v = tostring(v)
		set[_v] = true
	end
	return set
end

-- Unite: Combine all unique elements from both arrays
local function tbl_unite(array1, array2)
	local set = tbl_to_set(array1)
	for _, v in ipairs(array2) do
		local _v = tostring(v)
		set[_v] = true
	end
	local result = {}
	for k in pairs(set) do
		table.insert(result, k)
	end
	return result
end

-- Subtract: Remove elements of array2 from array1
local function tbl_subtract(array1, array2)
	local set2 = tbl_to_set(array2)
	local result = {}
	for _, v in ipairs(array1) do
		local _v = tostring(v)
		if not set2[_v] then
			table.insert(result, _v)
		end
	end
	return result
end

-- Intersect: Keep only common elements between both arrays
local function tbl_intersect(array1, array2)
	local set2 = tbl_to_set(array2)
	local result = {}
	for _, v in ipairs(array1) do
		local _v = tostring(v)
		if set2[_v] then
			table.insert(result, _v)
		end
	end
	return result
end

-- Exclude: Remove common elements, keeping only unique ones from both arrays
local function tbl_exclude(array1, array2)
	local set1, set2 = tbl_to_set(array1), tbl_to_set(array2)
	local result = {}

	for _, v in ipairs(array1) do
		local _v = tostring(v)
		if not set2[_v] then
			table.insert(result, _v)
		end
	end
	for _, v in ipairs(array2) do
		local _v = tostring(v)
		if not set1[_v] then
			table.insert(result, _v)
		end
	end
	return result
end

local function tbl_is_subset(small, large)
	local lookup = {}

	for _, v in ipairs(large) do
		lookup[v] = true
	end

	for _, v in ipairs(small) do
		if not lookup[v] then
			return false
		end
	end

	return true
end

local get_cwd = ya.sync(function()
	return tostring(cx.active.current.cwd)
end)

---@param tags_tbl string tags database table
---@return table<{[string]:string[]}
local function read_tags_tbl(tags_tbl)
	local save_path = get_state(STATE_KEY.save_path)
	local tbl_saved_file = pathJoin(save_path, tags_tbl, "tags.json")

	local file = io.open(tbl_saved_file, "r")
	if file == nil then
		return {}
	end
	local tags_tbl_records_encoded = file:read("*all")
	file:close()
	local tag_records = ya.json_decode(tags_tbl_records_encoded)
	return tag_records
end

-- tags_db format: { "parent_abs_path a.k.a tags_tbl" = { "filename" = [ "q", "w", ... ] } }
---@param tags_db table<{[string]: table<{[string]:string[]}>}>
local function write_tags_db(tags_db)
	local save_path = get_state(STATE_KEY.save_path)
	for tags_tbl, tags_tbl_records in pairs(tags_db) do
		local tags_tbl_save_dir = pathJoin(save_path, tags_tbl)
		for fname, tags in pairs(tags_tbl_records) do
			if #tags == 0 then
				tags_db[tags_tbl][fname] = nil
			end
		end
		if next(tags_db[tags_tbl]) == nil then
			-- delete mode
			fs.remove("file", Url(pathJoin(tags_tbl_save_dir, "tags.json")))
			fs.remove("dir_clean", Url(tags_tbl_save_dir))
			local tags_parent_tbl = Url(tags_tbl_save_dir):parent()
			if tags_parent_tbl and tags_parent_tbl ~= save_path then
				fs.remove("dir_clean", tags_parent_tbl)
			end
		else
			-- create/update mode
			local _, err_create_save_dir = fs.create("dir_all", Url(tags_tbl_save_dir))
			if err_create_save_dir then
				fail("Can't create save tags file: %s", tags_tbl_save_dir)
				break
			else
				local _, err_write_tags_tbl =
					fs.write(Url(pathJoin(tags_tbl_save_dir, "tags.json")), ya.json_encode(tags_tbl_records))
				if err_write_tags_tbl then
					fail("Can't save tags to file: %s", tags_tbl_save_dir)
				end
			end
		end
		broadcast(PUBSUB_KIND.tags_tbl_changed, tags_tbl)
	end
end

local render = ya.sync(function()
	ya.render()
end)

function M:fetch(job)
	local tags_db = get_state(STATE_KEY.tags_database)
	for _, file in ipairs(job.files) do
		local tags_tbl = tostring(file.url:parent())
		if tags_db[tags_tbl] == nil then
			tags_db[tags_tbl] = read_tags_tbl(tags_tbl)
		end
	end
	set_state(STATE_KEY.tags_database, tags_db)
	render()
	return true
end

function M:has_tags(file, tags_filter)
	local url
	if type(file) == "string" then
		url = Url(file)
	else
		url = file.url
	end
	local tags_tbl = tostring(url:parent())
	local fname = tostring(url:name())

	local tags_database = get_state(STATE_KEY.tags_database)
	if tags_database[tags_tbl] and tags_database[tags_tbl][fname] then
		local tags = tags_database[tags_tbl][fname] or {}
		return tbl_is_subset(tags_filter, tags)
	end
	return false
end

function M:setup(opts)
	local st = self
	local save_path = pathJoin(
		(ya.target_family() == "windows" and os.getenv("APPDATA") .. "\\yazi\\config\\tags")
			or (os.getenv("HOME") .. "/.config/yazi/tags")
	)
	st[STATE_KEY.tags_database] = {}
	st[STATE_KEY.ui_mode] = UI_MODE.icon
	st[STATE_KEY.colors] = {}
	st[STATE_KEY.icons] = {
		default = DEFAULT_TAG_ICON,
	}
	st[STATE_KEY.linemode_order] = DEFAULT_LINEMODE_ORDER
	if type(opts) == "table" then
		st[STATE_KEY.ui_mode] = opts.ui_mode or st[STATE_KEY.ui_mode]
		st[STATE_KEY.save_path] = pathJoin(opts.save_path or save_path)
		st[STATE_KEY.colors] = opts.colors or st[STATE_KEY.colors]
		st[STATE_KEY.icons] = ya.dict_merge(st[STATE_KEY.icons], opts.icons or {})
		st[STATE_KEY.linemode_order] = tonumber(opts.linemode_order) or st[STATE_KEY.linemode_order]
	end

	-- render tags
	Linemode:children_add(function(_self)
		if st[STATE_KEY.ui_mode] == UI_MODE.hidden then
			return ""
		end
		local tags_tbl = tostring(_self._file.url:parent())
		local fname = _self._file.name
		local spans = {}
		if st[STATE_KEY.tags_database][tags_tbl] and st[STATE_KEY.tags_database][tags_tbl][fname] then
			-- default true
			local is_reversed_color = not st[STATE_KEY.colors]
				or st[STATE_KEY.colors].reversed == nil
				or st[STATE_KEY.colors].reversed == true
			local tags = st[STATE_KEY.tags_database][tags_tbl][fname] or {}
			table.sort(tags)
			for _, tag in ipairs(tags) do
				local style = ui.Style()
				if _self._file:is_hovered() then
					if is_reversed_color then
						style:bg(st[STATE_KEY.colors][tag] and st[STATE_KEY.colors][tag] or "reset")
					else
						style:fg(st[STATE_KEY.colors][tag] and st[STATE_KEY.colors][tag] or "reset")
					end
				else
					style:fg(st[STATE_KEY.colors][tag] and st[STATE_KEY.colors][tag] or "reset")
				end
				if st[STATE_KEY.ui_mode] == UI_MODE.icon then
					spans[#spans + 1] = ui.Span(" " .. (st[STATE_KEY.icons][tag] or st[STATE_KEY.icons].default))
						:style(style)
				elseif st[STATE_KEY.ui_mode] == UI_MODE.text then
					spans[#spans + 1] = ui.Span(" " .. tag):style(style):bold()
				end
			end
		end
		return ui.Line(spans)
	end, st[STATE_KEY.linemode_order])

	ps.sub(PUBSUB_KIND.files_deleted, function(payload)
		local args = ya.quote("files-deleted")
		for _, url in ipairs(payload.urls) do
			args = args .. " " .. ya.quote(tostring(url))
		end
		ya.manager_emit("plugin", {
			self._id,
			args,
		})
	end)

	ps.sub_remote(PUBSUB_KIND.ui_mode_changed, function(mode)
		set_state(STATE_KEY.ui_mode, mode)
		render()
	end)

	ps.sub_remote(PUBSUB_KIND.tags_tbl_changed, function(tags_tbl)
		local tags_db = get_state(STATE_KEY.tags_database)
		if tags_db and tags_tbl and tags_db[tags_tbl] then
			tags_db[tags_tbl] = read_tags_tbl(tags_tbl)
			set_state(STATE_KEY.tags_database, tags_db)
			render()
		end
	end)
end

local selected_files = ya.sync(function()
	local tab, raw_urls = cx.active, {}
	for _, u in pairs(tab.selected) do
		raw_urls[#raw_urls + 1] = tostring(u)
	end
	return raw_urls
end)

local selected_or_hovered_files = ya.sync(function()
	local tab, raw_urls = cx.active, selected_files()
	if #raw_urls == 0 and tab.current.hovered then
		raw_urls[1] = tostring(tab.current.hovered.url)
	end
	return raw_urls
end)

local function toggle_tag(new_tag_key)
	local tags_db = get_state(STATE_KEY.tags_database)
	local changed_tags_db = {}
	for _, raw_url in ipairs(selected_or_hovered_files()) do
		local url = Url(raw_url)
		local tags_tbl = tostring(url:parent())
		local fname = tostring(url:name())
		if not tags_db[tags_tbl] then
			tags_db[tags_tbl] = {}
		end
		if not tags_db[tags_tbl][fname] then
			tags_db[tags_tbl][fname] = {}
		end
		local tags = tags_db[tags_tbl][fname]
		local is_removed = false

		-- remove if exist
		for idx = #tags, 1, -1 do
			if tags[idx] == new_tag_key then
				table.remove(tags, idx)
				is_removed = true
			end
		end

		-- add if not exist
		if not is_removed then
			table.insert(tags, new_tag_key)
		end
		tags_db[tags_tbl][fname] = tags
		changed_tags_db[tags_tbl] = tags_db[tags_tbl]
	end

	write_tags_db(changed_tags_db)
end

local function show_cands_ui_modes()
	local choice_mode = ya.which({ cands = CAND_MODES })
	local selected_mode = CAND_MODES[choice_mode].on
	if not selected_mode then
		return ""
	elseif selected_mode == "1" then
		return SELECTION_MODE.REPLACE
	elseif selected_mode == "2" then
		return SELECTION_MODE.UNITE
	elseif selected_mode == "3" then
		return SELECTION_MODE.SUBTRACT
	elseif selected_mode == "4" then
		return SELECTION_MODE.INTERSECT
	elseif selected_mode == "5" then
		return SELECTION_MODE.EXCLUDE
	elseif selected_mode == "6" then
		return SELECTION_MODE.UNDO
	end
end

function M:entry(job)
	local action = job.args[1]
	ya.manager_emit("escape", { visual = true })
	if action == "toggle-tag" then
		local selected_tag_key = job.args.key
		if selected_tag_key ~= nil and #tostring(selected_tag_key) ~= 1 then
			fail(NOTIFY_MSG.TAG_KEY_INVALID)
			return
		end
		if not selected_tag_key then
			local choice = ya.which({ cands = CAND_TAG_KEYS, silent = true })
			if not choice then
				return
			end
			selected_tag_key = CAND_TAG_KEYS[choice].on
		end
		toggle_tag(selected_tag_key)
	elseif action == "clear" then
		local args = ya.quote("files-deleted")
		local files_to_clear = selected_or_hovered_files()
		for _, url in ipairs(files_to_clear) do
			args = args .. " " .. ya.quote(url)
		end
		ya.manager_emit("plugin", {
			get_state("_id"),
			args,
		})
	elseif action == "toggle-ui" then
		local ui_mode = job.args.mode
		-- toggle between show icons/text keys/hidden
		if not ui_mode then
			local old_ui_mode = get_state(STATE_KEY.ui_mode)
			for idx, m in ipairs(UI_MODE_ORDERED) do
				if m == old_ui_mode then
					ui_mode = UI_MODE_ORDERED[idx + 1 > #UI_MODE_ORDERED and 1 or idx + 1]
					break
				end
			end
		end
		broadcast(PUBSUB_KIND.ui_mode_changed, ui_mode)
	elseif action == "toggle-select" then
		local select_mode = job.args.mode or SELECTION_MODE.REPLACE
		local selected_tag_key = job.args.tag
		local new_selected_files = {}
		-- Mode undo
		if select_mode == SELECTION_MODE.UNDO then
			new_selected_files = get_state(STATE_KEY.preserve_selected_files) or {}
			if new_selected_files == nil then
				return
			end
			local preseve_selected_files = selected_files()
			set_state(STATE_KEY.preserve_selected_files, preseve_selected_files)
		else
			if not selected_tag_key then
				local choice = ya.which({ cands = CAND_TAG_KEYS, silent = true })
				if not choice then
					return
				end
				selected_tag_key = CAND_TAG_KEYS[choice].on
			end
			if not select_mode then
				select_mode = show_cands_ui_modes()
				if not select_mode then
					return
				end
			end
			local tags_tbl = get_cwd()
			local tags_db = get_state(STATE_KEY.tags_database)
			local tagged_filenames = tags_db[tags_tbl] or {}
			for fname, tags in pairs(tagged_filenames) do
				for _, tag in ipairs(tags) do
					if tag == selected_tag_key then
						table.insert(new_selected_files, pathJoin(tags_tbl, fname))
						break
					end
				end
			end
			local preseve_selected_files = selected_files()
			set_state(STATE_KEY.preserve_selected_files, preseve_selected_files)
			local old_selected_files = tbl_deep_clone(preseve_selected_files)
			if select_mode == SELECTION_MODE.REPLACE then
				-- no needs to do anything else
			elseif select_mode == SELECTION_MODE.UNITE then
				new_selected_files = tbl_unite(old_selected_files, new_selected_files)
			elseif select_mode == SELECTION_MODE.INTERSECT then
				new_selected_files = tbl_intersect(old_selected_files, new_selected_files)
			elseif select_mode == SELECTION_MODE.SUBTRACT then
				new_selected_files = tbl_subtract(old_selected_files, new_selected_files)
			elseif select_mode == SELECTION_MODE.EXCLUDE then
				new_selected_files = tbl_exclude(old_selected_files, new_selected_files)
			else
				return
			end
		end

		-- clear selection
		ya.manager_emit("escape", { select = true })
		for _, url in ipairs(new_selected_files) do
			ya.manager_emit("toggle", { Url(url), state = "on" })
		end
	elseif action == "filter" then
		local filter_tags = {}
		local inputted_tags = job.args.keys
		local input_mode = job.args.input
		if not inputted_tags then
			local choice
			if not input_mode then
				choice = ya.which({ cands = CAND_TAG_KEYS, silent = true })
				if not choice then
					return
				end
				inputted_tags = CAND_TAG_KEYS[choice].on
			else
				local input_value, input_event = ya.input({
					title = "Enter tags:",
					position = { "center", w = 50 },
				})

				if input_event == 1 and input_value then
					inputted_tags = input_value
				else
					return
				end
			end
		end

		for _, code in utf8.codes(inputted_tags) do
			local key = utf8.char(code)
			filter_tags[key] = true
		end

		local tags_tbl = get_cwd()
		local tags_db = get_state(STATE_KEY.tags_database)
		local tagged_filenames = tags_db[tags_tbl] or {}
		local query = ""
		for fname, tags in pairs(tagged_filenames) do
			for _, tag in ipairs(tags) do
				if filter_tags[tag] then
					query = query .. fname .. "|"
					break
				end
			end
		end
		query = "^(" .. query:sub(1, -2) .. ")$"
		ya.manager_emit("filter_do", { query, smart = true, insensitive = false })
	elseif action == "files-deleted" then
		-- get changes tags
		local changed_tags_db = {}
		local tags_db = get_state(STATE_KEY.tags_database)
		for idx, raw_url in ipairs(job.args) do
			local url = Url(raw_url)
			if idx == 1 or url == nil then
				goto continue
			end
			local tags_tbl = tostring(url:parent())
			local fname = tostring(url:name())
			if tags_db and tags_tbl and tags_db[tags_tbl] then
				tags_db[tags_tbl][fname] = nil
				changed_tags_db[tags_tbl] = tags_db[tags_tbl]
			end
			::continue::
		end
		write_tags_db(changed_tags_db)
	end
end

return M
