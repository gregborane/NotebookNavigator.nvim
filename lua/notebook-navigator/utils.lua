local utils = {}

utils.get_cell_marker = function(bufnr, cell_markers)
  local ft = vim.bo[bufnr].filetype

  if ft == nil or ft == "" then
    print "[NotebookNavigator] utils.lua: Empty filetype"
  end

  local user_opt_cell_marker = cell_markers[ft]
  if user_opt_cell_marker then
    return user_opt_cell_marker
  end

  if not vim.bo.commentstring then
    error("There's no cell marker and no commentstring defined for filetype " .. ft)
  end

  local cstring = string.gsub(vim.bo.commentstring, "^%%", "%%%%")
  return cstring:format "%%"
end

local supported_repls = {
  { name = "jukit", module = "jukit" },
  { name = "pyrepl", module = "pyrepl" },
  { name = "iron", module = "iron" },
  { name = "toggleterm", module = "toggleterm" },
  { name = "molten", module = "molten.health" },
}

function utils.find_supported_repls()
  local available = {}

  -- 1. Gather all installed plugin directory names
  local plugin_paths = vim.fn.globpath(vim.o.packpath, "pack/*/*/*", false, true)
  local installed_plugins = {}
  for _, path in ipairs(plugin_paths) do
    local name = vim.fn.fnamemodify(path, ":t")
    table.insert(installed_plugins, name:lower())
  end

  -- 2. Check each supported REPL
  for _, repl in ipairs(supported_repls) do
    -- Check if it can be loaded as a Lua module OR exists in packpath
    local is_installed = vim.tbl_contains(installed_plugins, repl.name:lower()) or pcall(require, repl.module)

    if is_installed then
      table.insert(available, repl.name)
    end
  end

  return available
end

return utils
