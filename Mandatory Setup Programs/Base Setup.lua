-- Check for --rebooted flag
local args = { ... }
local rebooted = false
for _, v in ipairs(args) do
    if v == "--rebooted" then
        rebooted = true
    end
end

    -- Check if Basalt is installed, if not install Basalt
    if not fs.exists("/libraries/basalt.lua") then
        shell.run(
            "wget",
            "run",
            "https://raw.githubusercontent.com/JPuggers0/CC-Tweaked-Programs/master/Mandatory%20Setup%20Programs/Basalt_installer.lua"
        )
    end

-- Make sure previous user startup.lua is safe, then prepare for and start a reboot
if rebooted then
    fs.delete("/startup.lua")
    if fn.exists("/startup.lua.bkp") then
        fs.move("/startup.lua.bkp", "/startup.lua")
    end
elseif fs.exists("/startup.lua.bkp") then
    shell.run(
        "wget",
        "https://raw.githubusercontent.com/JPuggers0/CC-Tweaked-Programs/master/Mandatory%20Setup%20Programs/reboot_helper.lua",
        "/startup.lua"
    )
    print("Rebooting computer before continuing setup...")
    os.startTimer(2.5)
    os.reboot()
elseif fs.exists("/startup.lua") then
    fs.move("/startup.lua", "/startup.lua.bkp")
    shell.run(
        "wget",
        "https://raw.githubusercontent.com/JPuggers0/CC-Tweaked-Programs/master/Mandatory%20Setup%20Programs/reboot_helper.lua",
        "/startup.lua"
    )
    print("Rebooting computer before continuing setup...")
    os.startTimer(2.5)
    os.reboot()
elseif not fs.exists("/startup.lua") and not fs.exists("/startup.lua.bkp") then
    shell.run(
        "wget",
        "https://raw.githubusercontent.com/JPuggers0/CC-Tweaked-Programs/master/Mandatory%20Setup%20Programs/reboot_helper.lua",
        "/startup.lua"
    )
    print("Rebooting computer before continuing setup...")
    os.startTimer(2.5)
    os.reboot()
else
    print("Something went wrong\nStartup file check reached catch-all\nDebugging needed!")
    os.exit(1)
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
local main = basalt.createFrame()

local checkboxes = {}
local labels = {}
local focusedIndex = 1

local listContainer = main:addScrollableFrame()
    :setPosition(2, 2)
    :setSize(26, 12)
    :setBackground(colors.gray)

for i, program in ipairs(software) do
    local yPos = (i - 1) * 2 + 1

    local cb = listContainer:addCheckbox()
        :setPosition(2, yPos)
        :setBackground(colors.lightGray)

    local lbl = listContainer:addLabel()
        :setPosition(5, yPos)
        :setText(program.name)
        :setForeground(colors.white)

    table.insert(checkboxes, cb)
    table.insert(labels, lbl)
end

local function updateFocus()
    for i, lbl in ipairs(labels) do
        if i == focusedIndex then
            lbl:setBackground(colors.blue)
            listContainer:scrollTo((i - 1) * 2)
        else
            lbl:setBackground(colors.gray)
        end
    end
end

local function installerReboot()
    term.clear()

    local w, h = term.getSize()
    local text = "Rebooting..."

    local x = math.floor((w - #text) / 2) + 1
    local y = math.floor(h / 2) + 1

    term.setCursorPos(x, y)
    term.setTextColor(colors.yellow)

    print(text)

    os.sleep(2.5)
    os.reboot()
end

local function runInstallation()
    main:hide()

    term.clear()
    term.setCursorPos(1, 1)

    print("Starting Bulk Installation...")
    print("----------------------------")

    for i, cb in ipairs(checkboxes) do
        if cb:getValue() then
            local program = software[i]

            print("Installing: " .. program.name)

            shell.run(
                "wget",
                "run",
                program.url
            )
        end
    end

    print("\nInstallation Complete!")
    print("Press any key to reboot...")

    os.pullEvent("key")

    installerReboot()
end

main:onKeyDown(function(self, event, key)
    if key == keys.up and focusedIndex > 1 then
        focusedIndex = focusedIndex - 1
        updateFocus()

    elseif key == keys.down and focusedIndex < #software then
        focusedIndex = focusedIndex + 1
        updateFocus()

    elseif key == keys.space then
        checkboxes[focusedIndex]:setValue(
            not checkboxes[focusedIndex]:getValue()
        )

    elseif key == keys.enter then
        runInstallation()
    end
end)

updateFocus()
basalt.run()