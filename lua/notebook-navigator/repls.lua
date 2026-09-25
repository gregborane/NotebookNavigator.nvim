local repls = {}

local utils = require "notebook-navigator.utils"

-- iron.nvim
---@diagnostic disable-next-line: unused-local
repls.iron = function(start_line, end_line, repl_args, _cell_marker)
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  require("iron.core").send(nil, lines)

  return true
end

-- toggleterm
---@diagnostic disable-next-line: unused-local
repls.toggleterm = function(start_line, end_line, repl_args, cell_marker)
  local id = 1
  local trim_spaces = false
  if repl_args then
    id = repl_args.id or 1
    trim_spaces = (repl_args.trim_spaces == nil) or repl_args.trim_spaces
  end
  local current_window = vim.api.nvim_get_current_win()
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  if not lines or not next(lines) then
    return
  end

  for _, line in ipairs(lines) do
    local l = trim_spaces and line:gsub("^%s+", ""):gsub("%s+$", "") or line
    require("toggleterm").exec(l, id)
  end

  -- Jump back with the cursor where we were at the beginning of the selection
  local cursor_line, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_set_current_win(current_window)

  vim.api.nvim_win_set_cursor(current_window, { cursor_line, cursor_col })

  return true
end

-- molten
---@diagnostic disable-next-line: unused-local
repls.molten = function(start_line, end_line, repl_args, cell_marker)
  local line_count = vim.api.nvim_buf_line_count(0)

  if line_count < (end_line + 1) then
    vim.api.nvim_buf_set_lines(0, end_line + 1, end_line + 1, false, { cell_marker, "" })
  end

  local ok, _ = pcall(vim.fn.MoltenEvaluateRange, start_line, end_line + 1)
  if not ok then
    vim.cmd "MoltenInit"
    return false
  end

  return true
end

-- pyrepl.nvim
repls.pyrepl = function(_start_line, _end_line, repl_args, _cell_marker)
  local pyrepl = require "pyrepl"

  pyrepl.open_repl(repl_args or {})
  pyrepl.send_cell()

  return true
end

-- jukit
---@diagnostic disable-next-line: unused-local
repls.jukit = function(start_line, end_line, repl_args, cell_marker)
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local code = table.concat(lines, "\n")
  if not code:find "%S" then
    return false
  end

  local current_window = vim.api.nvim_get_current_win()
  local current_buffer = vim.api.nvim_get_current_buf()
  local view = vim.fn.winsaveview()
  local ok, success = pcall(function()
    if vim.api.nvim_buf_get_name(current_buffer) == "" then
      error("Open a named file before starting jukit.", 0)
    end

    if vim.fn["jukit#splits#split_exists"] "output" == 0 then
      vim.fn["jukit#splits#output"]()
      vim.notify "[NotebookNavigator] Jukit started. Wait for the REPL prompt, then run again."
      return false
    end

    if vim.g.jukit_terminal == "nvimterm" then
      local job = vim.g.jukit_output_title
      if type(job) ~= "number" or vim.fn.jobwait({ job }, 0)[1] ~= -1 then
        error("Jukit's REPL has stopped. Close its split and reopen it.", 0)
      end
      if vim.g._jukit_main_buf ~= current_buffer then
        error("Jukit's REPL belongs to another buffer. Close it there before switching files.", 0)
      end
    end

    if vim.g._jukit_python == 1 and vim.g.jukit_ipython == 1 then
      if vim.fn["jukit#util#ipython_info_get"]("import_complete", 1) ~= 1 then
        error("IPython is not ready. Wait for its prompt, then run again.", 0)
      end
    end

    -- Jukit derives .jukit from expand('%:p:h'), so the source buffer
    -- must be current when send_to_split() is called.
    if vim.api.nvim_win_is_valid(current_window) then
      vim.api.nvim_set_current_win(current_window)

      if vim.api.nvim_buf_is_valid(current_buffer) then
        vim.api.nvim_win_set_buf(current_window, current_buffer)
      end

      vim.fn.winrestview(view)
    end

    -- Use NotebookNavigator's range, not jukit's cell-marker parser.
    vim.fn["jukit#send#send_to_split"](code)
    return true
  end)

  -- Jukit's sender switches windows; restore focus before run_and_move resumes.
  if vim.api.nvim_win_is_valid(current_window) then
    vim.api.nvim_set_current_win(current_window)
    vim.fn.winrestview(view)
  end

  if not ok then
    vim.notify("[NotebookNavigator] " .. tostring(success), vim.log.levels.ERROR)
    return false
  end
  return success
end

-- no repl
repls.no_repl = function(_) end

local get_repl = function(repl_provider)
  local chosen_repl

  if repl_provider == "auto" then
    local available_repls = utils.find_supported_repls()

    for _, name in ipairs(available_repls) do
      chosen_repl = repls[name]

      if chosen_repl then
        break
      end
    end
  else
    chosen_repl = repls[repl_provider]
  end

  if chosen_repl == nil then
    vim.notify("[NotebookNavigator] The provided repl, " .. repl_provider .. ", is not supported.")

    return repls.no_repl
  end

  return chosen_repl
end

return get_repl
