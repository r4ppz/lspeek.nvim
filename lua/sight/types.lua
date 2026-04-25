---@alias FloatBorder "none" | "single" | "double" | "rounded"

---@class FloatOpts
---@field width? number The width of the window (default: 40)
---@field height? number The height of the window (default: 10)
---@field row? number The row position relative to cursor (default: 1)
---@field col? number The column position relative to cursor (default: 1)
---@field border? FloatBorder The border style (default: "rounded")
---@field enter? boolean Whether to move cursor into the window (default: true)
