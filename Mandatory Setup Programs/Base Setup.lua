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

-- UI STAGE

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
local main = basalt.createFrame()

local checkboxes = {}
local labels = {}
local buttons = {}
local focusedIndex = 1

local listContainer = main:addFrame()
    :setScrollable(true)
    :setPosition(2, 2)
    :setSize(26, 12)
    :setBackground(colors.gray)

local states = {}

for i, program in ipairs(software) do
    local yPos = (i - 1) * 2 + 1
    states[i] = false

    local btn = listContainer:addButton()
        :setPosition(2, yPos)
        :setSize(4, 1)
        :setText("[ ]")
        :setBackground(colors.gray)
        :setForeground(colors.white)

    table.insert(buttons, btn)

    local lbl = listContainer:addLabel()
        :setPosition(6, yPos)
        :setText(program.name)
        :setForeground(colors.white)

    table.insert(checkboxes, states) -- we reuse "checkboxes" later logically
    table.insert(labels, lbl)
end

local function updateFocus()
    for i, lbl in ipairs(labels) do
        if i == focusedIndex then
            lbl:setBackground(colors.blue)
            listContainer:setOffset(0, (i - focusedIndex) * 2)
        else
            lbl:setBackground(colors.gray)
        end
    end
end

local function installerReboot()
    term.clear()
    local w, h = term.getSize()
    local text = "Rebooting..."

    term.setCursorPos(math.floor((w - #text) / 2) + 1, math.floor(h / 2) + 1)
    print(text)

    sleep(2.5)
    os.reboot()
end

local function runInstallation()
    term.clear()
    term.setCursorPos(1, 1)

    term.clear()
    print("Starting Bulk Installation...")

    for i, cb in ipairs(checkboxes) do
        if cb:getValue() then
            print("Installing: " .. software[i].name)
            shell.run("wget", "run", software[i].url)
        end
    end

    print("\nInstallation Complete!")
    print("Press any key to reboot...")
    os.pullEvent("key")

    installerReboot()
end

while true do
    local event, key = os.pullEvent("key")

    if key == keys.up and focusedIndex > 1 then
        focusedIndex = focusedIndex - 1
        updateFocus()

    elseif key == keys.down and focusedIndex < #software then
        focusedIndex = focusedIndex + 1
        updateFocus()

    elseif key == keys.space then
        states[focusedIndex] = not states[focusedIndex]

        -- update button text if you're using toggle buttons
        local btn = buttons[focusedIndex]
        if btn then
            btn:setText(states[focusedIndex] and "[X]" or "[ ]")
        end

    elseif key == keys.enter then
        runInstallation()
        break
    end
end

updateFocus()
basalt.run()