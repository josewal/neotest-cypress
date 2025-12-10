#!/usr/bin/env lua

-- Add the mock directory to the package path
package.path = package.path .. ";./tests/mock/?.lua;./tests/mock/?/init.lua"

-- Set up the mock environment before running tests
require("vusted.runner").run()