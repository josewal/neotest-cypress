---@meta

---@class neotest.Position
---@field id string
---@field name string
---@field type string
---@field path string

---@class neotest.Tree
---@field data fun(): neotest.Position

---@class neotest.RunSpec
---@field command string
---@field args string[]
---@field context table

return {}