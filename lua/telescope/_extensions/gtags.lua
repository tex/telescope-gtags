local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local previewers = require "telescope.previewers"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local entry_display = require "telescope.pickers.entry_display"

function split (inputstr, sep)
   if sep == nil then
      sep = "%s"
   end
   local t={}
   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
   end
   return t
end

local gtags = function(opts)
  opts = opts or {}
  if not opts.symbol then
    opts.symbol = vim.fn.input("Enter symbol > ", "")
  end

  local displayer = entry_display.create {
    separator = " ",
    items = {
      { remaining = true },
      { remaining = true },
    },
  }
  local make_display = function(entry)
    return displayer {
	entry.path,
      { entry.symbol, "TelescopeResultsIdentifier" },
    }
  end
  opts.entry_maker = function(entry)
    local a = split(entry, ":")
    return {
      value = a[3],	-- this goes to quickfix together with path and lnum
      display = make_display,
      ordinal = a[1] .. " " .. a[3],	-- this is used for search
      symbol = a[3],	-- my entry to be used in make_display
      path = a[1],	-- used by grep_previewer
      lnum = tonumber(a[2]), -- used by grep_previewer
    }
    end
  pickers.new(opts, {
    prompt_title = "Symbol " .. opts.title .. " " .. opts.symbol,
    finder = finders.new_oneshot_job(vim.tbl_flatten({opts.cmd, opts.symbol}), opts ),
    sorter = conf.generic_sorter(opts),
    previewer = conf.grep_previewer(opts),
 }):find()
end

local gtags_completion = function(opts)
  opts = opts or {}
  opts.symbol = opts.symbol or ""
  pickers.new(opts, {
    prompt_title = "Symbol completion " .. opts.symbol,
    finder = finders.new_oneshot_job(vim.tbl_flatten({{"global", "-c"}, opts.symbol}), opts ),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        gtags({cmd = {"global", "--result=grep", "-d"}, title = "definition", symbol = selection[1]})
      end)
      return true
    end,
 }):find()
end

local gtags_grep = function(opts)
  opts = opts or {}
  opts.title = "grep"
  opts.cmd = {"global", "--result=grep", "-g"}
  return gtags(opts)
end

local gtags_ref = function(opts)
  opts = opts or {}
  opts.title = "reference"
  opts.cmd = {"global", "--result=grep", "-r"}
  return gtags(opts)
end

local gtags_def = function(opts)
  opts = opts or {}
  opts.title = "definition"
  opts.cmd = {"global", "--result=grep", "-d"}
  return gtags(opts)
end

-- to execute the function
-- gtags_completion({symbol = "ma"})
-- gtags({cmd = {"global", "--result=grep", "-g"}, title = "reference", symbol = "main"})
-- gtags({cmd = {"global", "--result=grep", "-d"}, title = "definition", symbol = "main"})

return require("telescope").register_extension {
  setup = function(ext_config, config)
    -- access extension config and user config
  end,
  exports = {
    grep = gtags_grep,
    ref = gtags_ref,
    def = gtags_def,
    sym = gtags_completion,
  },
}
