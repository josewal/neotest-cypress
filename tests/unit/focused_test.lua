-- Simple focused test for the core issue
print("Focused test for 'no tests being registered' issue")

-- This represents the core functionality that needs to be tested
local test_files = {
  "example.cy.ts",
  "example.cy.js", 
  "example.cy.tsx",
  "example.cy.jsx"
}

for _, file in ipairs(test_files) do
  local is_test = string.match(file, "%.cy%.[tj]sx?$") ~= nil
  print(file .. " is test file: " .. tostring(is_test))
end

print("Core functionality test completed")