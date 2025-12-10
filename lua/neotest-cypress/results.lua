local util = require("neotest-cypress.util")

local M = {}

-- Map Cypress test state to NeoTest status
local function map_status(cypress_state)
  if cypress_state == "passed" then
    return "passed"
  elseif cypress_state == "failed" then
    return "failed"
  elseif cypress_state == "pending" or cypress_state == "skipped" then
    return "skipped"
  end
  return "skipped"
end

-- Extract error information from Cypress test result
local function extract_errors(test)
  if not test.err or test.err == vim.NIL then
    return nil
  end

  local errors = {}
  local err = test.err

  -- Build error message
  local message = err.message or "Test failed"
  if err.stack then
    table.insert(errors, {
      message = message .. "\n" .. err.stack,
    })
  else
    table.insert(errors, {
      message = message,
    })
  end

  return errors
end

-- Build position ID from Cypress test title path
-- Cypress format: ["describe name", "nested describe", "test name"]
local function build_position_id(file_path, title_path)
  if not title_path or #title_path == 0 then
    return file_path
  end
  return util.create_position_id(file_path, title_path)
end

-- Parse Cypress JSON output and convert to NeoTest results format
function M.parse(results_path, file_path)
  local success, data = pcall(function()
    return vim.fn.json_decode(vim.fn.readfile(results_path))
  end)

  if not success or not data then
    return {}
  end

  local results = {}

  -- Cypress JSON structure: { runs: [{ tests: [...] }] }
  if not data.runs or #data.runs == 0 then
    return results
  end

  local run = data.runs[1]
  if not run.tests then
    return results
  end

  -- Process each test result
  for _, test in ipairs(run.tests) do
    local pos_id = build_position_id(file_path, test.title)
    local status = map_status(test.state)
    local errors = nil

    if status == "failed" then
      errors = extract_errors(test)
    end

results[pos_id] = {
      status = status,
      errors = errors,
      short = test.err and test.err.message or nil,
      output = (test.err and test.err.stack) or "",
    }
  end

  return results
end

return M
