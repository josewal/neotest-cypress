local vim = vim
local M = {}

-- Log levels with their numeric values for comparison
local log_levels = {
  OFF = 0,
  ERROR = 1,
  WARN = 2,
  INFO = 3,
  DEBUG = 4
}

-- Current log level (set by config)
M.log_level = "INFO"

-- Debug logging function with level filtering
function M.log(msg, level)
  -- Safely handle logging in fast event contexts
  local success, result = pcall(function()
    level = level or 'INFO'

    -- Only log if the current log level is high enough
    if log_levels[level] and log_levels[M.log_level] and log_levels[level] > log_levels[M.log_level] then
      return
    end

    -- Use os.getenv to get home dir as fallback to avoid vim.fn in fast context
    local data_dir
    if vim.fn and vim.fn.stdpath then
      data_dir = vim.fn.stdpath('data')
    else
      data_dir = os.getenv('HOME') .. '/.local/share/nvim'
    end
    local log_file = data_dir .. '/neotest-cypress.log'
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')

    local f = io.open(log_file, 'a')
    if f then
      -- Use safe tostring instead of vim.inspect in case it's not available
      local msg_str = vim.inspect and vim.inspect(msg) or tostring(msg)
      f:write(string.format("[%s] %s: %s\n", level, timestamp, msg_str))
      f:close()
    end
  end)
  
  -- If logging fails, just silently continue
  if not success then
    -- Could optionally print to stderr: io.stderr:write("Logging failed: " .. tostring(result) .. "\n")
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

-- Escape special characters for cypress-grep pattern
-- cypress-grep uses minimatch/regex, so we escape regex special chars
function M.escape_grep_pattern(pattern)
  -- Escape regex special characters that might appear in test names
  -- Characters: ( ) . % + - * ? [ ] ^ $ { } | \
  local escaped = pattern:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$%{%}%|\\])", "\\%1")
  return escaped
end

-- Shell escape function to replace vim.fn.shellescape() 
-- This is safe to call from fast event contexts
function M.shell_escape(str)
  if not str then return '""' end
  -- Simple shell escaping: wrap in single quotes and escape any single quotes
  return "'" .. str:gsub("'", "'\"'\"'") .. "'"
end

return M
