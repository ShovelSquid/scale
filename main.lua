-- gonna be making some recursive shi
Platform = {}
function Platform:new(x, y, z, r)
    p = {
        x = x,
        y = y,
        z = z,
        r = r,
    }
    setmetatable(p, self)
    self.__index = self
    return p
end

function Platform:branch()
    -- get the next recursive things

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
        },
        velocity = {
            x = 0,          -- change in x position
            y = 0,          -- change in y position
            z = 0,          -- change in z position
            max_x = 150,
            max_y = 150,
            max_z = 150,
            fall_damage_threshold = 10,
            jump_force = 3,
            ground_jump = true,
            jumps = 1,
            max_jumps = 1,
        },
        acceleration = {
            x = 0,          -- change in x velocity
            y = 0,          -- change in y velocity
            z = 0,          -- change in z velocity
            gravity = -9.8,  -- change to apply in z velocity
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
        }
    }
    setmetatable(p, self)
    self.__index = self
    return p
end

function Player:draw()
    love.graphics.push()
    love.graphics.translate(self.position.x, self.position.y)
    love.graphics.scale(2)
    love.graphics.setColor(1, 0.5, 0, 1)
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
        return nil
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
    if direction == nil then
        self.acceleration.x = 0
        self.acceleration.y = 0
    else
        self.acceleration.direction = direction
        self.acceleration.x = direction.x * self.acceleration.move
        self.acceleration.y = direction.y * self.acceleration.move
    end
end

function Player:falling()
    self.acceleration.z = self.acceleration.gravity
    self.position.onGround = false
end

function Player:hitGround()
    if self.velocity.z >= self.velocity.fall_damage_threshold then
        self:takeDamage(math.floor(self.velocity.z/self.velocity.fall_damage_threshold))
    end
    self.position.onGround = true
    self.velocity.jumps = self.velocity.max_jumps
end

function Player:takeDamage(damage)
    self.health.bars = self.health.bars - damage
    -- then determine current state of being
    if self.health.bars <= self.health.dead then
        self.health.state = self.health.states.dead

    elseif self.health.bars <= self.health.bloodied then
        self.health.state = self.health.states.bloodied

    elseif self.health.bars <= self.health.injured then
        self.health.state = self.health.states.injured
    end
end
-- damage = velocity * mass

function Player:jumpAction()
    if self:canJump() then self:jump()
    else return end
end

function Player:jump()
    if self.position.onGround and not self.velocity.ground_jump or not self.position.onGround then
        self.velocity.jumps = self.velocity.jumps - 1
    end
    self.velocity.z = self.velocity.jump_force
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
    self.acceleration.drag.x = math.abs(self.velocity.x)/self.velocity.max_x
    self.acceleration.drag.y = math.abs(self.velocity.y)/self.velocity.max_y
    self.acceleration.drag.z = math.abs(self.velocity.z)/self.velocity.max_z
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





mousePos = {
    x = 0,
    y = 0,
}
player = Player:new(0, 0, 0)
function love.update(dt)
    mousePos.x, mousePos.y = love.mouse.getPosition()
    player:move(dt)
end

function love.draw()
    love.graphics.clear(1,1,0, 1)
    love.graphics.setColor(love.math.random(70, 90)/100, love.math.random(80, 100)/100, love.math.random(30, 40)/100, love.math.random(20, 100)/100)
    love.graphics.ellipse("fill", mousePos.x, mousePos.y, love.math.random(500, 600)/100, love.math.random(500, 600)/100)
    player:draw()
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
    love.graphics.print(position, 20, 20)
    love.graphics.print(velocity, 20, 40)
    love.graphics.print(acceleration, 20, 60)
    love.graphics.print(drag, 20, 80)
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