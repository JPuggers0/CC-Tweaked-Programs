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

local main = basalt.getMainFrame()

-- Title
main:addLabel()
    :setText("Select Software to Install")
    :setPosition(2, 1)

-- Correct scroll container (THIS is the real Basalt element)
local scrollFrame = main:addScrollFrame()
    :setPosition(2, 3)
    :setSize(40, 12)

local checkboxes = {}

-- Build checkbox list
for i, item in ipairs(software) do
    local cb = scrollFrame:addCheckbox()
        :setText(item.name)
        :setPosition(1, i)
        :setValue(false)

    checkboxes[#checkboxes + 1] = {
        checkbox = cb,
        data = item
    }
end

-- Install button (outside scroll frame)
main:addButton()
    :setText("Install Selected")
    :setPosition(2, 16)
    :setSize(20, 1)
    :onClick(function()

        for _, entry in ipairs(checkboxes) do
            if entry.checkbox:getValue() then
                local item = entry.data

                print("Installing " .. item.name)

                shell.run("wget", "run", item.url)
            end
        end

        print("Done.")
    end)

basalt.run()