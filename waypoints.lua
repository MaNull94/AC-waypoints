local onlineExtras = ac.INIConfig.onlineExtras()
local trackName = ac.getTrackName()
ac.debug("trackName", trackName)
local prefix = 'POINT_'
local numberLength = 4 -- 000_ 001_ и т.д.

local lastPointNumber = -1
local lastPointName = 'name'
local pointIndex = 0
-- local skip = false
local teleports = {}
for _, parameterName in onlineExtras:iterateValues('TELEPORT_DESTINATIONS', 'POINT') do

  local withoutPrefix = parameterName:sub(#prefix + 1, #parameterName)
  -- ac.debug(withoutPrefix)


  -- TODO убрать хардкод и брать подстроку от '_'
  local pointNumber = withoutPrefix:sub(1, 3)
  -- ac.debug("number", pointNumber)
  local parameter = withoutPrefix:sub(numberLength + 1, #withoutPrefix)
  -- ac.log("p -> " .. parameter)

  -- если читаем новую точку
  local value = onlineExtras:get('TELEPORT_DESTINATIONS', parameterName, nil)
  if parameter == '' and value ~= nil then
    if tonumber(pointNumber) > lastPointNumber then
      local pointTrackName = onlineExtras:get('TELEPORT_DESTINATIONS', prefix..pointNumber..'_GROUP')[1]
      if pointTrackName == trackName then
        teleports[value[1]] = pointIndex
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





    for pointName, pointIndex in pairs(teleports) do
      if ui.button(pointName) then
        ac.teleportToServerPoint(pointIndex)
      end
      ui.sameLine()
    end
    ui.invisibleButton()


  -- ui.invisibleButton()
    -- ui.button("1.1"); ui.sameLine() 
    -- ui.button("1.2")
    
    -- ui.button("2.2"); ui.sameLine()
    -- ui.button("2.3")


  

  
  -- if ui.button('tp') then
  --   -- physics.setCarPosition(carIndex: integer, pos: vec3, dir: vec3)
  --   -- physics.setCarPosition(0, vec3(208.1,-1.1,-5.6), vec3(0.0, 0.0, 0.0))
  --   physics.setCarPosition(0, vec3(208.1,-1.1,-5.6), vec3(0.0, 0.0, 0.0))
  -- end

end