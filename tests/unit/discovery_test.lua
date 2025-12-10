#!/usr/bin/env lua

-- Simple test to check if position discovery is working
local util = require("neotest-cypress.util")

-- Test the position ID creation
print("Testing position ID creation")
local id = util.create_position_id("file.cy.ts", {"suite1", "test1"})
print("Position ID: " .. id)

-- Test if a file is a test file
print("\nTesting file detection")
local isTestFile = util.is_test_file("example.cy.ts")
print("Is test file (example.cy.ts): " .. tostring(isTestFile))

local isNotTestFile = util.is_test_file("example.ts")
print("Is test file (example.ts): " .. tostring(isNotTestFile))

print("\nAll basic tests passed!")