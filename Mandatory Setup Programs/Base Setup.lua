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

-- Title
main:addLabel({
    x = 2, y = 1,
    text = "Select software to install:",
    foreground = colors.yellow,
})

-- Hint line
main:addLabel({
    x = 2, y = 2,
    text = "Up/Dn: move  Space: toggle  Enter: install",
    foreground = colors.gray,
})

-- ScrollFrame for the checklist (rows 3 to H-1, leave row H for button)
local scrollH = H - 3
local scrollFrame = main:addScrollFrame({
    x = 1, y = 3,
    width = W - 1,
    height = scrollH,
    background = colors.black,
})

-- State
local checked  = {}
local labels   = {}   -- the Label elements we update for visual feedback
local cursorIdx = 1

local function rowText(i)
    local box = checked[i] and "[x]" or "[ ]"
    return " " .. box .. " " .. software[i].name
end

local function renderRows()
    for i, lbl in ipairs(labels) do
        lbl:set("text", rowText(i))
        if i == cursorIdx then
            lbl:set("background", colors.blue)
            lbl:set("foreground", colors.white)
        else
            lbl:set("background", colors.black)
            lbl:set("foreground", colors.white)
        end
    end
end

-- Build one label per software entry; make them clickable via onClick on a Button
-- We use Buttons (full-width, height 1) so mouse clicks work naturally
for i, sw in ipairs(software) do
    checked[i] = false
    local btn = scrollFrame:addButton({
        x = 1, y = i,
        width = W - 2,
        height = 1,
        text = rowText(i),
        background = colors.black,
        foreground = colors.white,
    })
    btn:onClick(function()
        cursorIdx = i
        checked[i] = not checked[i]
        renderRows()
    end)
    labels[i] = btn
end

renderRows()

-- Keyboard navigation
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
end)

-- Install button at the very bottom
main:addButton({
    x = 1, y = H,
    width = W,
    height = 1,
    text = "[ Install Selected ]",
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