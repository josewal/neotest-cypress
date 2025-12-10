local vim = vim
---@type neotest.lib
local lib = require("neotest.lib")
local results_parser = require("neotest-cypress.results")
local util = require("neotest-cypress.util")
local config = require("neotest-cypress.config")
require("neotest-cypress.types")

-- Pretty print utility for tracing using Noice if available, fallback to vim.notify
local function pp(label, value)
  local has_noice, noice = pcall(require, "noice")

  -- Format the message
  local msg
  if type(value) == "table" then
    msg = string.format("%s:\n%s", label, vim.inspect(value))
  else
    msg = string.format("%s: %s", label, tostring(value))
  end

  -- Use noice if available, otherwise fallback to vim.notify
  if has_noice and noice then
    noice.notify(msg, "info", {
      title = "neocy",
      timeout = 2000,
    })
  else
    vim.notify(msg, vim.log.levels.INFO, { title = "neocy" })
  end
end

local M = {}

M.name = "neotest-cypress"

-- Configuration
local current_config = config.defaults

-- Find the project root by locating cypress.config.ts/js or package.json
---@param dir string
---@return string|nil
function M.root(dir)
  -- Set log level from config
  if current_config.log_level then
    util.set_log_level(current_config.log_level)
  end

  pp("root: searching", dir)

  -- Try to find the project root by searching up the directory tree
  local root_path = lib.files.match_root_pattern(
    "cypress.config.ts",
    "cypress.config.js",
    "package.json"
  )(dir)

  pp("root: found", root_path)
  return root_path
end

-- Identify Cypress test files by pattern *.cy.{ts,tsx,js,jsx}
---@param file_path string
---@return boolean
function M.is_test_file(file_path)
  if not file_path then
    return false
  end

  -- Check if file matches Cypress test patterns
  local is_cypress_test =
    vim.endswith(file_path, ".cy.ts") or
    vim.endswith(file_path, ".cy.tsx") or
    vim.endswith(file_path, ".cy.js") or
    vim.endswith(file_path, ".cy.jsx")

  -- Only print when it's actually a test file to reduce noise
  if is_cypress_test then
    pp("is_test_file", file_path)
  end

  return is_cypress_test
end

-- Filter out directories that should not be searched
---@param name string
---@return boolean
function M.filter_dir(name)
  local filtered = name ~= "node_modules" and
                   name ~= ".git" and
                   name ~= "dist" and
                   name ~= "build"

  -- Reduce printing verbosity - only print when filtering out directories
  if not filtered then
    pp("filter_dir: excluding", name)
  end

  return filtered
end

-- Discover test positions using treesitter
---@param file_path string
---@return neotest.Position[]
function M.discover_positions(file_path)
  pp("discover_positions: parsing", file_path)

  -- Try to parse positions with treesitter
  local success, positions = pcall(function()
    -- Try the treesitter parsing with file path
    local parsed = lib.treesitter.parse_positions(
      file_path,
      {
        nested_namespaces = true,
        require_namespaces = false,
      }
    )

    if parsed and #parsed > 0 then
      pp("discover_positions: treesitter found", #parsed .. " positions")
      -- Apply our custom position_id function
      for _, pos in ipairs(parsed) do
        if pos.name then
          -- Update the position ID with our custom format
          pos.id = util.create_position_id(file_path, {pos.name})
        end
      end
    end

    return parsed
  end)

  if not success or not positions or #positions == 0 then
    if not success then
      pp("discover_positions: treesitter error", positions)
    end
    pp("discover_positions: falling back to default parser", file_path)

    -- Try fallback: read the file content and use lib.positions.parse_tree
    local file_content = lib.files.read(file_path)

    if file_content then
      positions = lib.positions.parse_tree(file_content)
      pp("discover_positions: fallback found", #positions .. " positions")
    else
      pp("discover_positions: failed to read file", file_path)
      positions = {}
    end
  end

  return positions or {}
end

-- Build the Cypress command to execute tests
---@param args {tree: neotest.Tree}
---@return neotest.RunSpec
function M.build_spec(args)
  return util.safe_call(function()
    local position = args.tree:data()
    local results_path = vim.fn.tempname() .. ".json"

    pp("build_spec", {
      spec = position.path,
      results_path = results_path,
      position_id = position.id
    })

    return {
      command = "npx",
      args = {
        "cypress",
        "run",
        "--spec",
        position.path,
        "--reporter",
        "json",
        "--reporter-options",
        "output=" .. results_path,
        "--headless",
      },
      context = {
        results_path = results_path,
        pos_id = position.id,
        file = position.path,
      },
    }
  end)
end

-- Parse Cypress JSON output and map to NeoTest format
---@param spec neotest.RunSpec
---@param result table
---@param tree neotest.Tree
---@return table
function M.results(spec, result, tree)
  return util.safe_call(function()
    local results_path = spec.context.results_path
    local file_path = spec.context.file or tree:data().path

    pp("results: parsing output", results_path)

    if not results_path then
      pp("results: no results path", "missing")
      return {}
    end

    local parsed_results = results_parser.parse(results_path, file_path)
    pp("results: parsed", {
      results_path = results_path,
      file_path = file_path,
      result_count = parsed_results and vim.tbl_count(parsed_results) or 0
    })

    return parsed_results or {}
  end)
end

-- Setup function to configure the adapter
---@param opts? table
function M.setup(opts)
  opts = opts or {}
  current_config = config.setup(opts)

  pp("setup: configured", {
    log_level = current_config.log_level,
    debug = opts.debug or false
  })

  -- Set log level
  if current_config.log_level then
    util.set_log_level(current_config.log_level)
  end

  -- Set debug mode if specified
  if opts.debug ~= nil then
    util.set_debug_mode(opts.debug)
  end
end

return M
