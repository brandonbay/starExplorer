
local composer = require('composer')
local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via 'composer.removeScene()'
-- ----------------------------------------------------------------------------------

local musicTrack

local json = require('json')
local settings = composer.getVariable('settings')
local filePath = composer.getVariable('filePath')
local sheetOptions = composer.getVariable('sheetOptions')
local objectSheet = graphics.newImageSheet( 'gameObjects.png', sheetOptions )
local physics = require('physics')
local firstShip, secondShip, thirdShip
local shipHighlight
local mainGroup
physics.start()
physics.setGravity(0,0)

local function gotoMenu()
  composer.gotoScene('menu', { time=800, effect='crossFade' })
end

local function saveSettings()
  local file = io.open(filePath, 'w')

  if file then
    file:write(json.encode(composer.getVariable('settings')))
    io.close(file)
  end
end

local function handleKeypress(event)
	if (event.phase == 'up' and event.keyName == 'back') then
		gotoMenu()
		return true
	end
end

local function createAsteroids()
	local firstAsteroid = display.newImageRect(
		mainGroup,
		objectSheet,
		1,
		sheetOptions.frames[1].width,
		sheetOptions.frames[1].height
	)

  firstAsteroid.x = display.contentCenterX - 150
  firstAsteroid.y = 90
  local firstAsteroidPoints = display.newText(mainGroup, '50pts', display.contentCenterX - 150, 160, native.systemFont, 28)
  firstAsteroidPoints:setFillColor(0.75, 0.78, 1)
  physics.addBody(firstAsteroid, 'dynamic', { radius=40, bounce=0.8 })
	firstAsteroid:applyTorque(math.random(2,2))

  local secondAsteroid = display.newImageRect(
		mainGroup,
		objectSheet,
		2,
		sheetOptions.frames[2].width,
		sheetOptions.frames[2].height
	)

  secondAsteroid.x = display.contentCenterX
  secondAsteroid.y = 90
  local secondAsteroidPoints = display.newText(mainGroup, '100pts', display.contentCenterX, 160, native.systemFont, 28)
  secondAsteroidPoints:setFillColor(0.75, 0.78, 1)
  physics.addBody(secondAsteroid, 'dynamic', { radius=40, bounce=0.8 })
  secondAsteroid:applyTorque(math.random(-3,-3))

  local thirdAsteroid = display.newImageRect(
		mainGroup,
		objectSheet,
		3,
		sheetOptions.frames[3].width,
		sheetOptions.frames[3].height
	)

  thirdAsteroid.x = display.contentCenterX + 150
  thirdAsteroid.y = 90
  local thirdAsteroidPoints = display.newText(mainGroup, '500pts', display.contentCenterX + 150, 160, native.systemFont, 28)
  thirdAsteroidPoints:setFillColor(0.75, 0.78, 1)
  physics.addBody(thirdAsteroid, 'dynamic', { radius=40, bounce=0.8 })
	thirdAsteroid:applyTorque(math.random(4,4))
end

local function displayShipChoice()
  local firstShipOptions = sheetOptions.frames[4]
	firstShip = display.newImageRect(
		mainGroup,
		objectSheet,
		4,
		firstShipOptions.width,
		firstShipOptions.height
	)

  firstShip.x = display.contentCenterX
  firstShip.y = 260
  firstShip.shipType = 4
  local firstShipEngine = display.newText(mainGroup, 'Engine: Average', display.contentCenterX, 330, native.systemFont, 28)
  local firstShipWeapon = display.newText(mainGroup, 'Weapon: Average', display.contentCenterX, 360, native.systemFont, 28)
  firstShipEngine:setFillColor(0.75, 0.78, 1)
  firstShipWeapon:setFillColor(0.75, 0.78, 1)

  local secondShipOptions = sheetOptions.frames[5]
	secondShip = display.newImageRect(
		mainGroup,
		objectSheet,
		5,
		secondShipOptions.width,
		secondShipOptions.height
	)

  secondShip.x = display.contentCenterX
  secondShip.y = 460
  secondShip.shipType = 5
  local secondShipEngine = display.newText(mainGroup, 'Engine: Fast', display.contentCenterX, 530, native.systemFont, 28)
  local secondShipWeapon = display.newText(mainGroup, 'Weapon: Slow', display.contentCenterX, 560, native.systemFont, 28)
  secondShipEngine:setFillColor(0.75, 0.78, 1)
  secondShipWeapon:setFillColor(0.75, 0.78, 1)

  local thirdShipOptions = sheetOptions.frames[6]
	thirdShip = display.newImageRect(
		mainGroup,
		objectSheet,
		6,
		thirdShipOptions.width,
		thirdShipOptions.height
	)

  thirdShip.x = display.contentCenterX
  thirdShip.y = 660
  thirdShip.shipType = 6
  local thirdShipEngine = display.newText(mainGroup, 'Engine: Slow', display.contentCenterX, 730, native.systemFont, 28)
  local thirdShipWeapon = display.newText(mainGroup, 'Weapon: Fast', display.contentCenterX, 760, native.systemFont, 28)
  thirdShipEngine:setFillColor(0.75, 0.78, 1)
  thirdShipWeapon:setFillColor(0.75, 0.78, 1)
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

	local background = display.newImageRect(mainGroup, 'background.png', 800, 1400)
	background.x = display.contentCenterX
	background.y = display.contentCenterY

	local menuButton = display.newText(mainGroup, 'Menu', display.contentCenterX, 960, native.systemFont, 44)
  menuButton:setFillColor(0.75, 0.78, 1)
  menuButton:addEventListener('tap', gotoMenu)

  createAsteroids()
  displayShipChoice()
  firstShip:addEventListener('tap', selectShip)
  secondShip:addEventListener('tap', selectShip)
  thirdShip:addEventListener('tap', selectShip)

  shipHighlight = display.newCircle(mainGroup, display.contentCenterX, (settings.shipType - 3) * 200 + 60, 60)
  shipHighlight:setFillColor(0.25, 0.70, 0.16, 0.15)

	musicTrack = audio.loadStream('audio/Midnight-Crawlers_Looping.wav')
end

-- show()
function scene:show(event)
	local sceneGroup = self.view
	local phase = event.phase

	if (phase == 'will') then
		-- Code here runs when the scene is still off screen (but is about to come on screen)
	elseif (phase == 'did') then
		-- Code here runs when the scene is entirely on screen
    physics.start()
		Runtime:addEventListener('key', handleKeypress)
		audio.play(musicTrack, { channel=1, loops=-1 })
	end
end

-- hide()
function scene:hide(event)
	local sceneGroup = self.view
	local phase = event.phase

	if (phase == 'will') then
		-- Code here runs when the scene is on screen (but is about to go off screen)
	elseif (phase == 'did') then
		-- Code here runs immediately after the scene goes entirely off screen
    physics.pause()
		Runtime:removeEventListener('key', handleKeypress)
		audio.stop(1)
    saveSettings()
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
