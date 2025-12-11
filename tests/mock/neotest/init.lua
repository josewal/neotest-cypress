-- Mock neotest module
local M = {}

-- Export the lib module
M.lib = require("neotest.lib")

-- Mock summary module with marked() function
M.summary = {}
local marked_tests = {}

function M.summary.marked()
  return marked_tests
end

-- Helper to set marked tests for testing
function M.summary._set_marked(tests_table)
  marked_tests = tests_table
end

-- Mock client
M.client = {}
function M.client:get_position(pos_id)
  -- Return a mock tree-like object
  return {
    data = function()
      return {
        id = pos_id,
        name = pos_id:match("::([^:]+)$") or pos_id,
      }
    end
  }
end

return M