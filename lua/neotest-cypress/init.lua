local vim = vim
---@type neotest.lib
local lib = require("neotest.lib")
local results_parser = require("neotest-cypress.results")
local util = require("neotest-cypress.util")
local config = require("neotest-cypress.config")
require("neotest-cypress.types")

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
  
  util.log("Searching for project root in: " .. tostring(dir), "DEBUG")
  
  -- Try to find the project root by searching up the directory tree
  local root_path = lib.files.match_root_pattern(
    "cypress.config.ts", 
    "cypress.config.js", 
    "package.json"
  )(dir)
  
  util.log("Found project root: " .. tostring(root_path), "DEBUG")
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
  
  -- Only log when it's actually a test file to reduce noise
  if is_cypress_test then
    util.log({file_path = file_path, is_cypress_test = is_cypress_test}, "DEBUG")
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
  
  -- Reduce logging verbosity - only log when filtering out directories
  if not filtered then
    util.log({dir = name, filtered = filtered}, "DEBUG")
  end
  
  return filtered
end

-- Discover test positions using treesitter
---@param file_path string
---@return neotest.Position[]
function M.discover_positions(file_path)
  util.log("Discovering positions for: " .. tostring(file_path), "DEBUG")
  
  -- Try to parse positions with treesitter
  local success, positions = pcall(function()
    return lib.treesitter.parse_positions(
      file_path,
      {
        nested_namespaces = true,
        require_namespaces = false,
      },
      {
        position_id = function(file, names)
          return require('neotest-cypress.util').create_position_id(file, names)
        end,
      }
    )
  end)
  
  if not success or not positions then
    util.log("Error in treesitter parsing, falling back to default position parsing", "WARN")
    positions = lib.positions.parse_tree(lib.files.read(file_path))
  end
  
  util.log("Discovered positions", "DEBUG")
  return positions or {}
end

-- Build the Cypress command to execute tests
---@param args {tree: neotest.Tree}
---@return neotest.RunSpec
function M.build_spec(args)
  return util.safe_call(function()
    local position = args.tree:data()
    local results_path = vim.fn.tempname() .. ".json"
    
    util.log({
      position_path = position.path,
      results_path = results_path,
      position_id = position.id
    }, "DEBUG")
    
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

    -- Use the 'result' parameter for future debugging if needed
    util.log({result = result}, "DEBUG")

    if not results_path then
      util.log("No results path provided", "WARN")
      return {}
    end

    local parsed_results = results_parser.parse(results_path, file_path)
    util.log({
      results_path = results_path,
      file_path = file_path, 
      parsed_results_count = parsed_results and vim.tbl_count(parsed_results) or 0
    }, "DEBUG")

    return parsed_results or {}
  end)
end

-- Setup function to configure the adapter
---@param opts? table
function M.setup(opts)
  opts = opts or {}
  current_config = config.setup(opts)
  
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