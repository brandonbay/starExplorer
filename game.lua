
local composer = require('composer')
local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via 'composer.removeScene()'
-- -----------------------------------------------------------------------------------

local physics = require('physics')
physics.start()
physics.setGravity(0,0)

local sheetOptions = {
	frames = {
		{ -- [1] asteroid 1
			x = 0,
			y = 0,
			width = 102,
			height = 85
		},
		{ -- [2] asteroid 2
			x = 0,
			y = 85,
			width = 90,
			height = 83
		},
		{ -- [3] asteroid 3
			x = 0,
			y = 168,
			width = 100,
			height = 97
		},
		{ -- [4] ship
			x = 0,
			y = 265,
			width = 98,
			height = 79
		},
		{ -- [5] laser
			x = 98,
			y = 265,
			width = 14,
			height = 40
		}
	}
}

local objectSheet = graphics.newImageSheet( 'gameObjects.png', sheetOptions )

local lives = 3
local score = 0
local died = false

local asteroidsTable = {}

local ship
local shipVelocityX = 0
local shipVelocityY = 0
local shipSpeed = 300
local gameLoopTimer
local livesText
local scoreText

local backGroup
local mainGroup
local uiGroup

local function updateText()
	livesText.text = 'Lives: ' .. lives
	scoreText.text = 'Score: ' .. score
end

local function createAsteroid()
	local asteroidType = math.random(3)
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

	local whereFrom = math.random(3)

	if ( whereFrom == 1 ) then
		-- From the left
		newAsteroid.x = -60
		newAsteroid.y = math.random(500)
		newAsteroid:setLinearVelocity(math.random(40,120), math.random(20,60))
	elseif ( whereFrom == 2 ) then
			-- From the top
			newAsteroid.x = math.random(display.contentWidth)
			newAsteroid.y = -60
			newAsteroid:setLinearVelocity(math.random(-40,40), math.random(40,120))
	elseif ( whereFrom == 3 ) then
			-- From the right
			newAsteroid.x = display.contentWidth + 60
			newAsteroid.y = math.random(500)
			newAsteroid:setLinearVelocity(math.random(-120,-40), math.random(20,60))
	end

	newAsteroid:applyTorque( math.random(-6,6) )
end

local function fireLaser()
		local newLaser = display.newImageRect(mainGroup, objectSheet, 5, 14, 40)
		physics.addBody( newLaser, 'dynamic', { isSensor=true } )
		newLaser.isBullet = true
		newLaser.myName = 'laser'

		newLaser.x = ship.x
		newLaser.y = ship.y
		newLaser:toBack()

		transition.to(newLaser, { y=-40, time=500,
			onComplete = function() display.remove(newLaser) end
		})
end

local function dragShip(event)
		local ship = event.target
		local phase = event.phase

		if (phase == 'began') then
			display.currentStage:setFocus(ship)
			ship.touchOffsetX = event.x - ship.x
			ship.touchOffsetY = event.y - ship.y
		elseif (phase == 'moved') then
			ship.x = event.x - ship.touchOffsetX
			ship.y = event.y - ship.touchOffsetY
		elseif (phase == 'ended' or phase == 'cancelled') then
			display.currentStage:setFocus(nil)
		end

		return true
end

local function endGame()
	composer.gotoScene('menu', { time=800, effect='crossFade' })
end

local function keyControlShip(event)
	if (event.phase == 'up' and event.keyName == 'back') then
		endGame()
		return true
	elseif (event.phase == 'up' and event.keyName == 'space') then
		fireLaser()
		return true
	elseif (event.phase == 'down') then
		if (event.keyName == 'left') then
			shipVelocityX = shipVelocityX - shipSpeed
		elseif (event.keyName == 'right') then
			shipVelocityX = shipVelocityX + shipSpeed
		elseif (event.keyName == 'up') then
			shipVelocityY = shipVelocityY - shipSpeed
		elseif (event.keyName == 'down') then
			shipVelocityY = shipVelocityY + shipSpeed
		end
	elseif (event.phase == 'up') then
		if (event.keyName == 'left') then
			shipVelocityX = shipVelocityX + shipSpeed
		elseif (event.keyName == 'right') then
			shipVelocityX = shipVelocityX - shipSpeed
		elseif (event.keyName == 'up') then
			shipVelocityY = shipVelocityY + shipSpeed
		elseif (event.keyName == 'down') then
			shipVelocityY = shipVelocityY - shipSpeed
		end
	end
	ship:setLinearVelocity(shipVelocityX, shipVelocityY)
	return true
end

local function restoreShip()
	ship.isBodyActive = false
	ship.x = display.contentCenterX
	ship.y = display.contentHeight - 100

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
			score = score + 100
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

	ship = display.newImageRect(mainGroup, objectSheet, 4, 98, 79)
	ship.x = display.contentCenterX
	ship.y = display.contentHeight - 100
	physics.addBody (ship, {radius=30, isSensor=true})
	ship.myName = 'ship'

	livesText = display.newText(uiGroup, 'Lives: ' .. lives, 200, 80, native.systemFont, 36)
	scoreText = display.newText(uiGroup, 'Score: ' .. score, 400, 80, native.systemFont, 36)

	ship:addEventListener('tap', fireLaser)
	ship:addEventListener('touch', dragShip)
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
		Runtime:addEventListener('key', keyControlShip)
		Runtime:addEventListener('collision', onCollision)
		gameLoopTimer = timer.performWithDelay(750, gameLoop, 0)
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
		Runtime:removeEventListener('key', keyControlShip)
		physics.pause()
		composer.removeScene('game')
	end
end

-- destroy()
function scene:destroy(event)
	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view
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
