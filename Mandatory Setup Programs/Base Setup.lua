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

-- UI Stage
local main = basalt.getMainFrame()
local W, H = term.getSize()

main:addLabel({
    x = 2, y = 1,
    text = "Select software to install:",
    foreground = colors.yellow,
})
main:addLabel({
    x = 2, y = 2,
    text = "Up/Dn: move  Space: toggle  Enter: install",
    foreground = colors.gray,
})

local listH = H - 3
local checked   = {}
local cursorIdx = 1

for i = 1, #software do
    checked[i] = false
end

-- A Display element gives us a raw writable surface — no states, no overrides
local display = main:addDisplay({
    x = 1, y = 3,
    width = W,
    height = listH,
    background = colors.black,
})

local function renderRows()
    display:clear(colors.black)
    for i = 1, #software do
        local bg = (i == cursorIdx) and colors.blue or colors.black
        local prefix = checked[i] and "[x] " or "[ ] "
        display:setCursorPos(1, i)
        display:setBackgroundColor(bg)
        display:setTextColor(colors.white)
        display:write((" " .. prefix .. software[i].name):sub(1, W))
    end
end

renderRows()

-- Mouse clicks on the display: which row?
display:onClick(function(self, btn, x, y)
    if y >= 1 and y <= #software then
        cursorIdx = y
        checked[cursorIdx] = not checked[cursorIdx]
        renderRows()
    end
end)

local function doInstall()
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
end

basalt.onEvent("key", function(key)
    if key == keys.up then
        if cursorIdx > 1 then
            cursorIdx = cursorIdx - 1
            renderRows()
        end
    elseif key == keys.down then
        if cursorIdx < #software then
            cursorIdx = cursorIdx + 1
            renderRows()
        end
    elseif key == keys.space then
        checked[cursorIdx] = not checked[cursorIdx]
        renderRows()
    elseif key == keys.enter then
        doInstall()
    end
end)

main:addButton({
    x = 1, y = H,
    width = W,
    height = 1,
    text = "[ Install Selected ]",
    background = colors.blue,
    foreground = colors.white,
}):onClick(doInstall)

basalt.run()