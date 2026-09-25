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

  for _, repl in ipairs(supported_repls) do
    local is_available = false

    if repl.name == "jukit" then
      -- Check if Jukit's autoload function exists in Neovim's runtime
      is_available = vim.fn.exists "*jukit#splits#output" == 1
        or #vim.api.nvim_get_runtime_file("autoload/jukit.vim", false) > 0
    else
      -- Check standard Lua modules via pcall
      is_available = pcall(require, repl.module)
    end

    if is_available then
      available[#available + 1] = repl.name
    end
  end

  return available
end

return utils
