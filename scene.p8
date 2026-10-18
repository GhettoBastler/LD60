Scene = Object:extend()

function Scene:init()
end


function Scene:update()
end

function Scene:draw()
end

function Scene:enter(...)
    -- reset camera
    camera()
    -- reset menu items
    for i=1, 5 do
        menuitem(i)
    end

    -- game loop
    -- _update = function() self:update() end
    _update60 = function() self:update() end
    _draw = function() self:draw() end

    -- initialize scene
    self:init(...)
end
