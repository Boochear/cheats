-- ============================================================
--  DiscordLib — Full Feature Demo
--  Shows every method the library exposes
-- ============================================================

local DiscordLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Boochear/cheats/main/source.lua"))()

-- ============================================================
--  WINDOW + SERVER
-- ============================================================
local Window = DiscordLib:Window("DiscordLib Demo")
local Server = Window:Server("Demo Server", "rbxthumb://type=GameIcon&id={universe_id}&w=150&h=150")  -- "" = first letter of name as icon

-- ============================================================
--  CHANNELS
-- ============================================================
local ChElements = Server:Channel("Elements")
local ChSliders  = Server:Channel("Sliders")
local ChInputs   = Server:Channel("Inputs")
local ChMisc     = Server:Channel("Misc")

-- ============================================================
--  BUTTON
-- ============================================================
ChElements:Button("Button Example", function()
    print("You clicked the button!")
end)

-- ============================================================
--  TOGGLE
-- ============================================================
ChElements:Toggle("Toggle Example", false, function(state)
    print("[Demo] Toggle ->", state)
end)

-- ============================================================
--  LABEL (text divider)
-- ============================================================
ChElements:Label("── Label Example ──")

-- ============================================================
--  SEPARATOR
-- ============================================================
ChElements:Seperator()

-- ============================================================
--  DROPDOWN
-- ============================================================
local dropdown = ChElements:Dropdown(
    "Dropdown Example",
    {"Option 1", "Option 2", "Option 3", "Option 4"},
    function(selected)
        print("[Demo] Dropdown ->", selected)
    end
)

-- dropdown methods
ChElements:Button("Dropdown: Add Item", function()
    dropdown:Add("Added Option")
end)

ChElements:Button("Dropdown: Clear All", function()
    dropdown:Clear()
end)

-- ============================================================
--  KEYBIND
-- ============================================================
ChElements:Bind("Keybind Example", Enum.KeyCode.G, function()
    print("G was pressed!")
end)

-- ============================================================
--  COLORPICKER
-- ============================================================
ChElements:Colorpicker("Colorpicker Example", Color3.fromRGB(114, 137, 228), function(color)
    print("[Demo] Color ->", color)
end)

-- ============================================================
--  TEXTBOX
-- ============================================================
ChInputs:Textbox("Textbox Example", "Type something...", true, function(text)
    print("[Demo] Textbox ->", text)
end)

-- textbox with disappear = false (keeps text after submit)
ChInputs:Textbox("Textbox (keep text)", "Type and press Enter...", false, function(text)
    print("[Demo] Textbox keep ->", text)
end)

-- ============================================================
--  SLIDERS
-- ============================================================
ChSliders:Slider("Slider 1-100", 1, 100, 50, function(value)
    print("[Demo] Slider ->", value)
end)

ChSliders:Slider("Slider Float 0-1", 0, 1, 0.5, function(value)
    print("[Demo] Float Slider ->", value)
end)

-- slider with return value (Change method)
local sliderRef = ChSliders:Slider("Programmatic Slider", 0, 100, 0, function(value)
    print("[Demo] Programmatic Slider ->", value)
end)

ChSliders:Button("Set Programmatic Slider to 75", function()
    sliderRef:Change(75)
end)

-- ============================================================
--  LABELS AS SECTION HEADERS
-- ============================================================
ChMisc:Label("── Info ──")
ChMisc:Label("Window size: 681 x 396")
ChMisc:Label("RightCtrl toggles settings menu")
ChMisc:Label("Drag the top bar to move the window")

-- ============================================================
--  MULTIPLE TOGGLES (state tracking demo)
-- ============================================================
local toggleStates = {}

ChMisc:Toggle("Toggle A", false, function(state)
    toggleStates.A = state
    print("[Demo] Toggle A ->", state)
end)

ChMisc:Toggle("Toggle B", false, function(state)
    toggleStates.B = state
    print("[Demo] Toggle B ->", state)
end)

ChMisc:Button("Print All Toggle States", function()
    print("[Demo] Toggle A =", toggleStates.A)
    print("[Demo] Toggle B =", toggleStates.B)
end)