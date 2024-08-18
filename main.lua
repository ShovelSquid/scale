-- gonna be making some recursive shi
Platform = {}
function Platform:new(x, y, z, r, player)
    p = {
        x = x,
        y = y,
        z = z,
        r = r,
        color = {
            r = math.random(80, 100)/100,
            g = math.random(0, 40)/100,
            b = math.random(0, 20)/100,
            a = 1,
        },
        player = player,
        depth = 0,
        depth_factor = 0.01,
    }
    setmetatable(p, self)
    self.__index = self
    return p
end

-- function Platform:update()
--     platform:onPlatform(player)
-- end

-- get vector from entity/player to platform
function Platform:getVector(entity)
    vector = {x = 0, y = 0, z = 0}
    vector.x = entity.position.x - self.x
    vector.y = entity.position.y - self.y
    vector.z = entity.position.z - self.z
    self.depth = 1/(1+self.depth_factor*vector.z)
    magnitude = math.sqrt(vector.x^2, vector.y^2, vector.z^2)
    direction = {x = vector.x/magnitude, y = vector.y/magnitude, z = vector.z/magnitude}
    return vector, magnitude, direction
end

-- not platform specific
-- want to have a radius value, and a minimum radius value for a z distance
-- at that z distance, the radius is that minimum
-- everywhere in between, get the in between
-- at z = 0, radius = base
-- at z = distance, radius = min
function z_damp(min, z)
    return -min*math.atan(0.1*z)
end

function Platform:draw()
    if self.z >= player.position.z + player.position.max_z_view_distance then
        return
    end
    vector, magnitude, direction = self:getVector(player)
    love.graphics.push()
    love.graphics.translate(self.x * self.depth, self.y * self.depth)
    love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
    -- love.graphics.circle("fill", player.position.z - self.z * player.position.x, player.position.z - self.z * player.position.y, self.r - (player.position.z - self.z))
    love.graphics.circle("fill", 0, 0, self.r + z_damp(30, vector.z))
    if self:inPlatform(player) then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print("In!", 50, -20)
    end
    love.graphics.pop()
end

function Platform:branch()
    -- get the next recursive things

end

-- check if player (or any other entity) is in the platform if their z is close
function Platform:inPlatform(entity)
    if entity.position.x < self.x + self.r and
       entity.position.x > self.x - self.r and
       entity.position.y < self.y + self.r and
       entity.position.y > self.y - self.r then
        return true
    else
        return false
    end
end

function Platform:onPlatform(entity)
    if self:inPlatform(entity) and entity.position.z <= self.z and entity.position.z > self.z - 5 then
        entity:hitGround(self)
        return true
    end
    return false
end


Player = {}
function Player:new(x, y, z)
    -- need its position
    p = {
        position = {
            x = x,          -- x position
            y = y,          -- y position
            z = z,          -- 0 when on ground; gets lower and lower as time goes on
            onGround = true,
            max_z_view_distance = 120,
        },
        velocity = {
            x = 0,          -- change in x position
            y = 0,          -- change in y position
            z = 0,          -- change in z position
            max_x = 150,
            max_y = 150,
            max_z = 100000000000,
            fall_damage_threshold = 30,
            ground_jump_force = 30,
            air_jump_force = 15,
            ground_jump = true,
            jumps = 1,
            max_jumps = 4,
        },
        acceleration = {
            x = 0,          -- change in x velocity
            y = 0,          -- change in y velocity
            z = 0,          -- change in z velocity
            gravity = -20,  -- change to apply in z velocity
            move = 60,       -- change to apply to velocity
            apply = 1,      -- apply change in acceleration every amt of seconds
            direction = {
                x = 0,
                y = 0,
            },
            drag = {
                x = 0,
                y = 0,
                z = 0,
            },
        },
        health = {
            bars = 3,
            states = {
                healthy = 3,
                injured = 2,
                bloodied = 1,
                dead = 0,
            },
            state = 3,

            -- segments = 8,
            -- units = 6,
            -- total_health = bars*segments*units,
            -- injured = 1*segments*units,

            max_bars = 3,
            -- bar_segments = 8,
            -- segment_unit = 6,
            -- max_health = max_bars*bar_segments*segment_unit,
        },
        input = {
            left = false,
            up = false,
            right = false,
            down = false,
            jump = false,
        },
        color = {
            r = 1,
            g = 0.5,
            b = 0,
            a = 0.75,
        },
    }
    setmetatable(p, self)
    self.__index = self
    return p
end

function Player:draw()
    love.graphics.push()
    love.graphics.translate(self.position.x, self.position.y)
    love.graphics.scale(2)
    love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
    love.graphics.circle("fill", 0, 0, 20)
    love.graphics.pop()
end

function Player:move(dt)
    -- apply change in acceleration and velocities
    self.velocity.x = self.velocity.x + self.acceleration.x * dt
    self.velocity.y = self.velocity.y + self.acceleration.y * dt
    self.velocity.z = self.velocity.z + self.acceleration.z * dt

    self.position.x = self.position.x + self.velocity.x * dt
    self.position.y = self.position.y + self.velocity.y * dt
    self.position.z = self.position.z + self.velocity.z * dt
    self:drag(dt)
end

function Player:setInput(key, value)
    if key == "left" then
        if value == true and not self.input.left then
            self.input.left = true
        elseif value == false and self.input.left then
            self.input.left = false
        end
    end
    if key == "up" then
        if value == true and not self.input.up then
            self.input.up = true
        elseif value == false and self.input.up then
            self.input.up = false
        end
    end
    if key == "right" then
        if value == true and not self.input.right then
            self.input.right = true
        elseif value == false and self.input.right then
            self.input.right = false
        end
    end
    if key == "down" then
        if value == true and not self.input.down then
            self.input.down = true
        elseif value == false and self.input.down then
            self.input.down = false
        end
    end
    self:changeDirection()

    if key == "jump" then
        if value == true then
            self.input.jump = true
            self:jumpAction()
        elseif value == false then
            self.input.jump = false
        end
    end
end

function Player:getUnitVector()
    vectors = {}
    if self.input.left then table.insert(vectors, {x = -1, y = 0}) end
    if self.input.up then table.insert(vectors, {x = 0, y = -1}) end
    if self.input.right then table.insert(vectors, {x = 1, y = 0}) end
    if self.input.down then table.insert(vectors, {x = 0, y = 1}) end
    if #vectors < 1 then
        return {x = 0, y = 0}
    end

    -- else, evaluate the unit vector
    combined_vector = {x = 0, y = 0}
    for key, vector in ipairs(vectors) do
        combined_vector.x = combined_vector.x + vector.x
        combined_vector.y = combined_vector.y + vector.y
    end
    -- now we need to get the direction to be at a length of one
    magnitude = math.sqrt(combined_vector.x^2 + combined_vector.y^2)     -- get magnitude of combined vector:
    unit_vector = {x = combined_vector.x/magnitude, y = combined_vector.y/magnitude}     -- divide combined_vector by magnitude to get the unit vector
    return unit_vector
end

function Player:changeDirection()
    -- get movement via direction as a unit vector
    direction = self:getUnitVector()
    self.acceleration.direction = direction
    if direction == {x = 0, y = 0} then
        self.acceleration.x = 0
        self.acceleration.y = 0
    else
        self.acceleration.x = direction.x * self.acceleration.move
        self.acceleration.y = direction.y * self.acceleration.move
    end
end

function Player:falling()
    self.acceleration.z = self.acceleration.gravity
    self.position.onGround = false
end

function Player:hitGround(platform)
    if math.abs(self.velocity.z) >= self.velocity.fall_damage_threshold then
        self:takeDamage(math.floor(math.abs(self.velocity.z)/self.velocity.fall_damage_threshold))
    end
    self.position.onGround = true
    self.acceleration.z = 0
    self.velocity.z = 0
    self.position.z = platform.z
    self.velocity.jumps = self.velocity.max_jumps
end

function Player:takeDamage(damage)
    self.health.bars = self.health.bars - damage
    -- then determine current state of being
    if self.health.bars <= self.health.states.dead then
        self.health.state = self.health.states.dead

    -- elseif self.health.bars <= self.health.states.bloodied then
    --     self.health.state = self.health.states.bloodied

    -- elseif self.health.bars <= self.health.states.injured then
    --     self.health.state = self.health.states.injured
    end
end
-- damage = velocity * mass

function Player:jumpAction()
    if self:canJump() then self:jump()
    else return end
end

function Player:jump()
    jump_force = self.velocity.ground_jump_force
    if self.position.onGround and not self.velocity.ground_jump or not self.position.onGround then
        self.velocity.jumps = self.velocity.jumps - 1
        jump_force = self.velocity.air_jump_force
    end
    if self.velocity.z < 0 then
        self.velocity.z = jump_force
    else
        self.velocity.z = self.velocity.z + jump_force
    end
    self.input.jump = false
    self:falling()
end

function Player:canJump()
    if self.position.onGround and self.velocity.ground_jump then
        return true
    elseif not self.position.onGround and self.velocity.jumps >= 1 then
        return true
    end
    return false
end

function Player:drag(dt)
    self.velocity.x = self.velocity.x - self.velocity.x * self.acceleration.drag.x * dt
    self.velocity.y = self.velocity.y - self.velocity.y * self.acceleration.drag.y * dt
    self.velocity.z = self.velocity.z - self.velocity.z * self.acceleration.drag.z * dt
    -- self.acceleration.drag.z = math.abs(self.velocity.z)/self.velocity.max_z

    if self.acceleration.direction.x == 0 then
        self.acceleration.drag.x = 0.8
    else
        self.acceleration.drag.x = math.abs(self.velocity.x)/self.velocity.max_x
    end

    if self.acceleration.direction.y == 0 then
        self.acceleration.drag.y = 0.8
    else
        self.acceleration.drag.y = math.abs(self.velocity.y)/self.velocity.max_y
    end
    -- if self.velocity.x <= 0.0001 then self.velocity.x = 0 end
    -- if self.velocity.y <= 0.0001 then self.velocity.y = 0 end
    -- if self.velocity.z <= 0.0001 then self.velocity.z = 0 end
end

Healthbar = {}
function Healthbar:new(x1, y1, x2, y2, segments, units)
    h = {
        position = {
            x1 = x1,
            y1 = y1,
            x2 = x2,
            y2 = y2,
        }
    }
    setmetatable(h, self)
    self.__index = self
    return h
end

width, height = love.graphics.getDimensions()
mousePos = {
    x = 0,
    y = 0,
}
player = Player:new(0, 0, 0)
platforms = {}
platform = Platform:new(0, 0, 0, 50, player)
platform2 = Platform:new(145, 145, 25, 50, player)
platform3 = Platform:new(185, -130, -50, 50, player)
table.insert(platforms, platform)
table.insert(platforms, platform2)
table.insert(platforms, platform3)


function love.update(dt)
    mousePos.x, mousePos.y = love.mouse.getPosition()
    player:move(dt)
    for key, platform in pairs(platforms) do
        platform:onPlatform(player)
    end
end

function love.draw()
    love.graphics.clear(1,1,0, 1)
    -- draw world centered around player
    love.graphics.push()
    love.graphics.translate(-player.position.x+width/2, -player.position.y+width/2)
    for key, platform in pairs(platforms) do
        platform:draw()
    end
    player:draw()
    love.graphics.pop()
    -- draw cursor
    love.graphics.setColor(love.math.random(70, 90)/100, love.math.random(80, 100)/100, love.math.random(30, 40)/100, love.math.random(20, 100)/100)
    love.graphics.ellipse("fill", mousePos.x, mousePos.y, love.math.random(500, 600)/100, love.math.random(500, 600)/100)
    love.graphics.setColor(0.6, 0.2, 0, 1)
    -- draw text
    position = [[position:   x: ]]..player.position.x..[[
    y: ]]..player.position.y..[[
    z: ]]..player.position.z
    velocity = [[velocity:   x: ]]..player.velocity.x..[[
    y: ]]..player.velocity.y..[[
    z: ]]..player.velocity.z
    acceleration = [[acceleration:   x: ]]..player.acceleration.x..[[
    y: ]]..player.acceleration.y..[[
    z: ]]..player.acceleration.z
    drag = [[drag:   x: ]]..player.acceleration.drag.x..[[
    y: ]]..player.acceleration.drag.y..[[
    z: ]]..player.acceleration.drag.z
    onGround = "on ground: ".. tostring(player.position.onGround)
    jumps = "jumps: "..player.velocity.jumps
    health = "health: "..player.health.bars.."    state: "..player.health.state
    love.graphics.print(position, 20, 20)
    love.graphics.print(velocity, 20, 40)
    love.graphics.print(acceleration, 20, 60)
    love.graphics.print(drag, 20, 80)
    love.graphics.print(onGround, 20, 100)
    love.graphics.print(jumps, 20, 120)
    love.graphics.print(health, 20, 140)
end

function love.keypressed(key, scancode, isrepeat)
    if key == "a" or key == "left" then
        player:setInput("left", true)
    end
    if key == "w" or key == "up" then
        player:setInput("up", true)
    end
    if key == "d" or key == "right" then
        player:setInput("right", true)
    end
    if key == "s" or key == "down" then
        player:setInput("down", true)
    end
    if key == "space" then
        player:setInput("jump", true)
    end
end

function love.keyreleased(key)
    if key == "a" or key == "left" then
        player:setInput("left", false)
    end
    if key == "w" or key == "up" then
        player:setInput("up", false)
    end
    if key == "d" or key == "right" then
        player:setInput("right", false)
    end
    if key == "s" or key == "down" then
        player:setInput("down", false)
    end
    if key == "space" then
        player:setInput("jump", false)
    end
end