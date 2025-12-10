---@diagnostic disable: undefined-global
describe("discovery", function()
  it("should create position IDs correctly", function()
    local util = require("neotest-cypress.util")
    local id = util.create_position_id("file.cy.ts", {"suite1", "test1"})
    assert.equals("file.cy.ts::suite1::test1", id)
  end)
end)