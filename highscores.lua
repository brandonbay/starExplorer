
local composer = require('composer')
local json = require('json')
local scene = composer.newScene()

local filePath = composer.getVariable('filePath')
local musicTrack
local scoresTable = {}
local settings = composer.getVariable('settings')
local sheetOptions = composer.getVariable('sheetOptions')
local objectSheet = graphics.newImageSheet('gameObjects.png', sheetOptions)

local function gotoMenu()
  composer.gotoScene('menu', { time=800, effect='crossFade' })
end

local function handleKeypress(event)
	if event.phase == 'up' and event.keyName == 'back' then
		gotoMenu()
		return true
	end
end

local function saveScores()
  for i = #scoresTable, 11, -1 do
    table.remove(scoresTable, i)
  end

  local file = io.open(filePath, 'w')

  if file and settings then
		print('saving')
		settings.highScores = scoresTable
    file:write(json.encode(settings))
    io.close(file)
  end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create(event)
	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen
	musicTrack = audio.loadStream('audio/Midnight-Crawlers_Looping.wav')

	scoresTable = settings and settings.highScores or {}
	local finalScore = composer.getVariable('finalScore')
	if finalScore and finalScore > 0 then
		table.insert(scoresTable, {ship = settings.shipType, score = finalScore})
  	composer.setVariable('finalScore', 0)

		local function compare(a, b)
	    return a.score > b.score
	  end
	  table.sort(scoresTable, compare)

		saveScores()
	end

	local background = display.newImageRect(sceneGroup, 'background.png', 800, 1400)
	background.x, background.y = display.contentCenterX, display.contentCenterY

	local highScoresHeader = display.newText(sceneGroup, 'High Scores', display.contentCenterX, 100, native.systemFont, 44)
	for i = 1, 10 do
    if scoresTable[i] then
      local yPos = 150 + (i * 56)

			local shipType = scoresTable[i].ship or 4
			local shipOptions = sheetOptions.frames[shipType]
			local shipIcon = display.newImageRect(
				sceneGroup,
				objectSheet,
				shipType,
				30 / shipOptions.height * shipOptions.width,
				30
			)
			shipIcon.x = display.contentCenterX - 130
		  shipIcon.y = yPos

			local rankNum = display.newText(sceneGroup, i .. ":", display.contentCenterX-50, yPos, native.systemFont, 36)
      rankNum:setFillColor(0.8)
      rankNum.anchorX = 1

      local thisScore = display.newText(sceneGroup, scoresTable[i].score, display.contentCenterX-30, yPos, native.systemFont, 36)
      thisScore.anchorX = 0
    end
  end

	local menuButton = display.newText(sceneGroup, 'Menu', display.contentCenterX, 860, native.systemFont, 44)
  menuButton:setFillColor(0.75, 0.78, 1)
  menuButton:addEventListener('tap', gotoMenu)
end

-- show()
function scene:show(event)
	local sceneGroup = self.view
	local phase = event.phase

	if phase == 'will' then
		-- Code here runs when the scene is still off screen (but is about to come on screen)
	elseif phase == 'did' then
		-- Code here runs when the scene is entirely on screen
		audio.play(musicTrack, { channel=1, loops=-1 })
		Runtime:addEventListener('key', handleKeypress)
	end
end

-- hide()
function scene:hide(event)
	local sceneGroup = self.view
	local phase = event.phase

	if phase == 'will' then
		-- Code here runs when the scene is on screen (but is about to go off screen)
	elseif phase == 'did' then
		-- Code here runs immediately after the scene goes entirely off screen
		audio.stop(1)
		Runtime:removeEventListener('key', handleKeypress)
		composer.removeScene('highscores')
	end
end

-- destroy()
function scene:destroy(event)
	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view
	audio.dispose(musicTrack)
end

-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener('create', scene)
scene:addEventListener('show', scene)
scene:addEventListener('hide', scene)
scene:addEventListener('destroy', scene)
-- -----------------------------------------------------------------------------------

return scene
