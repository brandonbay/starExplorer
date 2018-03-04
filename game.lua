
local composer = require('composer')
local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via 'composer.removeScene()'
-- -----------------------------------------------------------------------------------

-- returns the degrees between (0,0) and pt (note: 0 degrees is 'east')
math.angleOf = function(point)
   local x, y = point.x, point.y
   local angle = math.atan2(y,x)*180/math.pi
   if angle < 0 then angle = 360 + angle end
   return angle
end

-- returns the degrees between two points (note: 0 degrees is 'east')
math.angleBetween = function(point1, point2)
   local x, y = point2.x - point1.x, point2.y - point1.y
   return math.angleOf( { x=x, y=y } )
end

local physics = require('physics')
physics.start()
physics.setGravity(0,0)
local settings = composer.getVariable('settings')
local sheetOptions = composer.getVariable('sheetOptions')
local objectSheet = graphics.newImageSheet( 'gameObjects.png', sheetOptions )

local lives = 3
local score = 0
local died = false

local asteroidsTable = {}

local ship
local shipVelocityX, shipVelocityY  = 0, 0
local laserVelocityX, laserVelocityY  = 0, -10
local gameLoopTimer
local livesText
local scoreText

local backGroup
local mainGroup
local uiGroup

local explosionSound
local fireSound
local musicTrack

local function updateText()
	livesText.text = 'Lives: ' .. lives
	scoreText.text = 'Score: ' .. score
end

local function createAsteroid()
	local asteroidType = math.random(12)
	if (asteroidType < 8) then
		asteroidType = 1
	elseif (asteroidType < 12) then
		asteroidType = 2
	elseif (asteroidType == 12) then
		asteroidType = 3
	end

	local newAsteroid = display.newImageRect(
		mainGroup,
		objectSheet,
		asteroidType,
		sheetOptions.frames[asteroidType].width,
		sheetOptions.frames[asteroidType].height
	)
	table.insert(asteroidsTable, newAsteroid)
	physics.addBody(newAsteroid, 'dynamic', { radius=40, bounce=0.8 })
	newAsteroid.myName = 'asteroid'
	newAsteroid.points = sheetOptions.frames[asteroidType].points

	local whereFrom = math.random(3)

	if (whereFrom == 1) then
		-- From the left
		newAsteroid.x = -60
		newAsteroid.y = math.random(500)
		newAsteroid:setLinearVelocity(math.random(40,120), math.random(20,60))
	elseif (whereFrom == 2) then
		-- From the top
		newAsteroid.x = math.random(display.contentWidth)
		newAsteroid.y = -60
		newAsteroid:setLinearVelocity(math.random(-40,40), math.random(40,120))
	elseif (whereFrom == 3) then
		-- From the right
		newAsteroid.x = display.contentWidth + 60
		newAsteroid.y = math.random(500)
		newAsteroid:setLinearVelocity(math.random(-120,-40), math.random(20,60))
	end

	newAsteroid:applyTorque(math.random(-6,6))
end

local function fireLaser()
	if (died == false) then
		audio.play(fireSound)

		local newLaser = display.newImageRect(mainGroup, objectSheet, 7, 14, 40)
		physics.addBody( newLaser, 'dynamic', { isSensor=true } )
		newLaser.isBullet = true
		newLaser.myName = 'laser'

		newLaser.x = ship.x
		newLaser.y = ship.y
		newLaser.rotation = ship.rotation
		newLaser:toBack()

		newLaser:setLinearVelocity(ship.laserSpeed * laserVelocityX, ship.laserSpeed * laserVelocityY)

		timer.performWithDelay( 500, function() display.remove(newLaser) end)
	end
end

local function checkShipInBounds()
	if (died == false) then
		if ((shipVelocityX > 0 and ship.x >= (display.contentWidth - 140)) or
			(shipVelocityX < 0 and ship.x <= 140)) then
			shipVelocityX = 0
		end
		if ((shipVelocityY > 0 and ship.y >= (display.contentHeight - 40)) or
			(shipVelocityY < 0 and ship.y <= 40)) then
			shipVelocityY = 0
		end
	end
	return true
end

local function dragShip(event)
		local phase = event.phase
		local xDistance, yDistance

		if (died == true) then
			return true
		end

		if (phase == 'began') then
			display.currentStage:setFocus(ship)
		end

		if (phase == 'began' or phase == 'moved') then
			xDistance, yDistance = event.x - ship.x, event.y - ship.y
			if (math.abs(xDistance) >= 80 or math.abs(yDistance) >= 80) then
				ship.rotation = math.angleBetween(ship, event) + 90
				local shipAngle = math.atan2(yDistance, xDistance)
				shipVelocityX, shipVelocityY = math.cos(shipAngle), math.sin(shipAngle)
				laserVelocityX, laserVelocityY = shipVelocityX, shipVelocityY
			end
		end

		if (phase == 'ended' or phase == 'cancelled') then
			display.currentStage:setFocus(nil)
			shipVelocityX, shipVelocityY = 0, 0
		end

		checkShipInBounds()
		ship:setLinearVelocity(ship.shipSpeed * shipVelocityX, ship.shipSpeed * shipVelocityY)

		return true
end

local function endGame()
	composer.setVariable('finalScore', score)
	composer.gotoScene('highscores', { time=800, effect='crossFade' })
end

local function handleKeypress(event)
	if (event.phase == 'up' and event.keyName == 'back') then
		endGame()
		return true
	elseif (event.phase == 'up' and event.keyName == 'space') then
		if (died == false) then
			fireLaser()
		end
		return true
	elseif (event.phase == 'down') then
		if (event.keyName == 'left') then
			shipVelocityX = shipVelocityX - ship.shipSpeed
		elseif (event.keyName == 'right') then
			shipVelocityX = shipVelocityX + ship.shipSpeed
		elseif (event.keyName == 'up') then
			shipVelocityY = shipVelocityY - ship.shipSpeed
		elseif (event.keyName == 'down') then
			shipVelocityY = shipVelocityY + ship.shipSpeed
		end
	elseif (event.phase == 'up') then
		if (event.keyName == 'left' and shipVelocityX < 0) then
			shipVelocityX = shipVelocityX + ship.shipSpeed
		elseif (event.keyName == 'right' and shipVelocityX > 0) then
			shipVelocityX = shipVelocityX - ship.shipSpeed
		elseif (event.keyName == 'up' and shipVelocityY < 0) then
			shipVelocityY = shipVelocityY + ship.shipSpeed
		elseif (event.keyName == 'down' and shipVelocityY > 0) then
			shipVelocityY = shipVelocityY - ship.shipSpeed
		end
	end
	if (died == false) then
		checkShipInBounds()
		ship:setLinearVelocity(shipVelocityX, shipVelocityY)
	end
	return true
end

local function restoreShip()
	ship.isBodyActive = false
	ship.x = display.contentCenterX
	ship.y = display.contentHeight - 100

	shipVelocityX, shipVelocityY = 0, 0
	laserVelocityX, laserVelocityY = 0, -10
	ship.rotation = 0
	ship:setLinearVelocity(shipVelocityX, shipVelocityY)

	transition.to(ship, {alpha=1, time=4000,
		onComplete=function()
			ship.isBodyActive = true
			died = false
		end
	})
end

local function onCollision(event)
	if (event.phase == 'began') then
		local obj1 = event.object1
		local obj2 = event.object2

		if (
			(obj1.myName == 'laser' and obj2.myName == 'asteroid') or
			(obj1.myName == 'asteroid' and obj2.myName == 'laser')
		) then
			display.remove(obj1)
			display.remove(obj2)
			audio.play(explosionSound)

			local asteroid = obj1.myName == 'asteroid' and obj1 or obj2

			score = score + asteroid.points
			scoreText.text = 'Score: ' .. score

			for i = #asteroidsTable, 1, -1 do
				if (asteroidsTable[i] == obj1 or asteroidsTable[i] == obj2) then
					table.remove(asteroidsTable, i)
				end
			end
		elseif (
			(obj1.myName == 'ship' and obj2.myName == 'asteroid') or
			(obj1.myName == 'asteroid' and obj2.myName == 'ship')
		) then
			if (died == false) then
				died = true
				audio.play(explosionSound)

				lives = lives - 1
				livesText.text = 'Lives: ' .. lives

				if (lives == 0) then
					display.remove(ship)
					timer.performWithDelay(2000, endGame)
				else
					ship.alpha = 0
					timer.performWithDelay(1000, restoreShip)
				end
			end
		end
	end
end

local function gameLoop()
	createAsteroid()
	for i = #asteroidsTable, 1, -1 do
		local thisAsteroid = asteroidsTable[i]
		if (thisAsteroid.x < -100 or
			thisAsteroid.x > display.contentWidth + 100 or
			thisAsteroid.y < -100 or
			thisAsteroid.y > display.contentHeight + 100)
		then
			display.remove(thisAsteroid)
			table.remove(asteroidsTable, i)
		end
	end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create(event)
	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	physics.pause()

	backGroup = display.newGroup()
	sceneGroup:insert(backGroup)

	mainGroup = display.newGroup()
	sceneGroup:insert(mainGroup)

	uiGroup = display.newGroup()
	sceneGroup:insert(uiGroup)

	local background = display.newImageRect(backGroup, 'background.png', 800, 1400)
	background.x = display.contentCenterX
	background.y = display.contentCenterY

	local shipType = settings and settings.shipType or 4
	local shipOptions = sheetOptions.frames[shipType]
	ship = display.newImageRect(mainGroup, objectSheet, shipType, shipOptions.width, shipOptions.height)
	ship.x = display.contentCenterX
	ship.y = display.contentHeight - 100
	physics.addBody (ship, {radius=30, isSensor=true})
	ship.myName = 'ship'
	ship.shipSpeed = shipOptions.shipSpeed
	ship.laserSpeed = shipOptions.laserSpeed

	livesText = display.newText(uiGroup, 'Lives: ' .. lives, 200, 80, native.systemFont, 36)
	scoreText = display.newText(uiGroup, 'Score: ' .. score, 400, 80, native.systemFont, 36)

	ship:addEventListener('tap', fireLaser)

	explosionSound = audio.loadSound('audio/explosion.wav')
	fireSound = audio.loadSound('audio/fire.wav')
	musicTrack = audio.loadStream('audio/80s-Space-Game_Looping.wav')
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
		Runtime:addEventListener('collision', onCollision)
		Runtime:addEventListener('touch', dragShip)
		Runtime:addEventListener('enterFrame', checkShipInBounds)
		gameLoopTimer = timer.performWithDelay(750, gameLoop, 0)
		audio.setVolume(0.25, { channel=1 })
		audio.play(musicTrack, { channel=1, loops=-1 })
	end
end

-- hide()
function scene:hide(event)
	local sceneGroup = self.view
	local phase = event.phase

	if (phase == 'will') then
		-- Code here runs when the scene is on screen (but is about to go off screen)
		timer.cancel(gameLoopTimer)
	elseif (phase == 'did') then
		-- Code here runs immediately after the scene goes entirely off screen
		Runtime:removeEventListener('collision', onCollision)
		Runtime:removeEventListener('key', handleKeypress)
		Runtime:removeEventListener('touch', dragShip)
		Runtime:removeEventListener('enterFrame', checkShipInBounds)
		physics.pause()
		audio.stop(1)
		audio.setVolume(0.5, { channel=1 })
		composer.removeScene('game')
	end
end

-- destroy()
function scene:destroy(event)
	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view
		audio.dispose(explosionSound)
    audio.dispose(fireSound)
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
