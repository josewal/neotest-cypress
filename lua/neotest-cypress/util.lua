local vim = vim
local M = {}

-- Current log level
M.log_level = "WARN"

-- Log levels with their numeric values for comparison
local log_levels = {
  OFF = 0,
  ERROR = 1,
  WARN = 2,
  INFO = 3,
  DEBUG = 4
}

-- Set log level
function M.set_log_level(level)
  if log_levels[level] then
    M.log_level = level
  end
end

-- Debug logging function with level filtering
function M.log(msg, level)
  level = level or 'INFO'
  
  -- Only log if the current log level is high enough
  if log_levels[level] and log_levels[M.log_level] and log_levels[level] > log_levels[M.log_level] then
    return
  end
  
  local log_file = vim.fn.stdpath('data') .. '/neotest-cypress.log'
  local timestamp = os.date('%Y-%m-%d %H:%M:%S')
  
  local f = io.open(log_file, 'a')
  if f then
    f:write(string.format("[%s] %s: %s\n", level, timestamp, vim.inspect(msg)))
    f:close()
  end
end

-- Safe function wrapper with error logging
function M.safe_call(func, ...)
  local success, result_or_error = pcall(func, ...)
  if not success then
    M.log(string.format("Error: %s", tostring(result_or_error)), 'ERROR')
    error(result_or_error)
  end
  return result_or_error
end

-- Generate a position ID from file path and test path
-- Format: file_path::describe_name::nested_describe::test_name
function M.create_position_id(file_path, names)
  local parts = { file_path }
  for _, name in ipairs(names) do
    table.insert(parts, name)
  end
  return table.concat(parts, "::")
end

-- Extract the test name from a position ID
function M.get_test_name_from_id(pos_id)
  local parts = vim.split(pos_id, "::", { plain = true })
  return parts[#parts]
end

-- Get the parent namespace names from a position ID
function M.get_namespace_path(pos_id)
  local parts = vim.split(pos_id, "::", { plain = true })
  local namespaces = {}
  for i = 2, #parts - 1 do
    table.insert(namespaces, parts[i])
  end
  return namespaces
end

-- Enable or disable debug mode
function M.set_debug_mode(enabled)
  vim.g.neotest_cypress_debug_mode = enabled == true
  M.log(string.format("Debug mode %s", enabled and 'enabled' or 'disabled'))
end

return M