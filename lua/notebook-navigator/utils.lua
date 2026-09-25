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
    local ok = pcall(require, repl.module)

    if ok then
      available[#available + 1] = repl.name
    end
  end

  return available
end

function utils.has_value(tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end

  return false
end

return utils
