
================================================================================
                            LASERS UI LIBRARY
                                 README
================================================================================

  A modern, animated Roblox UI library for executors — 22 components, key
  system, config saving, themes, localization, toasts, popups, and full
  Rayfield Gen2 parity.

  Version  : 1.0
  License  : MIT
  Language : Luau (Roblox)

================================================================================
CONTENTS
================================================================================

  1.  Features
  2.  Installation
  3.  Quick Start
  4.  Window Configuration
  5.  Components
  6.  Key System
  7.  Config System
  8.  Themes
  9.  Notifications & Toasts
  10. Popups & Confirm Dialogs
  11. Localization
  12. Advanced Features
  13. Full API Reference
  14. Rayfield Gen2 Compatibility
  15. Executor Support
  16. Changelog
  17. License


================================================================================
1. FEATURES
================================================================================

UI
  - 22 components: buttons, toggles, sliders, dropdowns, color pickers,
    keybinds, console, steppers, and more
  - 6 built-in themes: default, cobalt, ember, amethyst, frost, rose
  - Custom theme tables — swap the entire palette at runtime
  - Smooth Quart/Quad tweens on every state change
  - Sidebar and top-tab layouts
  - Window resizing — drag the bottom-right corner
  - Hover tooltips on every row

ENGINE
  - Flag system — every component registers a value for persistence
  - Auto-save / auto-load configs to disk
  - Config sharing via base64 export/import
  - Key system — plain text or remote URL
  - Localization — locale tables + custom translator functions
  - Secure mode — suppress logging with LASERS_SECURE
  - Full Rayfield Gen2 parity — drop-in compatibility

EXTRAS
  - Rich notifications (hover-pauses, click-dismisses)
  - Pill-style toasts (top or bottom)
  - Modal popups with changelog boxes
  - Blocking confirm dialogs
  - In-game console with log levels
  - Watermark (FPS / ping / custom text)
  - Floating action button

DEVELOPER
  - Both camelCase and PascalCase config keys
  - Every component has :Set(), :Get(), :Lock(), :Unlock()
  - Every component supports :MoveTo(), :MoveToTop(), :MoveToBottom()
  - Graceful degradation on executors missing clipboard / file IO / HTTP
  - Auto-detects all mainstream executor globals


================================================================================
2. INSTALLATION
================================================================================

OPTION 1 — Load from host:

    local Library = loadstring(game:HttpGet("https://your.host/lasers.lua"))()

OPTION 2 — Paste the source directly into a LocalScript inside ReplicatedFirst.

OPTION 3 — Expose globally so other scripts can reach it:

    getgenv().Lasers = loadstring(game:HttpGet("https://your.host/lasers.lua"))()


================================================================================
3. QUICK START
================================================================================

    local Library = loadstring(game:HttpGet("https://your.host/lasers.lua"))()

    -- Optional: gate behind a key check (yields until accepted)
    Library:KeySystem({
        Key = "key-2773",
        GetKeyURL = "https://discord.gg/yourinvite",
    })

    -- Build the window
    local Window = Library:CreateWindow({
        Name = "My Hub",
        Subtitle = "v1.0",
        Theme = "cobalt",
        ToggleKey = Enum.KeyCode.RightShift,
        Configuration = {
            AutoSave = true,
            AutoLoad = true,
            FileName = "MainConfig",
        },
    })

    -- Add a tab
    local Main = Window:CreateTab({ Name = "Main", Icon = "house" })
    Main:CreateSection({ Name = "Combat" })

    -- Add components
    Main:CreateToggle({
        Name = "Auto Attack",
        Flag = "autoAttack",
        Default = false,
        Callback = function(state)
            print("Auto Attack:", state)
        end,
    })

    Main:CreateSlider({
        Name = "Attack Speed",
        Min = 1, Max = 10, Default = 5,
        Suffix = "x",
        Flag = "atkSpeed",
        Callback = function(value)
            print("Speed:", value)
        end,
    })

    -- Flash a toast
    Window:Toast({ Title = "Loaded", Subtitle = "All modules ready" })


================================================================================
4. WINDOW CONFIGURATION
================================================================================

    local Window = Library:CreateWindow({
        Name = "Lasers Hub",
        Subtitle = "v1.0.0",
        Icon = "rocket",
        Theme = "cobalt",
        SidebarLayout = true,
        PlayerName = "Signed in as Guest",
        ToggleKey = Enum.KeyCode.RightShift,
        ShowUserInfo = true,

        Configuration = {
            AutoSave = true,
            AutoLoad = true,
            FileName = "default",
            CustomFolder = "MyGame",
        },

        Locale = "en",
        Translations = {
            fr = { ["Main"] = "Principal" },
        },
        Translator = function(source, locale)
            -- return translated string or nil
        end,
    })


FIELD                   TYPE                DEFAULT         DESCRIPTION
--------------------------------------------------------------------------------
Name                    string              "Lib Name"      Window title
Subtitle                string              —               Small text under title
Icon                    string              —               Lucide glyph next to title
Theme                   string | table      "default"       Theme preset or custom table
SidebarLayout           boolean             false           true=sidebar, false=top tabs
PlayerName              string              —               Text at base of sidebar
ToggleKey               Enum.KeyCode        RightShift      Hide/show key
ShowUserInfo            boolean             true            Show avatar + display name
Configuration           table               —               Enables config saving
Locale                  string              —               Initial locale
Translations            table               —               Localization table
Translator              function            —               Custom translation function


CONFIGURATION SUB-TABLE
--------------------------------------------------------------------------------
AutoSave                boolean             Save config every 2 seconds
AutoLoad                boolean             Load saved config on startup
FileName                string              Name of the config file
CustomFolder            string              Subfolder inside LasersUI/Configs/


================================================================================
5. COMPONENTS
================================================================================

All components are created on a Tab:

    local Tab = Window:CreateTab({ Name = "Main", Icon = "house" })


COMPONENT TABLE
--------------------------------------------------------------------------------
 #   COMPONENT         METHOD                              PERSISTENCE
--------------------------------------------------------------------------------
 1   Label             Tab:CreateLabel(text)               no
 2   Warning           Tab:CreateWarning(text)             no
 3   Button            Tab:CreateButton({...})             no
 4   Toggle            Tab:CreateToggle({...})             yes
 5   Slider            Tab:CreateSlider({...})             yes
 6   Dropdown          Tab:CreateDropdown({...})           yes
 7   Input             Tab:CreateInput({...})              yes
 8   Keybind           Tab:CreateKeybind({...})            yes
 9   Color Picker      Tab:CreateColorPicker({...})        yes
 10  Stat              Tab:CreateStat({...})               no
 11  Progress          Tab:CreateProgress({...})           no
 12  Console           Tab:CreateConsole({...})            no
 13  Text              Tab:CreateText({...})               no
 14  Divider           Tab:CreateDivider({...})            no
 15  Section           Tab:CreateSection({...})            no
 16  Group             Tab:CreateGroup({...})              no
 17  Image             Tab:CreateImage({...})              no
 18  Button Group      Tab:CreateButtonGroup({...})        no
 19  Selector          Tab:CreateSelector({...})           yes
 20  Hyperlink         Tab:CreateHyperlink({...})          no
 21  Stepper           Tab:CreateStepper({...})            yes
 22  Tag               Tab:CreateTag({...})                no


--------------------------------------------------------------------------------
5.1  LABEL
--------------------------------------------------------------------------------

    local lbl = Tab:CreateLabel("Hello, world!")
    lbl:Set("Updated text")

Non-interactive text row.

Handle:
  :Set(str)
  .Instance


--------------------------------------------------------------------------------
5.2  WARNING
--------------------------------------------------------------------------------

    local w = Tab:CreateWarning("This cannot be undone.")
    w:Set("New warning text")

Amber-bordered box with exclamation icon.

Handle:
  :Set(str)
  .Instance


--------------------------------------------------------------------------------
5.3  BUTTON
--------------------------------------------------------------------------------

    Tab:CreateButton({
        Name = "Reset settings",
        Description = "Clears everything",   -- tooltip
        Callback = function() print("clicked") end,
    })

Handle:
  .Instance


--------------------------------------------------------------------------------
5.4  TOGGLE / SWITCH
--------------------------------------------------------------------------------

    local toggle = Tab:CreateToggle({
        Name = "Auto Sprint",
        Flag = "autoSprint",
        Default = false,
        Description = "Sprint automatically when moving.",
        Callback = function(state) print(state) end,
    })

    toggle:Set(true)
    toggle:Set(true, true)   -- silent (no callback)
    toggle:Get()

Alias: Tab:CreateSwitch(cfg)

Fields:
  Name / name                string
  Flag / flag                string
  Default / default / Value  boolean
  Description / description  string
  Callback / callback        function

Handle:
  :Set(bool, silent)
  :Get() -> bool


--------------------------------------------------------------------------------
5.5  SLIDER
--------------------------------------------------------------------------------

    local slider = Tab:CreateSlider({
        Name = "Walk Speed",
        Range = { 16, 200 },      -- or Min / Max
        Default = 16,
        Increment = 1,
        Suffix = " w/s",
        HideLabel = false,
        Flag = "walkSpeed",
        Callback = function(value, dragging) end,
    })

    slider:Set(50)
    slider:Get()

Fields:
  Name / name                string
  Range / range              {min, max}    default {0, 100}
  Min / max / min / max      number        alternative to Range
  Default / value            number        starting value
  Increment / increment      number        default 1
  Suffix / suffix            string        appended to display
  HideLabel / hideLabel      boolean       hide the name row
  Flag / flag                string
  Callback / callback        function(value, dragging)

The callback receives (value, dragging). dragging is true while the user is
actively dragging the knob and false when they let go.

Handle:
  :Set(number, silent)
  :Get() -> number


--------------------------------------------------------------------------------
5.6  DROPDOWN
--------------------------------------------------------------------------------

    local dd = Tab:CreateDropdown({
        Name = "Weapon",
        Options = { "Sword", "Bow", "Staff" },
        Default = "Sword",
        MultiSelect = false,
        Placeholder = "Select one...",
        Flag = "weapon",
        Callback = function(selection) print(selection) end,
    })

    dd:Set("Bow")
    dd:Set({ "Sword", "Bow" })   -- multi
    dd:Get()
    dd:Add("Dagger")
    dd:Remove("Staff")
    dd:Refresh({ "Sword", "Axe" })

Fields:
  Name / name                string
  Options / options          table
  Value / value / Default    string or table
  MultiSelect / multi        boolean
  Placeholder / placeholder  string
  Flag / flag                string
  Callback / callback        function(value)

Features:
  - Filter-as-you-type search box appears when expanded
  - Add / Remove options at runtime

Handle:
  :Set(valueOrTable, silent)
  :Get()
  :Refresh(newOptions)
  :Add(option)
  :Remove(option)


--------------------------------------------------------------------------------
5.7  INPUT / TEXTBOX
--------------------------------------------------------------------------------

    local input = Tab:CreateInput({
        Name = "Player name",
        Placeholder = "Type here...",
        Value = "",
        Numeric = false,
        ClearOnFocus = false,
        MinWidth = 56,
        MaxWidth = 180,
        Flag = "playerName",
        Callback = function(text) print(text) end,
    })

    input:Set("Bob")
    input:Get()

Alias: Tab:CreateTextbox(cfg)

Fields:
  Name / name                string
  Value / value / Default    string
  Placeholder / placeholder  string
  Numeric / numeric          boolean    only accept numbers
  ClearOnFocus / clearOnFocus boolean   empty box when focused
  MinWidth / maxWidth        number
  Flag / flag                string
  Callback / callback        function(text)

Callback fires when the user presses Enter or the box loses focus.

Handle:
  :Set(str, silent)
  :Get() -> string


--------------------------------------------------------------------------------
5.8  KEYBIND
--------------------------------------------------------------------------------

    local bind = Tab:CreateKeybind({
        Name = "Sprint",
        Default = Enum.KeyCode.LeftShift,
        Hold = false,
        HoldDuration = 0.5,
        Flag = "sprintKey",
        Callback = function(key, held) end,
    })

    bind:Set(Enum.KeyCode.F)
    bind:Get()

Fields:
  Name / name                string
  Value / value / Default    Enum.KeyCode
  Hold / hold                boolean     require holding
  HoldDuration / holdDuration number     seconds required (0.5)
  Flag / flag                string
  Callback / callback        function(key, held)
  OnPress / onPress          function(state)

Behaviour:
  - Click the key box to enter rebinding mode
  - Press Backspace to clear. Press Escape to cancel
  - Mouse buttons accepted too
  - Hold mode: fires callback(true) after HoldDuration of continuous press,
    fires callback(false) on release

Handle:
  :Set(keyCode, silent)
  :Get() -> Enum.KeyCode or Enum.UserInputType


--------------------------------------------------------------------------------
5.9  COLOR PICKER (with alpha)
--------------------------------------------------------------------------------

    local color = Tab:CreateColorPicker({
        Name = "Highlight",
        Color = Color3.fromRGB(100, 160, 255),
        Alpha = 1,
        Flag = "highlight",
        Callback = function(c, a) end,
    })

    color:Set(Color3.fromRGB(255, 0, 0))
    color:SetAlpha(0.5)
    color:Get()
    color:GetAlpha()

Fields:
  Name / name                string
  Color / color / Default    Color3
  Alpha / alpha              number     0..1
  Flag / flag                string
  Callback / callback        function(color, alpha)

Handle:
  :Set(color, silent)
  :SetAlpha(alpha, silent)
  :Get() -> Color3
  :GetAlpha() -> number


--------------------------------------------------------------------------------
5.10  STAT
--------------------------------------------------------------------------------

    Tab:CreateStat({
        Name = "Revenue",
        Value = 12400,
        Prefix = "$",
        Suffix = "",
        Roll = true,
        Compact = false,
    })

Fields:
  Name / name                string
  Value / value              number or string
  Prefix / prefix            string
  Suffix / suffix            string
  Roll / roll                boolean     animate value changes
  Compact / compact          boolean     shorter row

Display-only.

Handle:
  :Set(v, silent)
  :Get()
  :ZeroChange()             -- clears the delta indicator


--------------------------------------------------------------------------------
5.11  PROGRESS / PROGRESSBAR
--------------------------------------------------------------------------------

    local prog = Tab:CreateProgress({
        Name = "Setup",
        Min = 0, Max = 100, Value = 25,
        Steps = nil,              -- "value/max" readout
        Indeterminate = false,    -- sweep animation
        ShowReadout = true,
        Formatter = function(v, min, max) return v .. "%" end,
        Text = nil,               -- static readout text
        Flag = "progress",
    })

    prog:Set(75)
    prog:GetProgress()
    prog:SetRange(0, 200)
    prog:SetIndeterminate(true)

Alias: Tab:CreateProgressBar(cfg)

Handle:
  :Set(value)
  :Get()
  :GetProgress() -> 0..1
  :SetRange(min, max)
  :SetText(str)
  :SetIndeterminate(bool)


--------------------------------------------------------------------------------
5.12  CONSOLE
--------------------------------------------------------------------------------

    local console = Tab:CreateConsole({
        Name = "Output",
        Text = "--- started ---",
        Height = 130,
        Follow = true,
        MaxLines = 200,
    })

    console:Append("player joined")
    console:Clear()
    console:Copy()

Fields:
  Name / name                string
  Text / text / Code / code  string      initial content
  Height / height            number      default 130
  Follow / follow            boolean     auto-scroll to bottom
  MaxLines / maxLines        number      default 200

Monospace scrolling log.

Handle:
  :Set(str)
  :Append(str)
  :Clear()
  :Get() -> string
  :Copy()
  :SetHeight(pixels)


--------------------------------------------------------------------------------
5.13  TEXT / PARAGRAPH
--------------------------------------------------------------------------------

    Tab:CreateText({
        Name = "Read this first",       -- optional title
        Text = "Long body text.",       -- optional body
    })

Alias: Tab:CreateParagraph(cfg)

Handle:
  :Set(bodyText)
  :SetTitle(titleText)
  :Get() -> string


--------------------------------------------------------------------------------
5.14  DIVIDER
--------------------------------------------------------------------------------

    Tab:CreateDivider({
        Text = "or",
        Spacing = 8,
        Line = true,
    })

Handle:
  :Set(text)
  .Instance


--------------------------------------------------------------------------------
5.15  SECTION
--------------------------------------------------------------------------------

    Tab:CreateSection({ Name = "Combat" })
    Tab:CreateSection("Combat")       -- string shorthand

Small caps header used to group rows.

Handle:
  :Set(text)
  .Instance


--------------------------------------------------------------------------------
5.16  GROUP
--------------------------------------------------------------------------------

    local group = Tab:CreateGroup({ Direction = "row" })  -- or "column"
    local left  = group:CreateGroup({ Direction = "column" })
    local right = group:CreateGroup({ Direction = "column" })

    group:CreateSection("Header")

Layout container for placing multiple elements side by side.

Handle:
  :CreateSection(name)
  :CreateGroup(sub)
  .Instance


--------------------------------------------------------------------------------
5.17  IMAGE
--------------------------------------------------------------------------------

    Tab:CreateImage({
        Image = "rbxassetid://12345678",
        Height = 140,
    })

Handle:
  :Set(assetId)
  .Instance


--------------------------------------------------------------------------------
5.18  BUTTON GROUP
--------------------------------------------------------------------------------

    Tab:CreateButtonGroup({
        Buttons = {
            { Name = "Accept", Callback = function() end },
            { Name = "Decline", Callback = function() end },
        },
    })

Row of side-by-side buttons that split the width evenly.

Handle:
  .Buttons    -- array of TextButtons
  .Instance


--------------------------------------------------------------------------------
5.19  SELECTOR
--------------------------------------------------------------------------------

    local sel = Tab:CreateSelector({
        Name = "Mode",
        Options = { "Easy", "Normal", "Hard" },
        Default = "Normal",
        Flag = "difficulty",
        Callback = function(v) end,
    })

    sel:Set("Hard")
    sel:Get()
    sel:Refresh({ "Easy", "Hard", "Extreme" })

Left / right chevron cycling.

Handle:
  :Set(value, silent)
  :Get()
  :Refresh(newOptions)


--------------------------------------------------------------------------------
5.20  HYPERLINK
--------------------------------------------------------------------------------

    Tab:CreateHyperlink({
        Name = "Discord",
        URL = "https://discord.gg/yourinvite",
        Callback = function() end,
    })

Copies URL to clipboard on click.

Handle:
  .Instance


--------------------------------------------------------------------------------
5.21  STEPPER
--------------------------------------------------------------------------------

    local step = Tab:CreateStepper({
        Name = "Volume",
        Min = 0, Max = 100, Default = 50,
        Increment = 5,
        Flag = "volume",
        Callback = function(v) end,
    })

    step:Set(75)
    step:Get()

Number input with minus / plus buttons.

Handle:
  :Set(number, silent)
  :Get() -> number


--------------------------------------------------------------------------------
5.22  TAG
--------------------------------------------------------------------------------

    local tag = Tab:CreateTag({
        Name = "Status",
        Text = "Ready",
        Color = Color3.fromRGB(90, 210, 130),
    })

    tag:Set("Busy", Color3.fromRGB(255, 95, 95))

Inline colored pill next to a name inside a row.

Handle:
  :Set(text, color)
  .Instance


================================================================================
6. KEY SYSTEM
================================================================================

Gate your script behind a key check. Supports hardcoded keys AND remote keys
fetched from a URL. Yields until a valid key is accepted.

    local key = Library:KeySystem({
        -- Use one of these:
        Key = "key-2773",                          -- plain text
        URL = "https://example.com/api/key",       -- remote (returns plain text)

        -- Optional:
        GetKeyURL = "https://discord.gg/yourinvite",
        Title = "Lasers Hub",
        Description = "Enter your key to continue.",
        Placeholder = "xxxx-xxxx-xxxx",
        SubmitText = "Unlock",
        SaveKey = true,                            -- cache to disk
        FileName = "lasers_key.txt",

        OnSuccess = function(key) print("Welcome!") end,
        OnFail = function(input) print("Rejected:", input) end,
    })

    print("Unlocked with key:", key)


NOTE: KeySystem YIELDS until a valid key is accepted.
      Place it BEFORE CreateWindow.


REMOTE KEY RESOLUTION
--------------------------------------------------------------------------------
If URL is set, the library makes an HTTP GET and treats the response body as
the valid key (trimmed of surrounding whitespace). Your server should return
plain text, not JSON.

    HTTP GET https://example.com/api/key
    -> 200 OK
    -> Body: key-2773

If Key is also set, no HTTP request is made — the hardcoded key wins.

WHITESPACE: user input is trimmed, so " key-2773 " matches "key-2773".

FILE CACHE: if SaveKey is enabled and the executor exposes writefile/readfile,
valid keys are written to FileName and silently revalidated on next run.


================================================================================
7. CONFIG SYSTEM
================================================================================

--------------------------------------------------------------------------------
AUTO-SAVE / AUTO-LOAD
--------------------------------------------------------------------------------

    local Window = Library:CreateWindow({
        Name = "My Hub",
        Configuration = {
            AutoSave = true,
            AutoLoad = true,
            FileName = "MainConfig",
            CustomFolder = "MyGame",
        },
    })

Auto-load runs once on window creation.
Auto-save is throttled to once every 2 seconds of Heartbeat activity.


--------------------------------------------------------------------------------
MANUAL SAVE / LOAD
--------------------------------------------------------------------------------

    Window:Save("PvP Loadout")
    Window:Load("PvP Loadout")
    Window:ListConfigs()             -- -> {"MainConfig", "PvP Loadout"}
    Window:DeleteConfig("PvP Loadout")

Files stored at:
    <executor-workspace>/LasersUI/Configs/<CustomFolder>/<name>.json


--------------------------------------------------------------------------------
READING / WRITING FLAGS
--------------------------------------------------------------------------------

Every component with a Flag is registered in two tables:

    Window.Flags.autoAttack            -- current value
    Window:Get("autoAttack")           -- same value
    Window:Set("autoAttack", true)     -- updates UI + fires callback


--------------------------------------------------------------------------------
SHARING CONFIGS
--------------------------------------------------------------------------------

    local blob = Library:ExportConfig()       -- base64, copies to clipboard
    Library:ImportConfig(blob)
    Library:ImportConfigFromClipboard()       -- needs clipboard getter


SUPPORTED SERIALIZATION TYPES
--------------------------------------------------------------------------------
    boolean / number / string      native JSON
    Color3                         { __type="Color3", r, g, b }
    EnumItem (Keybinds)            { __type="EnumItem", enumType, name }
    table                          recursive


================================================================================
8. THEMES
================================================================================

BUILT-IN PRESETS
--------------------------------------------------------------------------------
    Name           Accent           Base
--------------------------------------------------------------------------------
    default        Blue             Neutral dark
    cobalt         Deep blue        Neutral dark
    ember          Warm orange      Dark brown
    amethyst       Purple           Dark violet
    frost          Cyan             Cold blue
    rose           Pink             Dark rose

    Library:SetTheme("ember")
    Library:GetTheme()    --> "ember"

CUSTOM THEMES
--------------------------------------------------------------------------------
    Library:SetTheme({
        Accent = Color3.fromRGB(255, 80, 80),
        Background = Color3.fromRGB(10, 10, 10),
        Secondary = Color3.fromRGB(22, 22, 22),
        Element = Color3.fromRGB(30, 30, 30),
        ElementHover = Color3.fromRGB(40, 40, 40),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(170, 170, 170),
        Stroke = Color3.fromRGB(150, 150, 150),
    })

    -- Or on the fly
    Window:ChangeTheme("frost")

FULL THEME KEY LIST
--------------------------------------------------------------------------------
    Background, Secondary, Element, ElementHover, Off, Stroke, Text, SubText,
    Warning, Accent, Success, Error


================================================================================
9. NOTIFICATIONS & TOASTS
================================================================================

--------------------------------------------------------------------------------
NOTIFICATIONS
--------------------------------------------------------------------------------

Rich cards that slide in from the bottom-right. Hover pauses the timer.
Click dismisses. Stacks up to 6.

    Library:Notify({
        Type = "success",    -- "info" | "success" | "warning" | "error"
        Title = "Saved",
        Content = "Config written to disk.",
        Duration = 4,
    })

    -- Shorthands
    Library:NotifySuccess("Saved", "Config written.")
    Library:NotifyError("Failed", "Server unreachable.")
    Library:NotifyWarning("Careful", "This action is destructive.")
    Library:NotifyInfo("Info", "Loading complete.")


--------------------------------------------------------------------------------
TOASTS
--------------------------------------------------------------------------------

Pill-style popups from the top or bottom of the screen.

    Library:Toast({ Title = "Saved", Icon = "circle-check" })

    -- With avatar
    Library:Toast({
        Title = "Nova",
        Subtitle = "joined the server",
        Avatar = 1,               -- Roblox UserId
        Position = "Bottom",
        Duration = 5,
    })

    -- Subtitle above title
    Library:Toast({
        Title = "Achievement",
        Subtitle = "Unlocked",
        SubtitleAboveTitle = true,
    })

FIELDS
--------------------------------------------------------------------------------
    Title                string
    Subtitle             string
    SubtitleAboveTitle   boolean
    Icon                 string     Lucide glyph
    Avatar               number     Roblox UserId
    Position             string     "Top" (default) | "Bottom"
    Duration             number     auto-derived if omitted
    MinWidth             number


================================================================================
10. POPUPS & CONFIRM DIALOGS
================================================================================

--------------------------------------------------------------------------------
POPUP
--------------------------------------------------------------------------------

Modal dialogs with a dimmed backdrop. Perfect for changelogs and choices.

    Library:Popup({
        Title = "What's new",
        Subtitle = "Version 1.2",
        Content = "This update brings new features:",
        Boxes = {
            { icon = "bolt", title = "Faster", description = "Reduced latency." },
            { icon = "shield", title = "Safer", description = "Better anti-cheat." },
        },
        Options = {
            { Text = "Later", Style = "neutral" },
            { Text = "Update", Style = "primary", Callback = function() end },
        },
        Dismissible = true,
    })


--------------------------------------------------------------------------------
CONFIRM DIALOG (BLOCKING)
--------------------------------------------------------------------------------

Returns true on confirm, false on cancel.

    if Library:Confirm({
        Title = "Reset everything?",
        Description = "This cannot be undone.",
        Danger = true,
        ConfirmText = "Yes, reset",
        CancelText = "Cancel",
    }) then
        print("user confirmed")
    end


================================================================================
11. LOCALIZATION
================================================================================

    local Window = Library:CreateWindow({
        Name = "My Hub",
        Locale = "fr",
        Translations = {
            fr = {
                ["Auto Sprint"] = "Sprint auto",
                ["Combat"]      = "Combat",
            },
            de = {
                ["Auto Sprint"] = "Auto-Sprint",
            },
        },
    })

    -- Runtime updates
    Window:SetLocale("de")
    Window:RegisterTranslations({ jp = { ["Combat"] = "\u{6226}\u{95D8}" } })

    -- Custom translator function
    Window:SetTranslator(function(source, locale)
        return myService[locale][source]
    end)

All strings created through Create* are automatically translated.
Locale codes fall back to their base language (fr-CA -> fr).


================================================================================
12. ADVANCED FEATURES
================================================================================

--------------------------------------------------------------------------------
LOCKING COMPONENTS
--------------------------------------------------------------------------------

Dims a row and blocks all input. Perfect for premium-only features.

    local esp = Tab:CreateToggle({ Name = "ESP", Flag = "esp" })

    esp:Lock("Premium only")
    esp:IsLocked()     --> true
    esp:Unlock()

Locked components ignore user input and skip their callbacks.


--------------------------------------------------------------------------------
REORDERING COMPONENTS
--------------------------------------------------------------------------------

    esp:MoveToTop()
    esp:MoveToBottom()
    esp:MoveTo(3)
    esp:MoveUp()
    esp:MoveDown()


--------------------------------------------------------------------------------
WINDOW TAGS
--------------------------------------------------------------------------------

Small pills next to the title bar.

    local tag = Window:CreateTag({
        Text = "v1.0",
        Color = Color3.fromRGB(100, 160, 255),
        Icon = "star",
    })

    tag:Set({ Text = "live", Color = Color3.fromRGB(90, 210, 130) })


--------------------------------------------------------------------------------
TAB BADGES
--------------------------------------------------------------------------------

Red counter pills next to tab names.

    Tab:SetBadge(3)
    Tab:GetBadge()      --> 3
    Tab:ClearBadge()


--------------------------------------------------------------------------------
WATERMARK
--------------------------------------------------------------------------------

    local wm = Library:SetWatermark({
        Text = "My Hub v1.0",
        ShowFPS = true,
        ShowPing = true,
    })

    wm:SetText("Updated text")
    wm:Destroy()


--------------------------------------------------------------------------------
FLOATING ACTION BUTTON
--------------------------------------------------------------------------------

    Library:CreateFloatingButton({
        Icon = "gear",
        Color = Color3.fromRGB(100, 160, 255),
        Size = 46,
        Callback = function()
            Library._window:Toggle()
        end,
    })


--------------------------------------------------------------------------------
IN-GAME CONSOLE
--------------------------------------------------------------------------------

    Library:Log("Loaded successfully", "success")
    Library:Log("Retrying...", "warning")
    Library:Log("Crash: nil value", "error")

    Library:OpenConsole()
    Library:CloseConsole()
    Library:ToggleConsole()
    Library:ClearLogs()

Log levels: info, success, warning, error, debug.


--------------------------------------------------------------------------------
WINDOW METHODS
--------------------------------------------------------------------------------

    Window:SetTitle("New Title")
    Window:SetSubtitle("v2.0")
    Window:SetPlayerName("Signed in as Nova")

    Window:Show()
    Window:Hide()
    Window:Toggle()
    Window:Collapse()
    Window:Expand()
    Window:Resize(700, 500)
    Window:SelectTab("Main")
    Window:Destroy()   -- or :Unload()


================================================================================
13. FULL API REFERENCE
================================================================================

--------------------------------------------------------------------------------
LIBRARY LEVEL
--------------------------------------------------------------------------------
    Library:CreateWindow(cfg)                 Create the main window
    Library:KeySystem(cfg)                    Blocking key prompt
    Library:Notify(cfg)                       Show a notification
    Library:NotifyInfo/Error/Success/Warning  Shorthand notifications
    Library:Toast(cfg)                        Show a toast pill
    Library:Popup(cfg)                        Show a modal popup
    Library:Confirm(cfg)                      Blocking confirm dialog
    Library:SetWatermark(cfg)                 Show a watermark
    Library:CreateFloatingButton(cfg)         Floating action button
    Library:SetTheme(name) / GetTheme()       Theme control
    Library:Log(msg, kind)                    Push a log entry
    Library:ClearLogs()                       Clear all logs
    Library:OpenConsole() / CloseConsole()    Console control
    Library:ToggleConsole()
    Library:ExportConfig()                    Config as base64
    Library:ImportConfig(str)                 Import base64
    Library:ImportConfigFromClipboard()


--------------------------------------------------------------------------------
WINDOW
--------------------------------------------------------------------------------
    Window:CreateTab(cfg)                     Create a tab
    Window:CreateTag(cfg)                     Add a header pill
    Window:CreateSection(cfg)                 Sidebar heading
    Window:SetTitle/Subtitle/PlayerName       Update header text
    Window:Show/Hide/Toggle()                 Visibility
    Window:Collapse/Expand()                  Minimize / restore
    Window:Resize(w, h)                       Pixel size
    Window:SelectTab(nameOrTab)               Switch tabs
    Window:ChangeTheme(nameOrTable)           Runtime theme swap
    Window:SetLocale(id)                      Change locale
    Window:RegisterTranslations(tbl)          Add translations
    Window:SetTranslator(fn)                  Custom translator
    Window:Save(name) / Load(name)            Manual config
    Window:ListConfigs() / DeleteConfig(name) Config management
    Window:Get(flag) / Set(flag, v)           Flag access
    Window:Destroy() / Unload()               Destroy the window


--------------------------------------------------------------------------------
TAB
--------------------------------------------------------------------------------
    Tab:Select() / Deselect() / Remove()      Tab lifecycle
    Tab:SetBadge(n) / GetBadge() / ClearBadge Badge control
    Tab:Save() / Load()                       Shortcut to window save/load
    Tab:CreateXxx(cfg)                        Every component


================================================================================
14. RAYFIELD GEN2 COMPATIBILITY
================================================================================

Lasers UI ships with drop-in compatibility for scripts written against
Rayfield Gen2. Every Rayfield field, method, and component name is supported.

    FEATURE                                  SUPPORTED
--------------------------------------------------------------------------------
    Name, Subtitle, Icon                     yes
    Theme (preset or table)                  yes
    SidebarLayout                            yes
    Configuration.AutoSave / AutoLoad        yes
    Locale / Translations / Translator       yes
    Window:Show/Hide/Toggle/Collapse/Expand  yes
    Window:SelectTab/Unload                  yes
    Window:Save/Load/ListConfigs/DeleteConfig yes
    Window.Flags, Window:Get/Set             yes
    Window:CreateTag                         yes
    Window:CreateSection                     yes
    Library:Notify with Type                 yes
    Library:Toast (top/bottom, avatar, etc)  yes
    Library:Popup with Boxes                 yes
    createToggle/createSlider/createDropdown yes
    Flag, ForgetState, Description           yes
    :Lock(reason) / :Unlock()                yes
    :MoveTo/MoveToTop/MoveToBottom           yes
    Color picker with alpha                  yes
    RAYFIELD_SECURE global                   yes (also LASERS_SECURE)
    Both camelCase and PascalCase            yes

MIGRATING FROM RAYFIELD
--------------------------------------------------------------------------------
Change loadstring(game:HttpGet(".../rayfield.lua"))() to the Lasers UI URL.
Everything else runs unchanged.


================================================================================
15. EXECUTOR SUPPORT
================================================================================

The library auto-detects and gracefully degrades on every mainstream executor.

    FEATURE          DETECTED GLOBALS
--------------------------------------------------------------------------------
    Clipboard write  setclipboard, toclipboard, writeclipboard,
                     write_clipboard, syn.write_clipboard, Clipboard.set

    Clipboard read   getclipboard, syn.get_clipboard, Clipboard.get

    HTTP request     syn.request, http.request, http_request, request

    GUI parents      gethui, cloneref(CoreGui), CoreGui

    File IO          writefile, readfile, isfile, isfolder, makefolder,
                     listfiles, delfile


GRACEFUL DEGRADATION
--------------------------------------------------------------------------------
    No clipboard     falls back to "Clipboard unavailable" notification
    No file IO       config saving/loading silently disabled
    No HTTP          key URL fetching fails with friendly error
    No UIShadow      shadow instances are skipped silently


TESTED ON
--------------------------------------------------------------------------------
    Synapse X, Script-Ware, Krnl, Fluxus, SirHurt, Hydrogen, Wave, AWP, Delta,
    and any executor exposing the standard globals.


================================================================================
16. CHANGELOG
================================================================================

v1.0 — Initial Release
--------------------------------------------------------------------------------
    - 22 components with animations
    - Full Rayfield Gen2 parity
    - Key system (plain text + remote URL)
    - Rich notifications, toasts, popups, confirm dialogs
    - Config saving, auto-save/load, base64 export/import
    - 6 built-in themes + custom theme tables
    - Localization with fallback chains
    - In-game console with log levels
    - Watermark and floating action button
    - Executor detection and graceful degradation
    - LASERS_SECURE (with RAYFIELD_SECURE fallback)


================================================================================
17. LICENSE
================================================================================

MIT License

Copyright (c) 2024 Lasers UI

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


================================================================================
                    Made with love for the Roblox scripting
                              community
================================================================================
                    End of README
================================================================================
