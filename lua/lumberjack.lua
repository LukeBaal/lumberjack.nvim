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

---Highlight given lines matching given keyword
---@param buf integer ID of buffer to highlight
---@param keyword string Name of keyword from M.options to highlight
---@param start integer First line in range to highlight (1 indexed)
---@param end_ integer Last line in range to highlight (Exclusive)
M.highlight_keywords = function(buf, keyword, start, end_)
	start = start - 1
	local namespace = M.options.namespaces[keyword]
	local background = M.options.background[keyword]
	local foreground = M.options.foreground[keyword]

	if not namespace or not foreground or not background then
		print("Lumberjack: Invalid keyword: " .. keyword)
		return
	end

	local lines = vim.api.nvim_buf_get_lines(buf, start, end_, false)
	M.clear_highlights(buf, namespace)

	for i, line in ipairs(lines) do
		local start_idx, end_idx = string.find(line, keyword)
		if start_idx then
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
