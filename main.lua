mousePos = {
    x = 0,
    y = 0,
}
function love.update(dt)
    mousePos.x, mousePos.y = love.mouse.getPosition()
end

function love.draw()
    love.graphics.clear(1,1,0, 1)
    love.graphics.setColor(love.math.random(0, 100)/100, love.math.random(0, 100)/100, love.math.random(0, 100)/100, love.math.random(20, 100)/100)
    love.graphics.ellipse("fill", mousePos.x, mousePos.y, love.math.random(2000, 9500)/100, love.math.random(2000, 9500)/100)
end