local vim = vim
local util = require("neotest-cypress.util")

local M = {}

-- Map Cypress test state to NeoTest status
local function map_status(cypress_state)
  local mapped_status = 
  (cypress_state == "passed" and "passed") or
  (cypress_state == "failed" and "failed") or
  ((cypress_state == "pending" or cypress_state == "skipped") and "skipped") or
  "skipped"

  util.log({
    cypress_state = cypress_state, 
    mapped_status = mapped_status
  }, "DEBUG")

  return mapped_status
end

-- Extract error information from Cypress test result
local function extract_errors(test)
  return util.safe_call(function()
    if not test.err or test.err == vim.NIL then
      util.log("No error information found", "DEBUG")
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

    util.log({
      message = message, 
      has_stack = not not err.stack
    }, "DEBUG")

    return errors
  end)
end

-- Build position ID from Cypress test title path
-- Cypress format: ["describe name", "nested describe", "test name"]
local function build_position_id(file_path, title_path)
  return util.safe_call(function()
    if not title_path or #title_path == 0 then
      util.log({
        file_path = file_path, 
        title_path = title_path, 
        message = "No title path, using file path as position ID"
      }, "DEBUG")
      return file_path
    end

    local pos_id = util.create_position_id(file_path, title_path)

    util.log({
      file_path = file_path,
      title_path = title_path,
      pos_id = pos_id
    }, "DEBUG")

    return pos_id
  end)
end

-- Parse Cypress JSON output and convert to NeoTest results format
function M.parse(results_path, file_path)
  return util.safe_call(function()
    util.log({
      results_path = results_path, 
      file_path = file_path
    }, "DEBUG")

    local data = vim.fn.json_decode(vim.fn.readfile(results_path))

    local results = {}

    -- Cypress JSON structure: { runs: [{ tests: [...] }] }
    if not data.runs or #data.runs == 0 then
      util.log("No runs found in JSON data", "WARN")
      return results
    end

    local run = data.runs[1]
    if not run.tests then
      util.log("No tests found in run", "WARN")
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

    util.log({
      total_results = #run.tests,
      processed_results = vim.tbl_count(results)
    }, "INFO")

    return results
  end)
end

return M
