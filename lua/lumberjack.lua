local M = {}

local add_highlight = function(opts)
	vim.api.nvim_buf_add_highlight(opts.buf, opts.namespace, opts.hl_group, opts.line, opts.col_start, opts.col_end)
end

local clear_highlights = function(buf, namespace_id)
	vim.api.nvim_buf_clear_namespace(buf, namespace_id, 0, -1)
end

M.options = {
	foreground = {
		-- FATAL = "@comment.error",
		-- ERROR = "@comment.error",
		-- WARN = "@comment.warning",
		-- INFO = "@comment.note",
		-- DEBUG = "@markup",
		FATAL = "DiagnosticError",
		ERROR = "DiagnosticError",
		WARN = "DiagnosticWarn",
		INFO = "DiagnosticInfo",
		DEBUG = "DiagnosticHint",
	},
	background = {
		FATAL = "DiagnosticError",
		ERROR = "DiagnosticError",
		WARN = "DiagnosticWarn",
		INFO = "DiagnosticInfo",
		DEBUG = "DiagnosticHint",
	},
	namespaces = {
		FATAL = vim.api.nvim_create_namespace("LumberjackFatal"),
		ERROR = vim.api.nvim_create_namespace("LumberjackError"),
		WARN = vim.api.nvim_create_namespace("LumberjackWarning"),
		INFO = vim.api.nvim_create_namespace("LumberjackInfo"),
		DEBUG = vim.api.nvim_create_namespace("LumberjackDebug"),
	},
}

M.highlight_keywords = function(buf, keyword, start, end_)
	start = start - 1
	local namespace = M.options.namespaces[keyword]
	local foreground = M.options.foreground[keyword]
	local background = M.options.background[keyword]

	if not namespace or not foreground or not background then
		print("Lumberjack: Invalid keyword: " .. keyword)
		return
	end

	local lines = vim.api.nvim_buf_get_lines(buf, start, end_, false)
	clear_highlights(buf, namespace)

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
				col_end = end_idx,
			})

			-- After log level
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

M.setup = function()
	-- vim.keymap.set("v", "LE", function()
	-- 	local buf = vim.api.nvim_get_current_buf()
	-- 	local line_start = vim.api.nvim_buf_get_mark(buf, "<")[1]
	-- 	local line_end = vim.api.nvim_buf_get_mark(buf, ">")[1]
	-- 	M.highlight_keywords(buf, "ERROR", line_start - 1, line_end)
	-- end)
end

return M
