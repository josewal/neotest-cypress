-- Mock neotest.lib module
local M = {}

-- Mock files.match_root_pattern
M.files = {}
function M.files.match_root_pattern(...)
  return function(dir)
    -- Simple mock that returns the dir if it contains "neocy" or "test"
    if string.find(dir, "neocy") or string.find(dir, "test") then
      return "/mock/project/root"
    end
    return nil
  end
end

-- Mock treesitter module
M.treesitter = {}
function M.treesitter.parse_positions(file_path, opts)
  -- Return a proper structure that matches real treesitter parser
  local positions = {}
  
  -- For basic.cy.ts fixture
  if string.find(file_path, "basic.cy.ts") then
    table.insert(positions, {
      type = "describe",
      name = "basic test suite", 
      range = { 1, 0, 11, 1 },
      id = file_path .. "::basic test suite",
      -- Add children for nested tests
      children = {
        {
          type = "it",
          name = "should pass",
          range = { 2, 2, 4, 3 },
          id = file_path .. "::basic test suite::should pass"
        },
        {
          type = "describe", 
          name = "nested suite",
          range = { 6, 0, 10, 1 },
          id = file_path .. "::basic test suite::nested suite",
          children = {
            {
              type = "it",
              name = "should also pass", 
              range = { 7, 4, 9, 5 },
              id = file_path .. "::basic test suite::nested suite::should also pass"
            }
          }
        }
      }
    })
  end
  
  return positions
end

-- Mock positions.parse_tree
M.positions = {}
function M.positions.parse_tree(content)
  return {}
end

-- Mock files.read
function M.files.read(file_path)
  return "mock file content"
end

return M