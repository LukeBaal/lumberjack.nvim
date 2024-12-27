# `lumberback.nvim`

A Neovim plugin for highlighting logs in log text files by their log level

## Setup

Lazy
```lua
  {
    dir = 'lukebaal/lumberjack.nvim',
    config = function()
      require('lumberjack').setup {
        -- Set highlight colours for log level text
        foreground = {
          -- Override default namespace for ERROR logs
		  ERROR = "@comment.error",
          -- Extend built-in log levels to also highlight Debug logs
          DEBUG = 'DiagnosticHint',
        },
        -- Set highlight colours for other text in log that isn't the log level
        background = {
          DEBUG = 'DiagnosticHint',
        },
      }

      -- Add keymaps
      local set = vim.keymap.set
      set('n', '<leader>la', ':LumberjackAll<CR>', { desc = '[L]umberjack highlight [A]ll' })
      set('n', '<leader>lc', ':LumberjackClear<CR>', { desc = '[L]umberjack [C]lear highlights' })
      set('n', '<leader>lE', ':LumberjackCustom FATAL ERROR WARN<CR>', { desc = '[L]umberjack highlight FATAL/ERROR/WARN' })
      set('n', '<leader>lf', ':LumberjackFatal<CR>', { desc = '[L]umberjack highlight [F]ATAL' })
      set('n', '<leader>le', ':LumberjackError<CR>', { desc = '[L]umberjack highlight [E]RROR' })
      set('n', '<leader>lw', ':LumberjackWarn<CR>', { desc = '[L]umberjack highlight [W]ARN' })
      set('n', '<leader>li', ':LumberjackInfo<CR>', { desc = '[L]umberjack highlight [I]NFO' })
      set('n', '<leader>ld', ':LumberjackCustom DEBUG<CR>', { desc = '[L]umberjack highlight [D]EBUG' })
    end,
  },
```

## Usage

Highlight all logs in current buffer
```
:LumberbackAll
```

Clear all logs in current buffer
```
:LumberbackClear
```

Specific log level
```
:LumberjackFatal
:LumberjackError
:LumberjackWarn
:LumberjackInfo
:LumberjackDebug
```

Highlight sub-set of log levels
```
:LumberjackCustom FATAL ERROR WARN
```
