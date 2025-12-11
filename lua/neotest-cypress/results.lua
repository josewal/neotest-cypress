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

-- Extract JSON from Cypress output (may have other text mixed in)
local function extract_json_from_output(output)
  -- Cypress JSON reporter outputs JSON to stdout, but there may be other output mixed in
  -- Look for the JSON object that starts with { and contains "stats"

  -- Try to find JSON object boundaries
  local json_start = output:find('{"stats":')
  if not json_start then
    -- Try alternate pattern - sometimes the JSON starts differently
    json_start = output:find('{%s*"stats"')
  end

  if not json_start then
    util.log("Could not find JSON start in output", "WARN")
    return nil
  end

  -- Find the matching closing brace
  local depth = 0
  local json_end = nil
  for i = json_start, #output do
    local char = output:sub(i, i)
    if char == '{' then
      depth = depth + 1
    elseif char == '}' then
      depth = depth - 1
      if depth == 0 then
        json_end = i
        break
      end
    end
  end

  if not json_end then
    util.log("Could not find JSON end in output", "WARN")
    return nil
  end

  return output:sub(json_start, json_end)
end

-- Parse JSON data and convert to NeoTest results format
local function parse_json_data(data, file_path)
  local results = {}

  -- Cypress JSON reporter structure: { stats: {...}, tests: [...], passes: [...], failures: [...], pending: [...] }
  -- Note: This is different from the full Cypress run output which has { runs: [...] }

  -- Build a map of fullTitle -> state from the passes/failures/pending arrays
  local state_map = {}
  
  if data.passes then
    for _, test in ipairs(data.passes) do
      state_map[test.fullTitle or test.title] = "passed"
    end
  end
  
  if data.failures then
    for _, test in ipairs(data.failures) do
      state_map[test.fullTitle or test.title] = "failed"
    end
  end
  
  if data.pending then
    for _, test in ipairs(data.pending) do
      state_map[test.fullTitle or test.title] = "skipped"
    end
  end

  local tests = data.tests

  -- If data has 'runs' structure (full Cypress output), extract tests from there
  if not tests and data.runs and #data.runs > 0 then
    local run = data.runs[1]
    tests = run.tests
  end

  if not tests then
    util.log("No tests found in JSON data", "WARN")
    util.log({ data_keys = vim.tbl_keys(data) }, "DEBUG")
    return results
  end

  -- Process each test result
  for _, test in ipairs(tests) do
    -- Cypress JSON reporter gives us:
    -- - title: just the test name
    -- - fullTitle: complete path with describe blocks separated by spaces
    -- For matching against NeoTest positions, we use fullTitle and create
    -- a position ID that matches what discover_positions creates
    
    -- Use fullTitle as a single string for now - we'll need to match this
    -- against the position tree that NeoTest creates
    local pos_id = file_path .. "::" .. (test.fullTitle or test.title)
    
    -- Get state from the state_map, or use test.state if available, or default to skipped
    local cypress_state = state_map[test.fullTitle or test.title] or test.state or "skipped"
    local status = map_status(cypress_state)
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
    
    util.log({
      test_title = test.title,
      test_fullTitle = test.fullTitle,
      pos_id = pos_id,
      cypress_state = cypress_state,
      status = status
    }, "DEBUG")
  end

  util.log({
    total_results = #tests,
    processed_results = vim.tbl_count(results)
  }, "INFO")

  return results
end

-- Parse Cypress JSON output from stdout content
function M.parse_from_output(output_content, file_path)
  return util.safe_call(function()
    util.log({
      output_length = #output_content,
      file_path = file_path
    }, "DEBUG")

    -- Extract JSON from the output (may contain non-JSON text)
    local json_str = extract_json_from_output(output_content)

    if not json_str then
      util.log("Failed to extract JSON from output", "ERROR")
      util.log({ output_preview = output_content:sub(1, 500) }, "DEBUG")
      return {}
    end

    local success, data = pcall(vim.json.decode, json_str)
    if not success then
      util.log("Failed to parse JSON: " .. tostring(data), "ERROR")
      util.log({ json_preview = json_str:sub(1, 500) }, "DEBUG")
      return {}
    end

    return parse_json_data(data, file_path)
  end)
end

-- Parse Cypress JSON output from file (legacy, kept for compatibility)
function M.parse(results_path, file_path)
  return util.safe_call(function()
    util.log({
      results_path = results_path,
      file_path = file_path
    }, "DEBUG")

    -- Check if file exists
    local file_exists = vim.fn.filereadable(results_path) == 1
    if not file_exists then
      util.log("Results file does not exist: " .. results_path, "ERROR")
      return {}
    end

    local content = table.concat(vim.fn.readfile(results_path), "\n")
    return M.parse_from_output(content, file_path)
  end)
end

return M
