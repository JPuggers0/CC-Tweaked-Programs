-- Check for --rebooted flag
local args = { ... }
local rebooted = false

for _, v in ipairs(args) do
    if v == "--rebooted" then
        rebooted = true
        break
    end
end

local STARTUP = "/startup.lua"
local BACKUP  = "/startup.lua.bkp"

local function installRebootHelper()
    shell.run(
        "wget",
        "https://raw.githubusercontent.com/JPuggers0/CC-Tweaked-Programs/master/Mandatory%20Setup%20Programs/reboot_helper.lua",
        STARTUP
    )
end

local function rebootWithMessage()
    print("Rebooting computer before continuing setup...")
    sleep(2.5)
    os.reboot()
end

-- Reboot Recovery

if rebooted then
    if fs.exists(BACKUP) then
        if fs.exists(STARTUP) then
            fs.delete(STARTUP)
        end
        fs.move(BACKUP, STARTUP)
    end
end

-- Bootstrap and reboot preparations
local needsReboot = false

if not rebooted then
    if fs.exists(STARTUP) and not fs.exists(BACKUP) then
        fs.move(STARTUP, BACKUP)
        installRebootHelper()
        needsReboot = true

    elseif not fs.exists(STARTUP) and not fs.exists(BACKUP) then
        installRebootHelper()
        needsReboot = true

    elseif fs.exists(BACKUP) and not fs.exists(STARTUP) then
        installRebootHelper()
        needsReboot = true

    elseif fs.exists(STARTUP) and fs.exists(BACKUP) then
        fs.delete(STARTUP)
        fs.move(BACKUP, STARTUP)
    end
end

-- Reboot if required
if needsReboot then
    rebootWithMessage()
end

-- Basalt install check
if not fs.exists("/libraries/basalt.lua") then
    shell.run(
        "wget",
        "run",
        "https://raw.githubusercontent.com/JPuggers0/CC-Tweaked-Programs/master/Mandatory%20Setup%20Programs/Basalt_installer.lua"
    )
end

local software = {
    {
        name = "cash",
        url = "https://raw.githubusercontent.com/JPuggers0/CC-Tweaked-Programs/master/Base%20Setup%20Programs/cash_installer.lua"
    },
    {
        name = "consult",
        url = "https://raw.githubusercontent.com/JPuggers0/CC-Tweaked-Programs/master/Base%20Setup%20Programs/CONSULT_installer.lua"
    },
}

local basalt = require("/libraries/basalt")

-- UI stage
local main = basalt.getMainFrame()
local W, H = term.getSize()

-- Title label
main:addLabel({
    x = 2, y = 1,
    text = "Select software to install:",
    foreground = colors.yellow,
})

-- Scrollable area for checkboxes (leave room for title + button)
local scrollH = H - 4
local scrollFrame = main:addScrollFrame({
    x = 1, y = 2,
    width = W - 1,
    height = scrollH,
    background = colors.black,
})

-- Track checked state and the checkbox elements
local checked = {}
local checkboxes = {}

for i, sw in ipairs(software) do
    checked[i] = false
    local cb = scrollFrame:addCheckBox({
        x = 2,
        y = i,
        text    = "[ ] " .. sw.name,
        checkedText = "[x] " .. sw.name,
        checked = false,
        foreground = colors.white,
        background = colors.black,
    })
    cb:onChange("checked", function(self, val)
        checked[i] = val
    end)
    checkboxes[i] = cb
end

-- Keyboard navigation: up/down moves focus, space toggles
local focusIndex = 1
local function updateFocus(newIdx)
    focusIndex = newIdx
    checkboxes[focusIndex]:setFocus()
end

basalt.onEvent("key", function(key)
    if key == keys.down then
        local next = math.min(focusIndex + 1, #checkboxes)
        updateFocus(next)
    elseif key == keys.up then
        local prev = math.max(focusIndex - 1, 1)
        updateFocus(prev)
    end
end)

--[[ Set initial keyboard focus to the first checkbox
if #checkboxes > 0 then
    checkboxes[1]:setFocus()
end
--]]
-- Install button at the bottom
main:addButton({
    x = 2,
    y = H,
    width = W - 2,
    height = 1,
    text = "Install Selected",
    background = colors.blue,
    foreground = colors.white,
}):onClick(function()
    basalt.stop()
    local toInstall = {}
    for i, sw in ipairs(software) do
        if checked[i] then
            toInstall[#toInstall + 1] = sw
        end
    end
    if #toInstall == 0 then
        print("No software selected.")
    else
        for _, sw in ipairs(toInstall) do
            print("Installing: " .. sw.name)
            shell.run("wget", "run", sw.url)
        end
        print("Done!")
    end
end)

basalt.run()