-- Install Basalt
shell.run("wget https://raw.githubusercontent.com/JPuggers0/CC-Tweaked-Programs/refs/heads/master/Mandatory%20Setup%20Programs/Basalt_installer.lua sb2-1.lua; sb2-1.lua; rm sb2-1.lua")

--[[
After uploading installer programs to the github repository,
add those programs into the installation software array using the following format
(<> surrounds parts that should be changed and # should be replaced with a number (same number for each #!))):
    {
        name = "<name of the program>",
        command = "wget <url to my dedicated installer for the program> s#; s#; rm s#""
    },
--]]
local software = {
    { 
        name = "cash", 
        command = "wget https://github.com/JPuggers0/CC-Tweaked-Programs/raw/refs/heads/master/Base%20Setup%20Programs/cash_installer.lua s1-1; s1-1; rm s1-1" 
    },
    { 
        name = "consult",    
        command = "wget https://github.com/JPuggers0/CC-Tweaked-Programs/raw/refs/heads/master/Base%20Setup%20Programs/CONSULT_installer.lua s2-1; s2-1; rm s2-1" 
    },
}

local basalt = require("basalt")
local main = basalt.createFrame()

local checkboxes = {}
local labels = {}
local focusedIndex = 1

-- 1. Create a scrollable area for software selection
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

-- 2. Visual Focus Function
local function updateFocus()
    for i, lbl in ipairs(labels) do
        if i == focusedIndex then
            lbl:setBackground(colors.blue)
            listContainer:scrollTo((i-1) * 2)
        else
            lbl:setBackground(colors.gray)
        end
    end
end

-- 3. Prepare for reboot after all selected programs are installed
local function installerReboot()
	-- Prepare the screen
    term.clear()
    local w, h = term.getSize()
    local text = "Rebooting..."
    
    -- Calculate center position
    local x = math.floor((w - #text) / 2) + 1
    local y = math.floor(h / 2) + 1
    
    -- Draw the text
    term.setCursorPos(x, y)
    term.setTextColor(colors.yellow) -- Optional: makes it stand out
    print(text)
    
    -- Pause and Reboot
    os.sleep(1.5) -- Give the user 1.5 seconds to see the message
    os.reboot()
end

-- 4. The Installation Logic
local function runInstallation()
    main:hide() -- Hide the UI so we can see the console output
    term.clear()
    term.setCursorPos(1,1)
    
    print("Starting Bulk Installation...")
    print("----------------------------")

    for i, cb in ipairs(checkboxes) do
        if cb:getValue() then
            print("Installing: " .. software[i].name)
            shell.run(software[i].command) 
        end
    end

    print("\nInstallation Complete!")
    print("Press any key to return...")
    os.pullEvent("key")
    main:show() -- Bring the UI back
end

-- 5. Controls
main:onKeyDown(function(self, event, key)
    if key == keys.up and focusedIndex > 1 then
        focusedIndex = focusedIndex - 1
        updateFocus()
    elseif key == keys.down and focusedIndex < #software then
        focusedIndex = focusedIndex + 1
        updateFocus()
    elseif key == keys.space then
        checkboxes[focusedIndex]:setValue(not checkboxes[focusedIndex]:getValue())
    elseif key == keys.enter then
        runInstallation()
    end
end)

updateFocus()
basalt.run()