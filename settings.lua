
local composer = require('composer')
local json = require('json')
local physics = require('physics')
local scene = composer.newScene()

local filePath = composer.getVariable('filePath')
local mainGroup
local musicTrack
local settings = composer.getVariable('settings')
local sheetOptions = composer.getVariable('sheetOptions')
local objectSheet = graphics.newImageSheet('gameObjects.png', sheetOptions)

local firstShip, secondShip, thirdShip
local shipHighlight

physics.start()
physics.setGravity(0,0)

local function gotoMenu()
  composer.gotoScene('menu', { time=800, effect='crossFade' })
end

local function handleKeypress(event)
	if event.phase == 'up' and event.keyName == 'back' then
		gotoMenu()
		return true
	end
end

local function saveSettings()
  local file = io.open(filePath, 'w')

  if file then
    file:write(json.encode(composer.getVariable('settings')))
    io.close(file)
  end
end

local function createAsteroid(index, offset, points, spin)
  local asteroid = display.newImageRect(
		mainGroup,
		objectSheet,
		index,
		sheetOptions.frames[index].width,
		sheetOptions.frames[index].height
	)
  asteroid.x = display.contentCenterX + offset
  asteroid.y = 90
  local asteroidPoints = display.newText(
    mainGroup,
    points .. 'pts',
    display.contentCenterX + offset,
    160,
    native.systemFont,
    28
  )
  asteroidPoints:setFillColor(0.75, 0.78, 1)
  physics.addBody(asteroid, 'dynamic', { radius=40, bounce=0.8 })
	asteroid:applyTorque(math.random(spin,spin))
  return asteroid
end

local function createAsteroids()
	local firstAsteroid = createAsteroid(1, -150, 50, 2)
  local secondAsteroid = createAsteroid(2, 0, 100, -3)
  local secondAsteroid = createAsteroid(3, 150, 500, 4)
end

local function displayShipOption(index, engine, weapon)
  local offset = 200*(index-3)
  local shipOptions = sheetOptions.frames[index]
	local shipPreview = display.newImageRect(
		mainGroup,
		objectSheet,
		index,
		shipOptions.width,
		shipOptions.height
	)

  shipPreview.x = display.contentCenterX
  shipPreview.y = 60 + offset
  shipPreview.shipType = index
  local shipEngine = display.newText(
    mainGroup, 'Engine: ' .. engine,
    display.contentCenterX,
    130 + offset,
    native.systemFont,
    28
  )
  local shipWeapon = display.newText(
    mainGroup,
    'Weapon: ' .. weapon,
    display.contentCenterX,
    160 + offset,
    native.systemFont,
    28
  )
  shipEngine:setFillColor(0.75, 0.78, 1)
  shipWeapon:setFillColor(0.75, 0.78, 1)
  return shipPreview
end

local function selectShip(event)
  settings.shipType = event.target.shipType
  display.remove(shipHighlight)
  shipHighlight = display.newCircle(mainGroup, display.contentCenterX, (settings.shipType - 3) * 200 + 60, 60)
  shipHighlight:setFillColor(0.25, 0.70, 0.16, 0.15)
  composer.setVariable('settings', settings)
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create(event)
	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

  mainGroup = display.newGroup()
	sceneGroup:insert(mainGroup)
  physics.pause()
	musicTrack = audio.loadStream('audio/Midnight-Crawlers_Looping.wav')

	local background = display.newImageRect(mainGroup, 'background.png', 800, 1400)
	background.x, background.y = display.contentCenterX, display.contentCenterY

	local menuButton = display.newText(mainGroup, 'Menu', display.contentCenterX, 960, native.systemFont, 44)
  menuButton:setFillColor(0.75, 0.78, 1)
  menuButton:addEventListener('tap', gotoMenu)

  createAsteroids()
  firstShip = displayShipOption(4, 'Average', 'Average')
  firstShip:addEventListener('tap', selectShip)
	secondShip = displayShipOption(5, 'Fast', 'Slow')
  secondShip:addEventListener('tap', selectShip)
  thirdShip = displayShipOption(6, 'Slow', 'Fast')
  thirdShip:addEventListener('tap', selectShip)
  shipHighlight = display.newCircle(mainGroup, display.contentCenterX, (settings.shipType - 3) * 200 + 60, 60)
  shipHighlight:setFillColor(0.25, 0.70, 0.16, 0.15)
end

-- show()
function scene:show(event)
	local sceneGroup = self.view
	local phase = event.phase

	if phase == 'will' then
		-- Code here runs when the scene is still off screen (but is about to come on screen)
	elseif phase == 'did' then
		-- Code here runs when the scene is entirely on screen
    physics.start()
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
    physics.pause()
		audio.stop(1)
    saveSettings()
		Runtime:removeEventListener('key', handleKeypress)
		composer.removeScene('settings')
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
