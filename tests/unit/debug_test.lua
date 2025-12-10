-- Debug test for discovering test positions
-- Documents the fixes made and tests the pretty print tracing

print("[NEOCY] Diagnostic test file loaded")

-- Test fixture
local test_content = [[
describe("basic test suite", () => {
  it("should pass", () => {
    expect(true).toBe(true);
  });

  describe("nested suite", () => {
    it("should also pass", () => {
      cy.visit("/");
    });
  });
});
]]

print("[NEOCY] Test fixture loaded")
print("[NEOCY] Pretty print tracing enabled for: root, is_test_file, filter_dir, discover_positions, build_spec, results, setup")
