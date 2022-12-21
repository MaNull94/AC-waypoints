local filePath = 'apps\\lua\\waypoints'
local showSavedTextDelayInSecs = 5

--local sets = ac.INIConfig.scriptSettings()
--ac.debug('sets', sets)

local trackName = ac.getTrackName()
local prefix = 'POINT_'

local lastPointNumber = -1
local lastPointName = 'name'
local pointIndex = 0
local teleports = {}
local teleportIndex = 1

local onlineExtras = ac.INIConfig.onlineExtras()
for _, parameterName in onlineExtras:iterateValues('TELEPORT_DESTINATIONS', 'POINT') do

  local withoutPrefix = parameterName:sub(#prefix + 1, #parameterName)
  -- ac.debug(withoutPrefix)


  local numberLength = withoutPrefix:find('_')
  if numberLength == nil then
    numberLength = #withoutPrefix
  else
    numberLength = numberLength - 1
  end

  local pointNumber = withoutPrefix:sub(1, numberLength)
  -- ac.debug("number", pointNumber)
  local parameter = withoutPrefix:sub(numberLength + 2) -- +2 потому что 100_ это 4 + 2 = стартовая позиция откуда берется имя параметра
  -- ac.log("p -> " .. parameter)

  -- если читаем новую точку
  local value = onlineExtras:get('TELEPORT_DESTINATIONS', parameterName, nil)
  if parameter == '' and value ~= nil then
    if tonumber(pointNumber) ~= lastPointNumber then
      local pointTrackName = onlineExtras:get('TELEPORT_DESTINATIONS', prefix..pointNumber..'_GROUP')[1]
      if pointTrackName == trackName then
        local teleport = {}
        teleport['name'] = value[1]
        teleport['pointIndex'] = pointIndex
        teleports[teleportIndex] = teleport
        teleportIndex = teleportIndex + 1


        lastPointNumber = tonumber(pointNumber)
        lastPointName = value
      end
      pointIndex = pointIndex + 1
    end
  end

end


function script.windowMain(dt)
  ui.text(trackName .. ' teleports:\n')
  -- ac.log('hw log: ' .. counter)
  -- if ui.button('тык') then
  --   physics.teleportCarTo(0, 'START')
  --   for teleportLabel, teleportObject in pairs(ac.SpawnSet) do 
  --     -- ac.log('l  ' .. teleportLabel)
  --     -- ac.log('t  ' .. teleportObject)
  --     -- ac.log('t type - ' .. type(teleportObject))
      
  --   end
  -- end

  -- if ui.button('aga') then
  --   for i, j in pairs(ac) do
  --     startPos, endPos = string.find(i, 'tele')
  --     if startPos ~= nil then
  --       ac.log('i ' .. i)
  --     -- ac.log('j ' .. j)
  --     -- ac.log(' ')
  --     end
  --   end
  -- end

  -- if ui.button('tp_start') then
  --   physics.teleportCarTo(0, "START")
  -- end





  -- ipairs для вывода точек по порядку
    for i, teleport in ipairs(teleports) do
      if ui.button(teleport['name']) then
        ac.teleportToServerPoint(teleport['pointIndex'])
      end
      ui.sameLine()
    end
    ui.invisibleButton()


  if ui.button('save all') then
    local file = io.open("apps\\lua\\waypoints\\test.txt", "w")
    file:write("aboba")
    file:close()
  end

  -- if ui.button('tp') then
     -- physics.setCarPosition(carIndex: integer, pos: vec3, dir: vec3)
     -- physics.setCarPosition(0, vec3(208.1,-1.1,-5.6), vec3(0.0, 0.0, 0.0))
     -- physics.setCarPosition(0, vec3(208.1,-1.1,-5.6), vec3(0.0, 0.0, 0.0))
  -- end
  ac.debug('date', os.date("%Y%m%d_%H%M"))

end

local dummyPoints = {
  "P1",
  "P2",
  "P3",
  "P4",
  "P5",
  "P6",
  "P7",
  "P8",
}

local selectedPointIndex = 0
local pointEditedName -- edit point
local newPointName -- add point
local editPanelActive
local addAfter
function script.pointEditor(dt)
  ui.header(trackName .. ': Points list')
  ui.separator()
  ui.separator()
  local windowID = ui.getLastID()
  --ui.beginTransparentWindow(windowID, vec2(500, 500), vec2(100, 100), false)
  -- ui.text('текст без фона')
  --ui.endTransparentWindow()

  --ui.textDisabled("текст серым шрифтом")



  ui.beginChild(windowID, vec2(500, 100), true, ui.WindowFlags['HorizontalScrollbar'])
  for i, point in pairs(dummyPoints) do

    if ui.button(point) then
      selectedPointIndex = i
    end
    local buttonID = ui.getLastID()
    ui.itemPopup(buttonID, ui.MouseButton.Right,
            function()
              selectedPointIndex = i

              if ui.selectable('edit name') then
                ac.log(string.format("edit %s click", i))
                editPanelActive = true
                pointEditedName = point
              end

              if ui.selectable('delete') then
                ac.log(string.format("delete %s click", i))
                deletePanelActive = true
              end

              if ui.selectable('add after') then
                addPanelActive = true
                addAfter = true
              end

              if ui.selectable('add before') then
                addPanelActive = true
                addAfter = false
              end
            end
    )

    if i == selectedPointIndex then
      ui.sameLine()
      ui.invisibleButton()
      ui.sameLine()
      if ui.smallButton('up') then
        if selectedPointIndex > 1 then
          ac.log('up')
          local tempPoint = dummyPoints[selectedPointIndex - 1]
          dummyPoints[selectedPointIndex - 1] = dummyPoints[selectedPointIndex]
          dummyPoints[selectedPointIndex] = tempPoint
          selectedPointIndex = selectedPointIndex - 1
        end
      end

      ui.sameLine()
      if ui.smallButton('down') then
        if selectedPointIndex < #dummyPoints then
          ac.log('down')
          local tempPoint = dummyPoints[selectedPointIndex + 1]
          dummyPoints[selectedPointIndex + 1] = dummyPoints[selectedPointIndex]
          dummyPoints[selectedPointIndex] = tempPoint
          selectedPointIndex = selectedPointIndex + 1
        end
      end

    end
  end

  ui.endChild()

  if addPanelActive then
    local inputText
    if newPointName == nil then
      inputText = "new point"
    else
      inputText = newPointName
    end

    newPointName = ui.inputText('', inputText)

    local pos
    local insertIndex
    if addAfter then
      pos = 'after'
      insertIndex = selectedPointIndex + 1
    else
      pos = 'before'

      insertIndex = selectedPointIndex - 1
    end

    ui.sameLine()
    if ui.button('create ' .. pos) then
      newPointName = _trim(newPointName)
      if newPointName ~= '' then
        table.insert(dummyPoints, insertIndex, newPointName)
        addPanelActive = false
      end
    end


  end


  if selectedPointIndex > 0 and editPanelActive then
    local inputText
    if pointEditedName == nil then
      inputText = dummyPoints[selectedPointIndex]
    else
      inputText = pointEditedName
    end

    pointEditedName = ui.inputText("", inputText)

    ui.sameLine()
    if ui.button('save') then
      pointEditedName = _trim(pointEditedName)
      if pointEditedName ~= '' then
        dummyPoints[selectedPointIndex] = pointEditedName
        editPanelActive = false
      end
    end

    ui.sameLine()
    if ui.button('cancel') then
      selectedPointIndex = 0
      addPanelActive = false
    end


  end

  if selectedPointIndex > 0 and deletePanelActive then
    ui.text('Delete ' .. dummyPoints[selectedPointIndex] .. '?')
    if ui.button('yes') then
      dummyPoints[selectedPointIndex] = nil
      deletePanelActive = false
    end

    ui.sameLine()
    if ui.button('no') then
      deletePanelActive = false
    end

  end


  ui.separator()
  ui.separator()
  ui.separator()
  local savedPointsFilename = os.date("%Y%m%d_%H%M")
  local filePathFull = string.format("%s\\%s.txt", filePath, savedPointsFilename)
  if ui.button('save list as file') then
    local file = io.open(filePathFull, "w")
    for _, point in pairs(dummyPoints) do
      file:write(point .. '\n')
    end
    file:close()
    listSaveTick = os.clock()
  end

  if listSaveTick~= nil and listSaveTick + showSavedTextDelayInSecs > os.clock() then
    ui.sameLine()
    ui.text(filePathFull .. ' saved')
  end
end

function script.pointEditorSettings(dt)
  ui.text('settings window')
end

function _trim(string)
  return string:match'^%s*(.*%S)' or ''
end