vim.api.nvim_create_user_command("LumberjackFatal", function(opts)
	require("lumberjack").highlight_keywords(0, "FATAL", opts.line1, opts.line2)
end, { range = "%", addr = "lines" })

vim.api.nvim_create_user_command("LumberjackError", function(opts)
	require("lumberjack").highlight_keywords(0, "ERROR", opts.line1, opts.line2)
end, { range = "%", addr = "lines" })

vim.api.nvim_create_user_command("LumberjackWarn", function(opts)
	require("lumberjack").highlight_keywords(0, "WARN", opts.line1, opts.line2)
end, { range = "%", addr = "lines" })

vim.api.nvim_create_user_command("LumberjackInfo", function(opts)
	require("lumberjack").highlight_keywords(0, "INFO", opts.line1, opts.line2)
end, { range = "%", addr = "lines" })

vim.api.nvim_create_user_command("LumberjackCustom", function(opts)
	local lumberjack = require("lumberjack")
	vim.print(opts.fargs)
	for _, keyword in ipairs(opts.fargs) do
		lumberjack.highlight_keywords(0, keyword, opts.line1, opts.line2)
	end
end, { nargs = "+", range = "%", addr = "lines" })

vim.api.nvim_create_user_command("LumberjackAll", function(opts)
	local lumberjack = require("lumberjack")
	for keyword, _ in pairs(lumberjack.options.namespaces) do
		lumberjack.highlight_keywords(0, keyword, opts.line1, opts.line2)
	end
end, { range = "%", addr = "lines" })

vim.api.nvim_create_user_command("LumberjackClear", function()
	local lumberjack = require("lumberjack")
	for _, namespace in pairs(lumberjack.options.namespaces) do
		lumberjack.clear_highlights(0, namespace)
	end
end, {})
