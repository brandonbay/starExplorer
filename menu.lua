
local composer = require('composer')
local json = require('json')
local scene = composer.newScene()

local filePath = system.pathForFile('settings.json', system.DocumentsDirectory)
local musicTrack
local settings = {}
local sheetOptions = {
	frames = {
		{ -- [1] asteroid 1
			x = 0,
			y = 0,
			width = 102,
			height = 85,
			points = 50
		},
		{ -- [2] asteroid 2
			x = 0,
			y = 85,
			width = 90,
			height = 83,
			points = 100
		},
		{ -- [3] asteroid 3
			x = 0,
			y = 168,
			width = 100,
			height = 97,
			points = 500
		},
		{ -- [4] ship
			x = 0,
			y = 265,
			width = 98,
			height = 79,
			shipSpeed = 300,
			laserSpeed = 1200,
			laserPeriod = 350
		},
		{ -- [5] ship2
			x = 0,
			y = 344,
			width = 57,
			height = 74,
			shipSpeed = 600,
			laserSpeed = 900,
			laserPeriod = 500
		},
		{ -- [6] ship3
			x = 0,
			y = 421,
			width = 112,
			height = 80,
			shipSpeed = 75,
			laserSpeed = 10000,
			laserPeriod = 200
		},
		{ -- [7] laser
			x = 98,
			y = 265,
			width = 14,
			height = 40
		},
	}
}

local function gotoGame()
    composer.gotoScene('game', { time=800, effect='crossFade' })
end

local function gotoSettings()
    composer.gotoScene('settings', { time=800, effect='crossFade' })
end

local function gotoHighScores()
    composer.gotoScene('highscores', { time=800, effect='crossFade' })
end

local function loadSettings()
	local file = io.open(filePath, 'r')
	if file then
		local contents = file:read('*a')
		io.close(file)
    settings = json.decode(contents)
	end

	if not settings or not settings.highScores or not settings.shipType then
		settings = {}
		settings.shipType = 4
		settings.highScores = {
			{ship = 6, score = 10000},
			{ship = 5, score = 7500},
			{ship = 4, score = 5000},
			{ship = 4, score = 4000},
			{ship = 6, score = 3000},
			{ship = 4, score = 2500},
			{ship = 5, score = 1500},
			{ship = 6, score = 1000},
			{ship = 4, score = 750},
			{ship = 4, score = 500}
		}
	end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create(event)
	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen
  loadSettings()

	composer.setVariable('settings', settings)
  composer.setVariable('filePath', filePath)
	composer.setVariable('sheetOptions', sheetOptions)

	musicTrack = audio.loadStream('audio/Escape_Looping.wav')

	local background = display.newImageRect(sceneGroup, 'background.png', 800, 1400)
	background.x, background.y = display.contentCenterX, display.contentCenterY

	local title = display.newImageRect(sceneGroup, 'title.png', 500, 80)
  title.x, title.y = display.contentCenterX, 200

	local playButton = display.newText(sceneGroup, 'Play', display.contentCenterX, 700, native.systemFont, 44)
  playButton:setFillColor(0.82, 0.86, 1)

	local settingsButton = display.newText(sceneGroup, 'Settings', display.contentCenterX, 780, native.systemFont, 44)
  settingsButton:setFillColor(0.75, 0.78, 1)

  local highScoresButton = display.newText(sceneGroup, 'High Scores', display.contentCenterX, 860, native.systemFont, 44)
  highScoresButton:setFillColor(0.75, 0.78, 1)

	playButton:addEventListener('tap', gotoGame)
  settingsButton:addEventListener('tap', gotoSettings)
  highScoresButton:addEventListener('tap', gotoHighScores)
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
