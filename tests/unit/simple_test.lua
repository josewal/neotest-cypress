-- Simple test to verify core functionality
local util = require("neotest-cypress.util")

print("Testing basic functionality...")

-- Test position ID creation
local id = util.create_position_id("test.cy.ts", {"suite", "test"})
print("Position ID created: " .. id)

-- Test is_test_file function
local adapter = {
  is_test_file = function(file_path)
    return string.match(file_path, "%.cy%.[tj]sx?$") ~= nil
  end
}

print("Test file detection:")
print("example.cy.ts is test file: " .. tostring(adapter.is_test_file("example.cy.ts")))
print("example.ts is test file: " .. tostring(adapter.is_test_file("example.ts")))

print("Basic functionality test completed!")