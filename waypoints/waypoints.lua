local FILE_PATH = 'apps\\lua\\waypoints\\results'
local SHOW_SAVED_TEXT_DELAY_IN_SECS = 5

local TRACK_NAME = ac.getTrackName()
local PREFIX = 'POINT_'

local reloadPointsButtonClicked = false

local lastPointNumber = -1
local pointOrderIndex = 0
local currentTrackTeleportsFull = {} -- телепорты из конфига и из редактора
local cTTFullSize = 0
-- телепорты ТОЛЬКО из конфига
--для телепортов. КЭП. короче чтобы не было лишних тп,
--которые по факту есть только в редакторе, но не на сервере
local currentTrackTeleportConfig = {}
local cTTConfigSize = 0

local otherTrackTeleports = {} -- остальные точки телепорта из конфига
local oTTSize = 0

function loadPointsFromServerConfig()
  --ac.log('loadFrom server start')
  lastPointNumber = -1
  pointOrderIndex = 0
  currentTrackTeleportsFull = {}
  cTTFullSize = 0
  currentTrackTeleportConfig = {}
  cTTConfigSize = 0
  otherTrackTeleports = {}
  oTTSize = 0
  local onlineExtras = ac.INIConfig.onlineExtras()
  for _, parameterName in onlineExtras:iterateValues('TELEPORT_DESTINATIONS', 'POINT') do

    local withoutPrefix = parameterName:sub(#PREFIX + 1, #parameterName)
    --ac.debug(withoutPrefix)

    local numberLength = withoutPrefix:find('_')
    if numberLength == nil then
      numberLength = #withoutPrefix
    else
      numberLength = numberLength - 1
    end

    local pointNumber = withoutPrefix:sub(1, numberLength)
    --ac.debug("number", pointNumber)
    local parameter = withoutPrefix:sub(numberLength + 2) -- +2 потому что 100_ это 4 + 2 = стартовая позиция откуда берется имя параметра
    -- ac.log("p -> " .. parameter)

    local value = onlineExtras:get('TELEPORT_DESTINATIONS', parameterName, nil)
    -- если читаем новую точку
    if parameter == '' and value ~= nil and tonumber(pointNumber) ~= lastPointNumber then
      local teleportData = {}
      local teleport = {}
      -- todo по сути номер точки сохранять не обязательно
      teleport['pointNumber'] = tonumber(pointNumber)
      teleport['name'] = value[1]
      local pointTrackName = onlineExtras:get('TELEPORT_DESTINATIONS', PREFIX ..pointNumber..'_GROUP')[1]
      teleport['group'] = pointTrackName
      local pos = onlineExtras:get('TELEPORT_DESTINATIONS', PREFIX ..pointNumber..'_POS', vec3())

      teleport['pos'] = pos
      teleport['heading'] = onlineExtras:get('TELEPORT_DESTINATIONS', PREFIX ..pointNumber..'_HEADING')[1]
      teleportData['pointOrderIndex'] = pointOrderIndex
      teleportData['teleport'] = teleport
      if pointTrackName == TRACK_NAME then
        cTTFullSize = cTTFullSize + 1
        currentTrackTeleportsFull[cTTFullSize] = teleportData

        cTTConfigSize = cTTConfigSize + 1
        currentTrackTeleportConfig[cTTConfigSize] = teleportData

      else
        oTTSize = oTTSize + 1
        otherTrackTeleports[oTTSize] = teleportData
      end

      lastPointNumber = tonumber(pointNumber)
      pointOrderIndex = pointOrderIndex + 1
    end
  end
  reloadPointsButtonClicked = false
end

--загружаем точки из конфига
loadPointsFromServerConfig()


local POINTS_PER_LINE = 3 -- количество кнопок телепорта на одной строке
function script.windowMain(dt)
  --ac.log('main window')
  ui.text(TRACK_NAME .. ' teleports:\n')
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




  --ac.debug("current track teleport count", #currentTrackTeleports)
  -- ipairs для вывода точек по порядку
    for i, tpData in ipairs(currentTrackTeleportConfig) do
      --ac.log('tpData>' .. tpData)
      if ui.button(tpData['teleport']['name']) then
        ac.teleportToServerPoint(tpData['pointOrderIndex'])
      end
      if math.fmod(i, POINTS_PER_LINE) ~= 0 then
        ui.sameLine()
      end
    end
    ui.invisibleButton()

  -- if ui.button('tp') then
     -- physics.setCarPosition(carIndex: integer, pos: vec3, dir: vec3)
     -- physics.setCarPosition(0, vec3(208.1,-1.1,-5.6), vec3(0.0, 0.0, 0.0))
     -- physics.setCarPosition(0, vec3(208.1,-1.1,-5.6), vec3(0.0, 0.0, 0.0))
  -- end
  ac.debug('date', os.date("%Y%m%d_%H%M"))
end


local selectedPointIndex = 0
local pointEditedName -- edit point
local newPointName -- add point
local editPanelActive
local addAfter
local deletePanelActive
local addPanelActive

local addIndex

function script.pointEditor(dt)
  local windowID = ui.getLastID()
  --local windowPos = ui.windowPos()


  if reloadPointsButtonClicked then
    ac.log('reload points')
    loadPointsFromServerConfig()
  end

  local savedPointsFilename = os.date("%Y%m%d_%H%M")
  local filePathFull = string.format("%s\\%s.txt", FILE_PATH, savedPointsFilename)

  if listSaveTick~= nil and listSaveTick + SHOW_SAVED_TEXT_DELAY_IN_SECS > os.clock() then
    ui.sameLine()
    ui.dwriteText(filePathFull .. ' saved', 16, rgbm(100, 50, 0, 250))
    ui.textDisabled()
  end

  if ui.smallButton('save list as file') then
    local teleportList = {
      currentTrackTeleportsFull,
      otherTrackTeleports
    }
    _saveListToFile(teleportList, filePathFull)
    listSaveTick = os.clock()
  end


  ui.sameLine()
  reloadPointsButtonClicked = ui.smallButton('reload from server')

  ui.separator()
  ui.separator()
  ui.header(TRACK_NAME .. ': Points list')
  ui.separator()
  ui.separator()

  if ui.button('add point') then
    addPanelActive = true
    addAfter = nil
    addIndex = #currentTrackTeleportsFull + 1
  end

  --ui.textDisabled("текст серым шрифтом")

  --ui.modalPopup('MP title', 'MP msg', 'OK text', nil, 'OK icon ID', nil, 2525)
  --ui.modalPrompt('title', 'msg', 'defaultValue', 'okText', 'cancelText', 'okIconID', 'cancelIconID', 222)


  ui.beginChild(windowID, vec2(500, 275), true, ui.WindowFlags['HorizontalScrollbar'])
  for i, teleportData in pairs(currentTrackTeleportsFull) do
    if teleportData == 'deleted' then
      goto continue_pointEditor_for
    end

    local point = teleportData['teleport']['name']
    --ac.debug(i .. " name ->", point)
    --ac.debug(i .. " pos ->", teleportData['teleport']['pos'])
    --ac.debug(i .. " heading ->", teleportData['teleport']['heading'])

    if ui.button(point) then
      selectedPointIndex = i
    end
    local buttonID = ui.getLastID()
    ui.itemPopup(buttonID, ui.MouseButton.Right,
        function()
          _clearState()
          selectedPointIndex = i

          if ui.selectable('edit name') then
            --ac.log(string.format("edit %s click", i))
            editPanelActive = true
            pointEditedName = point
          end

          if ui.selectable('delete') then
            --ac.log(string.format("delete %s click", i))
            deletePanelActive = true
          end

          if ui.selectable('add after') then
            addPanelActive = true
            addAfter = true
            addIndex = selectedPointIndex
          end

          if ui.selectable('add before') then
            addPanelActive = true
            addAfter = false
            addIndex = selectedPointIndex
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
          local tempPoint = currentTrackTeleportsFull[selectedPointIndex - 1]
          currentTrackTeleportsFull[selectedPointIndex - 1] = currentTrackTeleportsFull[selectedPointIndex]
          currentTrackTeleportsFull[selectedPointIndex] = tempPoint
          selectedPointIndex = selectedPointIndex - 1
        end
      end


      ui.sameLine()
      if ui.smallButton('down') then
        if selectedPointIndex < #currentTrackTeleportsFull then
          ac.log('down')
          local tempPoint = currentTrackTeleportsFull[selectedPointIndex + 1]
          currentTrackTeleportsFull[selectedPointIndex + 1] = currentTrackTeleportsFull[selectedPointIndex]
          currentTrackTeleportsFull[selectedPointIndex] = tempPoint
          selectedPointIndex = selectedPointIndex + 1
        end
      end

    end
    :: continue_pointEditor_for ::
  end

  ui.endChild()

  ui.separator()
  ui.separator()
  ui.separator()

  if addPanelActive then
    local addInputText
    if newPointName == nil then
      addInputText = "new point"
    else
      addInputText = newPointName
    end


    _inner(addInputText, addIndex, addAfter)
  end


  if selectedPointIndex > 0 and editPanelActive then
    local inputText
    if pointEditedName == nil then
      inputText = currentTrackTeleportsFull[selectedPointIndex]['teleport']['name']
    else
      inputText = pointEditedName
    end

    ui.dwriteText('name must be unique', 20, rgbm(100, 0, 0, 50))
    pointEditedName = ui.inputText("", inputText)

    ui.sameLine()
    if ui.button('save') then
      pointEditedName = _trim(pointEditedName)
      if pointEditedName ~= '' then
        currentTrackTeleportsFull[selectedPointIndex]['teleport']['name'] = pointEditedName
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
    ui.text('Delete ' .. currentTrackTeleportsFull[selectedPointIndex]['teleport']['name'] .. '?')
    if ui.button('yes') then
      currentTrackTeleportsFull[selectedPointIndex] = 'deleted' -- если указать nil, то обрежется весь список
      deletePanelActive = false
    end

    ui.sameLine()
    if ui.button('no') then
      deletePanelActive = false
    end

  end


end

function script.pointEditorSettings(dt)
  ui.text('settings window')
end

function script.helpWindow(dt)
  ui.copyable('https://github.com/MaNull94/AC-waypoints')
  ui.text('aga')
  ui.hyperlink('aboba')
end

function _inner(inputText, pointIndex, addAfter_)

  ui.dwriteText('name must be unique', 20, rgbm(100, 0, 0, 50))
  newPointName = ui.inputText('', inputText)

  local posInsert
  local insertIndex
  if addAfter_ == nil then
    --ac.log('addAfter is nil')
    posInsert = ''
    insertIndex = pointIndex
  elseif addAfter_ then
    --ac.log('addAfter is true')
    posInsert = ' after'
    insertIndex = pointIndex + 1
  else
    --ac.log('addAfter is false')
    posInsert = ' before'
    insertIndex = pointIndex
  end

  ui.sameLine()
  if ui.button('create' .. posInsert) then
    newPointName = _trim(newPointName)
    if newPointName ~= '' then
      table.insert(currentTrackTeleportsFull, insertIndex, _createPoint(newPointName))
      newPointName = nil
      addPanelActive = false
    end
    --_clearState()
    selectedPointIndex = 0
  end

  ui.sameLine()
  if ui.button('cancel') then
    newPointName = nil
    addPanelActive = false
    --_clearState()
    selectedPointIndex = 0
  end
end

--[[Очистка данных и сокрытие панелей
]]
function _clearState()
  selectedPointIndex = 0
  pointEditedName = nil
  newPointName = nil
  editPanelActive = false
  addAfter = nil
  deletePanelActive = false
  addPanelActive = false
end

function _saveListToFile(list, path)
  local file = io.open(path, "w")
  local tpNumber = 0
  file:write('[TELEPORT_DESTINATIONS]\n')
  for _, tpList in ipairs(list) do
    for _, tpD in ipairs(tpList) do
      if tpD ~= 'deleted' then -- если точку не удалили, сохраняем
        local tp = tpD['teleport']
        ac.log("tp: " .. tp['name'])
        file:write(PREFIX..tpNumber..' = '..tp['name'] .. '\n')
        file:write(PREFIX..tpNumber..'_GROUP = '..tp['group'].. '\n')
        local tpPos = tp['pos']
        local tpPosAsText = string.format("%s,%s,%s", math.round(tpPos.x, 1), math.round(tpPos.y, 1), math.round(tpPos.z, 1) )
        file:write(PREFIX..tpNumber..'_POS = '..tpPosAsText.. '\n')
        file:write(PREFIX..tpNumber..'_HEADING = '..tp['heading'] .. '\n')
        file:write("\n")

        tpNumber = tpNumber + 1
      end
    end
  end
  file:close()
end

function _trim(string)
  return string:match'^%s*(.*%S)' or ''
end

function _createPoint(newPointName_)
  -- copy paste from https://www.racedepartment.com/downloads/comfy-map.52623/
  local x = math.round(ac.getCameraPosition().x,1)
  local y = math.round((ac.getCameraPosition().y - physics.raycastTrack(ac.getCameraPosition(), vec3(0, -1, 0), 20) + 0.5),1)
  local z = math.round(ac.getCameraPosition().z,1)
  local head = math.floor(-ac.getCompassAngle(ac.getCameraForward()))

  --ac.debug('new x', x)
  --ac.debug('new y', y)
  --ac.debug('new z', z)
  --ac.debug('new head', head)

  local point = {}
  point['name'] = newPointName_
  point['group'] = TRACK_NAME
  point['pos'] = vec3(x, y, z)
  point['heading'] = head

  local pointData = {}
  pointData['teleport'] = point
  return pointData
end