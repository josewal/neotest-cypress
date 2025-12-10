-- Debug test to understand the core issue
print("Debug test for treesitter queries")

-- Simple test to check if the queries can parse the test files
local test_content = [[
describe("basic test suite", () => {
  it("should pass", () => {
    expect(true).toBe(true);
  });
});
]]

print("Test content loaded")
print("Would test treesitter parsing here...")
print("But the real issue is likely in the query parsing")