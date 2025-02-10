local M = {}

---@class lumberjack.AddHighlightOpts
---@field buf integer Buffer to add highlights to
---@field namespace integer ID of namespace to associate highlights with
---@field hl_group string Name of highlight group to apply (i.e. what colour)
---@field line integer line to highlight (zero-indexed)
---@field col_start integer Start of (byte-indexed) range to highlight
---@field col_end integer End of (byte-indexed) range to highlight

---Add highlight
---@param opts lumberjack.AddHighlightOpts
local add_highlight = function(opts)
	vim.api.nvim_buf_add_highlight(opts.buf, opts.namespace, opts.hl_group, opts.line, opts.col_start, opts.col_end)
end

---Clear highlights of given namespace from given buffer
---@param buf integer Buffer to clear highlights from
---@param namespace integer ID of namespace of highlights to delete
M.clear_highlights = function(buf, namespace)
	vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
end

local goto_line = function(window, buffer, line_number)
	if not line_number then
		return
	end
	-- Ensure the line number is valid and within the buffer range
	local buf_lines = vim.api.nvim_buf_line_count(buffer)
	if line_number < 1 or line_number > buf_lines then
		print("Invalid line number: " .. line_number)
		return
	end

	-- Move the cursor to the specified line, column 0 (start of the line)
	vim.api.nvim_win_set_cursor(window, { line_number, 0 })
end

local function open_bottom_split()
	-- Get total height of the editor
	local total_height = vim.o.lines

	-- Calculate window height (20% of total)
	local win_height = math.floor(total_height * 0.25)

	-- Set window options
	local opts = {
		relative = "editor",
		width = vim.o.columns, -- Full width
		height = win_height,
		row = total_height - win_height, -- Position at bottom
		col = 0,
		style = "minimal",
		border = "single",
	}

	-- Create a new buffer
	local buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer

	-- Open the window
	local win = vim.api.nvim_open_win(buf, true, opts)

	-- Optional: Customize the buffer (disable line numbers, enable wrap, etc.)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_win_set_option(win, "number", false)
	vim.api.nvim_win_set_option(win, "winfixheight", false)
end

local function open_vertical_split_with_lines(lines)
	-- Open a new vertical split
	if M.options.orientation == "horizontal" then
		-- vim.api.nvim_open_win(0, true, { relative = "editor", width = 100, height = 100 })
		-- local new_buf = vim.api.nvim_create_buf(false, true)
		-- vim.api.nvim_open_win(new_buf, true, {
		--           relative =
		--       })
		vim.cmd("10split new")
		vim.cmd(":setlocal buftype=nowrite")
		vim.cmd(":setlocal bufhidden=delete")
		vim.cmd(":setlocal noswapfile")
	elseif M.options.orientation == "floating" then
		open_bottom_split()
	else
		vim.cmd("vnew")
		vim.cmd(":setlocal buftype=nowrite")
		vim.cmd(":setlocal bufhidden=delete")
		vim.cmd(":setlocal noswapfile")
	end

	-- Get the buffer ID of the new window
	local buf = vim.api.nvim_get_current_buf()
	local win = vim.api.nvim_get_current_win()

	-- Set the buffer content to the provided lines
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Define the function to run on cursor movement
	local function on_cursor_moved()
		local cursor_pos = vim.api.nvim_win_get_cursor(0)
		local line_num = cursor_pos[1]
		local index = M.state.matching_indexes[line_num]
		if vim.api.nvim_win_is_valid(M.state.src_window) then
			goto_line(M.state.src_window, M.state.src_buffer, index)
		end
	end

	vim.api.nvim_create_autocmd("QuitPre", {
		buffer = M.state.src_buffer,
		callback = function()
			vim.api.nvim_win_close(M.state.filtered_window, true)
		end,
	})

	-- Attach an autocommand to CursorMoved for the new buffer
	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = buf, -- Only apply to the new buffer
		callback = on_cursor_moved,
	})

	return win
end

---@class lumberjack.Options
---@field ready boolean: True iff, setup has been called at least once (i.e. namespaces were created)
---@field foreground table<string, string>: Maps log level to hl_group to use to highlight log level text
---@field background table<string, string>: Maps log level to hl_group to use to highlight text in log that isn't the log level
---@field namespaces table<string, integer>: Maps log level to ID of namespace to use for highlighting
M.options = {
	ready = false,
	foreground = {
		-- FATAL = "@comment.error",
		-- ERROR = "@comment.error",
		-- WARN = "@comment.warning",
		-- INFO = "@comment.note",
		-- DEBUG = "@markup",
		-- FATAL = "DiagnosticError",
		-- ERROR = "DiagnosticError",
		-- WARN = "DiagnosticWarn",
		-- INFO = "DiagnosticInfo",
		-- DEBUG = "DiagnosticHint",
	},
	background = {
		FATAL = "DiagnosticError",
		ERROR = "DiagnosticError",
		WARN = "DiagnosticWarn",
		INFO = "DiagnosticInfo",
		-- DEBUG = "DiagnosticHint",
	},
	namespaces = {},
}

M.state = {
	src_window = 0,
	src_buffer = 0,
	filtered_window = -1,
	matching_lines = {},
	matching_indexes = {},
}

---Highlight given lines matching given keyword
---@param buf integer ID of buffer to highlight
---@param keyword string Name of keyword from M.options to highlight
---@param start integer First line in range to highlight (1 indexed)
---@param end_ integer Last line in range to highlight (Exclusive)
---@param open_split boolean IF true, open split with filtered lines
M.highlight_keywords = function(buf, keyword, start, end_, open_split)
	start = start - 1
	local namespace = M.options.namespaces[keyword]
	local background = M.options.background[keyword]
	local foreground = M.options.foreground[keyword]

	if not namespace or not foreground or not background then
		print("Lumberjack: Invalid keyword: " .. keyword)
		return
	end

	M.state.src_window = vim.api.nvim_get_current_win()
	if buf == 0 then
		M.state.src_buffer = vim.api.nvim_get_current_buf()
	else
		M.state.src_buffer = buf
	end

	local lines = vim.api.nvim_buf_get_lines(buf, start, end_, false)
	M.clear_highlights(buf, namespace)

	M.state.matching_lines = {}
	M.state.matching_indexes = {}

	for i, line in ipairs(lines) do
		local start_idx, end_idx = string.find(line, keyword)

		if start_idx then
			table.insert(M.state.matching_lines, line)
			table.insert(M.state.matching_indexes, i)
			-- Before log level
			add_highlight({
				buf = buf,
				namespace = namespace,
				hl_group = background,
				line = start + i - 1,
				col_start = 0,
				col_end = start_idx - 1,
			})

			-- Log level
			add_highlight({
				buf = buf,
				namespace = namespace,
				hl_group = foreground,
				line = start + i - 1,
				col_start = start_idx - 1,
				col_end = end_idx or -1,
			})

			-- After log level
			if end_idx then
				add_highlight({
					buf = buf,
					namespace = namespace,
					hl_group = background,
					line = start + i - 1,
					col_start = end_idx,
					col_end = -1,
				})
			end
		end
	end

	if open_split then
		M.state.filtered_window = open_vertical_split_with_lines(M.state.matching_lines)
	end
end

M.setup = function(opts)
	M.options = vim.tbl_deep_extend("keep", opts, M.options)

	for keyword, _ in pairs(M.options.background) do
		if not M.options.foreground[keyword] then
			M.options.foreground[keyword] = M.options.background[keyword]
		end
		M.options.namespaces[keyword] = vim.api.nvim_create_namespace("Lumberjack" .. keyword)
	end

	M.options.ready = true
end

return M
