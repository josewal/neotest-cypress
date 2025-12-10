local util = require("neotest-cypress.util")

describe("util", function()
  it("creates position IDs correctly", function()
    local id = util.create_position_id("file.cy.ts", {"suite1", "test1"})
    assert.equals("file.cy.ts::suite1::test1", id)
  end)

  it("extracts test name from position ID", function()
    local name = util.get_test_name_from_id("file.cy.ts::suite::test")
    assert.equals("test", name)
  end)

  it("gets namespace path from position ID", function()
    local namespaces = util.get_namespace_path("file.cy.ts::a::b::test")
    assert.same({"a", "b"}, namespaces)
  end)

  it("safely calls functions", function()
    local result = util.safe_call(function() return "ok" end)
    assert.equals("ok", result)
  end)
end)
