local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local previewers = require "telescope.previewers"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local entry_display = require "telescope.pickers.entry_display"

-- {"global", "--result=grep", "-d"}
local CMD_DEF = {"/home/milan/dev/ttags/target/debug/ttags", "-d"}
-- {"global", "--result=grep", "-r"}
local CMD_REF = {"/home/milan/dev/ttags/target/debug/ttags", "-r"}
-- {"global", "-c"}
local CMD_COMPLETE = {"/home/milan/dev/ttags/target/debug/ttags", "-c"}

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
  opts.default_text = opts.default_text or ""

  local live_completion = finders.new_job(function(prompt)
    if not prompt or prompt == "" then
      return nil
    end
    return vim.tbl_flatten {CMD_COMPLETE, prompt}
  end, opts.entry_maker, 0, opts.cwd)

  local target_action = function()
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

  if not opts.symbol then
    pickers.new(opts, {
      prompt_title = "Symbol completion " .. opts.default_text,
      finder = live_completion,
      sorter = conf.generic_sorter(opts),
      previewer = conf.file_previewer(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          local symbol = selection[1]
          opts.symbol = symbol
          target_action()
        end)
        return true
      end,
    }):find()
  else
    target_action()
  end
end

local gtags_ref = function(opts)
  opts = opts or {}
  opts.title = "reference"
  opts.cmd = CMD_REF
  return gtags(opts)
end

local gtags_def = function(opts)
  opts = opts or {}
  opts.title = "definition"
  opts.cmd = CMD_DEF
  return gtags(opts)
end

return require("telescope").register_extension {
  setup = function(ext_config, config)
    -- access extension config and user config
  end,
  exports = {
    ref = gtags_ref,
    def = gtags_def,
  },
}
